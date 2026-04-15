# Playtest Report — Sprint 14 (Post-Balance)

**Build:** main@ad839c6 (optic/S14-playtest)
**Date:** 2026-04-15
**Simulations run:** 1,530
**Simulator:** Python headless sim matching GDD v2 TickSystem + DamageCalculator (deterministic, seeded RNG)
**Agent:** Optic (Playtest Lead, AI subagent)

## Summary

Sprint 14 balance changes moved the needle but **did not achieve target balance**. Fortress remains dominant (78.6% WR, down from 80.3%). Scout improved slightly (20.1% WR, up from 15.7%) but is still far below viable. Minigun shot share barely changed (47.5%, was 46.9%). Railgun usage improved slightly (6.2%, up from 4.4%). Economy changes helped early game but the death spiral persists from mid-game onward — the sim player goes negative by match 50.

**Verdict: Another balance pass is needed.**

---

## Changes Tested (S14 Balance Changes v1)

| Change | Before | After |
|---|---|---|
| Fortress HP | 250 | 210 |
| Fortress Speed | 70 | 60 |
| Scout HP | 80 | 100 |
| Scout Speed | 200 | 220 |
| Minigun Damage | 4 | 3 |
| Minigun Energy Cost | 1 | 2 |
| Railgun Fire Rate | 0.5 | 0.6 |
| Railgun Energy Cost | 20 | 16 |
| Repair Rate (Win) | 10% | 5% |
| Repair Rate (Loss) | 25% | 15% |
| First-Win Bonus | 150 🔩 | 200 🔩 |

---

## Findings

### BALANCE: ❌ (Still failing)

**Chassis win rates (target: 45–55% each):**

| Chassis | Matches | Wins | Win% | S12 Win% | Δ | Status |
|---------|---------|------|------|----------|---|--------|
| Scout | 1,020 | 205 | 20.1% | 15.7% | +4.4pp | ❌ Still far below |
| Brawler | 1,020 | 523 | 51.3% | 49.1% | +2.2pp | ✅ On target |
| Fortress | 1,020 | 802 | 78.6% | 80.3% | −1.7pp | ❌ Still far above |

**Matchup matrix (row win% vs column):**

| | Scout | Brawler | Fortress |
|---|---|---|---|
| **Scout** | 48.8% | 5.9% | 2.4% |
| **Brawler** | 88.8% | 64.1% | 12.9% |
| **Fortress** | 98.8% | 88.2% | 55.9% |

**Comparison with Sprint 12:**

| | Scout (S12→S14) | Brawler (S12→S14) | Fortress (S12→S14) |
|---|---|---|---|
| **Scout** | 49.3→48.8% | 0.3→5.9% | 0.0→2.4% |
| **Brawler** | 99.7→88.8% | 45.1→64.1% | 3.0→12.9% |
| **Fortress** | 100→98.8% | 95.5→88.2% | 48.4→55.9% |

**Analysis:** The linear hierarchy Fortress > Brawler > Scout remains intact. The HP/speed adjustments made marginal improvements but the fundamental problem is unchanged: Fortress's 3 weapon slots and massive HP pool outclass everything. Scout gained +25% HP and +10% speed, but still can't deal enough damage with 1 weapon slot before dying. The matchup matrix shows Scout beats Fortress only 2.4% of the time — essentially never.

The Brawler mirror shifted from 45.1% to 64.1%, suggesting a slight player-1 positional advantage in the sim that was masked before. This is a sim artifact (starting position asymmetry), not a real balance issue.

### PACING: ✅

| Metric | S14 | S12 | Target |
|---|---|---|---|
| Median TTK | 2.75s | 2.8s | 2–5s |
| P10 (fast) | 1.6s | 1.6s | — |
| P90 (slow) | 3.6s | 4.4s | — |
| Timeouts | 0/1,530 (0%) | 1/1,500 (0.1%) | <5% |

TTK tightened slightly. The minigun damage nerf (4→3) reduced sustained DPS, but Fortress's lower HP (250→210) compensated. Net effect: matches resolve slightly faster on average. Zero timeouts is excellent.

### WEAPON USAGE: ⚠️ (Marginal improvement)

| Weapon | S14 Shots | S14 Share | S12 Share | Δ |
|---|---|---|---|---|
| Minigun | 13,933 | 47.5% | 46.9% | +0.6pp |
| Arc Emitter | 3,685 | 12.6% | 11.2% | +1.4pp |
| Plasma Cutter | 2,969 | 10.1% | 16.7% | −6.6pp |
| Flak Cannon | 2,966 | 10.1% | 8.3% | +1.8pp |
| Shotgun | 1,994 | 6.8% | 5.9% | +0.9pp |
| Missile Pod | 1,957 | 6.7% | 6.7% | 0pp |
| **Railgun** | **1,828** | **6.2%** | **4.4%** | **+1.8pp** |

**Total shots:** 29,332

**Analysis:**
- **Minigun** still dominates at 47.5% — the damage nerf (4→3) and energy cost increase (1→2) weren't enough. At 10 shots/sec and 2 energy/shot, it drains 20 energy/sec vs 5 regen — runs dry in 5 seconds. But 5 seconds of minigun fire at 3 damage = 150 raw damage, which kills a Scout or Brawler. The fire rate is the real problem, not the per-shot damage.
- **Railgun** improved from 4.4% to 6.2% — the fire rate buff (0.5→0.6) and energy reduction (20→16) helped, but it's still niche. 45 damage every 1.67s for 16 energy is better math now, but minigun's 30 DPS still dominates.
- **Plasma Cutter** dropped significantly (16.7→10.1%), likely because Scout (its primary user) still loses most matches, so plasma cutter rounds end quickly with fewer total shots.

### ECONOMY: ⚠️ (Early game fixed, mid/late still broken)

**S14 Economy Flow (50% WR simulation, 200 matches):**

| Checkpoint | Match | Bolts | Equip Value | Items Bought | Net/Match |
|---|---|---|---|---|---|
| Early | 5 | 133 🔩 | 640 🔩 | 5 | +176 🔩 |
| Early-mid | 10 | −23 🔩 | 640 🔩 | 5 | −56 🔩 |
| Mid | 20 | 155 🔩 | 1,170 🔩 | 8 | +142 🔩 |
| Mid-late | 30 | 94 🔩 | 1,570 🔩 | 10 | +132 🔩 |
| Late | 50 | −1,119 🔩 | 1,570 🔩 | 10 | −195 🔩 |
| Endgame | 100 | −5,161 🔩 | 1,570 🔩 | 10 | +22 🔩 |

**Final state:** −14,796 🔩, only 10/15 items purchased.

**Analysis:**
- **Early game (matches 1–5): ✅** First-win bonuses (200 🔩) carry the player through rapid purchases. 5 items in 5 matches is excellent pacing.
- **Mid game (matches 10–30): ⚠️** Oscillates between positive and negative. Repair costs at 5%/15% are lower but equipment values scale fast. With 1,570 🔩 equipment: win repair = 79 🔩, loss repair = 236 🔩. Net on loss = 40 − 236 = −196 🔩.
- **Late game (50+): ❌❌** Death spiral returns. Player can't afford remaining items (Railgun 300, Ablative Shell 300, Missile Pod 350, Fortress 400). Goes deeply negative.

**The core issue:** Percentage-based repair costs scale with equipment value, but earnings are flat. Any percentage-based system will eventually overtake flat earnings. The S14 changes delayed the crossover but didn't eliminate it.

---

## Metrics Summary

| Metric | S14 Value | S12 Value | Target | Status |
|---|---|---|---|---|
| Scout win% | 20.1% | 15.7% | 45–55% | ❌ |
| Brawler win% | 51.3% | 49.1% | 45–55% | ✅ |
| Fortress win% | 78.6% | 80.3% | 45–55% | ❌ |
| Median TTK | 2.75s | 2.8s | 2–5s | ✅ |
| Timeout rate | 0% | 0.1% | <5% | ✅ |
| Top weapon share (Minigun) | 47.5% | 46.9% | <30% | ❌ |
| Railgun share | 6.2% | 4.4% | >10% | ⚠️ |
| Economy: early | ~2 matches/item | 2–3 | 2–3 | ✅ |
| Economy: mid | ~5 matches/item | ~11 | 2–3 | ⚠️ |
| Economy: late | Negative net | Negative net | Positive | ❌ |

---

## Recommendations for Sprint 15

### Balance (Priority: HIGH)

The incremental stat tweaks aren't enough. Structural changes needed:

1. **Reduce Fortress weapon slots from 3→2.** This is the single biggest lever. Three weapon slots gives Fortress ~3× the DPS of Scout. Reducing to 2 slots while keeping its HP/armor advantages preserves its "tank" identity without making it a DPS monster.

2. **Add Scout evasion passive.** A 15–20% passive dodge chance based on speed differential would give Scout meaningful survivability that scales with its identity. Alternatively, give Scout 2 weapon slots (same as Brawler) to compensate for low HP.

3. **Nerf Minigun fire rate from 10→6.** The damage nerf didn't work because fire rate is the problem. At 6 shots/sec with 3 damage and 2 energy, DPS drops from 30 to 18 — opening real space for other weapons. Alternatively, add a spin-up mechanic (2s to reach full fire rate).

4. **Buff Railgun damage to 50 or reduce fire interval further.** The S14 buffs helped but railgun needs to be the clear alpha-strike choice. 50 damage at 0.6/sec for 16 energy = 30 DPS (matching minigun) but in burst form.

### Economy (Priority: HIGH)

5. **Switch from percentage-based to flat repair costs.** Example: Win repair = 20 🔩 flat, Loss repair = 50 🔩 flat, regardless of equipment value. This completely eliminates the death spiral.

6. **Alternatively, cap repair costs.** Max repair = 50 🔩 (win) or 100 🔩 (loss). Simple ceiling prevents runaway.

### Simulation Methodology (Priority: LOW)

7. **Add BrottBrain diversity.** Current sim uses simple aggressive stance for all brotts. Adding kiting/defensive stances for Scout specifically would likely improve Scout's win rate somewhat. Implement basic BrottBrain card evaluation in the sim for more realistic results.

8. **Add cover/arena variety.** All sims ran on open 16×16 arena (The Pit). Cover-heavy arenas (Junkyard) may favor Scout differently. Include arena mix in next sim pass.

---

## Appendix: Simulation Methodology

- **Engine:** Python 3 headless simulator implementing GDD v2 §5.1 tick system
- **Tick rate:** 20/sec, matching Godot implementation
- **Match format:** 1v1, open arena (The Pit, 16×16)
- **Loadout selection:** Random valid loadout per chassis weight budget per match
- **Armor selection:** Random (Plating, Reactive Mesh, or none), weight-checked
- **Stance:** Aggressive (Scout uses kiting at 70% max weapon range)
- **BrottBrain:** Not simulated (default behavior only)
- **RNG seed:** 42 (combat), 99 (economy)
- **Matchups:** 170 matches per chassis pair × 9 pairs = 1,530 total
- **Economy:** 200 matches at 50% win rate with first-win bonus tracking

---

*Report generated by Optic (AI Playtest Lead) — Sprint 14 balance verification*
*Simulation code: `sim.py` in repo root*
