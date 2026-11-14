extends Node3D
## First art-direction pass: an enchanted valley landmark layer.
## Lightweight meshes and a small number of lights keep this suitable for Android.

var _rng := RandomNumberGenerator.new()
var _stone := _mat(Color(0.42, 0.48, 0.52), 0.92)
var _gold := _mat(Color(0.92, 0.62, 0.19), 0.48, Color(1.0, 0.48, 0.08), 0.7)
var _blue_glow := _mat(Color(0.28, 0.72, 0.98), 0.22, Color(0.12, 0.58, 1.0), 2.2)
var _green_glow := _mat(Color(0.32, 0.92, 0.68), 0.28, Color(0.08, 0.9, 0.56), 1.6)

func _ready() -> void:
	_rng.seed = 14112026
	_build_stoneway()
	_build_ancient_gate()
	_build_crystal_altars()
	_build_floating_islands()
	_build_lanterns()
	_build_foreground_flora()
	_build_mountain_spires()

func _mat(color: Color, rough: float, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m

func _mesh_node(node_name: String, mesh: Mesh, pos: Vector3, material: Material, scale_value: Vector3 = Vector3.ONE, parent: Node = self) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = pos
	instance.scale = scale_value
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _build_stoneway() -> void:
	var slab := BoxMesh.new()
	slab.size = Vector3(1.0, 0.16, 1.0)
	for i in range(34):
		var z := 13.0 - float(i) * 1.62
		var x := _rng.randf_range(-1.25, 1.25)
		var stone_scale := Vector3(_rng.randf_range(2.0, 3.4), 1.0, _rng.randf_range(1.1, 1.65))
		var piece := _mesh_node("AncientRoadStone_%02d" % i, slab, Vector3(x, 0.12, z), _stone, stone_scale)
		piece.rotation.y = _rng.randf_range(-0.12, 0.12)
		if i % 4 == 0:
			var rune := BoxMesh.new()
			rune.size = Vector3(0.7, 0.025, 0.08)
			_mesh_node("RoadRune_%02d" % i, rune, Vector3(x, 0.22, z), _gold, Vector3.ONE)

func _build_ancient_gate() -> void:
	var pillar := BoxMesh.new()
	pillar.size = Vector3(1.25, 7.0, 1.4)
	for side in [-1.0, 1.0]:
		_mesh_node("GatePillar_%s" % str(side), pillar, Vector3(side * 7.0, 3.5, -25.0), _stone)
		var cap := BoxMesh.new()
		cap.size = Vector3(1.8, 0.45, 1.9)
		_mesh_node("GatePillarCap_%s" % str(side), cap, Vector3(side * 7.0, 7.15, -25.0), _gold)
	var lintel := BoxMesh.new()
	lintel.size = Vector3(15.5, 1.15, 1.8)
	_mesh_node("AncientGateLintel", lintel, Vector3(0.0, 7.1, -25.0), _stone)
	var crest := SphereMesh.new()
	crest.radius = 1.0
	crest.height = 1.6
	_mesh_node("GateCrest", crest, Vector3(0.0, 8.25, -25.0), _blue_glow, Vector3(1.25, 1.0, 0.45))

func _build_crystal_altars() -> void:
	var positions := [Vector3(-18, 0, -12), Vector3(19, 0, -31), Vector3(-27, 0, -49), Vector3(30, 0, 18)]
	for i in range(positions.size()):
		var p: Vector3 = positions[i]
		var base := CylinderMesh.new()
		base.top_radius = 1.25
		base.bottom_radius = 1.55
		base.height = 0.55
		base.radial_segments = 8
		_mesh_node("CrystalAltarBase_%02d" % i, base, p + Vector3.UP * 0.28, _stone)
		var crystal := PrismMesh.new()
		crystal.size = Vector3(1.15, 3.4, 1.0)
		var gem := _mesh_node("AncientCrystal_%02d" % i, crystal, p + Vector3.UP * 2.1, _blue_glow if i % 2 == 0 else _green_glow)
		gem.rotation.y = float(i) * 0.8
		var light := OmniLight3D.new()
		light.name = "CrystalGlow_%02d" % i
		light.position = p + Vector3.UP * 2.0
		light.light_color = Color(0.22, 0.68, 1.0) if i % 2 == 0 else Color(0.22, 1.0, 0.66)
		light.light_energy = 0.8
		light.omni_range = 8.0
		add_child(light)

func _build_floating_islands() -> void:
	var island_mesh := SphereMesh.new()
	island_mesh.radius = 1.0
	island_mesh.height = 2.0
	island_mesh.radial_segments = 9
	island_mesh.rings = 5
	var island_mat := _mat(Color(0.22, 0.34, 0.38), 1.0)
	var locations := [
		Vector3(-34, 24, -42), Vector3(31, 29, -55), Vector3(-57, 34, 8),
		Vector3(58, 27, -8), Vector3(4, 39, -76)
	]
	for i in range(locations.size()):
		var p: Vector3 = locations[i]
		_mesh_node("FloatingIsland_%02d" % i, island_mesh, p, island_mat, Vector3(8.0, 2.4, 6.5))
		var crystal := PrismMesh.new()
		crystal.size = Vector3(1.2, 3.2, 1.0)
		_mesh_node("SkyCrystal_%02d" % i, crystal, p + Vector3(0, 3.1, 0), _blue_glow, Vector3.ONE)

func _build_lanterns() -> void:
	var post := CylinderMesh.new()
	post.top_radius = 0.12
	post.bottom_radius = 0.2
	post.height = 2.7
	post.radial_segments = 7
	var orb := SphereMesh.new()
	orb.radius = 0.38
	orb.height = 0.76
	for i in range(8):
		var z := 8.0 - float(i) * 5.3
		for side in [-1.0, 1.0]:
			var x := side * 5.2
			_mesh_node("LanternPost_%02d_%s" % [i, str(side)], post, Vector3(x, 1.35, z), _stone)
			_mesh_node("LanternFlame_%02d_%s" % [i, str(side)], orb, Vector3(x, 2.9, z), _gold)
			if i % 2 == 0:
				var light := OmniLight3D.new()
				light.position = Vector3(x, 2.9, z)
				light.light_color = Color(1.0, 0.58, 0.2)
				light.light_energy = 0.42
				light.omni_range = 5.0
				add_child(light)

func _build_foreground_flora() -> void:
	var flower := SphereMesh.new()
	flower.radius = 0.22
	flower.height = 0.28
	flower.radial_segments = 6
	var palette := [_mat(Color(0.95, 0.48, 0.72), 0.7, Color(0.6, 0.12, 0.34), 0.35), _mat(Color(0.9, 0.78, 0.35), 0.7, Color(0.5, 0.3, 0.06), 0.3), _mat(Color(0.45, 0.7, 1.0), 0.7, Color(0.12, 0.34, 0.8), 0.35)]
	for i in range(70):
		var x := _rng.randf_range(-24.0, 24.0)
		var z := _rng.randf_range(-52.0, 22.0)
		if absf(x) < 3.5:
			continue
		_mesh_node("MagicBloom_%02d" % i, flower, Vector3(x, 0.25, z), palette[i % palette.size()], Vector3(1.0, 0.65, 1.0))

func _build_mountain_spires() -> void:
	var spire := PrismMesh.new()
	spire.size = Vector3(1.0, 2.0, 1.0)
	var material := _mat(Color(0.25, 0.36, 0.43), 0.95)
	var locations := [
		Vector3(-78, 12, -62), Vector3(-52, 15, -78), Vector3(-12, 11, -91),
		Vector3(34, 14, -88), Vector3(76, 13, -66), Vector3(91, 10, -18),
		Vector3(86, 12, 48), Vector3(48, 13, 78), Vector3(-38, 12, 80), Vector3(-88, 11, 42)
	]
	for i in range(locations.size()):
		var p: Vector3 = locations[i]
		_mesh_node("DistantMountainSpire_%02d" % i, spire, p, material, Vector3(_rng.randf_range(8.0, 14.0), _rng.randf_range(10.0, 18.0), _rng.randf_range(8.0, 13.0)))
