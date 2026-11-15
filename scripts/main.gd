extends Node3D

## يعيّن سكربت البطل المختار قبل تنفيذ _ready لعقدة اللاعب.

const LOUAY_SCRIPT: Script = preload("res://scripts/player/heroes/louay.gd")
const FADY_SCRIPT: Script = preload("res://scripts/player/heroes/fady.gd")
const ELSAYED_SCRIPT: Script = preload("res://scripts/player/heroes/elsayed.gd")


func _enter_tree() -> void:
	var player_node := get_node_or_null("Player") as CharacterBody3D
	if player_node == null:
		push_error("Main: لم يتم العثور على عقدة Player.")
		return

	var selected_hero := String(get_tree().root.get_meta("selected_hero", "Louay")).to_lower()
	match selected_hero:
		"louay", "lolo":
			player_node.set_script(LOUAY_SCRIPT)
		"fady":
			player_node.set_script(FADY_SCRIPT)
		"elsayed", "alsayed":
			player_node.set_script(ELSAYED_SCRIPT)
		_:
			push_warning("Main: البطل غير معروف؛ سيتم اختيار لؤي.")
			player_node.set_script(LOUAY_SCRIPT)
