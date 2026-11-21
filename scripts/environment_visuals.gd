extends Node3D

const TREE_MODEL_PATHS := [
	"res://assets/models/opengameart-stylized-trees/tree-normal-1.obj",
	"res://assets/models/opengameart-stylized-trees/tree-normal-2.obj",
	"res://assets/models/opengameart-stylized-trees/tree-normal-3.obj",
	"res://assets/models/opengameart-stylized-trees/tree-normal-4.obj",
]
const TREE_TEXTURE_PATHS := [
	"res://assets/models/opengameart-stylized-trees/tree-normal-1.png",
	"res://assets/models/opengameart-stylized-trees/tree-normal-2.png",
	"res://assets/models/opengameart-stylized-trees/tree-normal-3.png",
	"res://assets/models/opengameart-stylized-trees/tree-normal-4.png",
]
const CASTLE_TOWER_PATH := "res://assets/models/kenney-retro-fantasy-kit/Models/OBJ format/tower.obj"
const CASTLE_GATE_PATH := "res://assets/models/kenney-retro-fantasy-kit/Models/OBJ format/wall-fortified-gate.obj"
const CASTLE_WALL_PATH := "res://assets/models/kenney-retro-fantasy-kit/Models/OBJ format/wall-fortified.obj"
const ROCK_PACK_PATHS := [
	"res://assets/models/lokit-elf-village/Elf_Village_Free/FBX/Environment/Rock_01.fbx",
	"res://assets/models/lokit-elf-village/Elf_Village_Free/FBX/Environment/Boulder_01.fbx",
]

const TREE_LAYOUT := [
	{"name": "TreeWestNear", "model": 0, "position": Vector3(-12.0, 0.0, 7.0), "scale": 1.8},
	{"name": "TreeEastNear", "model": 1, "position": Vector3(12.0, 0.0, 2.0), "scale": 2.0},
	{"name": "TreeWestFar", "model": 2, "position": Vector3(-14.0, 0.0, -13.0), "scale": 2.1},
	{"name": "TreeEastFar", "model": 3, "position": Vector3(14.0, 0.0, -18.0), "scale": 2.0},
	{"name": "TreeWestOuter", "model": 1, "position": Vector3(-20.0, 0.0, 1.0), "scale": 2.25},
	{"name": "TreeEastOuter", "model": 0, "position": Vector3(20.0, 0.0, -7.0), "scale": 2.15},
	{"name": "TreeWestRidge", "model": 3, "position": Vector3(-20.0, 0.0, -27.0), "scale": 1.95},
	{"name": "TreeEastRidge", "model": 2, "position": Vector3(20.0, 0.0, -31.0), "scale": 2.15},
	{"name": "TreeWestCastle", "model": 0, "position": Vector3(-16.0, 0.0, -42.0), "scale": 1.8},
	{"name": "TreeEastCastle", "model": 1, "position": Vector3(16.0, 0.0, -44.0), "scale": 1.85},
]

const ROCK_LAYOUT := [
	{"name": "RockWest", "model": 0, "position": Vector3(-7.0, 0.0, -4.0), "scale": 2.8},
	{"name": "RockEast", "model": 0, "position": Vector3(7.0, 0.0, -24.0), "scale": 2.7},
	{"name": "BoulderWest", "model": 1, "position": Vector3(-10.5, 0.0, -30.0), "scale": 0.9},
	{"name": "BoulderEast", "model": 1, "position": Vector3(10.5, 0.0, -12.0), "scale": 0.82},
]


func _ready() -> void:
	_build_castle()
	_build_trees()
	_build_rocks()


func _build_castle() -> void:
	var castle := get_parent().get_node_or_null("Castle") as Node3D
	if castle == null:
		push_error("EnvironmentVisuals could not find the Castle node.")
		return

	var tower := load(CASTLE_TOWER_PATH) as Mesh
	var gate := load(CASTLE_GATE_PATH) as Mesh
	var wall := load(CASTLE_WALL_PATH) as Mesh
	if tower == null or gate == null or wall == null:
		push_error("A licensed Kenney castle mesh failed to load.")
		return

	_add_castle_mesh(castle, "Gatehouse", gate, Vector3(0.0, 0.0, 1.6), Vector3(13.0, 9.5, 3.2))
	_add_castle_mesh(castle, "RearWall", wall, Vector3(0.0, 0.0, -2.2), Vector3(13.0, 9.5, 2.4))
	_add_castle_mesh(castle, "WestWall", wall, Vector3(-5.4, 0.0, -0.2), Vector3(4.0, 9.5, 2.4), PI * 0.5)
	_add_castle_mesh(castle, "EastWall", wall, Vector3(5.4, 0.0, -0.2), Vector3(4.0, 9.5, 2.4), PI * 0.5)
	_add_castle_mesh(castle, "WestTowerVisual", tower, Vector3(-5.1, 0.0, 1.8), Vector3(4.3, 12.0, 4.3))
	_add_castle_mesh(castle, "EastTowerVisual", tower, Vector3(5.1, 0.0, 1.8), Vector3(4.3, 12.0, 4.3))
	_add_castle_mesh(castle, "WestRearTowerVisual", tower, Vector3(-5.1, 0.0, -3.0), Vector3(3.3, 10.0, 3.3))
	_add_castle_mesh(castle, "EastRearTowerVisual", tower, Vector3(5.1, 0.0, -3.0), Vector3(3.3, 10.0, 3.3))

	if castle.get_node_or_null("CastleCollision/CollisionShape3D") == null:
		push_error("Castle mesh is missing its StaticBody3D CollisionShape3D.")


func _add_castle_mesh(parent: Node3D, node_name: String, mesh: Mesh, local_position: Vector3, local_scale: Vector3, yaw: float = 0.0) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = local_position
	instance.scale = local_scale
	instance.rotation.y = yaw
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)


func _build_trees() -> void:
	var tree_meshes: Array[Mesh] = []
	var tree_materials: Array[Material] = []
	for index in range(TREE_MODEL_PATHS.size()):
		var mesh := load(TREE_MODEL_PATHS[index]) as Mesh
		var texture := load(TREE_TEXTURE_PATHS[index]) as Texture2D
		if mesh == null or texture == null:
			push_error("Stylized tree resource %d failed to load." % index)
			return
		var material := StandardMaterial3D.new()
		material.albedo_texture = texture
		material.roughness = 0.9
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		tree_meshes.append(mesh)
		tree_materials.append(material)

	for item in TREE_LAYOUT:
		var model_index: int = item["model"]
		var uniform_scale: float = item["scale"]
		var mesh: Mesh = tree_meshes[model_index]
		var bounds := mesh.get_aabb()
		var body := StaticBody3D.new()
		body.name = item["name"]
		body.position = item["position"]
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)

		var visual := MeshInstance3D.new()
		visual.name = "Visual"
		visual.mesh = mesh
		visual.material_override = tree_materials[model_index]
		visual.scale = Vector3.ONE * uniform_scale
		visual.position = Vector3(
			-(bounds.position.x + bounds.size.x * 0.5) * uniform_scale,
			-bounds.position.y * uniform_scale,
			-(bounds.position.z + bounds.size.z * 0.5) * uniform_scale
		)
		body.add_child(visual)

		var collider := CollisionShape3D.new()
		collider.name = "TrunkCollision"
		var trunk := CylinderShape3D.new()
		trunk.radius = 0.28 * uniform_scale
		trunk.height = 1.45 * uniform_scale
		collider.shape = trunk
		collider.position.y = trunk.height * 0.5
		body.add_child(collider)


func _build_rocks() -> void:
	var rock_scenes: Array[PackedScene] = []
	for path in ROCK_PACK_PATHS:
		var packed := load(path) as PackedScene
		if packed == null:
			push_error("A licensed LOKIT rock model failed to load: " + path)
			return
		rock_scenes.append(packed)

	for item in ROCK_LAYOUT:
		var model_index: int = item["model"]
		var uniform_scale: float = item["scale"]
		var body := StaticBody3D.new()
		body.name = item["name"]
		body.position = item["position"]
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)

		var instance := rock_scenes[model_index].instantiate() as Node3D
		instance.name = "Visual"
		instance.scale = Vector3.ONE * uniform_scale
		var local_bounds := _combined_mesh_aabb(instance)
		instance.position.y = -local_bounds.position.y * uniform_scale
		body.add_child(instance)

		var collider := CollisionShape3D.new()
		collider.name = "RockCollision"
		var shape := BoxShape3D.new()
		shape.size = Vector3(
			maxf(0.55, local_bounds.size.x * uniform_scale),
			maxf(0.5, local_bounds.size.y * uniform_scale),
			maxf(0.55, local_bounds.size.z * uniform_scale)
		)
		collider.shape = shape
		collider.position = Vector3(
			(local_bounds.position.x + local_bounds.size.x * 0.5) * uniform_scale,
			shape.size.y * 0.5,
			(local_bounds.position.z + local_bounds.size.z * 0.5) * uniform_scale
		)
		body.add_child(collider)


func _combined_mesh_aabb(node: Node) -> AABB:
	var result := AABB()
	var found := false
	for child in node.get_children():
		if child is MeshInstance3D and child.mesh != null:
			var child_bounds: AABB = child.transform * child.mesh.get_aabb()
			if found:
				result = result.merge(child_bounds)
			else:
				result = child_bounds
				found = true
			var nested := _combined_mesh_aabb(child)
			if nested.size != Vector3.ZERO:
				result = result.merge(child.transform * nested)
		else:
			var nested_bounds := _combined_mesh_aabb(child)
			if nested_bounds.size != Vector3.ZERO:
				if found:
					result = result.merge(nested_bounds)
				else:
					result = nested_bounds
					found = true
	return result
