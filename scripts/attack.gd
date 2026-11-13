extends Node
## Melee attack component. Attach as a child of Player; Player.attacked drives it.

@export var attack_range: float = 2.6
@export_range(-1.0, 1.0, 0.05) var minimum_facing_dot: float = 0.15
@export var damage: int = 1
@export var attack_cooldown: float = 0.35

var _player: CharacterBody3D
var _ready_to_attack := true


func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	if _player == null:
		push_error("AttackSystem must be a child of Player (CharacterBody3D).")
		return
	if not _player.attacked.is_connected(_on_player_attacked):
		_player.attacked.connect(_on_player_attacked)


func _on_player_attacked() -> void:
	if not _ready_to_attack or _player == null:
		return
	_ready_to_attack = false
	_hit_nearest_enemy()
	await get_tree().create_timer(attack_cooldown).timeout
	_ready_to_attack = true


func _hit_nearest_enemy() -> void:
	var forward := -_player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var best_enemy: Node3D = null
	var best_distance := attack_range
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or not node is Node3D:
			continue
		if not node.has_method("take_damage"):
			continue
		var offset: Vector3 = node.global_position - _player.global_position
		var flat_offset := Vector3(offset.x, 0.0, offset.z)
		var distance := flat_offset.length()
		if distance > best_distance or distance < 0.001:
			continue
		if forward.dot(flat_offset.normalized()) < minimum_facing_dot:
			continue
		best_distance = distance
		best_enemy = node
	if best_enemy != null:
		best_enemy.call("take_damage", damage)
