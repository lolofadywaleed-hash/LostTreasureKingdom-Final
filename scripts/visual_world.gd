extends Node3D
## Lightweight procedural scenery for the first open-world region.
## Keeps gameplay scenes, collision, player, enemies and HUD untouched.

@export_range(40, 180, 1) var tree_count: int = 104
@export_range(12, 64, 1) var rock_count: int = 38
@export_range(8, 32, 1) var crystal_count: int = 18

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 20261114
	_build_forest()
	_build_rocks()
	_build_crystals()
	_build_distant_hills()


func _random_world_position(margin_x: float = 12.0, margin_z: float = 12.0) -> Vector3:
	for attempt in range(120):
		var x := _rng.randf_range(-105.0 + margin_x, 105.0 - margin_x)
		var z := _rng.randf_range(-85.0 + margin_z, 85.0 - margin_z)
		# Keep the central approach to the castle, the road and player spawn clear.
		if absf(x) < 12.0 and z < 18.0:
			continue
		if Vector2(x, z).distance_to(Vector2(0.0, -39.0)) < 19.0:
			continue
		if Vector2(x, z).distance_to(Vector2(0.0, 12.0)) < 9.0:
			continue
		return Vector3(x, 0.0, z)
	return Vector3(24.0, 0.0, 24.0)


func _build_forest() -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.22
	trunk.bottom_radius = 0.38
	trunk.height = 3.5
	trunk.radial_segments = 7
	trunk.material = _vertex_material(Color.WHITE, 0.96)

	var canopy := SphereMesh.new()
	canopy.radius = 1.25
	canopy.height = 2.35
	canopy.radial_segments = 8
	canopy.rings = 5
	canopy.material = _vertex_material(Color.WHITE, 0.98)

	var trunk_transforms: Array[Transform3D] = []
	var canopy_transforms: Array[Transform3D] = []
	var canopy_colors: Array[Color] = []
	var palette := [
		Color(0.12, 0.34, 0.18),
		Color(0.16, 0.42, 0.20),
		Color(0.22, 0.46, 0.23),
		Color(0.10, 0.29, 0.19),
		Color(0.27, 0.48, 0.25)
	]

	for index in range(tree_count):
		var point := _random_world_position()
		var scale_factor := _rng.randf_range(0.78, 1.34)
		var lean := _rng.randf_range(-0.10, 0.10)
		var trunk_basis := Basis.from_scale(Vector3(0.82 * scale_factor, scale_factor, 0.82 * scale_factor))
		trunk_basis = trunk_basis.rotated(Vector3.UP, _rng.randf_range(0.0, TAU))
		trunk_transforms.append(Transform3D(trunk_basis, point + Vector3(0.0, 1.75 * scale_factor, 0.0)))
		var crown_scale := scale_factor * _rng.randf_range(0.88, 1.18)
		var crown_basis := Basis.from_scale(Vector3(1.15 * crown_scale, 1.22 * crown_scale, 1.15 * crown_scale))
		crown_basis = crown_basis.rotated(Vector3.UP, _rng.randf_range(0.0, TAU))
		crown_basis = crown_basis.rotated(Vector3.RIGHT, lean)
		canopy_transforms.append(Transform3D(crown_basis, point + Vector3(0.0, 3.65 * scale_factor, 0.0)))
		canopy_colors.append(palette[_rng.randi_range(0, palette.size() - 1)])

	_add_multimesh("ForestTrunks", trunk, trunk_transforms)
	_add_multimesh("ForestCanopies", canopy, canopy_transforms, canopy_colors)


func _build_rocks() -> void:
	var rock := SphereMesh.new()
	rock.radius = 1.0
	rock.height = 1.55
	rock.radial_segments = 7
	rock.rings = 4
	rock.material = _vertex_material(Color.WHITE, 1.0)

	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var palette := [Color(0.34, 0.39, 0.40), Color(0.43, 0.45, 0.43), Color(0.29, 0.34, 0.37)]
	for index in range(rock_count):
		var point := _random_world_position(8.0, 8.0)
		var sx := _rng.randf_range(0.65, 2.0)
		var sy := _rng.randf_range(0.45, 1.15)
		var sz := _rng.randf_range(0.55, 1.65)
		var basis := Basis.from_scale(Vector3(sx, sy, sz))
		basis = basis.rotated(Vector3.UP, _rng.randf_range(0.0, TAU))
		transforms.append(Transform3D(basis, point + Vector3(0.0, sy * 0.72, 0.0)))
		colors.append(palette[_rng.randi_range(0, palette.size() - 1)])
	_add_multimesh("NaturalRockClusters", rock, transforms, colors)


func _build_crystals() -> void:
	var crystal := CylinderMesh.new()
	crystal.top_radius = 0.015
	crystal.bottom_radius = 0.34
	crystal.height = 2.35
	crystal.radial_segments = 5
	crystal.material = _vertex_material(Color.WHITE, 0.28, Color(0.18, 0.62, 1.0), 1.8)

	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var palette := [Color(0.28, 0.78, 1.0), Color(0.48, 0.45, 1.0), Color(0.30, 0.95, 0.82)]
	for index in range(crystal_count):
		var point := _random_world_position(18.0, 18.0)
		var scale_factor := _rng.randf_range(0.65, 1.35)
		var basis := Basis.from_scale(Vector3(scale_factor, scale_factor, scale_factor))
		basis = basis.rotated(Vector3.UP, _rng.randf_range(0.0, TAU))
		transforms.append(Transform3D(basis, point + Vector3(0.0, 1.18 * scale_factor, 0.0)))
		colors.append(palette[_rng.randi_range(0, palette.size() - 1)])
	_add_multimesh("AncientCrystalGrove", crystal, transforms, colors)


func _build_distant_hills() -> void:
	var hill_mesh := SphereMesh.new()
	hill_mesh.radius = 1.0
	hill_mesh.height = 2.0
	hill_mesh.radial_segments = 9
	hill_mesh.rings = 5
	hill_mesh.material = _vertex_material(Color(0.20, 0.31, 0.34), 1.0)
	var positions := [
		Vector3(-96, 5, -72), Vector3(-70, 4, -83), Vector3(-34, 3, -84),
		Vector3(30, 4, -84), Vector3(70, 6, -78), Vector3(98, 5, -52),
		Vector3(100, 4, 0), Vector3(98, 5, 54), Vector3(62, 4, 82),
		Vector3(18, 3, 84), Vector3(-38, 5, 83), Vector3(-86, 6, 65),
		Vector3(-101, 4, 18)
	]
	for index in range(positions.size()):
		var hill := MeshInstance3D.new()
		hill.name = "HorizonHill_%02d" % index
		hill.mesh = hill_mesh
		var sx := _rng.randf_range(9.0, 17.0)
		var sy := _rng.randf_range(5.0, 10.0)
		var sz := _rng.randf_range(8.0, 15.0)
		hill.scale = Vector3(sx, sy, sz)
		hill.position = positions[index]
		add_child(hill)


func _add_multimesh(node_name: String, mesh: Mesh, transforms: Array[Transform3D], colors: Array[Color] = []) -> void:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = not colors.is_empty()
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for index in range(transforms.size()):
		multi.set_instance_transform(index, transforms[index])
		if not colors.is_empty():
			multi.set_instance_color(index, colors[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multi
	add_child(instance)


func _vertex_material(base_color: Color, roughness_value: float, emission_color: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = base_color
	material.vertex_color_use_as_albedo = true
	material.roughness = roughness_value
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission_color
		material.emission_energy_multiplier = emission_energy
	return material
