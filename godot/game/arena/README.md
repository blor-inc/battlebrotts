# Arena Tile System + Line of Sight
# BattleBrotts — Sprint 2

## Tile Types
enum TileType {
	FLOOR,    # Walkable, no effect
	WALL,     # Blocks movement + LoS, indestructible
	COVER,    # Walkable, 50% miss chance, destructible (50 HP)
	PILLAR,   # Blocks movement + LoS, indestructible
	HAZARD    # Walkable, deals damage (lava: 10 dmg/sec = 0.5/tick)
}

## Constants
const TILE_SIZE := 32  # pixels per tile

## Tile Properties
# blocks_movement: WALL, PILLAR
# blocks_los: WALL, PILLAR
# provides_cover: COVER (50% miss chance)
# deals_damage: HAZARD (0.5 per tick, ignores armor)
# destructible: COVER (50 HP)
