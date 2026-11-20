extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var enemy_script: GDScript = load("res://scripts/enemy.gd") as GDScript
	if enemy_script == null:
		_fail("Enemy script failed to load or parse")
		return

	var main_scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if main_scene == null:
		_fail("Main scene failed to load")
		return

	var game := main_scene.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame

	var player := game.get_node_or_null("Player") as CharacterBody3D
	var enemy := game.get_node_or_null("Enemy") as CharacterBody3D
	if player == null or enemy == null:
		_fail("Main scene must contain Player and Enemy CharacterBody3D nodes")
		return
	if enemy.get_script() == null or not enemy.has_method("take_damage"):
		_fail("Enemy gameplay script is not active")
		return
	if not enemy.get_node_or_null("CollisionShape3D") or not enemy.get_node("CollisionShape3D").shape is CapsuleShape3D:
		_fail("Enemy collision capsule was not initialized")
		return
	if enemy.get_node_or_null("Visual") == null or enemy.get_node_or_null("HitSparks") == null:
		_fail("Enemy visual or hit VFX was not initialized")
		return

	var health = player.get_node_or_null("HealthSystem")
	if health == null or health.current_health != health.max_health:
		_fail("Player health component did not initialize")
		return

	# Bring the enemy into attack range; its AI should damage the player.
	enemy.attack_cooldown = 0.2
	health.damage_invulnerability = 0.2
	enemy.global_position = player.global_position + Vector3(0.0, 0.0, -1.2)
	for _i in range(3):
		await physics_frame
	if health.current_health != health.max_health - enemy.attack_damage:
		_fail("Enemy AI did not damage the player at close range")
		return
	enemy.global_position = player.global_position + Vector3(0.0, 0.0, -4.0)
	await create_timer(0.25).timeout

	# Place the enemy in front of the player and verify the player's attack hits it.
	enemy.global_position = player.global_position + Vector3(0.0, 0.0, -2.0)
	player.attacked.emit()
	if enemy._health != enemy.max_health - 1:
		_fail("Player attack did not reduce enemy health")
		return
	if not enemy.get_node("HitSparks").emitting:
		_fail("Enemy hit sparks did not activate")
		return
	if enemy.get_node_or_null("DamageNumber") == null:
		_fail("Floating damage text was not created")
		return

	enemy._health = 1
	enemy.take_damage(1)
	if not enemy.is_queued_for_deletion():
		_fail("Enemy did not enter death/removal state at zero health")
		return

	await create_timer(0.75).timeout
	print("Enemy combat test passed: script, collision, AI attack, player hit, VFX, damage text, death")
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
