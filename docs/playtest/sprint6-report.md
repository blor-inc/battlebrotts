# Playtest Report — Sprint 6

**Build:** main@8d2e52b5
**Date:** 2026-04-14
**Analyst:** Optic (Playtest Lead)
**Simulations run:** Analytical review (headless sim blocked by TickSystem→Projectile class chain; sim script ready at `godot/tests/playtest_sim.gd` for when chain is fixed)

## Summary
The Scrapyard League game loop is structurally complete. Economy pacing looks reasonable on paper but needs simulation verification. Chassis balance has a potential fortress dominance issue. Weapon diversity is good. **Critical blocker: headless combat simulation doesn't run due to pre-existing class_name resolution chain.**

## Findings

### BALANCE: ⚠️ Potential Issues

**Chassis Balance — Needs Verification**
| Chassis | HP | Speed | Weight Cap | Weapon Slots | HP/Speed Ratio |
|---|---|---|---|---|---|
| Scout | 80 | 200 | 30 | 1 | 0.40 |
| Brawler | 150 | 120 | 55 | 2 | 1.25 |
| Fortress | 250 | 70 | 80 | 3 | 3.57 |

- Fortress has 3.1x the HP of Scout with 3 weapon slots — may be over-tuned
- Scout's 1 weapon slot severely limits damage output; speed advantage needs to compensate
- **Risk:** Fortress with 3 weapons may out-DPS and out-tank everything
- **Recommendation:** Run sim to verify. If fortress dominates, reduce HP to 200 or cap at 2 weapon slots

**Weapon Spread**
| Weapon | Damage | Energy | Weight | Cost | Effective DPS* |
|---|---|---|---|---|---|
| Minigun | 4 | 1 | 10 | Free | Sustained low |
| Plasma Cutter | 12 | 4 | 8 | Free | Medium burst |
| Shotgun | 6×pellets | 8 | 12 | 120 | High close-range |
| Arc Emitter | 8 | 6 | 11 | 150 | Medium AoE |
| Flak Cannon | 15 | 7 | 13 | 200 | High medium |
| Railgun | 45 | 20 | 15 | 300 | Spike (high CD) |
| Missile Pod | 30 | 12 | 18 | 350 | High (splash) |

*DPS cannot be calculated precisely without cooldown_ticks being parsed from nested data*

- Good cost-to-power progression
- Minigun as free starter is smart — low power encourages upgrades
- **Risk:** Railgun (45 dmg) may one-shot scouts (80 HP) — need to verify with armor mitigation
- **Risk:** Missile Pod at 350 bolts is very expensive; may never be purchasable in Scrapyard league

### ECONOMY: ⚠️ Needs Tuning Verification

**Income Flow**
- Starting: 200 bolts
- Per win: 100 bolts (first win: 150)
- Per loss: 40 bolts
- Repair (win): 10% of equipped item value
- Repair (loss): 25% of equipped item value

**Progression Pace (theoretical, starter gear)**
- Starter equipment value: 0 (all free items) → 0 repair cost
- After beating Junkbot (first win): 200 + 150 = 350 bolts
- Can buy: shotgun (120), arc_emitter (150), brawler (200), overclock (100)
- After 3 wins (best case): 200 + 150 + 100 + 100 = 550 bolts total earned

**Buy Pace:** ~1 item every 1-2 matches ✅ (target: 1 every 2-3)
- Slightly faster than target for starter gear (no repair costs)
- Will slow naturally as player buys expensive gear (higher repair costs)
- **Looks good** — repair cost scaling is a nice self-balancing mechanism

**Concern:** With free starter gear, repair costs are 0. Player accumulates bolts very fast early on. After buying a brawler (200) + shotgun (120), repair on win = 10% of 120 = 12 bolts. Still minimal. Economy is generous early, tight later. This seems intentional for onboarding.

### PACING: ⚠️ Unknown

- Cannot assess without simulating match durations
- 120s match timeout is reasonable for arena combat
- 20 ticks/sec gives good simulation fidelity
- **Need sim data:** Average match length, how often timeouts occur, DPS vs HP time-to-kill

### SCRAPYARD OPPONENTS: ✅ Good Difficulty Curve

1. **Junkbot** (scout + minigun): Weakest possible opponent. Good tutorial fight.
2. **Scrapper** (scout + plasma_cutter + plating): Upgraded weapon + armor. Noticeable step up.
3. **Bonebreaker** (brawler + minigun + shotgun): Tank chassis + dual weapons. Boss fight.

- Difficulty ramp is appropriate
- Player starts with same power as opponent 1 (scout + minigun)
- By opponent 3, player should have upgrades from economy
- **Gap check:** Player faces brawler chassis (150 HP) as scout (80 HP) unless they've bought brawler themselves. 200 bolt brawler is affordable after 2 wins.

### JUICE: ❌ Not Assessable
- No visual assets, animations, or effects to evaluate
- All combat is mathematical simulation
- This is expected for current sprint — visual polish comes later

## Metrics (Analytical)

| Metric | Value | Target | Status |
|---|---|---|---|
| Scrapyard opponents | 3 | 3 | ✅ |
| Item diversity | 7 weapons, 3 chassis, 3 armor, 6 modules | — | ✅ |
| Starting item cost | 0 | 0 | ✅ |
| Buy pace (theoretical) | ~1 per 1-2 matches | 1 per 2-3 | ⚠️ Slightly fast |
| Match timeout | 120s | — | ✅ |
| Test coverage (campaign) | 10/25 pass | 25/25 | ⚠️ Blocked |
| Headless sim working | No | Yes | ❌ Blocked |

## Critical Issues

1. **🔴 Headless simulation chain broken** — `Projectile` class_name not resolving → `TickSystem` → `MatchManager` → all combat fails in headless. Playtest sim script exists but can't run. This blocks all quantitative balance analysis.

2. **🟡 Fortress may dominate** — 250 HP + 3 weapon slots is significantly more powerful than other chassis. Needs sim verification.

3. **🟡 Railgun vs Scout** — 45 damage may be >50% of scout HP in one shot. Check armor mitigation.

## Recommendations (Prioritized)

1. **Fix Projectile class_name chain** (DevOps/Patch) — Unblocks all headless testing including the 1000+ sim playtest
2. **Run playtest_sim.gd** once chain is fixed — gives real balance data
3. **Consider fortress nerf** if sims show >55% win rate — reduce to 200 HP or 2 weapon slots
4. **Add cooldown_ticks to weapon analysis** — need DPS calculations for proper balance
5. **Verify economy with actual match data** — theoretical analysis shows slightly generous early game

## Needs Human Eyes

- **Overall game feel** — Eric should play through Scrapyard league once the web build is up
- **Difficulty curve** — Is the jump from opponent 2 to 3 too steep?
- **Economy satisfaction** — Does the buy pace feel rewarding or trivial?
