class_name EnemyManager
extends Node3D
## Registers existing enemies and provides controlled spawning for chapter encounters.

signal enemy_spawned(enemy: Node3D)
signal enemy_defeated(enemy: Node3D)

@export var enemy_scene: PackedScene
@export var spawn_positions: Array[Vector3] = []
@export var guard_path: NodePath = ^"../Enemy"

var _tracked_enemies: Array[Node3D] = []

func _ready() -> void:
	_register_existing_enemies()

func _register_existing_enemies() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		_register_enemy(node as Node3D)


func activate_guard() -> Node3D:
	var guard := get_node_or_null(guard_path) as Node3D
	if guard == null:
		return null
	if guard.has_method("activate_encounter"):
		guard.call("activate_encounter")
	_register_enemy(guard)
	return guard

func _register_enemy(enemy: Node3D) -> void:
	if enemy == null or _tracked_enemies.has(enemy):
		return
	_tracked_enemies.append(enemy)
	if not enemy.tree_exited.is_connected(_on_enemy_exited.bind(enemy)):
		enemy.tree_exited.connect(_on_enemy_exited.bind(enemy), CONNECT_ONE_SHOT)
	enemy_spawned.emit(enemy)

func spawn_enemy(at_position: Vector3) -> Node3D:
	if enemy_scene == null:
		push_error("EnemyManager needs an enemy_scene before spawning.")
		return null
	var enemy := enemy_scene.instantiate() as Node3D
	if enemy == null:
		push_error("enemy_scene must instantiate a Node3D.")
		return null
	enemy.global_position = at_position
	get_tree().current_scene.add_child(enemy)
	_register_enemy(enemy)
	return enemy

func spawn_configured_enemies() -> void:
	for position in spawn_positions:
		spawn_enemy(position)

func get_alive_enemy_count() -> int:
	var alive := 0
	for enemy in _tracked_enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			alive += 1
	return alive

func all_enemies_defeated() -> bool:
	return get_alive_enemy_count() == 0 and not _tracked_enemies.is_empty()

func _on_enemy_exited(enemy: Node3D) -> void:
	enemy_defeated.emit(enemy)
