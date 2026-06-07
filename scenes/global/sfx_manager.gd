extends Node

const SFX_DIR := "res://assets/sfx/"

const SFX_FILES: Dictionary = {
	"bear": "bear.ogg",
	"die": "die.ogg",
	"eating": "eating.ogg",
	"horse": "horse.ogg",
	"horse_eating": "horse-eating.ogg",
	"pickaxe": "pickaxe.ogg",
	"wolf_au": "wolf-au.ogg",
}

const FIRE_PATH := "res://assets/sfx/fire.mp3"

var _streams: Dictionary = {}
var _fire_stream: AudioStreamMP3

# One-shot player — reused, stops previous sound if overlapping
var _sfx_player: AudioStreamPlayer
# Dedicated fire player — persists while fire burns
var _fire_player: AudioStreamPlayer


func _ready() -> void:
	for name in SFX_FILES:
		_streams[name] = load(SFX_DIR + SFX_FILES[name]) as AudioStreamOggVorbis

	_fire_stream = load(FIRE_PATH) as AudioStreamMP3
	_fire_stream.loop = true

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX"
	add_child(_sfx_player)

	_fire_player = AudioStreamPlayer.new()
	_fire_player.bus = "SFX"
	_fire_player.stream = _fire_stream
	add_child(_fire_player)


func play_sfx(name: StringName) -> void:
	var stream: AudioStreamOggVorbis = _streams.get(name, null)
	if stream == null:
		push_warning("SFXManager: unknown sfx '%s'" % name)
		return
	_sfx_player.stream = stream
	_sfx_player.play()


func play_fire() -> void:
	if _fire_player.playing:
		return
	_fire_player.play()


func stop_fire() -> void:
	_fire_player.stop()
