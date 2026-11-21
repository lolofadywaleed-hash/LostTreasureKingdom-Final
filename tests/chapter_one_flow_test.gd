extends SceneTree

const GAME_STATE_SCRIPT = preload("res://scripts/game_state.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var test_save_uri := "user://lost_treasure_chapter_one.save"
	var test_save_path := ProjectSettings.globalize_path(test_save_uri)
	if FileAccess.file_exists(test_save_uri):
		DirAccess.remove_absolute(test_save_path)
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Main scene should load")
	var game := main_scene.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame

	var chapter := game.get_node("ChapterOne")
	var state := chapter.get_node("GameState")
	state.reset_progress()
	chapter._restore_progress()
	var chest := game.get_node("Collectibles/TreasureChest")
	var gate := game.get_node("Castle/GateController")
	assert(not state.key_collected and not state.guard_defeated, "Fresh chapter should have no progress")
	assert(not chest.can_open, "Chest must be locked before the guardian is defeated")
	assert(not gate.is_open(), "Gate must be closed at chapter start")
	gate.open_gate()
	assert(not gate.is_open(), "Gate must reject opening before chapter requirements")

	# Attempting to attack near the chest cannot bypass its lock.
	var player := game.get_node("Player")
	player.global_position = chest.global_position
	await physics_frame
	player.attacked.emit()
	assert(not chest.is_open(), "Chest must reject interaction before guardian defeat")

	# Collect the actual key and verify the guardian appears.
	var key := game.get_node("Collectibles/ForestKey")
	key._on_body_entered(player)
	await process_frame
	assert(state.key_collected, "Key collection must update chapter state")
	var enemy := game.get_node("Enemy")
	assert(enemy.encounter_active, "Guardian must activate after key collection")

	# Defeat the guardian, then open the chest for a real coin reward.
	enemy._health = 1
	enemy.take_damage(1)
	await process_frame
	assert(state.guard_defeated, "Guardian defeat must update chapter state")
	assert(chest.can_open, "Chest must unlock after guardian defeat")
	var before_coins: int = player.coins_collected
	chest._player = player
	chest._open()
	assert(chest.is_open(), "Chest should open after it is unlocked")
	assert(player.coins_collected == before_coins + chest.reward_coins, "Chest must grant its reward")
	assert(state.chest_opened, "Opening chest must update chapter state")
	assert(gate.is_open(), "Gate should open only after the chest requirement is complete")
	await process_frame
	assert(gate.is_open(), "Gate should open after chapter requirements")

	state.save_progress()
	var restored: Node = GAME_STATE_SCRIPT.new()
	restored.save_path = state.save_path
	restored.load_progress()
	assert(restored.key_collected and restored.guard_defeated and restored.chest_opened, "Saved progress must survive reload")
	print("Chapter one flow test passed: key lock, guardian, chest reward, gate, save")
	quit()
