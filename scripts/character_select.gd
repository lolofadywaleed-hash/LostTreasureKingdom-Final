extends Control

## يعرض أبطال اللعبة ويخزن اختيار اللاعب قبل فتح مشهد الاختبار.

@onready var hero_container: HBoxContainer = get_node_or_null("MarginContainer/VBoxContainer/HBoxContainer") as HBoxContainer


func _ready() -> void:
	if hero_container == null:
		push_error("CharacterSelect: لم يتم العثور على حاوية الأبطال.")
		return

	var characters: Array[Dictionary] = [
		{"name": "Lolo", "texture_path": "res://assets/characters/lolo.png"},
		{"name": "AlSayed", "texture_path": "res://assets/characters/alsayed.png"},
		{"name": "Fady", "texture_path": "res://assets/characters/fady.png"}
	]

	for character_data in characters:
		var texture_button := TextureButton.new()
		var hero_id: String = character_data["name"]
		var texture_path: String = character_data["texture_path"]
		var hero_texture := load(texture_path) as Texture2D
		if hero_texture == null:
			push_warning("CharacterSelect: تعذر تحميل صورة %s" % texture_path)
			continue
		texture_button.name = "Btn_" + hero_id
		texture_button.texture_normal = hero_texture
		texture_button.ignore_texture_size = true
		texture_button.custom_minimum_size = Vector2(250.0, 400.0)
		texture_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texture_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		texture_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
		texture_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		texture_button.pressed.connect(_on_hero_pressed.bind(hero_id))
		hero_container.add_child(texture_button)


func _on_hero_pressed(hero_id: String) -> void:
	if hero_id not in ["Lolo", "AlSayed", "Fady"]:
		push_error("CharacterSelect: بطل غير معروف: " + hero_id)
		return
	get_tree().root.set_meta("selected_hero", hero_id)
	var scene_error := get_tree().change_scene_to_file("res://scenes/main.tscn")
	if scene_error != OK:
		push_error("CharacterSelect: تعذر فتح main.tscn. Error: %s" % scene_error)
