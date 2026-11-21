extends Node

@onready var music_player: AudioStreamPlayer = $Music
@onready var attack_player: AudioStreamPlayer = $AttackSFX
@onready var coin_player: AudioStreamPlayer = $CoinSFX
@onready var skill_player: AudioStreamPlayer = $SkillSFX


func _ready() -> void:
	if music_player.stream is AudioStreamMP3:
		(music_player.stream as AudioStreamMP3).loop = true
	music_player.play()


func play_attack() -> void:
	_play_one_shot(attack_player)


func play_skill() -> void:
	_play_one_shot(skill_player)


func on_coins_changed(_total: int) -> void:
	_play_one_shot(coin_player)


func _play_one_shot(player: AudioStreamPlayer) -> void:
	if player == null or player.stream == null:
		return
	player.stop()
	player.play()
