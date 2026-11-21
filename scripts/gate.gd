extends Node3D
## Controls the existing CSG gate and its castle collision.

signal opened

@export var gate_path: NodePath = ^"../Gate"
@export var collision_path: NodePath = ^"../CastleCollision"
@export var open_height: float = 5.0
@export var open_duration: float = 0.8

var _gate: Node3D
var _collision: CollisionObject3D
var _is_open := false
var _unlocked := false
var _closed_position := Vector3.ZERO

func _ready() -> void:
	_gate = get_node_or_null(gate_path) as Node3D
	_collision = get_node_or_null(collision_path) as CollisionObject3D
	if _gate != null:
		_closed_position = _gate.position

func set_unlocked(unlocked: bool) -> void:
	_unlocked = unlocked
	if unlocked:
		open_gate()

func open_gate() -> void:
	if not _unlocked or _is_open or _gate == null:
		return
	_is_open = true
	if _collision != null:
		_collision.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	var tween := create_tween()
	tween.tween_property(_gate, "position:y", _closed_position.y + open_height, open_duration)
	tween.tween_callback(opened.emit)

func restore_opened() -> void:
	if _gate == null:
		return
	_unlocked = true
	_is_open = true
	_gate.position.y = _closed_position.y + open_height
	if _collision != null:
		_collision.process_mode = Node.PROCESS_MODE_DISABLED

func is_open() -> bool:
	return _is_open
