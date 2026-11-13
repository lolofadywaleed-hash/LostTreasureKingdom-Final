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
	assert(player.get_node_or_null("Visual") == null, "Old cylinder visual should be removed")
	var knight := player.get_node("KnightVisual")
	assert(knight.get_child_count() > 0, "Knight model should be instanced under KnightVisual")
	var knight_model := knight.get_child(0)
	assert(not knight_model.find_children("*", "Skeleton3D", true, false).is_empty(), "Knight model needs a skeleton")
	var knight_players := knight_model.find_children("*", "AnimationPlayer", true, false)
	assert(not knight_players.is_empty(), "Knight model needs an AnimationPlayer")
	assert(knight_players[0].has_animation("Idle") and knight_players[0].has_animation("Walk"), "Knight model should provide Idle and Walk")
	assert(player.get_node("CameraPivot") is Node3D, "Player should expose a CameraPivot")
	assert(player.get_node("CameraPivot/SpringArm3D/Camera3D").current, "Third-person camera should be active")
	assert(current_scene.get_node("WorldEnvironment").environment.sky.sky_material is ProceduralSkyMaterial)
	assert(current_scene.get_node("Path") is CSGBox3D)
	assert(current_scene.get_node("Castle/CastleKeep") is CSGBox3D)
	var hud := current_scene.get_node("MobileHUD")
	assert(hud != null, "Main scene should instantiate the mobile HUD")
	for action_name in ["move_left", "move_right", "move_up", "move_down", "jump", "attack", "skill"]:
		assert(InputMap.has_action(action_name), "HUD action should be registered: " + action_name)
	assert(hud.jump_button is BaseButton, "Jump HUD control should be a real button")
	assert(hud.jump_button.is_connected("pressed", Callable(hud, "_on_jump_button_pressed")), "Jump button pressed signal should be connected to HUD")
	hud.jump_button.pressed.emit()
	assert(player.jump_requested, "HUD pressed signal should request a player jump")
	player.jump_requested = false

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
	var knight_animation_players := player.get_node("KnightVisual").get_child(0).find_children("*", "AnimationPlayer", true, false)
	assert(not knight_animation_players.is_empty(), "Knight model should expose an AnimationPlayer")
	var knight_anim := knight_animation_players[0] as AnimationPlayer
	assert(knight_anim.current_animation == "Idle", "Knight should play Idle while standing")
	var initial_z := player.global_position.z
	Input.action_press("move_up")
	for _frame in range(20):
		await physics_frame
	assert(knight_anim.current_animation == "Walk", "Knight should play Walk while moving")
	Input.action_release("move_up")
	assert(player.global_position.z < initial_z - 0.2, "Keyboard forward input should move the player down the path")
	for _frame in range(4):
		await physics_frame
	assert(knight_anim.current_animation == "Idle", "Knight should return to Idle after movement")
	var jump_start_y := player.global_position.y
	Input.action_press("jump")
	for _frame in range(4):
		await physics_frame
	Input.action_release("jump")
	assert(player.global_position.y > jump_start_y + 0.05, "Player should jump with the existing physics")
	for _frame in range(50):
		await physics_frame
	assert(player.is_on_floor(), "Player should land after jumping")

	player.global_position = Vector3(0, -21, 12)
	await physics_frame
	assert(player.global_position.y > player.kill_height, "Falling below the kill plane should respawn the player")
	assert(absf(player.global_position.z - 12.0) < 0.1, "Respawn should return the player to the start")

	print("HUD, movement, and fall recovery test passed")
	quit()
