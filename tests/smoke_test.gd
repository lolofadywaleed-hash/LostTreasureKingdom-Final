extends SceneTree

func _initialize() -> void:
	var scene := load("res://scenes/character_select.tscn")
	assert(scene != null, "Character selection scene should load")
	var main := load("res://scenes/main.tscn")
	assert(main != null, "Main scene should load")
	print("Smoke test passed")
	quit()
