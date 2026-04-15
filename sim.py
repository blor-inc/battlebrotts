#!/usr/bin/env python3
"""BattleBrotts headless combat simulator — Sprint 14 balance verification.
Deterministic tick-based simulation matching GDD v2 + Balance Changes v1."""

import random, json, sys
from collections import defaultdict
from dataclasses import dataclass, field
from typing import List, Dict, Tuple

# --- DATA (from weapon_data.gd / chassis_data.gd, post-S14) ---

CHASSIS = {
    "scout":    {"hp": 100, "speed": 220, "weight_cap": 30, "weapon_slots": 1, "module_slots": 3},
    "brawler":  {"hp": 150, "speed": 120, "weight_cap": 55, "weapon_slots": 2, "module_slots": 2},
    "fortress": {"hp": 210, "speed": 60,  "weight_cap": 80, "weapon_slots": 3, "module_slots": 1},
}

WEAPONS = {
    "minigun":       {"damage": 3,  "pellets": 1, "range": 5,   "fire_rate": 10.0, "spread": 15.0, "energy": 2,  "weight": 10},
    "railgun":       {"damage": 45, "pellets": 1, "range": 12,  "fire_rate": 0.6,  "spread": 0.0,  "energy": 16, "weight": 15},
    "shotgun":       {"damage": 6,  "pellets": 5, "range": 3,   "fire_rate": 1.5,  "spread": 30.0, "energy": 8,  "weight": 12},
    "missile_pod":   {"damage": 30, "pellets": 1, "range": 8,   "fire_rate": 0.8,  "spread": 5.0,  "energy": 12, "weight": 18},
    "plasma_cutter": {"damage": 12, "pellets": 1, "range": 1.5, "fire_rate": 3.0,  "spread": 0.0,  "energy": 4,  "weight": 8},
    "arc_emitter":   {"damage": 8,  "pellets": 1, "range": 4,   "fire_rate": 2.0,  "spread": 10.0, "energy": 6,  "weight": 11},
    "flak_cannon":   {"damage": 15, "pellets": 1, "range": 6,   "fire_rate": 1.2,  "spread": 20.0, "energy": 7,  "weight": 13},
}

WEAPON_COSTS = {"minigun": 0, "plasma_cutter": 0, "shotgun": 120, "arc_emitter": 150,
                "flak_cannon": 200, "railgun": 300, "missile_pod": 350}

ARMOR = {
    "plating":       {"dr": 0.20, "weight": 15},
    "reactive_mesh": {"dr": 0.10, "weight": 8},
    "ablative_shell":{"dr": 0.40, "weight": 25},  # drops to 10% below 30% HP
    None:            {"dr": 0.0,  "weight": 0},
}

TICKS_PER_SEC = 20
MAX_TICKS = 120 * TICKS_PER_SEC  # 120s timeout
ENERGY_MAX = 100
ENERGY_REGEN_PER_TICK = 0.25
CRIT_CHANCE = 0.05
CRIT_MULT = 1.5
ARENA_SIZE = 16  # tiles, simple open arena for balance testing

import math

def fire_interval(fire_rate):
    return max(1, math.ceil(TICKS_PER_SEC / fire_rate))

@dataclass
class Brott:
    chassis: str
    weapons: List[str]
    armor: str = None
    hp: float = 0
    max_hp: float = 0
    energy: float = ENERGY_MAX
    x: float = 0
    y: float = 0
    speed_per_tick: float = 0
    weapon_timers: List[int] = field(default_factory=list)
    shots_fired: Dict[str, int] = field(default_factory=lambda: defaultdict(int))

    def __post_init__(self):
        c = CHASSIS[self.chassis]
        self.max_hp = c["hp"]
        self.hp = self.max_hp
        self.speed_per_tick = c["speed"] / TICKS_PER_SEC / 32.0  # tiles per tick
        self.weapon_timers = [0] * len(self.weapons)

    def alive(self):
        return self.hp > 0

    def armor_dr(self):
        if self.armor == "ablative_shell" and self.hp < self.max_hp * 0.3:
            return 0.10
        return ARMOR.get(self.armor, ARMOR[None])["dr"]

    def equip_value(self):
        val = 0
        for w in self.weapons:
            val += WEAPON_COSTS.get(w, 0)
        # armor costs omitted for simplicity (plating is free starter)
        return val


def build_loadouts(chassis: str) -> List[List[str]]:
    """Generate reasonable weapon loadouts for a chassis."""
    slots = CHASSIS[chassis]["weapon_slots"]
    cap = CHASSIS[chassis]["weight_cap"]
    # For each slot count, generate common combos
    wnames = list(WEAPONS.keys())
    loadouts = []
    if slots == 1:
        for w in wnames:
            if WEAPONS[w]["weight"] <= cap:
                loadouts.append([w])
    elif slots == 2:
        for i, w1 in enumerate(wnames):
            for w2 in wnames[i:]:
                if WEAPONS[w1]["weight"] + WEAPONS[w2]["weight"] <= cap:
                    loadouts.append([w1, w2])
    else:  # 3 slots
        for i, w1 in enumerate(wnames):
            for j, w2 in enumerate(wnames[i:], i):
                for w3 in wnames[j:]:
                    total = WEAPONS[w1]["weight"] + WEAPONS[w2]["weight"] + WEAPONS[w3]["weight"]
                    if total <= cap:
                        loadouts.append([w1, w2, w3])
    return loadouts if loadouts else [[wnames[0]] * slots]


def simulate_match(b1: Brott, b2: Brott, rng: random.Random) -> Tuple[int, int, float]:
    """Run one match. Returns (winner 1 or 2 or 0=draw, ticks, shot_counts merged)."""
    # Place brotts on opposite sides
    b1.x, b1.y = 2.0, ARENA_SIZE / 2.0
    b2.x, b2.y = ARENA_SIZE - 2.0, ARENA_SIZE / 2.0
    b1.hp = b1.max_hp; b2.hp = b2.max_hp
    b1.energy = ENERGY_MAX; b2.energy = ENERGY_MAX
    b1.weapon_timers = [0] * len(b1.weapons)
    b2.weapon_timers = [0] * len(b2.weapons)

    for tick in range(MAX_TICKS):
        # Movement: close distance (simple aggressive stance)
        for attacker, defender in [(b1, b2), (b2, b1)]:
            dx = defender.x - attacker.x
            dy = defender.y - attacker.y
            dist = math.sqrt(dx*dx + dy*dy)
            if dist > 0.5:
                # Move toward, but try to maintain min weapon range for kiting if scout
                target_dist = 0.5
                if attacker.chassis == "scout":
                    # Kiting: maintain max weapon range * 0.7
                    max_range = max(WEAPONS[w]["range"] for w in attacker.weapons)
                    target_dist = max_range * 0.7
                if dist > target_dist:
                    move = min(attacker.speed_per_tick, dist - target_dist)
                    attacker.x += (dx / dist) * move
                    attacker.y += (dy / dist) * move

        # Energy regen
        b1.energy = min(ENERGY_MAX, b1.energy + ENERGY_REGEN_PER_TICK)
        b2.energy = min(ENERGY_MAX, b2.energy + ENERGY_REGEN_PER_TICK)

        # Weapon fire
        for attacker, defender in [(b1, b2), (b2, b1)]:
            dx = defender.x - attacker.x
            dy = defender.y - attacker.y
            dist = math.sqrt(dx*dx + dy*dy)
            for i, wname in enumerate(attacker.weapons):
                w = WEAPONS[wname]
                attacker.weapon_timers[i] = max(0, attacker.weapon_timers[i] - 1)
                if attacker.weapon_timers[i] > 0:
                    continue
                if dist > w["range"]:
                    continue
                if attacker.energy < w["energy"]:
                    continue
                # Fire
                attacker.energy -= w["energy"]
                attacker.weapon_timers[i] = fire_interval(w["fire_rate"])
                attacker.shots_fired[wname] += 1

                # Hit calc
                pellets = w["pellets"]
                for _ in range(pellets):
                    # Spread hit check: angle offset
                    if w["spread"] > 0 and dist > 0.5:
                        offset_angle = rng.uniform(-w["spread"]/2, w["spread"]/2)
                        # Simple: miss if offset causes projectile to miss target hitbox (0.375 tile radius)
                        miss_dist = dist * math.tan(math.radians(abs(offset_angle)))
                        if miss_dist > 0.375:
                            continue
                    # Damage
                    base_dmg = w["damage"]
                    dr = defender.armor_dr()
                    crit = rng.random() < CRIT_CHANCE
                    eff_dmg = base_dmg * (1 - dr) * (CRIT_MULT if crit else 1.0)
                    eff_dmg = max(1.0, eff_dmg)
                    defender.hp -= eff_dmg

                    # Reactive mesh reflect
                    if defender.armor == "reactive_mesh":
                        attacker.hp -= 5

                if not defender.alive():
                    break
            if not b1.alive() or not b2.alive():
                break

        if not b1.alive() or not b2.alive():
            winner = 1 if b1.alive() else 2
            return winner, tick, tick / TICKS_PER_SEC

    # Timeout: higher HP% wins
    hp1_pct = b1.hp / b1.max_hp
    hp2_pct = b2.hp / b2.max_hp
    if hp1_pct > hp2_pct:
        return 1, MAX_TICKS, 120.0
    elif hp2_pct > hp1_pct:
        return 2, MAX_TICKS, 120.0
    return 0, MAX_TICKS, 120.0


def run_simulations(n_per_matchup=170, seed=42):
    """Run simulations across all chassis matchups."""
    rng = random.Random(seed)
    chassis_list = ["scout", "brawler", "fortress"]

    # Results
    chassis_wins = defaultdict(int)
    chassis_matches = defaultdict(int)
    matchup_wins = {}  # (c1, c2) -> [c1_wins, c2_wins, draws]
    weapon_shots = defaultdict(int)
    ttk_list = []
    timeouts = 0
    total_matches = 0

    for c1 in chassis_list:
        for c2 in chassis_list:
            key = (c1, c2)
            matchup_wins[key] = [0, 0, 0]
            # Get loadouts for each
            loadouts1 = build_loadouts(c1)
            loadouts2 = build_loadouts(c2)

            for _ in range(n_per_matchup):
                # Random loadout + armor
                weapons1 = rng.choice(loadouts1)
                weapons2 = rng.choice(loadouts2)
                armor1 = rng.choice(["plating", "reactive_mesh", None])
                armor2 = rng.choice(["plating", "reactive_mesh", None])
                # Check weight
                a1w = ARMOR.get(armor1, ARMOR[None])["weight"]
                a2w = ARMOR.get(armor2, ARMOR[None])["weight"]
                w1_total = sum(WEAPONS[w]["weight"] for w in weapons1) + a1w
                w2_total = sum(WEAPONS[w]["weight"] for w in weapons2) + a2w
                if w1_total > CHASSIS[c1]["weight_cap"]:
                    armor1 = None
                if w2_total > CHASSIS[c2]["weight_cap"]:
                    armor2 = None

                b1 = Brott(c1, weapons1, armor1)
                b2 = Brott(c2, weapons2, armor2)

                winner, ticks, ttk = simulate_match(b1, b2, rng)
                total_matches += 1
                ttk_list.append(ttk)
                if ttk >= 120.0:
                    timeouts += 1

                chassis_matches[c1] += 1
                chassis_matches[c2] += 1

                if winner == 1:
                    chassis_wins[c1] += 1
                    matchup_wins[key][0] += 1
                elif winner == 2:
                    chassis_wins[c2] += 1
                    matchup_wins[key][1] += 1
                else:
                    matchup_wins[key][2] += 1

                # Aggregate shots
                for wn, cnt in b1.shots_fired.items():
                    weapon_shots[wn] += cnt
                for wn, cnt in b2.shots_fired.items():
                    weapon_shots[wn] += cnt

    return {
        "total_matches": total_matches,
        "chassis_wins": dict(chassis_wins),
        "chassis_matches": dict(chassis_matches),
        "matchup_wins": {f"{k[0]}_vs_{k[1]}": v for k, v in matchup_wins.items()},
        "weapon_shots": dict(weapon_shots),
        "ttk_list": sorted(ttk_list),
        "timeouts": timeouts,
    }


def economy_sim(n_matches=200, win_rate=0.5, seed=99):
    """Simulate economy flow for a player progressing through the game."""
    rng = random.Random(seed)
    bolts = 0
    equip_value = 0  # start with free gear
    purchases = []
    # Item unlock order (rough progression)
    shop = [
        ("Overclock", 100), ("Shotgun", 120), ("Repair Nanites", 120),
        ("Arc Emitter", 150), ("Reactive Mesh", 150), ("Sensor Array", 150),
        ("Afterburner", 180), ("Brawler", 200), ("Flak Cannon", 200),
        ("Shield Projector", 200), ("EMP Charge", 250), ("Railgun", 300),
        ("Ablative Shell", 300), ("Missile Pod", 350), ("Fortress", 400),
    ]
    shop_idx = 0
    first_wins = set()  # opponents beaten for first time
    opponent_pool = list(range(26))  # 26 total opponents

    log = []
    for match in range(1, n_matches + 1):
        won = rng.random() < win_rate
        opponent = rng.choice(opponent_pool)
        first_win = won and opponent not in first_wins

        # Earnings
        earn = 100 if won else 40
        if first_win:
            earn = 200  # first-win bonus replaces normal win
            first_wins.add(opponent)

        # Repair: 5% on win, 15% on loss (S14 rates)
        repair_rate = 0.05 if won else 0.15
        repair = int(equip_value * repair_rate)
        net = earn - repair
        bolts += net

        # Try to buy
        while shop_idx < len(shop) and bolts >= shop[shop_idx][1]:
            item, cost = shop[shop_idx]
            bolts -= cost
            equip_value += cost
            purchases.append((match, item, cost))
            shop_idx += 1

        if match in [5, 10, 20, 30, 50, 100]:
            log.append({"match": match, "bolts": bolts, "equip_value": equip_value,
                        "items_bought": shop_idx, "net_this_match": net})

    return {"purchases": purchases, "checkpoints": log, "final_bolts": bolts,
            "items_bought": shop_idx, "total_items": len(shop)}


if __name__ == "__main__":
    print("Running combat simulations...", file=sys.stderr)
    results = run_simulations(n_per_matchup=170, seed=42)  # 170*9 = 1530 matches
    print("Running economy simulation...", file=sys.stderr)
    econ = economy_sim()
    print(json.dumps({"combat": results, "economy": econ}, default=str))
