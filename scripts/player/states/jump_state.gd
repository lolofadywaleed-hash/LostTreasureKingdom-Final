class_name JumpState
extends State

## حالة صعود اللاعب بعد القفز.


func _init() -> void:
	name = "jump"


func enter() -> void:
	player.play_hero_animation(&"jump")


func physics_update(delta: float) -> void:
	player.update_horizontal_movement(delta)
	if player.velocity.y <= 0.0:
		state_machine.transition_to(&"fall")
