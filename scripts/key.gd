extends Area3D
## Collectible chapter key built from Godot primitives; no external asset is assumed.

signal collected(key_id: String)

@export var key_id: String = "forest_key"
@export var spin_speed: float = 2.4

var _collected := false
var _base_y := 0.0
var _time := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	_base_y = position.y
	_time = randf() * TAU
	_build_visual()
	body_entered.connect(_on_body_entered)

func _build_visual() -> void:
	if get_node_or_null("KeyMesh") != null:
		return
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "KeyMesh"
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.09
	shaft.bottom_radius = 0.09
	shaft.height = 0.9
	shaft.radial_segments = 12
	mesh_instance.mesh = shaft
	mesh_instance.rotation_degrees = Vector3(0, 0, 90)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1.0, 0.72, 0.12, 1.0)
	gold.metallic = 0.85
	gold.roughness = 0.22
	gold.emission_enabled = true
	gold.emission = Color(0.55, 0.22, 0.02, 1.0)
	gold.emission_energy_multiplier = 1.2
	mesh_instance.material_override = gold
	add_child(mesh_instance)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.16
	ring.outer_radius = 0.25
	var ring_instance := MeshInstance3D.new()
	ring_instance.name = "KeyRing"
	ring_instance.mesh = ring
	ring_instance.material_override = gold
	ring_instance.position = Vector3(0.42, 0, 0)
	add_child(ring_instance)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = 0.7
	collision.shape = sphere
	add_child(collision)

func _process(delta: float) -> void:
	_time += delta
	rotate_y(spin_speed * delta)
	position.y = _base_y + sin(_time * 2.2) * 0.12

func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	set_deferred("monitoring", false)
	collected.emit(key_id)
	queue_free()
