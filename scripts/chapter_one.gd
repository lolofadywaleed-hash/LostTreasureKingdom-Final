extends Node3D
## Chapter one objective flow: key -> guardian -> chest -> castle gate.

const CHAPTER_ONE_CINEMATIC := preload("res://scenes/chapter_one_cinematic.tscn")

@onready var state: Node = $GameState
@onready var player: CharacterBody3D = get_parent().get_node("Player")
@onready var key: Area3D = get_parent().get_node("Collectibles/ForestKey")
@onready var enemy_manager: Node = get_parent().get_node("EnemyManager")
@onready var chest: Node = get_parent().get_node("Collectibles/TreasureChest")
@onready var gate: Node = get_parent().get_node("Castle/GateController")

var _objective_label: Label
var _completion_layer: CanvasLayer
var _objective_text := ""
var _objective_layer: CanvasLayer
var _cinematic: Node3D
var _hud: CanvasLayer
var _hud_was_visible := true
var _objective_layer_was_visible := true
var _player_physics_was_enabled := true
var _player_input_was_enabled := true
var _player_unhandled_input_was_enabled := true

func _ready() -> void:
	_build_objective_ui()
	state.load_progress()
	if key != null and key.has_signal("collected") and not key.collected.is_connected(_on_key_collected):
		key.collected.connect(_on_key_collected)
	if enemy_manager.has_signal("enemy_defeated") and not enemy_manager.enemy_defeated.is_connected(_on_guard_defeated):
		enemy_manager.enemy_defeated.connect(_on_guard_defeated)
	if chest.has_signal("opened") and not chest.opened.is_connected(_on_chest_opened):
		chest.opened.connect(_on_chest_opened)
	if gate.has_signal("opened") and not gate.opened.is_connected(_on_gate_opened):
		gate.opened.connect(_on_gate_opened)
	if player.has_signal("coins_changed") and not player.coins_changed.is_connected(_on_coins_changed):
		player.coins_changed.connect(_on_coins_changed)
	player.coins_collected = state.coins_collected
	_restore_progress()

func _restore_progress() -> void:
	if state.key_collected and is_instance_valid(key):
		key.queue_free()
	if state.guard_defeated:
		chest.set_unlocked(true)
	else:
		enemy_manager.activate_guard()
	if state.chest_opened:
		chest.restore_opened()
		gate.set_unlocked(true)
	if state.gate_opened or state.chapter_complete:
		gate.restore_opened()
		_show_completion()
	_update_objective()

func _on_key_collected(_key_id: String) -> void:
	state.key_collected = true
	state.save_progress()
	_update_objective()
	enemy_manager.activate_guard()

func _on_guard_defeated(_enemy: Node3D) -> void:
	state.guard_defeated = true
	state.save_progress()
	chest.set_unlocked(true)
	_update_objective()

func _on_chest_opened(reward: int) -> void:
	state.chest_opened = true
	state.chest_reward = reward
	state.save_progress()
	gate.set_unlocked(true)
	_update_objective()

func _on_gate_opened() -> void:
	state.gate_opened = true
	state.chapter_complete = true
	state.save_progress()
	_update_objective()
	_start_completion_cinematic()

func _start_completion_cinematic() -> void:
	if is_instance_valid(_cinematic):
		return
	_cinematic = CHAPTER_ONE_CINEMATIC.instantiate() as Node3D
	if _cinematic == null or not _cinematic.has_signal("cinematic_finished"):
		_show_completion()
		return
	_cinematic.connect("cinematic_finished", _on_cinematic_finished, CONNECT_ONE_SHOT)
	var parent_scene := get_parent()
	_hud = parent_scene.get_node_or_null("MobileHUD") as CanvasLayer
	if is_instance_valid(_hud):
		_hud_was_visible = _hud.visible
		_hud.visible = false
	if is_instance_valid(_objective_layer):
		_objective_layer_was_visible = _objective_layer.visible
		_objective_layer.visible = false
	_player_physics_was_enabled = player.is_physics_processing()
	_player_input_was_enabled = player.is_processing_input()
	_player_unhandled_input_was_enabled = player.is_processing_unhandled_input()
	player.set_physics_process(false)
	player.set_process_input(false)
	player.set_process_unhandled_input(false)
	parent_scene.add_child(_cinematic)

func _on_cinematic_finished(_skipped: bool) -> void:
	if is_instance_valid(_cinematic):
		_cinematic.queue_free()
	_cinematic = null
	if is_instance_valid(_hud):
		_hud.visible = _hud_was_visible
	if is_instance_valid(_objective_layer):
		_objective_layer.visible = _objective_layer_was_visible
	if is_instance_valid(player):
		player.set_physics_process(_player_physics_was_enabled)
		player.set_process_input(_player_input_was_enabled)
		player.set_process_unhandled_input(_player_unhandled_input_was_enabled)
		call_deferred("_restore_gameplay_camera")
	_show_completion()

func _restore_gameplay_camera() -> void:
	if not is_instance_valid(player):
		return
	var gameplay_camera := player.get_node_or_null("CameraPivot/SpringArm3D/Camera3D") as Camera3D
	if gameplay_camera != null:
		gameplay_camera.make_current()


func _on_coins_changed(total: int) -> void:
	state.coins_collected = total
	state.save_progress()

func _update_objective() -> void:
	if state.chapter_complete:
		_objective_text = "Chapter complete"
	elif not state.key_collected:
		_objective_text = "Objective: Find the forest key"
	elif not state.guard_defeated:
		_objective_text = "Objective: Defeat the forest guardian"
	elif not state.chest_opened:
		_objective_text = "Objective: Open the treasure chest"
	else:
		_objective_text = "Objective: Enter the castle gate"
	if is_instance_valid(_objective_label):
		_objective_label.text = _objective_text

func _build_objective_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ChapterObjectiveUI"
	layer.layer = 15
	add_child(layer)
	_objective_layer = layer
	var panel := PanelContainer.new()
	panel.position = Vector2(220, 24)
	panel.custom_minimum_size = Vector2(560, 54)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	_objective_label = Label.new()
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_objective_label.add_theme_font_size_override("font_size", 22)
	panel.add_child(_objective_label)

func _show_completion() -> void:
	if is_instance_valid(_completion_layer):
		return
	_completion_layer = CanvasLayer.new()
	_completion_layer.name = "ChapterCompleteUI"
	_completion_layer.layer = 30
	add_child(_completion_layer)
	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.05, 0.03, 0.84)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_completion_layer.add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	center.add_child(column)
	var title := Label.new()
	title.text = "CHAPTER ONE COMPLETE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	column.add_child(title)
	var reward := Label.new()
	reward.text = "The forest key, guardian, treasure, and castle gate are complete."
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(reward)
