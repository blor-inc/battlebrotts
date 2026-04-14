# Playtest Report — Sprint 12

**Build:** main@b0724d1  
**Date:** 2026-04-14  
**Simulations run:** 1,500  
**Simulator:** Python port of TickSystem + DamageCalculator (deterministic, seeded RNG)

## Summary

Fortress chassis dominates all matchups (80.3% overall win rate). Scout is non-viable (15.7%). Economy collapses mid-game due to repair costs scaling faster than earnings. TTK is fast (median 2.8s) which feels appropriate for an arcade mech battler. Weapon diversity needs work — minigun accounts for 47% of all shots fired.

## Findings

### BALANCE: ❌

**Chassis win rates (target: 45-55% each):**

| Chassis  | Matches | Wins | Win% | Status |
|----------|---------|------|------|--------|
| Scout    | 971     | 152  | 15.7% | ❌ Far below target |
| Brawler  | 996     | 489  | 49.1% | ✅ On target |
| Fortress | 1,033   | 830  | 80.3% | ❌ Far above target |

**Matchup matrix (row win% vs column):**

|          | Scout  | Brawler | Fortress |
|----------|--------|---------|----------|
| Scout    | 49.3%  | 0.3%    | 0.0%    |
| Brawler  | 99.7%  | 45.1%   | 3.0%    |
| Fortress | 100.0% | 95.5%   | 48.4%   |

**Analysis:** The game has a strict rock-paper-scissors hierarchy but it's completely linear: Fortress > Brawler > Scout. No counter-play exists. Scout's 80 HP and 1 weapon slot means it can't deal enough damage before being destroyed, even with 2.85x the speed. The speed advantage doesn't compensate because the sim converges to weapon range quickly regardless.

**Recommendations:**
1. **Buff Scout survivability:** Increase Scout HP to 100-110 OR add a passive dodge/evasion chance (e.g., 15% miss chance vs Scout based on speed differential)
2. **Nerf Fortress damage output:** Reduce weapon slots from 3→2, or add a fire rate penalty for Fortress
3. **Add chassis-specific passives:** Scout gets evasion, Brawler gets lifesteal, Fortress gets damage resistance already from weight→armor
4. Consider making speed matter more: faster closing distance should mean Scout dictates engagement range

### PACING: ✅

- **Average TTK:** 3.1s
- **Median TTK:** 2.8s  
- **P10 (fast):** 1.6s
- **P90 (slow):** 4.4s
- **Timeouts:** 1/1,500 (0.1%)

This is solid for a mech arena game. Matches are quick, decisive, and almost never time out. The sub-5s median means high replayability per session.

### WEAPON USAGE: ⚠️

| Weapon        | Shots  | Share  |
|---------------|--------|--------|
| Minigun       | 15,284 | 46.9%  |
| Plasma Cutter | 5,434  | 16.7%  |
| Arc Emitter   | 3,642  | 11.2%  |
| Flak Cannon   | 2,719  | 8.3%   |
| Missile Pod   | 2,175  | 6.7%   |
| Shotgun       | 1,931  | 5.9%   |
| Railgun       | 1,421  | 4.4%   |

**Analysis:** Minigun dominates due to its 10.0 fire rate and low energy cost (1). It fires 10x per second, making it by far the most efficient weapon in sustained DPS. Railgun is underused despite high alpha damage because its 0.5 fire rate and 20 energy cost means it fires once every 2 seconds and drains energy fast.

**Recommendations:**
1. Nerf minigun slightly (fire_rate 10→7, or damage 4→3) to open space for other weapons
2. Buff railgun energy efficiency (20→15 energy) since it's a high-commitment weapon
3. Shotgun needs either more range (3→4 tiles) or more pellets — its close range makes it hard to use

### ECONOMY: ⚠️

**Earning rates:**
- Win: 100 bolts | Loss: 40 bolts
- Average at 50% WR: 70 bolts/match (no repairs)

**Early game (starter gear, value ~0):** ✅
- No repair costs → clean 70 bolts/match average
- First purchase (Overclock, 100🔩) in ~2 matches
- Mid-tier item (~200🔩) in ~3 matches
- **On target for "1 item every 2-3 matches"**

**Mid game (equipment value ~300):** ❌
- Repair per win: 30🔩 | Repair per loss: 75🔩
- Net per win: 70🔩 | Net per loss: -35🔩
- Average net: ~18 bolts/match
- **~11 matches per mid-tier item — far off target**

**Late game (equipment value ~600+):** ❌❌
- Repair per win: 60🔩 | Repair per loss: 150🔩
- Net per loss: -110🔩 — **losing money on losses**
- Economy death spiral: losing players can't afford repairs, forced to downgrade

**Recommendations:**
1. **Cap repair costs** at 50% of match earnings (max 50🔩 on win, 20🔩 on loss)
2. OR **reduce loss repair rate** from 25%→15%
3. OR **increase base earnings** to 150 win / 60 loss
4. Consider a "minimum net earnings" floor (always earn at least 20🔩 even after repairs)

### JUICE: N/A
*Cannot assess visual/audio feedback in headless simulation. Needs human eyes.*

## Metrics Summary

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Scout win% | 15.7% | 45-55% | ❌ |
| Brawler win% | 49.1% | 45-55% | ✅ |
| Fortress win% | 80.3% | 45-55% | ❌ |
| Median TTK | 2.8s | 2-5s | ✅ |
| Timeout rate | 0.1% | <5% | ✅ |
| Weapon diversity (top weapon share) | 46.9% | <30% | ⚠️ |
| Economy: early game | 2-3 matches/item | 2-3 | ✅ |
| Economy: mid game | ~11 matches/item | 2-3 | ❌ |

## Needs Human Eyes

1. **Web build verification** — game is deployed at https://blor-inc.github.io/battlebrotts/game/ — Eric should load it and confirm it plays
2. **Visual feel** — can't assess art, animations, screen shake, hit feedback
3. **Menu flow** — does campaign→shop→match→result loop feel natural?
4. **Mobile/touch** — does it work on phone browser?
