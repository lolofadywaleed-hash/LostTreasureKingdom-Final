class_name ElSayed
extends PlayerBase

## السيد: بطل طاقة يرفع سرعته مؤقتاً عند استخدام القدرة.

func configure_hero() -> void:
	hero_name = &"elsayed"
	hero_color = Color(0.08, 0.35, 1.0)
	max_health = 140.0
	move_speed = 5.5
	special_damage = 25.0
	special_cooldown = 4.0
	special_speed_multiplier = 1.8
	special_duration = 2.0


func _perform_special_ability() -> void:
	apply_temporary_speed_boost()
	attack_requested.emit(special_damage)
