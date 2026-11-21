extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Main scene should load for all hero profiles")
	var expected := {
		"Lolo": {"health": 3, "speed": 5.0, "damage": 1},
		"AlSayed": {"health": 5, "speed": 4.2, "damage": 2},
		"Fady": {"health": 2, "speed": 6.4, "damage": 1}
	}
	for hero_name in ["Lolo", "AlSayed", "Fady"]:
		root.set_meta("selected_hero", hero_name)
		var game := main_scene.instantiate()
		root.add_child(game)
		current_scene = game
		await process_frame
		var player := game.get_node("Player")
		var health := player.get_node("HealthSystem")
		var attack := player.get_node("AttackSystem")
		assert(player.selected_hero == hero_name, "Selected hero should reach Player")
		assert(health.max_health == expected[hero_name]["health"], "Health profile mismatch for " + hero_name)
		assert(is_equal_approx(player.move_speed, expected[hero_name]["speed"]), "Speed profile mismatch for " + hero_name)
		assert(attack.damage == expected[hero_name]["damage"], "Damage profile mismatch for " + hero_name)
		assert(player.get_node("KnightVisual").get_child_count() > 0, "All heroes must use the available Louay visual")
		game.queue_free()
		await process_frame
	print("Hero profiles test passed for Lolo, AlSayed, and Fady")
	quit()
