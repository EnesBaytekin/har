extends Control

@export var video_path: String = ""
@export var next_scene: String = ""

var _player: VideoStreamPlayer


func _ready():
	MusicManager.stop_music()

	if video_path.is_empty():
		_goto_next()
		return

	var stream := VideoStreamTheora.new()
	stream.file = video_path
	if not FileAccess.file_exists(video_path):
		push_error("Video bulunamadi: ", video_path)
		_goto_next()
		return

	_player = VideoStreamPlayer.new()
	_player.stream = stream
	_player.expand = true
	_player.finished.connect(_goto_next)
	_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_player)
	_player.play()


func _input(event):
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return
	var key := int(event.keycode)
	if key == KEY_ENTER or key == KEY_SPACE or key == KEY_ESCAPE:
		if _player:
			_player.stop()
		_goto_next()


func _goto_next():
	if not next_scene.is_empty():
		get_tree().change_scene_to_file(next_scene)
