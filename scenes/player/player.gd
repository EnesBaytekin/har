extends CharacterBody3D

## Player ID: 0=Gamepad 1 + WASD, 1=Gamepad 2 + Arrows, 2=Gamepad 3, 3=Gamepad 4
@export var player_id: int = 0
@export var speed: float = 5.0

const PLAYER_SPRITES := {
	0: preload("res://assets/sprites/player_blue.png"),
	1: preload("res://assets/sprites/player_red.png"),
	2: preload("res://assets/sprites/player_green.png"),
	3: preload("res://assets/sprites/player_yellow.png"),
}

func _ready():
	_update_sprite()

func _update_sprite():
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return
	if PLAYER_SPRITES.has(player_id):
		sprite.texture = PLAYER_SPRITES[player_id]

func _physics_process(_delta: float) -> void:
	var input_dir := _get_input()

	if input_dir.length() > 0.15:
		var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
		velocity = direction * speed
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity = Vector3.ZERO

	move_and_slide()

func _get_input() -> Vector2:
	# --- Gamepad sol stick (öncelikli) ---
	var stick_x := Input.get_joy_axis(player_id, JOY_AXIS_LEFT_X)
	var stick_y := Input.get_joy_axis(player_id, JOY_AXIS_LEFT_Y)
	if abs(stick_x) > 0.15 or abs(stick_y) > 0.15:
		return Vector2(stick_x, stick_y)

	# --- Klavye (action_name içinde "p{player_id}" prefix'ini kullan) ---
	var prefix := "p%d_" % player_id
	return Vector2(
		Input.get_axis(prefix + "move_left", prefix + "move_right"),
		Input.get_axis(prefix + "move_up", prefix + "move_down")  # Z-ileri pozitif
	)
