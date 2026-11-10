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
	var hud := current_scene.get_node("MobileHUD")
	assert(hud != null, "Main scene should instantiate the mobile HUD")
	for action_name in ["attack", "jump", "skill"]:
		assert(InputMap.has_action(action_name), "HUD action should be registered: " + action_name)

	var attack_center: Vector2 = hud.attack_button.get_global_rect().get_center()
	hud._on_touch_pressed(20, attack_center)
	assert(Input.is_action_pressed("attack"), "Touching Attack should press its input action")
	hud._on_touch_released(20)
	assert(not Input.is_action_pressed("attack"), "Releasing Attack should release its input action")
	var skill_center: Vector2 = hud.skill_button.get_global_rect().get_center()
	hud._on_touch_pressed(22, skill_center)
	assert(Input.is_action_pressed("skill"), "Touching Skill should press its input action")
	hud._on_touch_released(22)
	assert(not Input.is_action_pressed("skill"), "Releasing Skill should release its input action")

	hud._on_touch_pressed(21, Vector2(100, 300))
	assert(hud.joystick_base.visible, "Joystick should appear at the initiating touch location")
	hud._update_joystick(Vector2(160, 300))
	assert(Input.get_action_strength("move_right") > 0.5, "Dragging joystick right should press move_right")
	hud._on_touch_released(21)
	assert(not hud.joystick_base.visible, "Joystick should hide when touch ends")
	assert(not Input.is_action_pressed("move_right"), "Joystick release should clear movement input")

	assert(player.has_signal("attacked"), "Player should expose an attacked signal")
	assert(player.has_signal("skill_used"), "Player should expose a skill-used signal")

	for _frame in range(30):
		await physics_frame
	assert(player.is_on_floor(), "Player should stand on the floor collision")
	var initial_z := player.global_position.z
	Input.action_press("move_forward")
	for _frame in range(20):
		await physics_frame
	Input.action_release("move_forward")
	assert(player.global_position.z < initial_z - 0.2, "Keyboard forward input should move the player down the path")

	player.global_position = Vector3(0, -21, 12)
	await physics_frame
	assert(player.global_position.y > player.kill_height, "Falling below the kill plane should respawn the player")
	assert(absf(player.global_position.z - 12.0) < 0.1, "Respawn should return the player to the start")

	print("HUD, movement, and fall recovery test passed")
	quit()
