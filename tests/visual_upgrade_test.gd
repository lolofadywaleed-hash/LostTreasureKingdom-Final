extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	assert(main_scene != null, "Main scene should load")
	var game := main_scene.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame

	var visuals := game.get_node("EnvironmentVisuals")
	assert(visuals.get_child_count() >= 14, "Environment should contain real tree/rock models")
	var castle_collision := game.get_node("Castle/CastleCollision/CollisionShape3D") as CollisionShape3D
	assert(castle_collision.shape is BoxShape3D, "Castle collision must remain present")
	var tree_collision_count := 0
	var rock_collision_count := 0
	for body in visuals.get_children():
		if body is StaticBody3D:
			var collision := body.get_node_or_null("TrunkCollision") as CollisionShape3D
			if collision != null and collision.shape != null:
				tree_collision_count += 1
			collision = body.get_node_or_null("RockCollision") as CollisionShape3D
			if collision != null and collision.shape is BoxShape3D:
				rock_collision_count += 1
	assert(tree_collision_count >= 8, "Trees should have trunk collision")
	assert(rock_collision_count >= 4, "Rocks should have collision")
	var first_tree := visuals.get_node("TreeWestNear/Visual") as MeshInstance3D
	assert(first_tree.material_override is StandardMaterial3D, "Tree should use a mobile-friendly material override")
	assert(first_tree.material_override.albedo_texture != null, "Tree should retain its detailed atlas texture")

	var enemy := game.get_node("Enemy") as CharacterBody3D
	var goblin := enemy.get_node_or_null("Visual/GoblinArcher") as Node3D
	assert(goblin != null, "Enemy should use the imported Goblin Archer model")
	assert(not goblin.find_children("*", "MeshInstance3D", true, false).is_empty(), "Goblin should contain visible meshes")

	var hud := game.get_node("MobileHUD")
	for node_path in ["Root/AttackButton/Icon", "Root/JumpButton/Icon", "Root/SkillButton/Icon"]:
		var icon := hud.get_node(node_path) as TextureRect
		assert(icon.texture != null, "HUD icon texture must load: " + node_path)

	var audio := game.get_node("AudioManager")
	for node_path in ["Music", "AttackSFX", "CoinSFX", "SkillSFX"]:
		var player := audio.get_node(node_path) as AudioStreamPlayer
		assert(player.stream != null, "Audio stream must load: " + node_path)
	assert(audio.get_node("Music").playing, "Fantasy BGM should start with the scene")
	var player := game.get_node("Player") as CharacterBody3D
	player.attacked.emit()
	player.skill_used.emit()
	assert(audio.get_node("AttackSFX").playing, "Attack signal should trigger its SFX")
	assert(audio.get_node("SkillSFX").playing, "Skill signal should trigger its SFX")

	var coin := game.get_node("Collectibles/Coin1") as Area3D
	var initial_coins: int = player.coins_collected
	coin._on_body_entered(player)
	assert(player.coins_collected == initial_coins + 1, "Coin pickup should preserve player currency logic")
	assert(audio.get_node("CoinSFX").playing, "Coin collection should trigger its SFX")
	await physics_frame
	assert(not coin.monitoring, "Collected coin should stop detecting bodies immediately")
	await create_timer(0.22).timeout
	assert(not is_instance_valid(coin), "Picked-up coin should animate out and be removed")

	print("Visual upgrade test passed: environment meshes/collisions, castle collision, Goblin, HUD icons, audio, coin pickup")
	quit()
