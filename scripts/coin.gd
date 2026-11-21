extends Area3D

@export var value: int = 1
@export var spin_speed: float = 3.0
@export var bob_height: float = 0.12
@export var bob_speed: float = 2.5

var _collected := false
var _base_y := 0.0
var _time := 0.0
var _gold_material: StandardMaterial3D
var _halo_material: StandardMaterial3D
var _coin_light: OmniLight3D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	_base_y = position.y
	_time = randf() * TAU

	if get_node_or_null("CoinMesh") == null:
		var coin_mesh := MeshInstance3D.new()
		coin_mesh.name = "CoinMesh"
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.35
		cylinder.bottom_radius = 0.35
		cylinder.height = 0.08
		cylinder.radial_segments = 24
		cylinder.rings = 1
		coin_mesh.mesh = cylinder
		coin_mesh.rotation_degrees = Vector3(90, 0, 0)
		var gold := StandardMaterial3D.new()
		gold.albedo_color = Color(1.0, 0.78, 0.15, 1.0)
		gold.metallic = 0.8
		gold.roughness = 0.3
		gold.emission_enabled = true
		gold.emission = Color(0.6, 0.4, 0.0, 1.0)
		gold.emission_energy_multiplier = 1.1
		_gold_material = gold
		coin_mesh.material_override = gold
		coin_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(coin_mesh)
		var halo := MeshInstance3D.new()
		halo.name = "CoinHalo"
		var halo_mesh := TorusMesh.new()
		halo_mesh.inner_radius = 0.39
		halo_mesh.outer_radius = 0.46
		halo_mesh.rings = 8
		halo_mesh.ring_segments = 16
		halo.mesh = halo_mesh
		halo.rotation_degrees.x = 90.0
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_halo_material = StandardMaterial3D.new()
		_halo_material.albedo_color = Color(1.0, 0.73, 0.2, 0.78)
		_halo_material.emission_enabled = true
		_halo_material.emission = Color(1.0, 0.5, 0.08)
		_halo_material.emission_energy_multiplier = 0.65
		_halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		halo.material_override = _halo_material
		add_child(halo)
		_coin_light = OmniLight3D.new()
		_coin_light.name = "CoinGlow"
		_coin_light.light_color = Color(1.0, 0.68, 0.12, 1.0)
		_coin_light.light_energy = 0.45
		_coin_light.omni_range = 2.2
		_coin_light.shadow_enabled = false
		add_child(_coin_light)

	if get_node_or_null("CollisionShape3D") == null:
		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		var sphere := SphereShape3D.new()
		sphere.radius = 0.55
		collision.shape = sphere
		add_child(collision)

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta
	rotate_y(spin_speed * delta)
	position.y = _base_y + sin(_time * bob_speed) * bob_height
	var shimmer := 0.72 + 0.55 * (0.5 + 0.5 * sin(_time * 4.2))
	if _gold_material != null:
		_gold_material.emission_energy_multiplier = shimmer
	if _halo_material != null:
		_halo_material.emission_energy_multiplier = 0.42 + shimmer * 0.38
	if _coin_light != null:
		_coin_light.light_energy = 0.24 + shimmer * 0.2

func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.has_method("add_coins"):
		return
	_collected = true
	set_deferred("monitoring", false)
	body.call("add_coins", value)
	var pickup_tween := create_tween()
	pickup_tween.set_parallel(true)
	var coin_mesh := get_node_or_null("CoinMesh") as Node3D
	var halo := get_node_or_null("CoinHalo") as Node3D
	if coin_mesh != null:
		pickup_tween.tween_property(coin_mesh, "scale", Vector3.ZERO, 0.15)
	if halo != null:
		pickup_tween.tween_property(halo, "scale", Vector3.ZERO, 0.15)
	pickup_tween.tween_property(self, "position:y", position.y + 0.28, 0.15)
	pickup_tween.chain().tween_callback(queue_free)
