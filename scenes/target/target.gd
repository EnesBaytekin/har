extends Node3D

## Hedef bölge — vagon ateşle birlikte buraya girince oyun sonu.

@export var fade_time: float = 3.0
@export var next_scene: String = "res://scenes/outro_cinematic/outro_cinematic.tscn"

var _fading: bool = false
var _fade_timer: float = 0.0
var _fade_rect: ColorRect = null

func _ready():
	$DetectionArea.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _fading:
		return
	if body.has_method("get_fire_level") and body.get_fire_level() > 0:
		_start_fade()

func _start_fade():
	_fading = true
	_fade_timer = 0.0
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(1, 1, 1, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var canvas = CanvasLayer.new()
	canvas.add_child(_fade_rect)
	add_child(canvas)

func _process(delta: float) -> void:
	if not _fading:
		return
	_fade_timer += delta
	var alpha := clampf(_fade_timer / fade_time, 0.0, 1.0)
	_fade_rect.color.a = alpha
	if alpha >= 1.0:
		if not next_scene.is_empty():
			get_tree().change_scene_to_file(next_scene)
