extends Node

## Oynatılacak webm videosu
@export var video_path: String = ""
## Video bitince gidilecek sahne
@export var next_scene: String = ""

func _ready():
	if video_path.is_empty():
		_goto_next()
		return

	var player := VideoStreamPlayer.new()
	var stream := load(video_path) as VideoStream
	if not stream:
		push_error("Video yüklenemedi: ", video_path)
		_goto_next()
		return

	player.stream = stream
	player.autoplay = true
	player.expand = true
	player.finished.connect(_goto_next)

	player.set_anchors_preset(Control.PRESET_FULL_RECT)

	var canvas := CanvasLayer.new()
	canvas.add_child(player)
	add_child(canvas)

func _goto_next():
	if not next_scene.is_empty():
		get_tree().change_scene_to_file(next_scene)
