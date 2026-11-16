extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var select_scene: PackedScene = load("res://scenes/character_select.tscn")
	assert(select_scene != null, "Character selection scene should load")
	var select := select_scene.instantiate() as Control
	root.add_child(select)
	current_scene = select
	for _frame in range(5):
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

	var preview_colors := {
		"Preview_Lolo": Color(0.12, 0.82, 0.38),
		"Preview_Fady": Color(0.92, 0.16, 0.18),
		"Preview_AlSayed": Color(0.12, 0.42, 0.96)
	}
	for preview_name in preview_colors:
		var preview := select.get_node_or_null(preview_name) as SubViewport
		assert(preview != null, "Missing 3D preview " + preview_name)
		var preview_meshes := preview.find_children("*", "MeshInstance3D", true, false)
		assert(not preview_meshes.is_empty(), "Preview must contain the Louay model")
		var preview_material := (preview_meshes[0] as MeshInstance3D).material_overlay as StandardMaterial3D
		var expected_preview: Color = preview_colors[preview_name]
		assert(preview_material != null and preview_material.albedo_color.is_equal_approx(Color(expected_preview.r, expected_preview.g, expected_preview.b, 0.16)), "Hero preview tint has the wrong color: " + preview_name)

	hero_row.get_node("Btn_Lolo").pressed.emit()
	await process_frame
	assert(current_scene != null)
	assert(root.get_meta("selected_hero", "") == "Lolo", "Selected hero should persist when changing scenes")
	assert(current_scene.scene_file_path == "res://scenes/main.tscn", "Hero choice should open the 3D scene")

	var enemy := current_scene.get_node_or_null("Enemy") as CharacterBody3D
	assert(enemy != null, "Main scene needs an enemy CharacterBody3D")
	assert(enemy.is_in_group("enemies"), "Enemy should register in the enemies group")
	var left_horn := enemy.get_node_or_null("Visual/LeftHorn") as MeshInstance3D
	var right_horn := enemy.get_node_or_null("Visual/RightHorn") as MeshInstance3D
	assert(left_horn != null and left_horn.mesh is CylinderMesh, "Left enemy horn must use CylinderMesh")
	assert(right_horn != null and right_horn.mesh is CylinderMesh, "Right enemy horn must use CylinderMesh")
	assert(is_zero_approx((left_horn.mesh as CylinderMesh).top_radius), "Enemy horn tip radius must be zero")
	var enemy_health_before := int(enemy.get("_health"))
	enemy.call("take_damage", 1)
	assert(int(enemy.get("_health")) == enemy_health_before - 1, "Enemy should lose health when damaged")

	var player := current_scene.get_node("Player") as CharacterBody3D
	assert(player != null, "Main scene needs a CharacterBody3D player")
	assert(player.selected_hero == "Lolo", "Player should receive the selected hero")
	var weapon_manager := player.get_node_or_null("WeaponManager")
	assert(weapon_manager != null, "Player should have the three-slot WeaponManager")
	var attack_system := player.get_node("AttackSystem")
	var weapon_hud := current_scene.get_node("MobileHUD")
	assert(weapon_hud.get_node_or_null("Root/Weapon1Button") != null and weapon_hud.get_node_or_null("Root/Weapon2Button") != null and weapon_hud.get_node_or_null("Root/Weapon3Button") != null, "HUD should expose all three weapon slots")
	weapon_manager.call("select_weapon", 1)
	assert(int(weapon_manager.get("current_weapon_index")) == 1, "Weapon slot 2 should be selectable")
	assert(int(attack_system.get("damage")) == 2, "Secondary weapon should update attack damage")
	weapon_manager.call("select_weapon", 2)
	assert(float(attack_system.get("attack_range")) >= 8.0, "Ranged weapon should increase attack reach")
	assert(weapon_hud.get_node("Root/Weapon3Button").tooltip_text == "Phantom Bow", "HUD should display the equipped ranged weapon")
	weapon_manager.call("select_weapon", 0)
	var ability_system := player.get_node_or_null("AbilitySystem")
	assert(ability_system != null, "Player should have the character-specific AbilitySystem")
	var health_system := player.get_node("HealthSystem")
	var ability_hud := current_scene.get_node("MobileHUD")
	var ability_label := ability_hud.get_node("Root/SkillButton/Label") as Label
	health_system.set("_invulnerable", false)
	var health_before_dash := int(health_system.get("current_health"))
	player.skill_used.emit()
	assert(bool(player.get("is_dodging")), "Louay's skill should start the shadow dash")
	assert(ability_label.text != "⚡", "Skill HUD should show the cooldown after activation")
	health_system.call("take_damage", 1)
	assert(int(health_system.get("current_health")) == health_before_dash, "Shadow dash should avoid incoming damage")
	for _dash_frame in range(20):
		await physics_frame
	assert(not bool(player.get("is_dodging")), "Shadow dash should end after its short duration")

	enemy.global_position = player.global_position + Vector3(0.0, 0.0, -2.0)
	ability_system.set("_cooldown_remaining", 0.0)
	player.set("selected_hero", "Fady")
	var enemy_health_before_blast := int(enemy.get("_health"))
	player.skill_used.emit()
	assert(int(enemy.get("_health")) == enemy_health_before_blast - 2, "Fady's fire blast should damage nearby enemies in the enemies group")

	ability_system.set("_cooldown_remaining", 0.0)
	player.set("selected_hero", "AlSayed")
	health_system.set("_invulnerable", false)
	var health_before_shield := int(health_system.get("current_health"))
	player.skill_used.emit()
	assert(bool(health_system.get("_shield_active")), "AlSayed's skill should activate the energy shield")
	health_system.call("take_damage", 1)
	assert(int(health_system.get("current_health")) == health_before_shield, "Energy shield should absorb incoming damage")
	player.set("selected_hero", "Lolo")
	var knight := player.get_node("KnightVisual")
	var hero_meshes := knight.get_child(0).find_children("*", "MeshInstance3D", true, false)
	assert(not hero_meshes.is_empty(), "Selected hero model should contain visible meshes")
	var hero_material := (hero_meshes[0] as MeshInstance3D).material_overlay as StandardMaterial3D
	assert(hero_material != null and hero_material.albedo_color.is_equal_approx(Color(0.12, 0.82, 0.38, 0.16)), "Lolo must use the green texture-preserving tint")
	root.set_meta("selected_hero", "Fady")
	knight.call("_apply_selected_hero_material")
	hero_material = (hero_meshes[0] as MeshInstance3D).material_overlay as StandardMaterial3D
	assert(hero_material.albedo_color.is_equal_approx(Color(0.92, 0.16, 0.18, 0.16)), "Fady must use the red material override")
	root.set_meta("selected_hero", "AlSayed")
	knight.call("_apply_selected_hero_material")
	hero_material = (hero_meshes[0] as MeshInstance3D).material_override as StandardMaterial3D
	assert(hero_material.albedo_color.is_equal_approx(Color(0.12, 0.42, 0.96, 0.16)), "AlSayed must use the blue material override")
	root.set_meta("selected_hero", "Lolo")
	knight.call("_apply_selected_hero_material")
	hero_material = (hero_meshes[0] as MeshInstance3D).material_override as StandardMaterial3D
	assert(hero_material.albedo_color.is_equal_approx(Color(0.12, 0.82, 0.38, 0.16)), "Lolo must remain green after switching back")
	assert(player.get_node("CollisionShape3D").shape is CapsuleShape3D, "Player must use a capsule collision shape")
	assert(player.get_node_or_null("Visual") == null, "Old cylinder visual should be removed")
	assert(knight.get_child_count() > 0, "Knight model should be instanced under KnightVisual")
	var knight_model := knight.get_child(0)
	assert(not knight_model.find_children("*", "Skeleton3D", true, false).is_empty(), "Knight model needs a skeleton")
	var knight_players := knight_model.find_children("*", "AnimationPlayer", true, false)
	assert(not knight_players.is_empty(), "Knight model needs an AnimationPlayer")
	assert(knight_players[0].has_animation("Idle") and knight_players[0].has_animation("Walk"), "Knight model should provide Idle and Walk")
	assert(player.get_node("CameraPivot") is Node3D, "Player should expose a CameraPivot")
	assert(player.get_node("CameraPivot/SpringArm3D/Camera3D").current, "Third-person camera should be active")
	assert(current_scene.get_node("WorldEnvironment").environment.sky.sky_material is ProceduralSkyMaterial)
	assert(current_scene.get_node("Path") is MeshInstance3D and current_scene.get_node("Path").mesh is BoxMesh, "Road should use a regular mesh, not CSG")
	assert(current_scene.get_node("Castle/CastleKeep") is CSGBox3D)
	assert(not current_scene.get_node("Castle/CastleKeep").visible, "Old placeholder castle keep should be hidden after visual replacement")
	var castle_upgrade := current_scene.get_node_or_null("Castle/VisualUpgrade")
	assert(castle_upgrade != null, "Castle should include the detailed visual upgrade")
	assert(castle_upgrade.get_child_count() >= 35, "Detailed castle should contain towers, battlements, gate and facade details")
	var floor_mesh := current_scene.get_node("GrassFloor") as MeshInstance3D
	assert(floor_mesh.mesh is PlaneMesh and (floor_mesh.mesh as PlaneMesh).size.x >= 200.0 and (floor_mesh.mesh as PlaneMesh).size.y >= 160.0, "Starter region should use a large mesh floor")
	assert(current_scene.get_node_or_null("FloorCollision/CollisionShape3D") != null, "Mesh floor must retain a separate collision body")
	var visual_world := current_scene.get_node_or_null("VisualWorld")
	assert(visual_world != null, "Main scene should include the procedural visual world")
	var forest := visual_world.get_node_or_null("ForestCanopies") as MultiMeshInstance3D
	var rocks := visual_world.get_node_or_null("NaturalRockClusters") as MultiMeshInstance3D
	var crystals := visual_world.get_node_or_null("AncientCrystalGrove") as MultiMeshInstance3D
	assert(forest != null and forest.multimesh.instance_count >= 100, "Procedural forest should contain at least 100 tree crowns")
	assert(rocks != null and rocks.multimesh.instance_count >= 30, "Procedural scenery should contain natural rock clusters")
	assert(crystals != null and crystals.multimesh.instance_count >= 15, "Procedural scenery should contain glowing crystal landmarks")
	assert(visual_world.find_children("HorizonHill_*", "MeshInstance3D", true, false).size() >= 12, "The world should include distant landscape silhouettes")
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
