extends Control

func _ready() -> void:
	var container = $HBoxContainer
	if not container:
		return

	var characters = [
		{"name": "Lolo", "path": "res://assets/characters/lolo.png"},
		{"name": "AlSayed", "path": "res://assets/characters/alsayed.png"},
		{"name": "Fady", "path": "res://assets/characters/fady.png"}
	]

	for char_data in characters:
		var btn = TextureButton.new()
		btn.name = "Btn_" + char_data["name"]

		var texture = load(char_data["path"])
		if texture:
			btn.texture_normal = texture

		btn.ignore_texture_size = true
		btn.custom_minimum_size = Vector2(200, 300)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		btn.pressed.connect(_on_character_pressed.bind(char_data["name"]))
		container.add_child(btn)

func _on_character_pressed(char_name: String) -> void:
	var main_scene_path = "res://scenes/main.tscn"
	var err = get_tree().change_scene_to_file(main_scene_path)
	if err != OK:
		print("Error: main.tscn not found!")
