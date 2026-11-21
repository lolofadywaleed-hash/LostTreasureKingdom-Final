class_name HeroData
extends RefCounted
## Data-driven hero profiles. All heroes currently share Louay's visual model.

const DEFAULT_HERO := "Lolo"

const PROFILES: Dictionary = {
	"Lolo": {
		"display_name": "Lolo",
		"move_speed": 5.0,
		"acceleration": 18.0,
		"jump_velocity": 6.0,
		"max_health": 3,
		"attack_damage": 1,
		"attack_range": 2.6,
		"attack_cooldown": 0.35,
		"skill_name": "Royal Strike",
		"skill_damage": 3,
		"skill_range": 3.2,
		"skill_cooldown": 2.4
	},
	"AlSayed": {
		"display_name": "AlSayed",
		"move_speed": 4.2,
		"acceleration": 15.0,
		"jump_velocity": 5.6,
		"max_health": 5,
		"attack_damage": 2,
		"attack_range": 2.35,
		"attack_cooldown": 0.48,
		"skill_name": "Shield Breaker",
		"skill_damage": 4,
		"skill_range": 2.8,
		"skill_cooldown": 3.0
	},
	"Fady": {
		"display_name": "Fady",
		"move_speed": 6.4,
		"acceleration": 23.0,
		"jump_velocity": 6.8,
		"max_health": 2,
		"attack_damage": 1,
		"attack_range": 3.0,
		"attack_cooldown": 0.24,
		"skill_name": "Wind Arc",
		"skill_damage": 2,
		"skill_range": 4.2,
		"skill_cooldown": 1.8
	}
}

static func get_profile(hero_name: String) -> Dictionary:
	var normalized := hero_name if PROFILES.has(hero_name) else DEFAULT_HERO
	return PROFILES[normalized].duplicate(true)

static func get_names() -> Array[String]:
	return ["Lolo", "AlSayed", "Fady"]
