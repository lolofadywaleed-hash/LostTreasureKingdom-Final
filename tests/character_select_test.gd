extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var select_scene: PackedScene = load("res://scenes/character_select.tscn")
	assert(select_scene != null)
	var select: Control = select_scene.instantiate()
	root.add_child(select)
	current_scene = select
	await process_frame
	for button_name in ["Btn_Lolo", "Btn_AlSayed", "Btn_Fady"]:
		var button := select.get_node_or_null("HBoxContainer/" + button_name) as TextureButton
		assert(button != null, "Missing button " + button_name)
		assert(button.texture_normal != null, "Missing image texture for " + button_name)
	select.get_node("HBoxContainer/Btn_Lolo").pressed.emit()
	await process_frame
	assert(current_scene != null)
	assert(current_scene.scene_file_path == "res://scenes/main.tscn", "Character choice should switch to main.tscn")
	print("Character selection test passed")
	quit()
