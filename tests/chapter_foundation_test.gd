extends SceneTree

const HERO_DATA_SCRIPT = preload("res://scripts/hero_data.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var lolo := HERO_DATA_SCRIPT.get_profile("Lolo")
	var alsayed := HERO_DATA_SCRIPT.get_profile("AlSayed")
	var fady := HERO_DATA_SCRIPT.get_profile("Fady")
	assert(lolo["max_health"] != alsayed["max_health"], "Heroes need different health values")
	assert(alsayed["attack_damage"] != fady["attack_damage"], "Heroes need different attack values")
	assert(fady["move_speed"] > lolo["move_speed"], "Fady should be the faster hero")
	assert(lolo["skill_name"] != alsayed["skill_name"], "Hero skills must be distinct")

	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn")
	assert(enemy_scene != null, "Standalone enemy scene should load")
	var enemy := enemy_scene.instantiate()
	assert(enemy is CharacterBody3D, "Standalone enemy must be a CharacterBody3D")
	enemy.queue_free()
	print("Chapter foundation data and enemy scene test passed")
	quit()
