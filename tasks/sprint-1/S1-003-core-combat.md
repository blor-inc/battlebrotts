# S1-003: Core Combat Simulation
**Assignee:** Nutts (Dev-01)
**Priority:** 🔴 High
**Status:** In Progress

## Description
Implement the core combat tick system based on GDD v2:
- Tick-based simulation loop
- Movement system (chassis speed, tile-based)
- Damage formula (weapons, armor reduction)
- Energy pool (100 max, 5/sec regen)
- Basic projectile/hit detection

## Acceptance Criteria
- [ ] Tick loop runs at consistent rate
- [ ] All 3 chassis types with correct stats
- [ ] At least 2 weapons functional
- [ ] Armor damage reduction works
- [ ] Energy consumption/regen works
- [ ] Unit tests for damage formula
