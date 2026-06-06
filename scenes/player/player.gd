extends CharacterBody3D

## Player ID: 0=Gamepad 1 + WASD, 1=Gamepad 2 + Arrows, 2=Gamepad 3, 3=Gamepad 4
@export var player_id: int = 0:
	set(value):
		_player_id = value
		_update_texture()
	get():
		return _player_id
var _player_id: int = 0
@export var speed: float = 5.0
## Hareket yönüne göre sprite'ı yatay flip et (Editor'den aç/kapa)
@export var flip_on_move: bool = true

const PLAYER_TEXTURES := {
	0: preload("res://assets/sprites/player1.png"),
	1: preload("res://assets/sprites/player2.png"),
	2: preload("res://assets/sprites/player3.png"),
	3: preload("res://assets/sprites/player4.png"),
}

func _ready():
	_update_texture()

func _update_texture():
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return
	if PLAYER_TEXTURES.has(player_id):
		sprite.texture = PLAYER_TEXTURES[player_id]

func _physics_process(_delta: float) -> void:
	var input_dir := _get_input()

	if input_dir.length() > 0.15:
		var direction := _input_to_camera_relative(input_dir)
		velocity = direction * speed
		_update_facing(input_dir.x)
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity = Vector3.ZERO

	move_and_slide()

## Input yönünü kameranın bakış açısına göre dönüştürür.
## Böylece "yukarı" her zaman kameradan uzaklaşan yön olur.
func _input_to_camera_relative(input_dir: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return Vector3(input_dir.x, 0, input_dir.y).normalized()

	var forward := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	forward.y = 0
	right.y = 0

	# Kameranın tam tepeden baktığı durumda forward sıfır olur
	if forward.length_squared() < 0.001:
		forward = Vector3(0, 0, -1)
	if right.length_squared() < 0.001:
		right = Vector3(1, 0, 0)

	forward = forward.normalized()
	right = right.normalized()

	return (forward * -input_dir.y + right * input_dir.x).normalized()

func _update_facing(input_x: float) -> void:
	if not flip_on_move or input_x == 0:
		return
	var sprite := $Sprite3D as Sprite3D
	if sprite:
		sprite.flip_h = input_x < 0

func _get_input() -> Vector2:
	# --- Gamepad sol stick (öncelikli) ---
	var stick_x := Input.get_joy_axis(player_id, JOY_AXIS_LEFT_X)
	var stick_y := Input.get_joy_axis(player_id, JOY_AXIS_LEFT_Y)
	if abs(stick_x) > 0.15 or abs(stick_y) > 0.15:
		return Vector2(stick_x, stick_y)

	# --- Klavye ---
	var prefix := "p%d_" % player_id
	return Vector2(
		Input.get_axis(prefix + "move_left", prefix + "move_right"),
		Input.get_axis(prefix + "move_up", prefix + "move_down")
	)
