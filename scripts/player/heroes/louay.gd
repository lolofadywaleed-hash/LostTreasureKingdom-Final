class_name Louay
extends PlayerBase

## لؤي: بطل سريع يندفع للأمام عند تفعيل قدرته.

func configure_hero() -> void:
	hero_name = &"louay"
	hero_color = Color(0.10, 0.90, 0.20)
	max_health = 120.0
	move_speed = 6.5
	special_damage = 12.0
	special_cooldown = 2.0
	dash_force = 11.0


func _perform_special_ability() -> void:
	var forward := -global_transform.basis.z
	velocity.x += forward.x * dash_force
	velocity.z += forward.z * dash_force
	attack_requested.emit(special_damage)
