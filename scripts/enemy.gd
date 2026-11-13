extends CharacterBody3D
## Mobile fantasy enemy with a procedural low-poly silhouette.
## Replace the generated visual with a licensed GLB later without changing its AI API.

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
var _visual_root: Node3D
var _visual_time := 0.0
var _visual_base_y := 0.0


func _ready() -> void:
	add_to_group("enemies")
	_health = max_health
	_ensure_collision()
	_build_enemy_visual()
	_add_hit_vfx()
	_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player == null:
		_player = get_node_or_null("../Player") as Node3D


func _ensure_collision() -> void:
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		add_child(collision)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.46
	capsule.height = 2.15
	collision.shape = capsule
	collision.position = Vector3(0.0, 1.075, 0.0)


func _build_enemy_visual() -> void:
	var old_visual := get_node_or_null("Visual")
	if old_visual != null:
		old_visual.queue_free()
	_visual_root = Node3D.new()
	_visual_root.name = "Visual"
	add_child(_visual_root)
	_visual_base_y = 0.0

	var armor := _make_material(Color(0.19, 0.055, 0.075), 0.22, 0.72)
	var armor_light := _make_material(Color(0.38, 0.09, 0.11), 0.35, 0.55)
	var horn_material := _make_material(Color(0.075, 0.055, 0.07), 0.05, 0.9)
	var eye_material := _make_material(Color(1.0, 0.24, 0.035), 0.1, 0.25, Color(1.0, 0.12, 0.015), 2.5)
	var trim := _make_material(Color(0.78, 0.39, 0.09), 0.7, 0.32)

	var torso := CapsuleMesh.new()
	torso.radius = 0.39
	torso.height = 1.0
	torso.radial_segments = 8
	_add_part("Torso", torso, armor, Vector3(0, 1.12, 0))

	var chest := SphereMesh.new()
	chest.radius = 0.39
	chest.height = 0.42
	chest.radial_segments = 8
	chest.rings = 4
	_add_part("ChestPlate", chest, armor_light, Vector3(0, 1.27, -0.08), Vector3(0, 0, 0))

	var head := SphereMesh.new()
	head.radius = 0.32
	head.height = 0.62
	head.radial_segments = 8
	head.rings = 5
	_add_part("Head", head, armor, Vector3(0, 1.86, 0))

	var horn := ConeMesh.new()
	horn.bottom_radius = 0.13
	horn.top_radius = 0.015
	horn.height = 0.48
	horn.radial_segments = 6
	_add_part("LeftHorn", horn, horn_material, Vector3(-0.21, 2.22, 0.02), Vector3(0, 0, -0.28))
	_add_part("RightHorn", horn, horn_material, Vector3(0.21, 2.22, 0.02), Vector3(0, 0, 0.28))

	var eye := SphereMesh.new()
	eye.radius = 0.055
	eye.height = 0.09
	eye.radial_segments = 8
	eye.rings = 4
	_add_part("LeftEye", eye, eye_material, Vector3(-0.115, 1.9, -0.285))
	_add_part("RightEye", eye, eye_material, Vector3(0.115, 1.9, -0.285))

	var arm := CapsuleMesh.new()
	arm.radius = 0.14
	arm.height = 0.72
	arm.radial_segments = 7
	_add_part("LeftArm", arm, armor, Vector3(-0.49, 1.13, 0), Vector3(0, 0, -0.42))
	_add_part("RightArm", arm, armor, Vector3(0.49, 1.13, 0), Vector3(0, 0, 0.42))

	var shoulder := SphereMesh.new()
	shoulder.radius = 0.23
	shoulder.height = 0.28
	shoulder.radial_segments = 7
	_add_part("LeftShoulder", shoulder, trim, Vector3(-0.43, 1.48, 0))
	_add_part("RightShoulder", shoulder, trim, Vector3(0.43, 1.48, 0))

	var leg := CapsuleMesh.new()
	leg.radius = 0.16
	leg.height = 0.68
	leg.radial_segments = 7
	_add_part("LeftLeg", leg, horn_material, Vector3(-0.21, 0.43, 0))
	_add_part("RightLeg", leg, horn_material, Vector3(0.21, 0.43, 0))


func _make_material(color: Color, metallic: float, roughness: float, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	return material


func _add_part(part_name: String, mesh: Mesh, material: Material, local_position: Vector3, local_rotation: Vector3 = Vector3.ZERO) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.material_override = material
	part.position = local_position
	part.rotation = local_rotation
	_visual_root.add_child(part)


func _process(delta: float) -> void:
	_visual_time += delta
	if is_instance_valid(_visual_root):
		_visual_root.position.y = _visual_base_y + sin(_visual_time * 2.4) * 0.035


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
	var process_material := ParticleProcessMaterial.new()
	process_material.direction = Vector3(0.0, 1.0, 0.0)
	process_material.spread = 180.0
	process_material.initial_velocity_min = 1.2
	process_material.initial_velocity_max = 3.0
	process_material.gravity = Vector3(0.0, -5.0, 0.0)
	process_material.scale_min = 0.045
	process_material.scale_max = 0.11
	sparks.process_material = process_material
	var spark_mesh := SphereMesh.new()
	spark_mesh.radius = 0.06
	spark_mesh.height = 0.12
	var spark_material := _make_material(Color(1.0, 0.48, 0.12), 0.0, 0.25, Color(1.0, 0.22, 0.04), 2.0)
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
