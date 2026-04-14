# damage_calculator.gd — Damage formula from GDD v2 §5.2
# BattleBrotts Core Combat · S1-003
#
# effective_damage = base_damage × (1 - armor_reduction) × crit_multiplier
# crit_chance = 5%, crit_multiplier = 1.5× (else 1.0×)
# Minimum damage: 1 (no attack deals 0).
# Reactive Mesh: 5 flat reflect to attacker, ignores attacker armor.
# Ablative Shell: reduction drops to 10% when wearer < 30% HP.
# Pellet weapons: each pellet rolls independently.
class_name DamageCalculator

const CRIT_CHANCE: float = 0.05
const CRIT_MULTIPLIER: float = 1.5
const MIN_DAMAGE: float = 1.0
const SPLASH_FALLOFF: float = 0.5   # 50% at splash radius

# ── Result struct ────────────────────────────────────────
# Returns { "damage": float, "is_crit": bool, "reflect_damage": float }

## Calculate damage for a single hit (one pellet / one projectile).
## rng: RandomNumberGenerator — caller owns seeding for determinism.
static func calc_hit(base_damage: float, armor_id: String,
		target_hp_ratio: float, rng: RandomNumberGenerator) -> Dictionary:
	# Armor reduction
	var reduction := ArmorData.effective_reduction(armor_id, target_hp_ratio)

	# Crit roll
	var is_crit := rng.randf() < CRIT_CHANCE
	var crit_mult := CRIT_MULTIPLIER if is_crit else 1.0

	var dmg := base_damage * (1.0 - reduction) * crit_mult
	dmg = maxf(dmg, MIN_DAMAGE)

	# Reactive Mesh reflect
	var reflect := 0.0
	if armor_id == "reactive_mesh":
		var armor := ArmorData.get_armor(armor_id)
		reflect = float(armor.get("reflect_damage", 0))

	return { "damage": dmg, "is_crit": is_crit, "reflect_damage": reflect }

## Calculate splash damage (e.g. Missile Pod at radius tiles).
static func calc_splash(base_damage: float, armor_id: String,
		target_hp_ratio: float, rng: RandomNumberGenerator) -> Dictionary:
	return calc_hit(base_damage * SPLASH_FALLOFF, armor_id, target_hp_ratio, rng)

## Fire a full weapon shot (handles pellets). Returns Array of hit results.
## For single-projectile weapons, returns array of 1.
static func calc_weapon_shot(weapon_id: String, armor_id: String,
		target_hp_ratio: float, rng: RandomNumberGenerator) -> Array:
	var w := WeaponData.get_weapon(weapon_id)
	var pellets: int = w.get("pellets", 1)
	var base_dmg: float = float(w["damage"])
	var results := []
	for i in pellets:
		results.append(calc_hit(base_dmg, armor_id, target_hp_ratio, rng))
	return results
