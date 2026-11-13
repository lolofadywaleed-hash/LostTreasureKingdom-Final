extends Node
## Three-heart player health component. Attach as a child of Player.

signal health_changed(current: int, maximum: int)
signal died

@export_range(1, 10, 1) var max_health: int = 3
@export var damage_invulnerability: float = 0.8

var current_health: int
var _invulnerable := false
var _player: CharacterBody3D
var _hud_layer: CanvasLayer
var _hearts_label: Label


func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	current_health = max_health
	_build_health_display()
	_update_display()
	health_changed.emit(current_health, max_health)


func take_damage(amount: int = 1) -> void:
	if current_health <= 0 or _invulnerable or amount <= 0:
		return
	current_health = maxi(0, current_health - amount)
	_update_display()
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		_die()
	else:
		_invulnerable = true
		await get_tree().create_timer(damage_invulnerability).timeout
		_invulnerable = false


func heal(amount: int = 1) -> void:
	if current_health <= 0 or amount <= 0:
		return
	current_health = mini(max_health, current_health + amount)
	_update_display()
	health_changed.emit(current_health, max_health)


func _build_health_display() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "HealthDisplay"
	_hud_layer.layer = 20
	get_tree().root.add_child.call_deferred(_hud_layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	panel.custom_minimum_size = Vector2(170, 52)
	_hud_layer.add_child(panel)
	_hearts_label = Label.new()
	_hearts_label.add_theme_font_size_override("font_size", 30)
	_hearts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_hearts_label)


func _update_display() -> void:
	if not is_instance_valid(_hearts_label):
		return
	var hearts := ""
	for i in range(max_health):
		hearts += "♥ " if i < current_health else "♡ "
	_hearts_label.text = hearts.strip_edges()


func _die() -> void:
	if is_instance_valid(_player):
		_player.velocity = Vector3.ZERO
		_player.set_physics_process(false)
	died.emit()
	var overlay := ColorRect.new()
	overlay.name = "GameOverOverlay"
	overlay.color = Color(0.02, 0.02, 0.04, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud_layer.add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	center.add_child(column)
	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	column.add_child(title)
	var retry := Button.new()
	retry.text = "TRY AGAIN"
	retry.custom_minimum_size = Vector2(220, 64)
	retry.pressed.connect(_retry)
	column.add_child(retry)


func _retry() -> void:
	get_tree().paused = false
	var error := get_tree().reload_current_scene()
	if error != OK:
		push_error("Could not reload current scene. Error: %s" % error)
