extends CharacterBody3D

signal attacked
signal skill_used
signal coins_changed(total: int)

@export var speed: float = 5.5
@export var jump_velocity: float = 5.0
@export var gravity: float = 14.0
@export var kill_height: float = -20.0

var coins_collected: int = 0
var _spawn_position := Vector3.ZERO


func _ready() -> void:
	_spawn_position = global_position

func add_coins(amount: int) -> void:
	coins_collected += amount
	coins_changed.emit(coins_collected)
	print("Coins collected: %d (+%d)" % [coins_collected, amount])

func _physics_process(delta: float) -> void:
	if global_position.y < kill_height:
		velocity = Vector3.ZERO
		global_position = _spawn_position

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input.x, 0, input.y).rotated(Vector3.UP, $SpringArm3D.rotation.y)
	if direction.length() > 1.0:
		direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	if InputMap.has_action("attack") and Input.is_action_just_pressed("attack"):
		attacked.emit()
	if InputMap.has_action("skill") and Input.is_action_just_pressed("skill"):
		skill_used.emit()

	move_and_slide()
