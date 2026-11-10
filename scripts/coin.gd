extends Area3D

@export var value: int = 1
@export var spin_speed: float = 3.0
@export var bob_height: float = 0.12
@export var bob_speed: float = 2.5

var _collected := false
var _base_y := 0.0
var _time := 0.0

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
		gold.emission_energy_multiplier = 0.4
		coin_mesh.material_override = gold
		add_child(coin_mesh)

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

func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.has_method("add_coins"):
		return
	_collected = true
	set_deferred("monitoring", false)
	body.call("add_coins", value)
	queue_free()
