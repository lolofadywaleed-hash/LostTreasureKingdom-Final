extends Control

const HERO_MODEL_PATH := "res://assets/models/louay_rigged_animated.glb"
const HERO_MODEL_PATHS := {
	"Lolo": "res://assets/models/louay_rigged_animated.glb",
	"Fady": "res://assets/models/fady_rigged_animated.glb",
	"AlSayed": "res://assets/models/alsayed_rigged_animated.glb"
}
const PREVIEW_HEIGHT := 2.55

func _ready() -> void:
	var container := get_node_or_null("MarginContainer/VBoxContainer/HBoxContainer") as HBoxContainer
	if container == null:
		push_error("Character selection is missing its hero-card container.")
		return
	var characters := [
		{"name": "Lolo", "label": "لؤي", "color": Color(0.12, 0.82, 0.38)},
		{"name": "Fady", "label": "فادي", "color": Color(0.92, 0.16, 0.18)},
		{"name": "AlSayed", "label": "السيد", "color": Color(0.12, 0.42, 0.96)}
	]
	for hero in characters:
		var button := TextureButton.new()
		button.name = "Btn_" + hero["name"]
		button.ignore_texture_size = true
		button.custom_minimum_size = Vector2(250, 400)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_character_pressed.bind(hero["name"]))
		container.add_child(button)
		var preview := await _create_hero_preview(hero)
		button.texture_normal = preview.get_texture()
		button.texture_pressed = preview.get_texture()
		button.texture_hover = preview.get_texture()
		var label := Label.new()
		label.name = "HeroName"
		label.text = hero["label"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.add_theme_font_size_override("font_size", 30)
		label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		label.offset_top = -58
		label.offset_bottom = -8
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(label)

func _create_hero_preview(hero: Dictionary) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = "Preview_" + str(hero["name"])
	viewport.size = Vector2i(500, 800)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	viewport.own_world_3d = true
	add_child(viewport)
	var stage := Node3D.new()
	stage.name = "PreviewStage"
	viewport.add_child(stage)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.32, 4.4)
	camera.current = true
	stage.add_child(camera)
	camera.look_at(Vector3(0, 1.25, 0), Vector3.UP)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-32, -28, 0)
	key_light.light_energy = 1.55
	key_light.shadow_enabled = true
	stage.add_child(key_light)
	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-2.0, 2.2, 2.0)
	fill_light.light_energy = 0.7
	fill_light.omni_range = 7.0
	stage.add_child(fill_light)
	var selected_path := str(HERO_MODEL_PATHS.get(str(hero["name"]), HERO_MODEL_PATH))
	if not ResourceLoader.exists(selected_path):
		push_warning("CharacterSelect: independent model is not installed for %s; no substitute will be shown." % str(hero["name"]))
		return viewport
	var packed := load(selected_path) as PackedScene
	if packed == null:
		push_error("Could not load hero model: " + HERO_MODEL_PATH)
		return viewport
	var model := packed.instantiate() as Node3D
	if model == null:
		push_error("Hero model root is not Node3D.")
		return viewport
	stage.add_child(model)
	model.rotation_degrees.y = 180.0
	if str(hero["name"]) == "Lolo":
		_apply_hero_material(model, hero["color"])
	await get_tree().process_frame
	_fit_preview_model(model)
	return viewport

func _apply_hero_material(model: Node3D, hero_color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(hero_color.r, hero_color.g, hero_color.b, 0.16)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.68
	material.metallic = 0.08
	for item in model.find_children("*", "MeshInstance3D", true, false):
		(item as MeshInstance3D).material_overlay = material

func _fit_preview_model(model: Node3D) -> void:
	var bounds := AABB()
	var first := true
	var inverse := model.global_transform.affine_inverse()
	for item in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := item as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var item_bounds: AABB = (inverse * mesh_instance.global_transform) * mesh_instance.get_aabb()
		if first:
			bounds = item_bounds
			first = false
		else:
			bounds = bounds.merge(item_bounds)
	if first or bounds.size.y <= 0.001:
		return
	var scale_factor := PREVIEW_HEIGHT / bounds.size.y
	model.scale = Vector3.ONE * scale_factor
	model.position = Vector3(-bounds.get_center().x * scale_factor, -bounds.position.y * scale_factor, -bounds.get_center().z * scale_factor)

func _on_character_pressed(char_name: String) -> void:
	if char_name not in ["Lolo", "Fady", "AlSayed"]:
		push_error("Unknown hero selected: " + char_name)
		return
	var selected_path := str(HERO_MODEL_PATHS.get(char_name, HERO_MODEL_PATH))
	if not ResourceLoader.exists(selected_path):
		push_warning("Cannot select %s: its independent GLB model has not been added yet." % char_name)
		return
	get_tree().root.set_meta("selected_hero", char_name)
	var err := get_tree().change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		push_error("Could not open res://scenes/main.tscn (error %s)." % err)
