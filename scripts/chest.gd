extends CSGBox3D

signal opened(reward: int)

@export var reward_coins: int = 10
@export var open_on_touch: bool = false
@export var lid_open_angle_deg: float = 110.0

var _is_open := false
var _player: Node3D = null
var _lid_pivot: Node3D
var _area: Area3D
var _hint: Label3D

func _ready() -> void:
	size = Vector3(1.2, 0.7, 0.8)
	use_collision = true
	material = _make_wood(Color(0.45, 0.26, 0.1, 1.0))
	_build_lid()
	_build_area()
	_build_hint()

func _make_wood(color: Color) -> StandardMaterial3D:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = color
	wood.roughness = 0.85
	return wood

func _build_lid() -> void:
	_lid_pivot = Node3D.new()
	_lid_pivot.name = "LidPivot"
	_lid_pivot.position = Vector3(0, 0.35, -0.4)
	add_child(_lid_pivot)

	var lid := MeshInstance3D.new()
	lid.name = "Lid"
	var box := BoxMesh.new()
	box.size = Vector3(1.24, 0.2, 0.84)
	lid.mesh = box
	lid.position = Vector3(0, 0.1, 0.4)
	lid.material_override = _make_wood(Color(0.55, 0.33, 0.12, 1.0))
	_lid_pivot.add_child(lid)

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
	_area.body_entered.connect(_on_body_entered)
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
	_area.set_deferred("monitoring", false)
	if _player != null:
		if _player.is_connected("attacked", _on_player_attacked):
			_player.disconnect("attacked", _on_player_attacked)
		_player.call("add_coins", reward_coins)
	var tween := create_tween()
	tween.tween_property(_lid_pivot, "rotation:x", -deg_to_rad(lid_open_angle_deg), 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	opened.emit(reward_coins)
