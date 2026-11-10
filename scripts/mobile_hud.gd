extends CanvasLayer

func _ready() -> void:
	var jump := Button.new()
	jump.text = "قفز"
	jump.custom_minimum_size = Vector2(100, 86)
	jump.position = Vector2(get_viewport().get_visible_rect().size.x - 135, get_viewport().get_visible_rect().size.y - 130)
	jump.add_theme_font_size_override("font_size", 24)
	add_child(jump)
	jump.button_down.connect(func(): Input.action_press("jump"))
	jump.button_up.connect(func(): Input.action_release("jump"))
	var label := Label.new()
	label.text = "حرّك إصبعك يسار الشاشة للتحرك"
	label.position = Vector2(20, get_viewport().get_visible_rect().size.y - 48)
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)
