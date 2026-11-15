class_name FallState
extends State

## حالة سقوط اللاعب والعودة إلى الأرض.


func _init() -> void:
	name = "fall"


func enter() -> void:
	player.play_hero_animation(&"fall")


func physics_update(delta: float) -> void:
	player.update_horizontal_movement(delta)
	if player.is_on_floor():
		if player.has_movement_input():
			state_machine.transition_to(&"run")
		else:
			state_machine.transition_to(&"idle")
