extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_uri := "user://lost_treasure_chapter_one.save"
	var save_path := ProjectSettings.globalize_path(save_uri)
	if FileAccess.file_exists(save_uri):
		DirAccess.remove_absolute(save_path)
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Main scene should load for retry test")
	var game := main_scene.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var state := game.get_node("ChapterOne/GameState")

	state.key_collected = true
	state.guard_defeated = true
	state.chest_opened = true
	state.chest_reward = 10
	state.coins_collected = 10
	state.save_progress()
	var health := game.get_node("Player/HealthSystem")
	health.current_health = 1
	health.take_damage(1)
	await process_frame
	health._retry()
	for _i in range(4):
		await process_frame

	var reloaded := current_scene
	assert(reloaded != null, "Retry should reload the current scene")
	var reloaded_state := reloaded.get_node("ChapterOne/GameState")
	assert(reloaded_state.key_collected and reloaded_state.guard_defeated and reloaded_state.chest_opened, "Retry must preserve chapter progress")
	var health_ui_count := reloaded.find_children("HealthDisplay", "CanvasLayer", true, false).size()
	assert(health_ui_count == 1, "Retry must leave exactly one health HUD")
	print("Retry persistence test passed: progress preserved and one health HUD remains")
	DirAccess.remove_absolute(save_path)
	quit()
