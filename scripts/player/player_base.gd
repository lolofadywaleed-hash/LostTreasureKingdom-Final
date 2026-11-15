class_name PlayerBase
extends CharacterBody3D

## الأساس المشترك لحركة الأبطال وإدخال الموبايل والأنيميشن والقدرات.

signal attacked
signal skill_used
signal coins_changed(total: int)
signal hero_changed(hero_name: StringName)
signal attack_requested(damage: float)

@export_group("Hero Configuration")
@export var hero_name: StringName = &"louay"
@export var hero_color: Color = Color(0.10, 0.90, 0.20)
@export_range(1.0, 500.0, 1.0) var max_health: float = 120.0
@export_range(0.1, 20.0, 0.1) var move_speed: float = 6.0

@export_group("Movement")
@export_range(0.1, 100.0, 0.1) var acceleration: float = 18.0
@export_range(0.1, 100.0, 0.1) var deceleration: float = 20.0
@export_range(0.1, 30.0, 0.1) var jump_velocity: float = 6.0
@export_range(0.1, 50.0, 0.1) var gravity: float = 18.0
@export_range(0.1, 30.0, 0.1) var rotation_speed: float = 10.0
@export var kill_height: float = -20.0

@export_group("Ability")
@export_range(0.0, 60.0, 0.1) var special_cooldown: float = 2.0
@export_range(0.1, 5.0, 0.05) var special_speed_multiplier: float = 1.5
@export_range(0.1, 10.0, 0.1) var special_duration: float = 1.5
@export_range(0.0, 100.0, 0.5) var special_damage: float = 15.0
@export_range(0.1, 30.0, 0.1) var dash_force: float = 10.0

@export_group("Input Actions")
@export var move_left_action: StringName = &"move_left"
@export var move_right_action: StringName = &"move_right"
@export var move_forward_action: StringName = &"move_up"
@export var move_back_action: StringName = &"move_down"
@export var jump_action: StringName = &"jump"
@export var attack_action: StringName = &"attack"
@export var skill_action: StringName = &"skill"

@export_group("Touch Camera")
@export_range(0.0001, 0.05, 0.0001) var camera_sensitivity: float = 0.005
@export var min_camera_pitch: float = -60.0
@export var max_camera_pitch: float = -10.0

@onready var camera_pivot: Node3D = get_node_or_null("CameraPivot") as Node3D
@onready var knight_visual: Node3D = get_node_or_null("KnightVisual") as Node3D
@onready var animation_player: AnimationPlayer = _find_animation_player()

var current_health: float = 120.0
var coins_collected: int = 0
var jump_requested: bool = false
var camera_touch_index: int = -1
var camera_pitch: float = 0.0
var current_animation: StringName = &""
var special_cooldown_remaining: float = 0.0
var special_duration_remaining: float = 0.0

var _spawn_position: Vector3 = Vector3.ZERO
var _base_move_speed: float = 6.0
var _state_machine: StateMachine


func _ready() -> void:
	add_to_group("player")
	floor_snap_length = 0.25
	_spawn_position = global_position
	configure_hero()
	_base_move_speed = move_speed
	current_health = max_health
	_state_machine = StateMachine.new()
	_state_machine.name = "StateMachine"
	add_child(_state_machine)
	var state_list: Array[State] = [
		IdleState.new(),
		RunState.new(),
		JumpState.new(),
		FallState.new()
	]
	_state_machine.initialize(self, state_list, &"idle")
	if camera_pivot != null:
		camera_pitch = clampf(camera_pivot.rotation.x, deg_to_rad(min_camera_pitch), deg_to_rad(max_camera_pitch))
		camera_pivot.rotation.x = camera_pitch
	if knight_visual != null:
		call_deferred("_apply_hero_material")
	hero_changed.emit(hero_name)
	print("Hero ready: %s | HP: %.0f | Speed: %.2f" % [hero_name, max_health, move_speed])


func configure_hero() -> void:
	pass


func _physics_process(delta: float) -> void:
	if global_position.y < kill_height:
		global_position = _spawn_position
		velocity = Vector3.ZERO
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	special_cooldown_remaining = maxf(0.0, special_cooldown_remaining - delta)
	if special_duration_remaining > 0.0:
		special_duration_remaining = maxf(0.0, special_duration_remaining - delta)
		if special_duration_remaining == 0.0:
			move_speed = _base_move_speed
	if Input.is_action_just_pressed(jump_action):
		jump_requested = true
	if Input.is_action_just_pressed(attack_action):
		attacked.emit()
	if Input.is_action_just_pressed(skill_action):
		use_special_ability()
	if _state_machine != null:
		_state_machine.physics_update(delta)
	move_and_slide()


func update_horizontal_movement(delta: float) -> void:
	var input_vector := Input.get_vector(move_left_action, move_right_action, move_forward_action, move_back_action)
	var movement_basis := global_transform.basis
	if camera_pivot != null:
		movement_basis = camera_pivot.global_transform.basis
	var forward := -movement_basis.z
	var right := movement_basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	var direction := (right * input_vector.x - forward * input_vector.y).normalized()
	if direction.length_squared() > 0.001:
		var target_velocity := direction * move_speed
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
		var target_angle := atan2(direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
	else:
		stop_horizontal_movement(delta)


func stop_horizontal_movement(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)


func has_movement_input() -> bool:
	return Input.get_vector(move_left_action, move_right_action, move_forward_action, move_back_action).length() > 0.1


func perform_jump() -> void:
	if not is_on_floor():
		return
	velocity.y = jump_velocity
	jump_requested = false


func use_special_ability() -> void:
	if special_cooldown_remaining > 0.0:
		return
	special_cooldown_remaining = special_cooldown
	_perform_special_ability()
	skill_used.emit()


func _perform_special_ability() -> void:
	pass


func apply_temporary_speed_boost() -> void:
	move_speed = _base_move_speed * special_speed_multiplier
	special_duration_remaining = special_duration


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins_collected += amount
	coins_changed.emit(coins_collected)


func play_hero_animation(animation_key: StringName) -> void:
	if animation_player == null:
		return
	var wanted := String(animation_key).to_lower()
	for animation_name in animation_player.get_animation_list():
		var candidate := String(animation_name).to_lower()
		if candidate == wanted or (wanted == "run" and candidate == "walk"):
			if current_animation == StringName(animation_name):
				return
			current_animation = StringName(animation_name)
			animation_player.play(animation_name, 0.15)
			return


func _find_animation_player() -> AnimationPlayer:
	var players := find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return null
	return players[0] as AnimationPlayer


func _apply_hero_material() -> void:
	if knight_visual == null:
		return
	var mesh_nodes := knight_visual.find_children("*", "MeshInstance3D", true, false)
	if mesh_nodes.is_empty():
		push_warning("PlayerBase: لم يتم العثور على MeshInstance3D داخل KnightVisual.")
		return
	var overlay := StandardMaterial3D.new()
	overlay.albedo_color = hero_color
	overlay.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	overlay.metallic = 0.12
	overlay.roughness = 0.55
	overlay.emission_enabled = true
	overlay.emission = hero_color
	overlay.emission_energy_multiplier = 0.12
	for mesh_node in mesh_nodes:
		var mesh_instance := mesh_node as MeshInstance3D
		if mesh_instance != null:
			mesh_instance.material_overlay = overlay


func _on_jump_button_pressed() -> void:
	jump_requested = true


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			var screen_width := get_viewport().get_visible_rect().size.x
			if touch.position.x > screen_width * 0.5:
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
	camera_pivot.rotation.y -= delta_position.x * camera_sensitivity
	camera_pitch = clampf(camera_pitch - delta_position.y * camera_sensitivity, deg_to_rad(min_camera_pitch), deg_to_rad(max_camera_pitch))
	camera_pivot.rotation.x = camera_pitch
