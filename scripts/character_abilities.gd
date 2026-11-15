extends Node
## Character-specific special abilities. Attach as a child of Player.

@export var cooldown_seconds: float = 8.0
@export var louay_dash_duration: float = 0.24
@export var louay_dash_speed: float = 16.0
@export var fady_blast_radius: float = 6.0
@export var fady_blast_damage: int = 2
@export var alsayed_shield_duration: float = 3.0

var _player: CharacterBody3D
var _health: Node
var _hud: Node
var _cooldown_remaining: float = 0.0
var _dash_particles: GPUParticles3D
var _shield_visual: MeshInstance3D


func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	if _player == null:
		push_error("AbilitySystem must be a child of Player (CharacterBody3D).")
		set_process(false)
		return
	_health = _player.get_node_or_null("HealthSystem")
	_hud = get_tree().current_scene.get_node_or_null("MobileHUD")
	if _player.has_signal("skill_used"):
		if not _player.skill_used.is_connected(_on_skill_requested):
			_player.skill_used.connect(_on_skill_requested)
	_build_dash_particles()
	_update_hud()


func _process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
		_update_hud()


func _on_skill_requested() -> void:
	if _cooldown_remaining > 0.0 or not is_instance_valid(_player):
		return
	_cooldown_remaining = cooldown_seconds
	var hero := str(_player.get("selected_hero")).to_lower()
	match hero:
		"lolo", "louay", "لؤي":
			_louay_shadow_dash()
		"fady", "فادي":
			_fady_fire_blast()
		"alsayed", "el_sayed", "السيد":
			_alsayed_energy_shield()
		_:
			push_warning("No special ability is configured for hero: " + hero)
			_cooldown_remaining = 0.0
	_update_hud()


func _louay_shadow_dash() -> void:
	if _player.has_method("start_shadow_dash"):
		_player.call("start_shadow_dash", louay_dash_duration, louay_dash_speed)
	if is_instance_valid(_dash_particles):
		_dash_particles.restart()
		_dash_particles.emitting = true


func _fady_fire_blast() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for node in enemies:
		if not is_instance_valid(node) or not node is Node3D:
			continue
		var enemy := node as Node3D
		if enemy.global_position.distance_to(_player.global_position) <= fady_blast_radius:
			if enemy.has_method("take_damage"):
				enemy.call("take_damage", fady_blast_damage)
	_spawn_fire_blast_visual()


func _alsayed_energy_shield() -> void:
	if is_instance_valid(_health) and _health.has_method("activate_shield"):
		_health.call("activate_shield", alsayed_shield_duration)
	_show_shield_visual()


func _build_dash_particles() -> void:
	_dash_particles = GPUParticles3D.new()
	_dash_particles.name = "ShadowDashTrail"
	_dash_particles.amount = 28
	_dash_particles.lifetime = 0.42
	_dash_particles.one_shot = true
	_dash_particles.explosiveness = 0.15
	_dash_particles.emitting = false
	_dash_particles.position = Vector3(0.0, 0.9, 0.35)
	var process_material := ParticleProcessMaterial.new()
	process_material.direction = Vector3(0.0, 0.15, 1.0)
	process_material.spread = 32.0
	process_material.initial_velocity_min = 1.0
	process_material.initial_velocity_max = 3.2
	process_material.gravity = Vector3(0.0, -0.8, 0.0)
	process_material.scale_min = 0.045
	process_material.scale_max = 0.13
	process_material.color = Color(0.34, 0.12, 0.82, 0.82)
	_dash_particles.process_material = process_material
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.07
	particle_mesh.height = 0.14
	var particle_material := StandardMaterial3D.new()
	particle_material.albedo_color = Color(0.42, 0.18, 0.95, 0.85)
	particle_material.emission_enabled = true
	particle_material.emission = Color(0.32, 0.08, 1.0)
	particle_material.emission_energy_multiplier = 2.0
	particle_mesh.material = particle_material
	_dash_particles.draw_pass_1 = particle_mesh
	_player.add_child(_dash_particles)


func _spawn_fire_blast_visual() -> void:
	var effect := MeshInstance3D.new()
	effect.name = "FireBlastEffect"
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 20
	sphere.rings = 10
	effect.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.28, 0.035, 0.48)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(1.0, 0.16, 0.015)
	material.emission_energy_multiplier = 2.5
	effect.material_override = material
	var world := get_tree().current_scene
	world.add_child(effect)
	effect.global_position = _player.global_position + Vector3(0.0, 0.25, 0.0)
	effect.scale = Vector3(0.2, 0.12, 0.2)
	var tween := effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector3(fady_blast_radius * 2.0, 0.28, fady_blast_radius * 2.0), 0.32)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.32)
	tween.chain().tween_callback(effect.queue_free)


func _show_shield_visual() -> void:
	if is_instance_valid(_shield_visual):
		_shield_visual.queue_free()
	_shield_visual = MeshInstance3D.new()
	_shield_visual.name = "EnergyShieldVisual"
	var sphere := SphereMesh.new()
	sphere.radius = 0.78
	sphere.height = 1.95
	sphere.radial_segments = 24
	sphere.rings = 16
	_shield_visual.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.62, 1.0, 0.22)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission = Color(0.08, 0.48, 1.0)
	material.emission_energy_multiplier = 1.4
	_shield_visual.material_override = material
	_shield_visual.position = Vector3(0.0, 1.0, 0.0)
	_shield_visual.scale = Vector3(1.18, 1.05, 1.18)
	_player.add_child(_shield_visual)
	var tween := _shield_visual.create_tween()
	tween.tween_property(_shield_visual, "scale", Vector3(1.28, 1.12, 1.28), 0.22)
	tween.tween_property(_shield_visual, "scale", Vector3(1.18, 1.05, 1.18), 0.22)
	await get_tree().create_timer(alsayed_shield_duration).timeout
	if is_instance_valid(_shield_visual):
		var fade := _shield_visual.create_tween()
		fade.tween_property(_shield_visual, "scale", Vector3.ZERO, 0.18)
		fade.tween_callback(_shield_visual.queue_free)
	_shield_visual = null


func _update_hud() -> void:
	if not is_instance_valid(_hud) or not _hud.has_method("update_skill_cooldown"):
		return
	var hero := str(_player.get("selected_hero")) if is_instance_valid(_player) else ""
	_hud.call("update_skill_cooldown", _cooldown_remaining, cooldown_seconds, hero)
