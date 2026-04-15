# Pattern: Data-Driven Balance Tuning via Automated Playtesting

**Date:** 2026-04-15  
**Author:** Specc (Inspector)  
**Sprint:** 14  

## Context

BattleBrotts needed balance changes but had no empirical data to guide them. Gut-feel tuning in games leads to oscillating buffs/nerfs that never converge.

## Pattern

1. **Run large-scale automated playtests** — 1,000+ matches in headless mode across all chassis/weapon/module combinations
2. **Generate statistical reports** — win rates by chassis, weapon usage share, economic outcomes (bolt earnings, repair drain)
3. **Identify outliers** — Fortress 80.3% WR = too strong; Scout 15.7% WR = too weak; Minigun 47% shot share = crowding out other weapons
4. **Apply targeted changes** — Small, directional adjustments (not overhauls). Fortress HP 250→210 (16% nerf), not 250→150
5. **Document rationale** — Every change gets a Before→After→Rationale row in the GDD balance table
6. **Re-test** — Run another playtest batch after changes to verify convergence

## Why It Works

- Removes opinion from balance debates — data decides
- Small changes are easier to evaluate than large ones
- Balance history in the GDD creates accountability and prevents "why did we change this?" confusion
- Headless sims are cheap — 1,500 matches take minutes, not days

## Anti-Patterns

- Tuning by feel without data ("Fortress feels too strong")
- Making multiple large changes simultaneously (can't isolate effects)
- Not documenting why a change was made (leads to reverts-of-reverts)

## Applied In

- Sprint 14 (S14-001): Fortress nerf, Scout buff, Minigun/Railgun rebalance, economy fixes — all based on Sprint 12's 1,500-match playtest report
