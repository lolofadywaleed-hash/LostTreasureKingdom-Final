extends Node3D
## Detailed stylized castle facade. Existing CastleCollision remains untouched.

var _stone: StandardMaterial3D
var _light_stone: StandardMaterial3D
var _roof: StandardMaterial3D
var _gold: StandardMaterial3D
var _window: StandardMaterial3D

func _ready() -> void:
	_stone = _material(Color(0.48, 0.53, 0.58), 0.88)
	_light_stone = _material(Color(0.72, 0.73, 0.68), 0.82)
	_roof = _material(Color(0.20, 0.32, 0.48), 0.7)
	_gold = _material(Color(0.88, 0.62, 0.22), 0.42, Color(0.9, 0.48, 0.12), 0.45)
	_window = _material(Color(0.35, 0.78, 1.0), 0.25, Color(0.12, 0.58, 1.0), 1.8)
	_build_keep()
	_build_towers()
	_build_gate()
	_build_windows_and_trim()

func _material(color: Color, roughness_value: float, glow: Color = Color.BLACK, glow_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	if glow_energy > 0.0:
		material.emission_enabled = true
		material.emission = glow
		material.emission_energy_multiplier = glow_energy
	return material

func _box(label: String, size_value: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size_value
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.position = pos
	node.material_override = material
	add_child(node)
	return node

func _cylinder(label: String, top: float, bottom: float, height_value: float, sides: int, pos: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height_value
	mesh.radial_segments = sides
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.position = pos
	node.material_override = material
	add_child(node)
	return node

func _build_keep() -> void:
	_box("GrandKeepStonework", Vector3(15.0, 9.0, 5.8), Vector3(0, 4.5, 0), _stone)
	_box("KeepFoundation", Vector3(16.0, 0.65, 6.6), Vector3(0, 0.35, 0), _light_stone)
	_box("KeepUpperCornice", Vector3(15.8, 0.55, 6.35), Vector3(0, 8.9, 0), _gold)
	for x in range(-6, 7, 2):
		_box("KeepBattlement_%s" % str(x), Vector3(1.05, 1.0, 5.9), Vector3(float(x), 9.65, 0), _light_stone)
	for x in [-4.5, -1.5, 1.5, 4.5]:
		_box("FacadePilaster_%s" % str(x), Vector3(0.42, 7.8, 0.28), Vector3(x, 4.6, 2.98), _light_stone)

func _build_towers() -> void:
	for side in [-1.0, 1.0]:
		var x := side * 6.2
		_cylinder("RoundTower_%s" % str(side), 1.42, 1.72, 13.0, 16, Vector3(x, 6.5, 0), _light_stone)
		_cylinder("TowerLowerBand_%s" % str(side), 1.82, 1.82, 0.48, 16, Vector3(x, 1.2, 0), _gold)
		_cylinder("TowerCrownBand_%s" % str(side), 1.75, 1.75, 0.55, 16, Vector3(x, 12.65, 0), _gold)
		_cylinder("TowerBlueRoof_%s" % str(side), 0.0, 1.9, 3.5, 16, Vector3(x, 14.55, 0), _roof)
		_cylinder("TowerFinial_%s" % str(side), 0.0, 0.28, 0.9, 8, Vector3(x, 16.75, 0), _gold)
		for i in range(8):
			var angle := TAU * float(i) / 8.0
			var merlon := _box("TowerMerlon_%s_%02d" % [str(side), i], Vector3(0.48, 0.85, 0.55), Vector3(x + cos(angle) * 1.48, 13.2, sin(angle) * 1.48), _light_stone)
			merlon.rotation.y = -angle

func _build_gate() -> void:
	_box("GateLeftPier", Vector3(1.25, 5.5, 1.0), Vector3(-2.45, 2.75, 3.05), _light_stone)
	_box("GateRightPier", Vector3(1.25, 5.5, 1.0), Vector3(2.45, 2.75, 3.05), _light_stone)
	_box("GateLintel", Vector3(6.0, 1.0, 1.2), Vector3(0, 5.55, 3.05), _gold)
	_box("GateShadow", Vector3(3.4, 4.5, 0.18), Vector3(0, 2.3, 3.12), _roof)
	_box("GateMagicSeal", Vector3(1.25, 1.65, 0.12), Vector3(0, 3.0, 3.25), _window)

func _build_windows_and_trim() -> void:
	for x in [-4.4, -1.5, 1.5, 4.4]:
		_box("UpperWindowFrame_%s" % str(x), Vector3(0.9, 1.7, 0.18), Vector3(x, 6.9, 3.0), _gold)
		_box("UpperWindowGlow_%s" % str(x), Vector3(0.56, 1.32, 0.1), Vector3(x, 6.9, 3.12), _window)
	for side in [-1.0, 1.0]:
		var x := side * 6.2
		for y in [4.2, 7.0, 9.7]:
			_box("TowerSlit_%s_%s" % [str(side), str(y)], Vector3(0.16, 0.95, 0.08), Vector3(x, y, 1.45), _window)