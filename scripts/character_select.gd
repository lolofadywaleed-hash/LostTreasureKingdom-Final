extends Control

const HEROES := ["لولو", "السيد", "فادي"]
const COLORS := [Color("#ed9b43"), Color("#58a6a6"), Color("#8d79be")]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#101b22")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var title := Label.new()
	title.text = "مملكة الكنز المفقود"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 35
	title.offset_bottom = 100
	add_child(title)
	var hint := Label.new()
	hint.text = "اختر بطلك لبدء المغامرة"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_top = 105
	hint.offset_bottom = 150
	add_child(hint)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_CENTER)
	row.position = Vector2(-480, -150)
	row.size = Vector2(960, 330)
	row.add_theme_constant_override("separation", 28)
	add_child(row)
	for i in HEROES.size():
		var card := Button.new()
		card.custom_minimum_size = Vector2(290, 310)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.text = HEROES[i] + "\n\nاضغط للاختيار"
		card.add_theme_font_size_override("font_size", 27)
		card.add_theme_color_override("font_color", Color.WHITE)
		var style := StyleBoxFlat.new()
		style.bg_color = COLORS[i]
		style.corner_radius_top_left = 24
		style.corner_radius_top_right = 24
		style.corner_radius_bottom_left = 24
		style.corner_radius_bottom_right = 24
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = Color("#f6d99b")
		card.add_theme_stylebox_override("normal", style)
		var hover := style.duplicate()
		hover.bg_color = COLORS[i].lightened(0.16)
		card.add_theme_stylebox_override("hover", hover)
		card.pressed.connect(_on_hero_selected.bind(HEROES[i]))
		row.add_child(card)

func _on_hero_selected(hero: String) -> void:
	get_node("/root/GameState").selected_hero = hero
	get_tree().change_scene_to_file("res://scenes/main.tscn")
