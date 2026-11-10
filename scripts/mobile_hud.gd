extends CanvasLayer

signal move_vector_changed(vector: Vector2)

const LEFT_HALF_RATIO := 0.5
const DEADZONE := 0.12
const BUTTON_HIT_PADDING := 1.2
const IDLE_ALPHA := 0.8

@onready var joystick_base: Panel = $Root/JoystickBase
@onready var joystick_knob: Panel = $Root/JoystickBase/Knob
@onready var attack_button: Control = $Root/AttackButton
@onready var jump_button: Control = $Root/JumpButton
@onready var skill_button: Control = $Root/SkillButton
@onready var coin_panel: Control = $Root/CoinPanel
@onready var coins_label: Label = $Root/CoinPanel/CoinLabel

var _buttons: Dictionary = {}
var _button_touches: Dictionary = {}
var _joystick_touch := -1
var _joystick_center := Vector2.ZERO
var _move_vector := Vector2.ZERO
var _coin_tween: Tween


func _ready() -> void:
	for action_name in ["jump", "attack", "skill"]:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
	_buttons = {
		"attack": attack_button,
		"jump": jump_button,
		"skill": skill_button,
	}
	for action_name in _buttons:
		var node: Control = _buttons[action_name]
		node.pivot_offset = node.size * 0.5
		_set_button_pressed(action_name, false)
	joystick_base.visible = false
	coins_label.text = "Coins: 0"

func _exit_tree() -> void:
	_reset_all()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_reset_all()

func update_coins(amount: int) -> void:
	coins_label.text = "Coins: %d" % amount
	if _coin_tween != null and _coin_tween.is_valid():
		_coin_tween.kill()
	coin_panel.pivot_offset = coin_panel.size * 0.5
	coin_panel.scale = Vector2.ONE
	_coin_tween = create_tween()
	_coin_tween.tween_property(coin_panel, "scale", Vector2(1.15, 1.15), 0.08)
	_coin_tween.tween_property(coin_panel, "scale", Vector2.ONE, 0.12)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_on_touch_pressed(touch.index, touch.position)
		else:
			_on_touch_released(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _joystick_touch:
			_update_joystick(drag.position)
			get_viewport().set_input_as_handled()

func _on_touch_pressed(index: int, pos: Vector2) -> void:
	var action_name := _button_at(pos)
	if action_name != "":
		_button_touches[index] = action_name
		Input.action_press(action_name)
		_set_button_pressed(action_name, true)
		get_viewport().set_input_as_handled()
		return
	var screen_width := get_viewport().get_visible_rect().size.x
	if pos.x < screen_width * LEFT_HALF_RATIO and _joystick_touch == -1:
		_joystick_touch = index
		_joystick_center = pos
		joystick_base.global_position = pos - joystick_base.size * 0.5
		joystick_knob.position = (joystick_base.size - joystick_knob.size) * 0.5
		joystick_base.visible = true
		_update_joystick(pos)
		get_viewport().set_input_as_handled()

func _on_touch_released(index: int) -> void:
	if index == _joystick_touch:
		_joystick_touch = -1
		joystick_base.visible = false
		_set_move_vector(Vector2.ZERO)
		get_viewport().set_input_as_handled()
	elif _button_touches.has(index):
		var action_name: String = _button_touches[index]
		_button_touches.erase(index)
		Input.action_release(action_name)
		_set_button_pressed(action_name, false)
		get_viewport().set_input_as_handled()

func _update_joystick(pos: Vector2) -> void:
	var radius := (joystick_base.size.x - joystick_knob.size.x) * 0.5
	var offset := (pos - _joystick_center).limit_length(radius)
	joystick_knob.position = (joystick_base.size - joystick_knob.size) * 0.5 + offset
	var vector := offset / radius
	if vector.length() < DEADZONE:
		vector = Vector2.ZERO
	_set_move_vector(vector)

func _set_move_vector(vector: Vector2) -> void:
	_move_vector = vector
	_apply_axis("move_left", maxf(-vector.x, 0.0))
	_apply_axis("move_right", maxf(vector.x, 0.0))
	_apply_axis("move_forward", maxf(-vector.y, 0.0))
	_apply_axis("move_back", maxf(vector.y, 0.0))
	move_vector_changed.emit(vector)

func _apply_axis(action_name: String, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action_name, strength)
	else:
		Input.action_release(action_name)

func _button_at(pos: Vector2) -> String:
	for action_name in _buttons:
		var node: Control = _buttons[action_name]
		var rect := node.get_global_rect()
		var radius := rect.size.x * 0.5 * BUTTON_HIT_PADDING
		if pos.distance_to(rect.get_center()) <= radius:
			return action_name
	return ""

func _set_button_pressed(action_name: String, pressed: bool) -> void:
	var node: Control = _buttons[action_name]
	node.modulate = Color(1, 1, 1, 1.0 if pressed else IDLE_ALPHA)
	node.scale = Vector2.ONE * (0.92 if pressed else 1.0)

func _reset_all() -> void:
	_joystick_touch = -1
	if is_instance_valid(joystick_base):
		joystick_base.visible = false
	_set_move_vector(Vector2.ZERO)
	for action_name in _button_touches.values():
		Input.action_release(action_name)
		if _buttons.has(action_name):
			_set_button_pressed(action_name, false)
	_button_touches.clear()
