extends CharacterBody3D

signal attacked
signal skill_used
signal coins_changed(total: int)

@export_group("Movement")
@export var move_speed: float = 5.0
@export var acceleration: float = 18.0
@export var deceleration: float = 20.0
@export var jump_velocity: float = 6.0
@export var gravity: float = 18.0
@export var rotation_speed: float = 10.0
@export var kill_height: float = -20.0

@export_group("Mobile Input")
@export var move_left_action: StringName = &"move_left"
@export var move_right_action: StringName = &"move_right"
@export var move_forward_action: StringName = &"move_up"
@export var move_back_action: StringName = &"move_down"
@export var jump_action: StringName = &"jump"

@export_group("Touch Camera")
@export var camera_sensitivity: float = 0.005
@export var min_camera_pitch: float = -45.0
@export var max_camera_pitch: float = 60.0

@export_group("Scene References")
@export var camera_pivot_path: NodePath = ^"CameraPivot"

@export_group("Animations")
@export var idle_animation: String = "Idle"
@export var walk_animation: String = "Walk"

@onready var camera_pivot: Node3D = get_node_or_null(camera_pivot_path) as Node3D
@onready var animation_player: AnimationPlayer = _find_animation_player()

var coins_collected: int = 0
var jump_requested: bool = false
var camera_touch_index: int = -1
var camera_pitch: float = 0.0
var current_animation: String = ""
var _spawn_position := Vector3.ZERO


func _ready() -> void:
	floor_snap_length = 0.25
	_spawn_position = global_position
	var visual_driver := get_node_or_null("KnightVisual")
	if visual_driver != null:
		visual_driver.set_physics_process(false)
	if camera_pivot:
		camera_pitch = camera_pivot.rotation.x
	else:
		push_warning("CameraPivot was not found!")
	if animation_player:
		_play_animation(idle_animation)
		print("Louay AnimationPlayer found! Available animations: ", animation_player.get_animation_list())
	else:
		push_warning("AnimationPlayer was not found inside Louay model!")


func _find_animation_player() -> AnimationPlayer:
	var players := find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		return players[0] as AnimationPlayer
	return null


func add_coins(amount: int) -> void:
	coins_collected += amount
	coins_changed.emit(coins_collected)
	print("Coins collected: %d (+%d)" % [coins_collected, amount])


func _physics_process(delta: float) -> void:
	if global_position.y < kill_height:
		velocity = Vector3.ZERO
		global_position = _spawn_position

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	if jump_requested and is_on_floor():
		velocity.y = jump_velocity
	jump_requested = false
	if Input.is_action_just_pressed(jump_action) and is_on_floor():
		velocity.y = jump_velocity

	var input_vector := Input.get_vector(move_left_action, move_right_action, move_forward_action, move_back_action)
	var camera_basis := global_transform.basis
	if camera_pivot:
		camera_basis = camera_pivot.global_transform.basis
	var forward := -camera_basis.z
	var right := camera_basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	var direction := (right * input_vector.x + forward * -input_vector.y).normalized()
	var target_velocity := direction * move_speed

	if direction.length() > 0.01:
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
		var target_angle := atan2(direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
		_play_animation(walk_animation)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
		_play_animation(idle_animation)

	if InputMap.has_action("attack") and Input.is_action_just_pressed("attack"):
		attacked.emit()
	if InputMap.has_action("skill") and Input.is_action_just_pressed("skill"):
		skill_used.emit()
	move_and_slide()


func _on_jump_button_pressed() -> void:
	jump_requested = true


func _play_animation(animation_name: String) -> void:
	if animation_player == null or current_animation == animation_name:
		return
	var actual_animation := _find_animation_name(animation_name)
	if actual_animation.is_empty():
		return
	current_animation = actual_animation
	animation_player.play(actual_animation, 0.15)


func _find_animation_name(animation_name: String) -> String:
	if animation_player == null:
		return ""
	for anim in animation_player.get_animation_list():
		if anim.to_lower() == animation_name.to_lower():
			return anim
	return ""


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if touch.position.x > get_viewport().get_visible_rect().size.x * 0.5:
				camera_touch_index = touch.index
		elif touch.index == camera_touch_index:
			camera_touch_index = -1
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == camera_touch_index:
			_rotate_camera(drag.relative)


func _rotate_camera(delta_position: Vector2) -> void:
	if camera_pivot == null:
		return
	rotate_y(-delta_position.x * camera_sensitivity)
	camera_pitch -= delta_position.y * camera_sensitivity
	camera_pitch = clampf(camera_pitch, deg_to_rad(min_camera_pitch), deg_to_rad(max_camera_pitch))
	camera_pivot.rotation.x = camera_pitch
