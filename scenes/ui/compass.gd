extends Control

## Pusula — hedefin hangi yönde olduğunu gösterir.
## Kamera döndükçe ok da döner, daima hedefi işaret eder.

const CIRCLE_SIZE := 64.0
const ARROW_LENGTH := 22.0
const ARROW_WIDTH := 4.0

var _target: Node3D = null

@onready var _bg := $Background as Panel
@onready var _arrow := $Arrow as ColorRect
@onready var _dist_label := $Distance as Label


func _ready() -> void:
	_position_children()
	_find_target()
	get_tree().root.size_changed.connect(_position_children)


func _position_children() -> void:
	var cx := size.x / 2.0
	var cy := CIRCLE_SIZE / 2.0 + 16.0

	# Daire arka plan
	_bg.position = Vector2(cx - CIRCLE_SIZE / 2.0, cy - CIRCLE_SIZE / 2.0)
	_bg.size = Vector2(CIRCLE_SIZE, CIRCLE_SIZE)

	# Ok — daire merkezinden yukarıya bakar (rotation=0 → hedef ileride)
	_arrow.position = Vector2(cx - ARROW_WIDTH / 2.0, cy - ARROW_LENGTH)
	_arrow.size = Vector2(ARROW_WIDTH, ARROW_LENGTH)
	_arrow.pivot_offset = Vector2(ARROW_WIDTH / 2.0, ARROW_LENGTH)

	# Mesafe yazısı
	_dist_label.position = Vector2(cx - 30.0, cy + CIRCLE_SIZE / 2.0 + 4.0)
	_dist_label.size = Vector2(60.0, 20.0)


func _process(_delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		_find_target()
		if not _target:
			return

	var cam := get_viewport().get_camera_3d()
	if not cam:
		return

	# Kamera forward ile hedef yönü arasındaki açı (XZ düzleminde)
	var cam_forward := -cam.global_transform.basis.z
	var to_target := _target.global_position - cam.global_position

	var fwd_2d := Vector2(cam_forward.x, cam_forward.z)
	var dir_2d := Vector2(to_target.x, to_target.z)

	if fwd_2d.length_squared() < 0.001 or dir_2d.length_squared() < 0.001:
		return

	var angle := fwd_2d.angle_to(dir_2d)
	var dist := to_target.length()

	_arrow.rotation = angle
	_dist_label.text = "%.0f m" % dist


func _find_target() -> void:
	var nodes := get_tree().get_nodes_in_group("targets")
	if nodes.size() > 0:
		_target = nodes[0] as Node3D
