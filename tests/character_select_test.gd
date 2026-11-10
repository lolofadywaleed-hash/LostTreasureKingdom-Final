extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var select_scene: PackedScene = load("res://scenes/character_select.tscn")
	assert(select_scene != null, "Character selection scene should load")
	var select := select_scene.instantiate() as Control
	root.add_child(select)
	current_scene = select
	await process_frame

	var hero_row := select.get_node_or_null("MarginContainer/VBoxContainer/HBoxContainer") as HBoxContainer
	assert(hero_row != null, "Hero row should exist inside the responsive containers")
	assert(select.get_node("MarginContainer/VBoxContainer/Title").text == "Choose Your Hero")
	for button_name in ["Btn_Lolo", "Btn_AlSayed", "Btn_Fady"]:
		var button := hero_row.get_node_or_null(button_name) as TextureButton
		assert(button != null, "Missing button " + button_name)
		assert(button.texture_normal != null, "Missing image texture for " + button_name)
		assert(button.stretch_mode == TextureButton.STRETCH_KEEP_ASPECT_COVERED)
		assert(button.size_flags_horizontal == 3 and button.size_flags_vertical == 3)

	hero_row.get_node("Btn_Lolo").pressed.emit()
	await process_frame
	assert(current_scene != null)
	assert(current_scene.scene_file_path == "res://scenes/main.tscn", "Hero choice should open the 3D scene")

	var player := current_scene.get_node("Player") as CharacterBody3D
	assert(player != null, "Main scene needs a CharacterBody3D player")
	assert(player.get_node("CollisionShape3D").shape is CapsuleShape3D, "Player must use a capsule collision shape")
	assert(player.get_node("Visual") is CSGCylinder3D, "Player should have a visible cylinder mesh")
	assert(player.get_node("SpringArm3D/Camera3D").current, "Third-person camera should be active")
	assert(current_scene.get_node("WorldEnvironment").environment.sky.sky_material is ProceduralSkyMaterial)
	assert(current_scene.get_node("Path") is CSGBox3D)
	assert(current_scene.get_node("Castle/CastleKeep") is CSGBox3D)

	for _frame in range(30):
		await physics_frame
	assert(player.is_on_floor(), "Player should stand on the floor collision")
	var initial_z := player.global_position.z
	Input.action_press("move_forward")
	for _frame in range(20):
		await physics_frame
	Input.action_release("move_forward")
	assert(player.global_position.z < initial_z - 0.2, "Keyboard forward input should move the player down the path")

	print("Phase 1 gameplay smoke test passed")
	quit()
