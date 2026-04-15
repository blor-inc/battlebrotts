# Pattern: Structural vs. Numerical Balance Constraints

**Date:** 2026-04-15  
**Author:** Specc (Inspector)  
**Sprint:** 16  

## Context

BattleBrotts ran three balance passes (S14–S16) using data-driven sim tuning. Scout chassis win rate barely improved across S12→S15 (+4.7pp over two passes) despite HP, speed, dodge, and economy buffs. The breakthrough came in S16 when a **structural** change (weapon slots 1→2) produced +10.1pp in a single pass.

## Pattern

When iterative numerical tuning fails to converge on a balance target after 2+ passes:

1. **Stop adjusting stats** — diminishing returns indicate the problem isn't numerical
2. **Identify structural constraints** — hard caps (slot counts, ability counts, range limits) that create ceilings regardless of stat values
3. **Test one structural change** — modify the constraint and re-sim
4. **Resume stat tuning** after the structural fix if needed

## Evidence

| Sprint | Change Type | Scout WR Δ |
|--------|------------|------------|
| S14 | Numerical (HP, speed, damage) | +4.4pp |
| S15 | Numerical (dodge passive, fire rate) | +0.3pp |
| S16 | **Structural** (weapon slots 1→2) | **+10.1pp** |

Two rounds of stat tuning: +4.7pp combined. One structural change: +10.1pp.

## Generalized Rule

**If three rounds of number tweaks don't fix a balance problem, the problem isn't the numbers.** Look for:
- Slot/capacity limits that cap effectiveness
- Missing ability categories (e.g., no defensive option for a class)
- Action economy imbalances (one class gets more actions per turn)
- Range/reach constraints that prevent engagement

## Anti-Patterns

- Continuing to buff stats past the structural ceiling ("just give Scout more HP")
- Making the structural change AND large stat changes simultaneously (can't measure effect)
- Assuming all balance problems are structural (most ARE numerical; this pattern applies when tuning doesn't converge)

## Applied In

- Sprint 16: Scout weapon slots 1→2, producing the largest single-pass WR improvement in the project
