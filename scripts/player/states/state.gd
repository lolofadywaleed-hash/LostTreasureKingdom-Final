class_name State
extends Node

## الصنف الأساسي لحالات حركة اللاعب.

var player: PlayerBase
var state_machine: StateMachine


func setup(player_reference: PlayerBase, machine_reference: StateMachine) -> void:
	player = player_reference
	state_machine = machine_reference


func enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
