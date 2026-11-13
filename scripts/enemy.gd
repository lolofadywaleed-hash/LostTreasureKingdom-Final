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


func _add_hit_vfx() -> void:
	if get_node_or_null("HitSparks") != null:
		return
	var sparks := GPUParticles3D.new()
	sparks.name = "HitSparks"
	sparks.amount = 18
	sparks.lifetime = 0.38
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.emitting = false
	sparks.position.y = 1.0
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 180.0
	process.initial_velocity_min = 1.2
	process.initial_velocity_max = 3.0
	process.gravity = Vector3(0.0, -5.0, 0.0)
	process.scale_min = 0.045
	process.scale_max = 0.11
	sparks.process_material = process
	var spark_mesh := SphereMesh.new()
	spark_mesh.radius = 0.06
	spark_mesh.height = 0.12
	var spark_material := StandardMaterial3D.new()
	spark_material.albedo_color = Color(1.0, 0.48, 0.12, 1.0)
	spark_material.emission_enabled = true
	spark_material.emission = Color(1.0, 0.22, 0.04, 1.0)
	spark_material.emission_energy_multiplier = 2.0
	spark_mesh.material = spark_material
	sparks.draw_pass_1 = spark_mesh
	add_child(sparks)


func _show_damage(amount: int) -> void:
	var label := Label3D.new()
	label.name = "DamageNumber"
	label.text = "-%d HP" % amount
	label.font_size = 48
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.38, 0.25, 1.0)
	label.outline_size = 10
	label.position = Vector3(0.0, 2.1, 0.0)
	add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", 3.0, 0.65)
	tween.tween_property(label, "modulate:a", 0.0, 0.65)
	tween.chain().tween_callback(label.queue_free)


func take_damage(amount: int = 1) -> void:
	if amount <= 0 or _health <= 0:
		return
	_health = maxi(0, _health - amount)
	_show_damage(amount)
	var sparks := get_node_or_null("HitSparks") as GPUParticles3D
	if sparks != null:
		sparks.restart()
		sparks.emitting = true
	if _health == 0:
		queue_free()
