extends Node3D

signal opened(reward: int)

@export var reward_coins: int = 10
@export var open_on_touch: bool = false
@export var lid_open_angle_deg: float = 110.0

var _is_open := false
var _player: Node3D = null
var _lid_animation: AnimationPlayer
var _lid_fallback: Node3D
var _area: Area3D
var _hint: Label3D

func _ready() -> void:
	_area = find_child("InteractArea", true, false) as Area3D
	if _area == null:
		_build_area()
	else:
		_area.collision_layer = 0
		_area.collision_mask = 1
		_area.monitorable = false
		_connect_area_signals()

	_lid_animation = find_child("AnimationPlayer", true, false) as AnimationPlayer
	_lid_fallback = find_child("Chest_Wood_Lid", true, false) as Node3D
	_build_hint()

func _build_area() -> void:
	_area = Area3D.new()
	_area.name = "InteractArea"
	_area.collision_layer = 0
	_area.collision_mask = 1
	_area.monitorable = false
	var shape := CollisionShape3D.new()
	var reach := BoxShape3D.new()
	reach.size = Vector3(3.2, 2.0, 3.2)
	shape.shape = reach
	shape.position = Vector3(0, 0.4, 0.4)
	_area.add_child(shape)
	add_child(_area)
	_connect_area_signals()

func _connect_area_signals() -> void:
	if not _area.body_entered.is_connected(_on_body_entered):
		_area.body_entered.connect(_on_body_entered)
	if not _area.body_exited.is_connected(_on_body_exited):
		_area.body_exited.connect(_on_body_exited)

func _build_hint() -> void:
	_hint = Label3D.new()
	_hint.name = "Hint"
	_hint.text = "Attack"
	_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hint.no_depth_test = true
	_hint.pixel_size = 0.01
	_hint.font_size = 48
	_hint.outline_size = 12
	_hint.position = Vector3(0, 1.5, 0)
	_hint.visible = false
	add_child(_hint)

func _on_body_entered(body: Node3D) -> void:
	if _is_open or not body.has_method("add_coins"):
		return
	_player = body
	if open_on_touch:
		_open()
		return
	if body.has_signal("attacked") and not body.is_connected("attacked", _on_player_attacked):
		body.connect("attacked", _on_player_attacked)
	_hint.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body != _player:
		return
	if body.is_connected("attacked", _on_player_attacked):
		body.disconnect("attacked", _on_player_attacked)
	_player = null
	_hint.visible = false

func _on_player_attacked() -> void:
	_open()

func _open() -> void:
	if _is_open:
		return
	_is_open = true
	_hint.visible = false
	if is_instance_valid(_area):
		_area.set_deferred("monitoring", false)
	if _player != null:
		if _player.is_connected("attacked", _on_player_attacked):
			_player.disconnect("attacked", _on_player_attacked)
		_player.call("add_coins", reward_coins)

	if _lid_animation != null and _lid_animation.has_animation("Chest_Open"):
		_lid_animation.play("Chest_Open")
	elif is_instance_valid(_lid_fallback):
		var tween := create_tween()
		tween.tween_property(_lid_fallback, "rotation:x", -deg_to_rad(lid_open_angle_deg), 0.5) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	opened.emit(reward_coins)
