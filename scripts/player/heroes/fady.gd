class_name Fady
extends PlayerBase

## فادي: بطل قوي يمتلك ضربة خاصة أعلى ضرراً.

func configure_hero() -> void:
	hero_name = &"fady"
	hero_color = Color(0.95, 0.12, 0.08)
	max_health = 180.0
	move_speed = 4.5
	special_damage = 35.0
	special_cooldown = 3.0


func _perform_special_ability() -> void:
	attack_requested.emit(special_damage)
	attacked.emit()
