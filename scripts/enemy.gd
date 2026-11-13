extends CharacterBody3D
## Lightweight mobile enemy AI. Uses direct steering and collision; no baked NavigationRegion is required.

@export var move_speed: float = 2.2
@export var gravity: float = 18.0
@export var detection_range: float = 15.0
@export var attack_range: float = 1.7
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.4
@export var max_health: int = 3

var _health: int
var _player: Node3D
var _can_attack := true


func _ready() -> void:
	add_to_group("enemies")
	_health = max_health
	if get_node_or_null("CollisionShape3D") == null:
		var collision := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.42
		capsule.height = 1.7
		collision.shape = capsule
		collision.position.y = 0.85
		add_child(collision)
	if get_node_or_null("Visual") == null:
		var visual := MeshInstance3D.new()
		visual.name = "Visual"
		var mesh := CapsuleMesh.new()
		mesh.radius = 0.42
		mesh.height = 1.7
		visual.mesh = mesh
		visual.position.y = 0.85
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.65, 0.12, 0.16)
		material.roughness = 0.75
		visual.material_override = material
		add_child(visual)
	_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player == null:
		_player = get_node_or_null("../Player") as Node3D


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
		if _player == null:
			return
	var offset := _player.global_position - global_position
	var flat := Vector3(offset.x, 0.0, offset.z)
	var distance := flat.length()
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	if distance <= detection_range and distance > attack_range:
		var direction := flat.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		rotation.y = atan2(direction.x, direction.z)
	elif distance <= attack_range:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 5.0 * delta)
		if _can_attack:
			_attack_player()
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta)
	move_and_slide()


func _attack_player() -> void:
	_can_attack = false
	var health := _player.get_node_or_null("HealthSystem")
	if health != null and health.has_method("take_damage"):
		health.call("take_damage", attack_damage)
	await get_tree().create_timer(attack_cooldown).timeout
	_can_attack = true


func take_damage(amount: int = 1) -> void:
	if amount <= 0 or _health <= 0:
		return
	_health = maxi(0, _health - amount)
	if _health == 0:
		queue_free()
