extends Node3D
## Lightweight, presentation-only ending cinematic for chapter one.
## Progress is saved by the existing ChapterOne/GameState flow, not by this scene.

signal cinematic_finished(skipped: bool)

@export var use_builtin_save: bool = false

const CINEMATIC_DURATION := 22.5
const SAFETY_TIMEOUT := 25.5
const SKIP_AVAILABLE_AFTER := 2.0
const ANIMATION_NAME := "chapter_one"

@onready var cinematic_camera: Camera3D = $CinematicCamera
@onready var crown_fragment: Node3D = $CrownFragment
@onready var memory_shadow: Node3D = $MemoryShadow
@onready var inner_gate_door: Node3D = $InnerGate/Door
@onready var key_light: DirectionalLight3D = $LightRig/KeyLight
@onready var crown_glow: OmniLight3D = $LightRig/CrownGlow
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var caption_label: Label = $CaptionLayer/CaptionRoot/CaptionPanel/CaptionLabel
@onready var skip_button: Button = $CaptionLayer/CaptionRoot/SkipButton

var _elapsed := 0.0
var _active := false

func _ready() -> void:
	if use_builtin_save:
		push_warning("This cinematic is presentation-only; chapter progress uses the existing GameState save flow.")
	_build_animation()
	skip_button.visible = false
	skip_button.pressed.connect(_on_skip_button_pressed)
	animation_player.animation_finished.connect(_on_animation_finished)
	_active = true
	set_process(true)
	_update_caption(0.0)
	animation_player.play(ANIMATION_NAME)
	_show_skip_after_delay()
	_finish_after_duration()
	_safety_finish()

func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed = minf(_elapsed + delta, SAFETY_TIMEOUT)
	_update_caption(_elapsed)

func _build_animation() -> void:
	var animation := Animation.new()
	animation.resource_name = ANIMATION_NAME
	animation.length = CINEMATIC_DURATION
	animation.loop_mode = Animation.LOOP_NONE
	_add_value_track(animation, "CinematicCamera:position", [
		[0.0, Vector3(0.0, 3.1, 10.2)],
		[4.5, Vector3(1.0, 2.7, 8.0)],
		[9.0, Vector3(-1.0, 2.45, 7.0)],
		[14.5, Vector3(0.0, 2.4, 6.0)],
		[19.0, Vector3(0.0, 2.25, 5.0)],
		[22.5, Vector3(0.0, 2.1, 4.7)],
	])
	_add_value_track(animation, "CinematicCamera:rotation", [
		[0.0, Vector3(-0.13, 0.0, 0.0)],
		[4.5, Vector3(-0.12, 0.10, 0.0)],
		[9.0, Vector3(-0.12, -0.12, 0.0)],
		[14.5, Vector3(-0.12, 0.0, 0.0)],
		[22.5, Vector3(-0.10, 0.0, 0.0)],
	])
	_add_value_track(animation, "CrownFragment:rotation", [
		[0.0, Vector3(0.0, 0.0, 0.0)],
		[22.5, Vector3(0.0, TAU, 0.0)],
	])
	_add_value_track(animation, "CrownFragment:scale", [
		[0.0, Vector3(0.65, 0.65, 0.65)],
		[4.5, Vector3.ONE],
		[9.0, Vector3(1.08, 1.08, 1.08)],
		[14.5, Vector3.ONE],
		[22.5, Vector3(1.04, 1.04, 1.04)],
	])
	_add_value_track(animation, "MemoryShadow:position", [
		[0.0, Vector3(-2.8, 0.0, -3.8)],
		[9.0, Vector3(-2.1, 0.0, -3.8)],
		[14.5, Vector3(-1.45, 0.0, -3.8)],
		[22.5, Vector3(-1.45, 0.0, -3.8)],
	])
	_add_value_track(animation, "MemoryShadow:scale", [
		[0.0, Vector3(0.02, 0.02, 0.02)],
		[9.0, Vector3(0.8, 0.8, 0.8)],
		[14.5, Vector3.ONE],
		[22.5, Vector3(0.9, 0.9, 0.9)],
	])
	_add_value_track(animation, "InnerGate/Door:position", [
		[0.0, Vector3(0.0, 1.55, 0.0)],
		[14.5, Vector3(0.0, 1.55, 0.0)],
		[19.0, Vector3(0.0, 4.65, 0.0)],
		[22.5, Vector3(0.0, 4.65, 0.0)],
	])
	_add_value_track(animation, "LightRig/KeyLight:light_energy", [
		[0.0, 0.55],
		[9.0, 0.8],
		[14.5, 0.7],
		[19.0, 1.0],
		[22.5, 0.75],
	])
	_add_value_track(animation, "LightRig/CrownGlow:light_energy", [
		[0.0, 0.25],
		[4.5, 0.8],
		[9.0, 1.1],
		[14.5, 0.55],
		[19.0, 0.9],
		[22.5, 0.55],
	])
	var library := AnimationLibrary.new()
	library.add_animation(ANIMATION_NAME, animation)
	animation_player.add_animation_library("", library)

func _add_value_track(animation: Animation, property_path: String, keyframes: Array) -> void:
	var track_index := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, NodePath(property_path))
	animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_CUBIC)
	animation.value_track_set_update_mode(track_index, Animation.UPDATE_CONTINUOUS)
	for keyframe in keyframes:
		animation.track_insert_key(track_index, float(keyframe[0]), keyframe[1])

func _show_skip_after_delay() -> void:
	await get_tree().create_timer(SKIP_AVAILABLE_AFTER).timeout
	if _active:
		skip_button.visible = true

func _finish_after_duration() -> void:
	await get_tree().create_timer(CINEMATIC_DURATION).timeout
	if _active:
		_finish(false)

func _safety_finish() -> void:
	await get_tree().create_timer(SAFETY_TIMEOUT).timeout
	if _active:
		_finish(false)

func _update_caption(elapsed: float) -> void:
	if elapsed < 4.5:
		caption_label.text = "Beyond the opened gate, an older secret stirs."
	elif elapsed < 9.0:
		caption_label.text = "A broken crown remembers its last ruler."
	elif elapsed < 14.5:
		caption_label.text = "The shadows of the past begin to stir."
	elif elapsed < 19.0:
		caption_label.text = "The inner gate yields to the light."
	else:
		caption_label.text = "The journey beyond the kingdom begins."

func _on_skip_button_pressed() -> void:
	if _elapsed >= SKIP_AVAILABLE_AFTER:
		_finish(true)

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == ANIMATION_NAME:
		_finish(false)

func _finish(skipped: bool) -> void:
	if not _active:
		return
	_active = false
	set_process(false)
	if animation_player.is_playing():
		animation_player.stop()
	cinematic_finished.emit(skipped)
