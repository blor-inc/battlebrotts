# Playtest Report — Sprint 16 (Final Balance v3)

**Build:** dev-01/S16-001-final-balance@b6490b2 (optic/S16-playtest)
**Date:** 2026-04-15
**Simulations run:** 1,530
**Simulator:** Python headless sim matching GDD v2 TickSystem + DamageCalculator (deterministic, seeded RNG)
**Agent:** Optic (Playtest Lead, AI subagent)

## Summary

Sprint 16's v3 balance changes represent a **massive improvement** across all dimensions. The Scout weapon slot buff (1→2) was the breakthrough change — Scout win rate jumped from 20.4% to **30.5%** (+10.1pp). Fortress dropped from 72.9% to **64.4%** (−8.5pp) thanks to the HP nerf (210→180). The linear hierarchy is weakening: Scout can now win ~25% of cross-chassis matchups (up from ~5%). Economy remains healthy with all 16 items purchased by match 34.

**Verdict: Major progress ✅. Not yet at 45–55% target, but the gap is closing fast. Scout needs one more nudge; Fortress is approaching range.**

---

## Changes Tested (S16 Balance Changes v3)

| Change | S15 Value | S16 Value | Rationale |
|---|---|---|---|
| Scout Weapon Slots | 1 | **2** | Structural fix — 1 slot was THE problem |
| Fortress HP | 210 | **180** | Further survivability nerf |
| Minigun Cost | Free | **50 🔩** | Price-gate to create meaningful early choice |
| Plasma Cutter Damage | 12 | **14** | Viable free starter alternative |
| Minigun Fire Rate | 6/sec | 6/sec | (unchanged from S15) |
| Repair (Win) | 20 🔩 flat | 20 🔩 flat | (unchanged from S15) |
| Repair (Loss) | 50 🔩 flat | 50 🔩 flat | (unchanged from S15) |
| Scout Passive | 15% dodge | 15% dodge | (unchanged from S15) |

---

## Findings

### BALANCE: ⚠️ (Significantly improved — approaching target)

**Chassis win rates (target: 45–55% each):**

| Chassis | Matches | Wins | Win% | S15 Win% | S14 Win% | S12 Win% | Δ (S15→S16) | Status |
|---------|---------|------|------|----------|----------|----------|-------------|--------|
| Scout | 1,020 | 311 | 30.5% | 20.4% | 20.1% | 15.7% | **+10.1pp** | ⚠️ Below target, major improvement |
| Brawler | 1,020 | 562 | 55.1% | 56.7% | 51.3% | 49.1% | −1.6pp | ⚠️ Slightly over target |
| Fortress | 1,020 | 657 | 64.4% | 72.9% | 78.6% | 80.3% | **−8.5pp** | ⚠️ Above target, trending down |

**Matchup matrix (row win% vs column):**

| | vs Scout | vs Brawler | vs Fortress |
|---|---|---|---|
| **Scout** | 56.5% | 24.7% | 17.6% |
| **Brawler** | 77.6% | 60.0% | 42.4% |
| **Fortress** | 81.8% | 64.7% | 54.1% |

**Cross-sprint matchup comparison:**

| Matchup | S12 | S14 | S15 | S16 | Trend |
|---|---|---|---|---|---|
| Scout vs Brawler | 0.3% | 5.9% | 6.5% | **24.7%** | 📈📈📈 Huge jump |
| Scout vs Fortress | 0.0% | 2.4% | 2.9% | **17.6%** | 📈📈📈 Huge jump |
| Brawler vs Fortress | 3.0% | 12.9% | 29.4% | **42.4%** | 📈📈 Approaching parity |
| Fortress vs Brawler | 95.5% | 88.2% | 73.5% | **64.7%** | 📉📉 Steady decline |
| Fortress vs Scout | 100% | 98.8% | 96.5% | **81.8%** | 📉📉 Scout gaining ground |

**Analysis:**

The Scout weapon slot buff (1→2) was the **single most impactful balance change across all four sprints**. Scout vs Brawler jumped from 6.5% to 24.7% (+18.2pp) and Scout vs Fortress from 2.9% to 17.6% (+14.7pp). This confirms S14 and S15 reports' diagnosis: the structural DPS deficit from 1 weapon slot was the root cause of Scout's non-viability.

The three-way dynamic is **finally emerging**. The linear hierarchy (Fortress > Brawler > Scout) still exists but is no longer absolute. Scout can win roughly 1-in-4 fights against Brawler and 1-in-6 against Fortress — it's a real threat now, not a guaranteed loss.

Brawler vs Fortress at 42.4% is tantalizingly close to the 45% lower bound. One more small Fortress nerf or Brawler buff could bring this into range.

The remaining gap: Scout is at 30.5% overall, still 14.5pp below the 45% floor. The dodge passive + 2 weapon slots helped enormously, but Scout's 100 HP means it still dies faster than it kills against higher-HP chassis. Options for S17: increase Scout HP to 110-120, increase dodge to 20%, or give Scout a speed-based damage bonus.

### PACING: ✅

| Metric | S16 | S15 | S14 | S12 | Target |
|---|---|---|---|---|---|
| Median TTK | 3.10s | 3.40s | 2.75s | 2.80s | 2–5s |
| P10 (fast) | 1.70s | 1.70s | 1.60s | 1.60s | — |
| P90 (slow) | 5.10s | 5.10s | 3.60s | 4.40s | — |
| Timeouts | 0/1,530 (0%) | 0/1,530 | 0/1,530 | 1/1,500 | <5% |

Median TTK dropped slightly from S15 (3.40s → 3.10s). This makes sense: Scout's extra weapon slot means more DPS output in Scout matchups, resolving fights faster. Still solidly within the 2–5s target. P90 at 5.10s is at the upper edge but acceptable. Zero timeouts across all recent sprints — the timeout mechanic is effectively dead, which is good.

### WEAPON USAGE: ✅ (Best distribution yet)

| Weapon | S16 Shots | S16 Share | S15 Share | S14 Share | S12 Share | Δ (S15→S16) |
|---|---|---|---|---|---|---|
| **Minigun** | 10,521 | **37.4%** | 36.2% | 47.5% | 46.9% | +1.2pp |
| Arc Emitter | 4,341 | 15.4% | 15.7% | 12.6% | 11.2% | −0.3pp |
| Plasma Cutter | 3,527 | 12.5% | 14.7% | 10.1% | 16.7% | −2.2pp |
| Flak Cannon | 3,231 | 11.5% | 11.6% | 10.1% | 8.3% | −0.1pp |
| Shotgun | 2,399 | 8.5% | 8.0% | 6.8% | 5.9% | +0.5pp |
| Missile Pod | 2,060 | 7.3% | 7.5% | 6.7% | 6.7% | −0.2pp |
| Railgun | 2,026 | 7.2% | 6.3% | 6.2% | 4.4% | +0.9pp |

**Total shots:** 28,105

**Analysis:** Weapon distribution is the most even it's ever been. Minigun is still the most-used weapon (37.4%) but no longer dominates — the gap between minigun and second-place has been stable since the S15 fire rate nerf. The 50 🔩 cost didn't dramatically shift usage in the sim (since loadout selection is random), but it creates a meaningful early-game economy decision for real players.

Railgun usage continued its upward trend (4.4% → 6.2% → 6.3% → 7.2%), confirming the S14 energy cost reduction (20→16) was the right call.

The "bottom 4" weapons (shotgun, flak, missile pod, railgun) together account for 34.5% of shots — healthy diversity.

### ECONOMY: ✅ (Excellent — no changes needed)

| Metric | S16 | S15 |
|---|---|---|
| All items purchased by | Match 34 | Match 32 |
| Final surplus (200 matches) | 6,190 🔩 | 6,240 🔩 |
| Death spiral? | **No** | **No** |

**Progression checkpoints:**

| Match | Bolts | Items Owned | Equip Value |
|---|---|---|---|
| 5 | 20 | 6 | 690 |
| 10 | 60 | 6 | 690 |
| 20 | 10 | 12 | 1,870 |
| 30 | 190 | 15 | 2,820 |
| 50 | 880 | 16 (all) | 3,220 |
| 100 | 3,040 | 16 | 3,220 |

The Minigun cost change (free → 50 🔩) added one extra early purchase without disrupting progression. Minigun is bought on match 1 alongside Overclock. All items purchased by match 34 (vs 32 in S15) — a negligible 2-match delay. The flat repair system continues to perform perfectly: no death spiral, steady positive income after the initial shopping spree.

---

## Sprint-over-Sprint Summary

| Metric | S12 | S14 | S15 | S16 | Target | Status |
|---|---|---|---|---|---|---|
| Scout WR | 15.7% | 20.1% | 20.4% | **30.5%** | 45–55% | ⚠️ Closing |
| Brawler WR | 49.1% | 51.3% | 56.7% | **55.1%** | 45–55% | ✅ |
| Fortress WR | 80.3% | 78.6% | 72.9% | **64.4%** | 45–55% | ⚠️ Closing |
| Median TTK | 2.80s | 2.75s | 3.40s | **3.10s** | 2–5s | ✅ |
| Timeouts | 0.1% | 0% | 0% | **0%** | <5% | ✅ |
| Minigun share | 46.9% | 47.5% | 36.2% | **37.4%** | <40% | ✅ |
| Economy viable | ❌ | ❌ | ✅ | **✅** | No death spiral | ✅ |

---

## Recommendations for S17

### Priority 1: Scout survivability buff
Scout is at 30.5% — 14.5pp below the 45% floor. The weapon slot fix was the structural solution; now Scout needs a survivability nudge. Options (pick one):
- **HP 100 → 120** (most straightforward, +20% effective HP)
- **Dodge 15% → 20%** (multiplicative with HP, harder to tune)
- **Speed-based damage reduction** (thematic but complex to implement)

Recommendation: **HP to 115–120**. Simple, predictable, and the sim can verify it in one pass.

### Priority 2: Fortress fine-tuning
Fortress at 64.4% is 9.4pp above the 55% ceiling. Options:
- **HP 180 → 170** (small nerf, might overshoot)
- **Speed 60 → 50** (indirect nerf — slower approach = more damage taken en route)
- **Weight cap 80 → 70** (limits loadout options, indirect)

Recommendation: **HP to 170**. Conservative step; verify with sims before going further.

### Priority 3: Monitor Brawler
Brawler at 55.1% is barely outside the target band. If Scout and Fortress converge, Brawler may self-correct. No direct changes recommended.

### Do NOT change:
- Economy (flat repair is working perfectly)
- Minigun (fire rate nerf landed well in S15, cost change is healthy)
- Weapon stats broadly (diversity is the best it's been)

---

## Methodology

- **1,530 matches** (170 per matchup × 9 matchups)
- Deterministic seeded RNG (seed=42) for reproducibility
- Random loadout selection per chassis weight cap
- Random armor selection (plating, reactive mesh, or none)
- 15% dodge chance applied per-hit for Scout chassis
- Simple aggressive AI (close distance, fire when in range, Scout kites at 70% max weapon range)
- 120-second timeout with HP% tiebreaker
- Economy sim: 200 matches at 50% win rate, 26 unique opponents, 200 🔩 first-win bonus
