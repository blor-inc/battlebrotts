# Sprint 7 Playtest Report
**Author:** Optic (Playtest Lead)
**Date:** 2026-04-14
**Matches Simulated:** 1,804 valid (1,940 total, 136 invalid due to weight cap violations)
**Build:** Post-PR #23 (Projectile class_name fix), PR #26 (integration tests)

---

## Executive Summary

Three **P0 balance issues** found:

1. 🔴 **Fortress is overpowered** — 77.9% win rate (target: 45-55%)
2. 🔴 **Scout is underpowered** — 19.6% win rate (target: 45-55%)
3. 🔴 **Railgun is overpowered** — 82.9% win rate (target: 40-60%)

Two **P1 balance issues:**

4. ⚠️ **Flak Cannon is severely underperforming** — 14.3% win rate
5. ⚠️ **Arc Emitter is underperforming** — 20.1% win rate

Economy pacing and TTK are healthy. No timeouts or degenerate matches.

---

## 1. Chassis Balance

| Chassis | Wins | Total | Win% | Status |
|---------|------|-------|------|--------|
| Scout | 115 | 587 | 19.6% | 🔴 P0 — severely underpowered |
| Brawler | 1,123 | 2,409 | 46.6% | ✅ healthy |
| Fortress | 477 | 612 | 77.9% | 🔴 P0 — overpowered |

### Matchup Matrix (Team A win %)

```
              scout    brawler   fortress
scout         45.0%      0.9%      0.0%
brawler       83.3%     44.2%      2.3%
fortress      93.8%     66.7%     53.3%
```

**Analysis:**
- **Fortress dominates everything.** 250 HP + 80 weight cap makes it a stat monster. Even brawler only beats fortress 2.3% of the time. The HP advantage (250 vs 150 vs 80) is too steep.
- **Scout is unviable.** 80 HP is too low to survive any engagement. The speed advantage (200 vs 120 vs 70) doesn't translate to combat wins because the tick system's movement phase doesn't create meaningful kiting opportunities.
- **Brawler is the most balanced.** 44-46% win rate in most contexts. The 150 HP / 55 weight / 2 weapon slots is a good middle ground.

### Recommendations
- **Reduce Fortress HP** from 250 → 200 (or 180). Keep it tanky but beatable.
- **Increase Scout HP** from 80 → 100 (or give it a 15% evasion passive to leverage speed).
- **Reduce Fortress weight cap** from 80 → 65 to limit loadout advantage.
- Alternative: give Scout a damage bonus (+15-20%) to compensate for low HP with burst.

---

## 2. Weapon Balance

| Weapon | Wins | Total | Win% | Status |
|--------|------|-------|------|--------|
| Railgun | 320 | 386 | 82.9% | 🔴 P0 — dominant |
| Missile Pod | 153 | 286 | 53.5% | ✅ healthy |
| Plasma Cutter | 148 | 283 | 52.3% | ✅ healthy |
| Minigun | 846 | 1,689 | 50.1% | ✅ baseline |
| Shotgun | 149 | 390 | 38.2% | ⚠️ slightly weak |
| Arc Emitter | 59 | 294 | 20.1% | ⚠️ P1 — underperforming |
| Flak Cannon | 40 | 280 | 14.3% | ⚠️ P1 — severely underperforming |

### TTK by Winning Weapon

```
railgun        :  7.2s avg
plasma_cutter  :  7.6s avg
shotgun        :  8.7s avg
missile_pod    : 10.0s avg
minigun        : 10.3s avg
arc_emitter    : 11.9s avg
flak_cannon    : 23.8s avg
```

**Analysis:**
- **Railgun (45 dmg, 12 range, 0 spread)** is too efficient. High damage + long range + perfect accuracy means it dominates before enemies close distance. The 20 energy cost and 0.5 fire rate don't compensate enough.
- **Flak Cannon** has 23.8s average TTK when it wins — nearly 2.5x the overall average. Its stats (15 dmg, 6 range, 20° spread, 1.2 fire rate) are mediocre in every dimension. It's the "worst of all worlds" weapon.
- **Arc Emitter** (8 dmg, 4 range, 2.0 fire rate) has decent DPS on paper but in practice gets outclassed by minigun (higher fire rate) and everything else (more damage or more range).
- **Minigun** at 50.1% is the perfect baseline weapon.
- **Missile Pod** at 53.5% is well-positioned as a premium projectile weapon.

### Recommendations
- **Railgun:** Reduce damage from 45 → 35, OR increase energy cost from 20 → 30, OR reduce range from 12 → 9.
- **Flak Cannon:** Increase damage from 15 → 22 and add splash_radius (1.5 tiles) to differentiate it as an AoE weapon.
- **Arc Emitter:** Increase chain_targets from 0 → 2 to justify its role as a multi-target weapon, OR increase fire rate from 2.0 → 3.0.
- **Shotgun:** Minor buff — increase range from 3 → 4 tiles. Currently too short to be useful before getting outranged.

---

## 3. TTK Analysis

| Metric | Value |
|--------|-------|
| Average match duration | 9.7s |
| Fastest match | 1.9s |
| Slowest match | 39.5s |
| Matches < 10 ticks | 0 (0%) |
| Timeouts (≥120s) | 0 (0%) |

**Analysis:**
- TTK is healthy. Average ~10s matches feel good for a real-time tactical game.
- No degenerate fast matches (no 1-tick kills).
- No timeouts — brotts always engage and resolve. This is partly because the tick system moves brotts toward each other.
- The 1.9s minimum is fine — that's ~38 ticks, enough for several exchanges.

✅ **No action needed on TTK.**

---

## 4. Arena Impact

| Arena | Matches | Avg Duration | Timeouts | Draws |
|-------|---------|-------------|----------|-------|
| The Pit | 1,619 | 10.1s | 0 | 88 |
| Junkyard | 185 | 6.8s | 0 | 1 |

**Analysis:**
- **Junkyard matches are 33% faster** than The Pit (6.8s vs 10.1s). The cover-heavy layout channels brotts into close-range engagements earlier.
- **The Pit has more draws** (88 vs 1), likely because the open layout allows more kiting/positioning where both brotts expire similarly.
- Arenas matter but don't dominate — good design.

✅ **Arena balance is healthy.** Junkyard is a faster, more aggressive arena; The Pit rewards positioning. Both are valid.

---

## 5. Economy Pacing

| Item | Cost | Matches to Earn (50% WR) |
|------|------|--------------------------|
| Overclock | 100 | ~1.4 matches |
| Shotgun | 120 | ~1.7 matches |
| Reactive Mesh | 150 | ~2.1 matches |
| Brawler | 200 | ~2.9 matches |
| Railgun | 300 | ~4.3 matches |
| Fortress | 400 | ~5.7 matches |

- Average earnings: ~70 bolts/match (100 win × 50% + 40 loss × 50%)
- First-win bonus (150) gives immediate purchasing power in early game
- **Target: 1 item every 2-3 matches → ACHIEVED for cheap/mid items**
- Premium items (300+) require 4+ matches — appropriate gating for progression

✅ **Economy pacing is well-calibrated.**

---

## P0 Issues — Immediate Action Required

### Issue 1: Fortress HP Too High
- **Severity:** P0
- **Impact:** Fortress has 77.9% overall win rate, beats brawler 66.7%, beats scout 93.8%
- **Root Cause:** 250 HP is 67% more than brawler (150) and 212% more than scout (80). No weapon can overcome this HP differential efficiently.
- **Recommended Fix:** Reduce Fortress HP to 180-200

### Issue 2: Scout HP Too Low
- **Severity:** P0
- **Impact:** 19.6% overall win rate, 0% vs fortress, 0.9% vs brawler
- **Root Cause:** 80 HP dies in ~2-4 weapon volleys. Speed doesn't help because movement doesn't create evasion.
- **Recommended Fix:** Increase Scout HP to 100-110, or add evasion passive

### Issue 3: Railgun Dominant
- **Severity:** P0
- **Impact:** 82.9% win rate across all matchups
- **Root Cause:** 45 damage × 12 range × 0 spread = guaranteed high damage at any range. Nothing competes.
- **Recommended Fix:** Reduce damage to 35 or reduce range to 9

---

## Methodology

- **Chassis balance:** 3×3 chassis grid, 100 matches per pair (mirror loadout: minigun + plating), 600 matches total on The Pit
- **Weapon balance:** 7×7 weapon grid, 30 matches per pair (brawler chassis, plating armor), 840 matches total on The Pit
- **Arena comparison:** 3 distinct matchups × 2 arenas × 50 matches = 300 matches
- **Random stress test:** 200 randomized matchups with varied chassis/weapon/armor/arena
- **Seed:** Randomized per match for statistical validity
- **Invalid matches (136):** Weight cap assertion failures from random loadout combos — filtered from analysis
