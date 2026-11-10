extends Control

func _ready() -> void:
	var container := get_node_or_null("MarginContainer/VBoxContainer/HBoxContainer") as HBoxContainer
	if container == null:
		push_error("Character selection is missing its hero-card container.")
		return

	var characters := [
		{"name": "Lolo", "path": "res://assets/characters/lolo.png"},
		{"name": "AlSayed", "path": "res://assets/characters/alsayed.png"},
		{"name": "Fady", "path": "res://assets/characters/fady.png"}
	]

	for char_data in characters:
		var button := TextureButton.new()
		button.name = "Btn_" + char_data["name"]
		button.texture_normal = load(char_data["path"])
		button.ignore_texture_size = true
		button.custom_minimum_size = Vector2(250, 400)
		button.size_flags_horizontal = 3
		button.size_flags_vertical = 3
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_character_pressed.bind(char_data["name"]))
		container.add_child(button)

func _on_character_pressed(_char_name: String) -> void:
	var err := get_tree().change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		push_error("Could not open res://scenes/main.tscn (error %s)." % err)
