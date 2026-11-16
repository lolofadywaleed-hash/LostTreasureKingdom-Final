extends Node3D
## Three-slot weapon controller. Uses lightweight procedural weapon visuals until licensed GLB weapons are added.
signal weapon_changed(index: int, weapon_name: String)

const HERO_WEAPONS := {
	"Lolo": [
		{"name": "Shadow Blade", "kind": "sword", "damage": 1, "range": 2.8, "cooldown": 0.34, "color": Color(0.38, 0.16, 0.95)},
		{"name": "Twin Daggers", "kind": "daggers", "damage": 2, "range": 2.2, "cooldown": 0.52, "color": Color(0.12, 0.82, 0.55)},
		{"name": "Phantom Bow", "kind": "bow", "damage": 2, "range": 8.5, "cooldown": 0.82, "color": Color(0.36, 0.68, 1.0)}
	],
	"Fady": [
		{"name": "Ember Saber", "kind": "sword", "damage": 1, "range": 2.8, "cooldown": 0.34, "color": Color(1.0, 0.24, 0.06)},
		{"name": "Flame Chakram", "kind": "chakram", "damage": 2, "range": 2.4, "cooldown": 0.52, "color": Color(1.0, 0.48, 0.06)},
		{"name": "Pyro Staff", "kind": "staff", "damage": 2, "range": 8.5, "cooldown": 0.82, "color": Color(1.0, 0.18, 0.04)}
	],
	"AlSayed": [
		{"name": "Royal Blade", "kind": "sword", "damage": 1, "range": 2.8, "cooldown": 0.34, "color": Color(0.18, 0.62, 1.0)},
		{"name": "Aegis Mace", "kind": "mace", "damage": 2, "range": 2.4, "cooldown": 0.52, "color": Color(0.32, 0.78, 1.0)},
		{"name": "Arcane Scepter", "kind": "staff", "damage": 2, "range": 8.5, "cooldown": 0.82, "color": Color(0.55, 0.38, 1.0)}
	]
}

var current_weapon_index: int = 0
var current_weapon_name: String = "Shadow Blade"
var _player: CharacterBody3D
var _attack_system: Node
var _hud: Node
var _visual: Node3D


func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	if _player == null:
		push_error("WeaponManager must be a child of Player.")
		set_process(false)
		return
	call_deferred("_initialize_manager")


func _initialize_manager() -> void:
	if not is_instance_valid(_player):
		return
	_attack_system = _player.get_node_or_null("AttackSystem")
	_hud = get_tree().current_scene.get_node_or_null("MobileHUD")
	select_weapon(0)


func get_weapon_definitions() -> Array:
	var hero_id := str(_player.get("selected_hero")) if is_instance_valid(_player) else "Lolo"
	return HERO_WEAPONS.get(hero_id, HERO_WEAPONS["Lolo"])


func select_weapon(index: int) -> void:
	if index < 0 or index > 2 or not is_instance_valid(_player):
		return
	if _attack_system == null:
		_attack_system = _player.get_node_or_null("AttackSystem")
	if _hud == null:
		_hud = get_tree().current_scene.get_node_or_null("MobileHUD")
	var definitions := get_weapon_definitions()
	var definition: Dictionary = definitions[index]
	current_weapon_index = index
	current_weapon_name = str(definition["name"])
	if is_instance_valid(_attack_system):
		_attack_system.set("damage", int(definition["damage"]))
		_attack_system.set("attack_range", float(definition["range"]))
		_attack_system.set("attack_cooldown", float(definition["cooldown"]))
		_attack_system.set("minimum_facing_dot", -0.15 if str(definition["kind"]) in ["bow", "staff"] else 0.15)
	_build_weapon_visual(definition)
	if is_instance_valid(_hud) and _hud.has_method("update_weapon_selection"):
		_hud.call("update_weapon_selection", index, current_weapon_name)
	weapon_changed.emit(index, current_weapon_name)


func _build_weapon_visual(definition: Dictionary) -> void:
	if is_instance_valid(_visual):
		_visual.queue_free()
	_visual = Node3D.new()
	_visual.name = "EquippedWeaponVisual"
	_visual.position = Vector3(0.02, -0.04, -0.12)
	_visual.rotation_degrees = Vector3(0.0, 0.0, -18.0)
	var character_loader := _player.get_node_or_null("KnightVisual")
	var hand_anchor: Node3D
	if character_loader != null and character_loader.has_method("get_weapon_anchor"):
		hand_anchor = character_loader.call("get_weapon_anchor") as Node3D
	if is_instance_valid(hand_anchor):
		hand_anchor.add_child(_visual)
	else:
		_visual.position = Vector3(0.58, 1.02, -0.12)
		add_child(_visual)
	var material := StandardMaterial3D.new()
	material.albedo_color = definition["color"]
	material.metallic = 0.72
	material.roughness = 0.24
	material.emission_enabled = true
	material.emission = definition["color"]
	material.emission_energy_multiplier = 0.55
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.09, 0.08)
	dark.metallic = 0.35
	dark.roughness = 0.55
	match str(definition["kind"]):
		"sword":
			_add_box("Blade", Vector3(0.12, 0.82, 0.055), Vector3(0, 0.55, 0), material)
			_add_box("Guard", Vector3(0.36, 0.075, 0.10), Vector3(0, 0.10, 0), dark)
			_add_cylinder("Grip", 0.055, 0.055, 0.30, Vector3(0, -0.08, 0), dark)
			_add_sphere("Pommel", 0.085, Vector3(0, -0.25, 0), material)
		"daggers":
			for side in [-1.0, 1.0]:
				_add_box("DaggerBlade_%s" % str(side), Vector3(0.075, 0.48, 0.045), Vector3(side * 0.13, 0.38, 0), material)
				_add_cylinder("DaggerGrip_%s" % str(side), 0.04, 0.04, 0.23, Vector3(side * 0.13, 0.02, 0), dark)
		"bow":
			_add_cylinder("BowUpperLimb", 0.035, 0.055, 0.62, Vector3(0, 0.50, 0), material, Vector3(0, 0, -0.20))
			_add_cylinder("BowLowerLimb", 0.055, 0.035, 0.62, Vector3(0, -0.10, 0), material, Vector3(0, 0, 0.20))
			_add_cylinder("BowGrip", 0.045, 0.045, 0.22, Vector3(0, 0.20, 0), dark)
			_add_cylinder("BowString", 0.012, 0.012, 1.0, Vector3(0, 0.20, -0.025), dark)
		"chakram":
			var ring := TorusMesh.new()
			ring.inner_radius = 0.22
			ring.outer_radius = 0.31
			ring.rings = 8
			ring.ring_segments = 24
			_add_mesh("FlameChakram", ring, material, Vector3(0, 0.35, 0))
		"mace":
			_add_cylinder("MaceHandle", 0.055, 0.055, 0.78, Vector3(0, 0.28, 0), dark)
			_add_sphere("MaceHead", 0.22, Vector3(0, 0.78, 0), material)
		"staff":
			_add_cylinder("ScepterShaft", 0.055, 0.055, 1.25, Vector3(0, 0.35, 0), dark)
			_add_sphere("ScepterCrystal", 0.18, Vector3(0, 1.02, 0), material)


func _add_box(label: String, size_value: Vector3, local_pos: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size_value
	_add_mesh(label, mesh, material, local_pos)


func _add_cylinder(label: String, top_radius: float, bottom_radius: float, height_value: float, local_pos: Vector3, material: Material, local_rotation: Vector3 = Vector3.ZERO) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height_value
	mesh.radial_segments = 10
	var node := _add_mesh(label, mesh, material, local_pos)
	node.rotation = local_rotation


func _add_sphere(label: String, radius_value: float, local_pos: Vector3, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius_value
	mesh.height = radius_value * 2.0
	mesh.radial_segments = 12
	mesh.rings = 8
	_add_mesh(label, mesh, material, local_pos)


func _add_mesh(label: String, mesh: Mesh, material: Material, local_pos: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.add_to_group("weapon_visual")
	node.mesh = mesh
	node.material_override = material
	node.position = local_pos
	_visual.add_child(node)
	return node
