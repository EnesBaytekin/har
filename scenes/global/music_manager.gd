extends Node

const MENU_MUSIC_PATH := "res://assets/musics/menu.ogg"
const GAME_MUSIC_PATH := "res://assets/musics/main.ogg"

var _menu_stream: AudioStreamOggVorbis
var _game_stream: AudioStreamOggVorbis
var _player: AudioStreamPlayer


func _ready() -> void:
	_menu_stream = load(MENU_MUSIC_PATH) as AudioStreamOggVorbis
	_game_stream = load(GAME_MUSIC_PATH) as AudioStreamOggVorbis

	_menu_stream.loop = true
	_game_stream.loop = true

	_player = AudioStreamPlayer.new()
	_player.bus = "Music"
	add_child(_player)


func play_menu_music() -> void:
	if _player.stream == _menu_stream and _player.playing:
		return
	_player.stream = _menu_stream
	_player.play()


func play_game_music() -> void:
	if _player.stream == _game_stream and _player.playing:
		return
	_player.stream = _game_stream
	_player.play()


func stop_music() -> void:
	_player.stop()
