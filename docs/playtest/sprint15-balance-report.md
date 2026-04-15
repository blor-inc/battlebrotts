# Playtest Report — Sprint 15 (Aggressive Balance v2)

**Build:** main@5b1c36a (optic/S15-playtest)
**Date:** 2026-04-15
**Simulations run:** 1,530
**Simulator:** Python headless sim matching GDD v2 TickSystem + DamageCalculator (deterministic, seeded RNG)
**Agent:** Optic (Playtest Lead, AI subagent)

## Summary

Sprint 15's aggressive balance changes made **significant progress** on multiple fronts. Fortress win rate dropped 5.7pp to 72.9% (from 78.6%), minigun shot share dropped 11.3pp to 36.2% (from 47.5%), and the flat repair economy **completely eliminates the death spiral** — all 15 items purchased by match 32 with 6,240 🔩 surplus. However, chassis balance still misses the 45–55% target for both Scout (20.4%) and Fortress (72.9%). The Fortress slot reduction helped but wasn't enough to break the linear hierarchy.

**Verdict: Economy is fixed ✅. Weapon diversity improved ⚠️. Chassis balance still failing ❌.**

---

## Changes Tested (S15 Aggressive Balance v2)

| Change | S14 Value | S15 Value |
|---|---|---|
| Fortress Weapon Slots | 3 | **2** |
| Fortress HP | 210 | 210 (unchanged) |
| Fortress Speed | 60 | 60 (unchanged) |
| Scout HP | 100 | 100 (unchanged) |
| Scout Speed | 220 | 220 (unchanged) |
| Scout Passive | None | **15% Dodge** |
| Minigun Fire Rate | 10/sec | **6/sec** |
| Minigun Damage | 3 | 3 (unchanged) |
| Minigun Energy | 2 | 2 (unchanged) |
| Railgun Fire Rate | 0.6 | 0.6 (unchanged) |
| Railgun Energy | 16 | 16 (unchanged) |
| Repair (Win) | 5% of equip value | **20 🔩 flat** |
| Repair (Loss) | 15% of equip value | **50 🔩 flat** |

---

## Findings

### BALANCE: ❌ (Improved but still failing)

**Chassis win rates (target: 45–55% each):**

| Chassis | Matches | Wins | Win% | S14 Win% | S12 Win% | Δ (S14→S15) | Status |
|---------|---------|------|------|----------|----------|-------------|--------|
| Scout | 1,020 | 208 | 20.4% | 20.1% | 15.7% | +0.3pp | ❌ Far below |
| Brawler | 1,020 | 578 | 56.7% | 51.3% | 49.1% | +5.4pp | ⚠️ Slightly over |
| Fortress | 1,020 | 744 | 72.9% | 78.6% | 80.3% | −5.7pp | ❌ Still far above |

**Matchup matrix (row win% vs column):**

| | vs Scout | vs Brawler | vs Fortress |
|---|---|---|---|
| **Scout** | 52.9% | 6.5% | 2.9% |
| **Brawler** | 90.6% | 52.9% | 29.4% |
| **Fortress** | 96.5% | 73.5% | 55.9% |

**Cross-sprint matchup comparison:**

| Matchup | S12 | S14 | S15 | Trend |
|---|---|---|---|---|
| Scout vs Brawler | 0.3% | 5.9% | 6.5% | 📈 Slow improvement |
| Scout vs Fortress | 0.0% | 2.4% | 2.9% | 📈 Minimal |
| Brawler vs Fortress | 3.0% | 12.9% | **29.4%** | 📈📈 Big jump |
| Fortress vs Brawler | 95.5% | 88.2% | **73.5%** | 📉📉 Significant nerf |

**Analysis:**

The Fortress weapon slot reduction (3→2) had the **biggest single impact** of any change across three sprints. Brawler vs Fortress jumped from 12.9% to 29.4% — Brawler is now competitive against Fortress in nearly a third of matchups. This validates the S14 report's top recommendation.

However, **Scout remains non-viable**. The 15% dodge passive barely moved the needle (+0.3pp overall). The fundamental problem: Scout has 1 weapon slot, low HP, and its speed advantage doesn't translate into enough survivability against multi-weapon opponents. Dodge at 15% isn't enough when you're taking 2–6 hits per weapon cycle.

Brawler crept above target to 56.7%. This is a side effect of Fortress getting weaker — Brawler picks up the wins that Fortress lost, while Scout stays flat. The three-way dynamic hasn't emerged; it's still a two-tier system (Brawler/Fortress viable, Scout not).

### PACING: ✅

| Metric | S15 | S14 | S12 | Target |
|---|---|---|---|---|
| Median TTK | 3.40s | 2.75s | 2.80s | 2–5s |
| P10 (fast) | 1.70s | 1.60s | 1.60s | — |
| P90 (slow) | 5.10s | 3.60s | 4.40s | — |
| Timeouts | 0/1,530 (0%) | 0/1,530 | 1/1,500 | <5% |

TTK increased notably — median up 0.65s. This is the expected result of minigun fire rate nerf (10→6): sustained DPS dropped from 30 to 18, so matches take longer. Still well within the 2–5s target. P90 at 5.1s is at the upper edge — monitor this. Zero timeouts is still excellent.

### WEAPON USAGE: ⚠️ (Significant improvement, not quite at target)

| Weapon | S15 Shots | S15 Share | S14 Share | S12 Share | Δ (S14→S15) |
|---|---|---|---|---|---|
| **Minigun** | **10,540** | **36.2%** | **47.5%** | **46.9%** | **−11.3pp** |
| Arc Emitter | 4,568 | 15.7% | 12.6% | 11.2% | +3.1pp |
| Plasma Cutter | 4,279 | 14.7% | 10.1% | 16.7% | +4.6pp |
| Flak Cannon | 3,385 | 11.6% | 10.1% | 8.3% | +1.5pp |
| Shotgun | 2,321 | 8.0% | 6.8% | 5.9% | +1.2pp |
| Missile Pod | 2,168 | 7.5% | 6.7% | 6.7% | +0.8pp |
| Railgun | 1,832 | 6.3% | 6.2% | 4.4% | +0.1pp |

**Total shots:** 29,093

**Analysis:**

The minigun fire rate nerf (10→6) **worked**. Shot share dropped from 47.5% to 36.2% — the single largest improvement in weapon diversity across all three sprints. At 6 shots/sec and 2 energy/shot, minigun DPS is now 18 (down from 30), making it no longer the default best-in-slot.

However, 36.2% is still above the <30% target. Minigun remains the most-used weapon because: (a) it's free (0 🔩 cost), (b) it's the lightest weapon (10 weight), and (c) it fires continuously at any range up to 5 tiles. Its versatility is the issue now, not its raw power.

The big winners are **Arc Emitter** (12.6→15.7%) and **Plasma Cutter** (10.1→14.7%). Both benefit from longer matches giving melee/short-range weapons more time to engage. Flak Cannon also gained.

**Railgun barely moved** (6.2→6.3%). The S15 changes didn't touch railgun further, and the Fortress slot reduction actually *hurts* railgun usage — Fortress was railgun's best platform (high weight cap, can pair with other weapons), and losing a slot makes railgun harder to justify. Consider targeted railgun buffs.

### ECONOMY: ✅✅ (Death spiral eliminated)

**S15 Economy Flow (50% WR, 200 matches, flat repair):**

| Checkpoint | Match | Bolts | Equip Value | Items Bought | Net/Match |
|---|---|---|---|---|---|
| Early | 5 | 70 🔩 | 640 🔩 | 5 | +180 🔩 |
| Early-mid | 10 | 110 🔩 | 640 🔩 | 5 | −10 🔩 |
| Mid | 20 | 60 🔩 | 1,820 🔩 | 11 | +180 🔩 |
| Mid-late | 30 | 240 🔩 | 2,770 🔩 | 14 | +180 🔩 |
| Late | 50 | 930 🔩 | 3,170 🔩 | **15** | −10 🔩 |
| Endgame | 100 | 3,090 🔩 | 3,170 🔩 | **15** | +80 🔩 |

**Final state:** 6,240 🔩 surplus, **all 15/15 items purchased by match 32.**

**Comparison with S14 economy:**

| Metric | S14 (%-based) | S15 (Flat) |
|---|---|---|
| Items bought by match 50 | 10/15 | **15/15** |
| Bolts at match 50 | −1,119 🔩 | +930 🔩 |
| Bolts at match 100 | −5,161 🔩 | +3,090 🔩 |
| Final bolts (200 matches) | −14,796 🔩 | **+6,240 🔩** |
| All items purchased? | ❌ Never | ✅ Match 32 |

**Analysis:**

The flat repair system is a **complete fix** for the death spiral. With 20 🔩 repair on wins and 50 🔩 on losses:
- **Win net:** 100 − 20 = +80 🔩 (always positive)
- **Loss net:** 40 − 50 = −10 🔩 (only slightly negative)
- **First-win net:** 200 − 20 = +180 🔩 (big boost)

The key insight: flat costs decouple repair from equipment value. A player with 3,000 🔩 worth of gear pays the same repair as a player with 100 🔩 — no scaling punishment. The 50 🔩 loss penalty is steep enough to feel meaningful but not enough to trap the player.

The player completes the entire shop by match 32 (vs never in S14). Post-shop surplus accumulates healthily. This could eventually fund prestige items, cosmetics, or a New Game+ tier.

**One concern:** Early game match 10 dips to −10 🔩 net (loss with no first-win bonus). This is fine — it creates tension without being punishing. The player recovers immediately on the next win.

---

## Metrics Summary

| Metric | S15 Value | S14 Value | S12 Value | Target | Status |
|---|---|---|---|---|---|
| Scout win% | 20.4% | 20.1% | 15.7% | 45–55% | ❌ |
| Brawler win% | 56.7% | 51.3% | 49.1% | 45–55% | ⚠️ |
| Fortress win% | 72.9% | 78.6% | 80.3% | 45–55% | ❌ |
| Median TTK | 3.40s | 2.75s | 2.80s | 2–5s | ✅ |
| Timeout rate | 0% | 0% | 0.1% | <5% | ✅ |
| Top weapon share (Minigun) | 36.2% | 47.5% | 46.9% | <30% | ⚠️ |
| Railgun share | 6.3% | 6.2% | 4.4% | >10% | ⚠️ |
| Economy: all items purchased | ✅ (match 32) | ❌ (never) | ❌ (never) | ✅ | ✅ |
| Economy: late-game bolts | +930 🔩 | −1,119 🔩 | — | Positive | ✅ |

**Targets hit: 4/9** (TTK, timeouts, economy ×2). **Improved but not at target: 3/9** (Brawler WR, minigun share, railgun share). **Still failing: 2/9** (Scout WR, Fortress WR).

---

## Recommendations for Sprint 16

### Chassis Balance (Priority: CRITICAL)

The slot reduction and dodge passive were right direction but insufficient. Scout needs a **structural buff**, not incremental tuning:

1. **Give Scout 2 weapon slots.** This is the nuclear option. Scout at 1 slot simply cannot compete. With 2 slots (same as Brawler/Fortress now), Scout would differentiate on speed + dodge + low HP. Weight cap of 30 limits Scout to light weapons (minigun + plasma_cutter, or arc_emitter + minigun), keeping loadouts distinct from Brawler's heavier combos.

2. **Increase Scout dodge to 25%.** If keeping 1 weapon slot, 15% dodge isn't enough. At 25%, Scout would survive ~33% longer on average, which could be enough for its single weapon to matter. Test both options (2-slot vs 25% dodge) separately.

3. **Reduce Fortress HP to 180.** Currently 210. At 2 weapon slots, Fortress still has the highest HP by a wide margin. Bringing it to 180 narrows the gap with Brawler (150) while keeping Fortress as the tankiest option.

4. **Consider a rock-paper-scissors mechanic.** The linear hierarchy persists because all stats scale linearly. Adding a mechanic where Scout has advantage over Fortress (e.g., speed-based armor penetration, or Fortress accuracy penalty vs fast targets) would force the triangle the game needs.

### Weapons (Priority: MEDIUM)

5. **Make minigun cost 50 🔩** (currently free). Price gate would naturally reduce adoption, especially early game when players have few bolts. Target: <30% share.

6. **Buff railgun to 50 damage or 0.8 fire rate.** Railgun needs to be the clear choice for burst/sniper builds. With Fortress down to 2 slots, railgun competes against minigun for the same slot — it needs to win that comparison for long-range builds.

### Simulation (Priority: LOW)

7. **Add defensive AI stances.** Scout kiting is implemented but no defensive/evasive behavior. A Scout that actively avoids combat until optimal range could perform much better. This is a sim limitation, not necessarily a game issue.

---

## Appendix: Sprint Progression Summary

| Metric | S12 (Pre-balance) | S14 (Conservative) | S15 (Aggressive) | Trend |
|---|---|---|---|---|
| Scout WR | 15.7% | 20.1% | 20.4% | 📈 Stalled |
| Brawler WR | 49.1% | 51.3% | 56.7% | 📈 Drifting high |
| Fortress WR | 80.3% | 78.6% | 72.9% | 📉 Improving |
| Minigun share | 46.9% | 47.5% | 36.2% | 📉📉 Big improvement |
| Railgun share | 4.4% | 6.2% | 6.3% | 📈 Stalled |
| Economy viable? | ❌ | ❌ | ✅ | Fixed |
| Median TTK | 2.80s | 2.75s | 3.40s | 📈 Longer (expected) |

## Appendix: Simulation Methodology

- **Engine:** Python 3 headless simulator implementing GDD v2 §5.1 tick system
- **Tick rate:** 20/sec, matching Godot implementation
- **Match format:** 1v1, open arena (The Pit, 16×16)
- **Loadout selection:** Random valid loadout per chassis weight budget per match
- **Armor selection:** Random (Plating, Reactive Mesh, or none), weight-checked
- **Stance:** Aggressive (Scout uses kiting at 70% max weapon range)
- **Scout dodge:** 15% chance per pellet to negate damage entirely
- **BrottBrain:** Not simulated (default behavior only)
- **RNG seed:** 42 (combat), 99 (economy)
- **Matchups:** 170 matches per chassis pair × 9 pairs = 1,530 total
- **Economy:** 200 matches at 50% win rate with first-win bonus tracking

---

*Report generated by Optic (AI Playtest Lead) — Sprint 15 balance verification*
*Simulation code: `sim.py` in repo root*
