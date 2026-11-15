class_name RunState
extends State

## حالة المشي والجري.


func _init() -> void:
	name = "run"


func enter() -> void:
	player.play_hero_animation(&"run")


func physics_update(delta: float) -> void:
	player.update_horizontal_movement(delta)
	if player.jump_requested and player.is_on_floor():
		player.perform_jump()
		state_machine.transition_to(&"jump")
		return
	if not player.is_on_floor():
		state_machine.transition_to(&"fall")
		return
	if not player.has_movement_input():
		state_machine.transition_to(&"idle")
