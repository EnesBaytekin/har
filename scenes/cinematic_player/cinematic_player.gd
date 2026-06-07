extends Control

@export var video_path: String = ""
@export var next_scene: String = ""

var _player: VideoStreamPlayer
var _preload_progress: Array = []
var _preload_started: bool = false


func _ready():
	if video_path.is_empty():
		_goto_next()
		return

	_start_preload()

	var stream := VideoStreamTheora.new()
	stream.file = video_path
	if not ResourceLoader.exists(video_path):
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


func _start_preload():
	if next_scene.is_empty() or _preload_started:
		return
	_preload_started = true
	var err := ResourceLoader.load_threaded_request(next_scene)
	if err != OK:
		push_error("Preload basarisiz: ", next_scene, " (", err, ")")
		_preload_started = false


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
	if next_scene.is_empty():
		return

	if _preload_started:
		_preload_started = false
		var status := ResourceLoader.load_threaded_get_status(next_scene, _preload_progress)
		match status:
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error("Preload gecersiz kaynak: ", next_scene)
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				var packed := ResourceLoader.load_threaded_get(next_scene) as PackedScene
				if packed:
					get_tree().change_scene_to_packed(packed)
					return
			ResourceLoader.THREAD_LOAD_FAILED:
				push_error("Preload basarisiz: ", next_scene)
			ResourceLoader.THREAD_LOAD_LOADED:
				var packed := ResourceLoader.load_threaded_get(next_scene) as PackedScene
				if packed:
					get_tree().change_scene_to_packed(packed)
					return

	get_tree().change_scene_to_file(next_scene)
