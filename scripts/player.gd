extends CharacterBody3D

@export var speed: float = 5.5
@export var jump_velocity: float = 5.0
@export var gravity: float = 14.0
var move_input := Vector2.ZERO
var joystick_origin := Vector2.ZERO
var active_touch := -1
var joystick_radius := 95.0

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input == Vector2.ZERO:
		input = move_input
	var direction := Vector3(input.x, 0, input.y).rotated(Vector3.UP, $SpringArm3D.rotation.y)
	if direction.length() > 1.0:
		direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x * 0.55 and active_touch == -1:
			active_touch = event.index
			joystick_origin = event.position
			move_input = Vector2.ZERO
		elif not event.pressed and event.index == active_touch:
			active_touch = -1
			move_input = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == active_touch:
			var drag_delta: Vector2 = event.position - joystick_origin
			move_input = drag_delta.limit_length(joystick_radius) / joystick_radius
			move_input.y = -move_input.y
