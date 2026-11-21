extends Node
## Local save state for chapter one. The scene owns this node; no global singleton is required.

@export var save_path: String = "user://lost_treasure_chapter_one.save"

var selected_hero: String = "Lolo"
var key_collected := false
var guard_defeated := false
var chest_opened := false
var gate_opened := false
var chapter_complete := false
var chest_reward := 0
var coins_collected := 0

func load_progress() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return
	var data = file.get_var()
	if data is not Dictionary:
		return
	selected_hero = str(data.get("selected_hero", selected_hero))
	key_collected = bool(data.get("key_collected", false))
	guard_defeated = bool(data.get("guard_defeated", false))
	chest_opened = bool(data.get("chest_opened", false))
	gate_opened = bool(data.get("gate_opened", false))
	chapter_complete = bool(data.get("chapter_complete", false))
	chest_reward = int(data.get("chest_reward", 0))
	coins_collected = int(data.get("coins_collected", 0))

func save_progress() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save chapter progress to %s" % save_path)
		return
	file.store_var({
		"selected_hero": selected_hero,
		"key_collected": key_collected,
		"guard_defeated": guard_defeated,
		"chest_opened": chest_opened,
		"gate_opened": gate_opened,
		"chapter_complete": chapter_complete,
		"chest_reward": chest_reward,
		"coins_collected": coins_collected,
	})

func reset_progress() -> void:
	selected_hero = "Lolo"
	key_collected = false
	guard_defeated = false
	chest_opened = false
	gate_opened = false
	chapter_complete = false
	chest_reward = 0
	coins_collected = 0
	save_progress()
