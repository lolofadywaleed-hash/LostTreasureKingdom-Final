class_name StateMachine
extends Node

## يدير حالات اللاعب وينفذ الانتقال بينها.

signal state_changed(previous_state: StringName, current_state: StringName)

var player: PlayerBase
var states: Dictionary = {}
var current_state: State
var current_state_name: StringName = &""


func initialize(player_reference: PlayerBase, state_list: Array[State], initial_state: StringName) -> void:
	player = player_reference
	for state in state_list:
		if state == null:
			continue
		var state_name := StringName(state.name)
		if state_name.is_empty():
			push_error("StateMachine: كل حالة يجب أن تملك اسماً.")
			continue
		states[state_name] = state
		add_child(state)
		state.setup(player, self)
	transition_to(initial_state)


func transition_to(next_state_name: StringName) -> void:
	if not states.has(next_state_name):
		push_error("StateMachine: حالة غير معروفة: %s" % next_state_name)
		return
	if current_state_name == next_state_name:
		return
	var previous_state_name := current_state_name
	if current_state != null:
		current_state.exit()
	current_state_name = next_state_name
	current_state = states[next_state_name] as State
	current_state.enter()
	state_changed.emit(previous_state_name, current_state_name)


func physics_update(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)
