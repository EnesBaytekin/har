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
				_target_angle = _normalize_angle(_target_angle - ROTATION_STEP)
			KEY_9:
				_target_angle = _normalize_angle(_target_angle + ROTATION_STEP)

func _process(delta: float) -> void:
	# Gamepad tetikleri ile kamera dönüşü
	var lt := Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)
	var rt := Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)
	if lt > 0.5:
		_target_angle = _normalize_angle(_target_angle - rotation_speed * lt * delta)
	if rt > 0.5:
		_target_angle = _normalize_angle(_target_angle + rotation_speed * rt * delta)

	var current_deg := rad_to_deg(rotation.y)

	# Mevcut açı ile hedef arasındaki KISA farkı bul (-180..180)
	var diff := _target_angle - current_deg
	diff = fmod(diff, 360.0)
	if diff > 180.0:
		diff -= 360.0
	elif diff < -180.0:
		diff += 360.0

	var step := rotation_speed * delta
	if abs(diff) <= step:
		rotation.y = deg_to_rad(current_deg + diff)
		_target_angle = _normalize_angle(_target_angle)
	else:
		rotation.y = deg_to_rad(current_deg + sign(diff) * step)

	# Smooth takip
	var target := _calculate_midpoint()
	var factor := clampf(follow_speed * delta, 0.0, 1.0)
	global_position = global_position.lerp(target, factor)

## Açıyı -180..180 aralığına normalize eder.
func _normalize_angle(deg: float) -> float:
	deg = fmod(deg, 360.0)
	if deg > 180.0:
		deg -= 360.0
	elif deg < -180.0:
		deg += 360.0
	return deg

## Tüm oyuncuların ortalama pozisyonunu döndürür.
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
