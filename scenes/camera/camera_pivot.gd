extends Node3D

## Takip edilecek oyuncuların NodePath'leri
@export var players: Array[NodePath] = []

## Pivot'un orta noktaya ne kadar hızlı yaklaştığı (0=sabit, yüksek=ani)
@export var follow_speed: float = 5.0
## Kamera dönüş hızı (derece/saniye)
@export var rotation_speed: float = 90.0

## Hedef açı — bu değere doğru yumuşakça döner
var _target_angle: float = 0.0
## Her tuş basışında dönülecek açı (derece)
const ROTATION_STEP = 15.0

func _ready():
	global_position = _calculate_midpoint()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := int(event.keycode)
		match key:
			KEY_8:
				_target_angle -= ROTATION_STEP
			KEY_9:
				_target_angle += ROTATION_STEP

func _process(delta: float) -> void:
	# Smooth dönüş: mevcut açıdan hedef açıya yaklaş
	var current_angle := rad_to_deg(rotation.y)
	var new_angle := move_toward(current_angle, _target_angle, rotation_speed * delta)
	rotation.y = deg_to_rad(new_angle)

	# Smooth takip
	var target := _calculate_midpoint()
	var factor := clampf(follow_speed * delta, 0.0, 1.0)
	global_position = global_position.lerp(target, factor)

## Tüm oyuncuların ortalama pozisyonunu döndürür.
## Hiç oyuncu yoksa pivot'un mevcut pozisyonunu korur.
func _calculate_midpoint() -> Vector3:
	var sum := Vector3.ZERO
	var count := 0

	for path in players:
		var node := get_node_or_null(path) as Node3D
		if node != null and is_instance_valid(node):
			sum += node.global_position
			count += 1

	if count > 0:
		var avg := sum / count
		return Vector3(avg.x, global_position.y, avg.z)

	return global_position
