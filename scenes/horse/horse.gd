extends CharacterBody3D

## Atın hareket hızı (tam tokken)
@export var speed: float = 5.0
## Hareket yönüne göre sprite'ı flip et
@export var flip_on_move: bool = true
## Maksimum tokluk
@export var max_hunger: float = 100.0
## Saniyede ne kadar hızlı acıksın
@export var hunger_rate: float = 1.5
## Elma başına dolan tokluk
@export var apple_feed_amount: float = 40.0

var rider_player_id: int = -1
var rider_node: Node3D = null
var _mount_ready: bool = false

var _hunger: float = 100.0

const INPUT_PREFIX = "p%d_"

var _anim_time: float = 0.0
const ANIM_SPEED: float = 10.0

const EMPTY_TEXTURE := preload("res://assets/sprites/horse.png")
const RIDER_TEXTURES := {
	0: preload("res://assets/sprites/horse_rider_0.png"),
	1: preload("res://assets/sprites/horse_rider_1.png"),
	2: preload("res://assets/sprites/horse_rider_2.png"),
	3: preload("res://assets/sprites/horse_rider_3.png"),
}

func _ready():
	_hunger = max_hunger
	_update_hunger_bar()

func _process(delta: float) -> void:
	if velocity.length_squared() > 0.1:
		_hunger = maxf(_hunger - hunger_rate * delta, 0.0)
	_update_hunger_bar()

	if rider_player_id < 0:
		return
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return
	if velocity.length_squared() > 0.01:
		_anim_time += delta * ANIM_SPEED
		sprite.frame = int(_anim_time) % 4
	else:
		_anim_time = 0.0
		sprite.frame = 0

func _physics_process(_delta: float) -> void:
	var current_speed := _get_current_speed()

	if rider_player_id >= 0:
		if _mount_ready and Input.is_action_just_pressed(INPUT_PREFIX % rider_player_id + "mount"):
			dismount()
			return
		_mount_ready = true

		var input_dir := _get_rider_input()
		if input_dir.length() > 0.15:
			var direction := _input_to_camera_relative(input_dir)
			velocity = direction * current_speed
			_update_facing(input_dir.x)
			look_at(global_position + direction, Vector3.UP)
		else:
			velocity = Vector3.ZERO

		move_and_slide()

		if rider_node and is_instance_valid(rider_node):
			rider_node.global_position = global_position
	else:
		velocity = Vector3.ZERO

func _get_current_speed() -> float:
	if _hunger <= 0.0:
		return 0.0
	var ratio := _hunger / max_hunger
	return speed * ratio

## Açlık bar'ını günceller (region_rect ile soldan kırpar).
func _update_hunger_bar():
	var fill := $HungerBarFill as Sprite3D
	if not fill:
		return
	var ratio := _hunger / max_hunger
	# Soldan itibaren kırp: ratio=1 → 64px, ratio=0 → 0px
	var w := ratio * 64.0
	fill.region_rect.size.x = w
	fill.offset.x = (64.0 - w) / -2.0
## Atı besle (player tarafından çağrılır).
func feed(amount: float) -> void:
	_hunger = minf(_hunger + amount, max_hunger)
	_update_hunger_bar()

## Player tarafından çağrılır — ata bindirir.
func mount_player(player: Node3D) -> bool:
	if rider_player_id >= 0:
		return false
	rider_node = player
	rider_player_id = player.get("player_id") as int
	_mount_ready = false
	_update_rider_texture()
	_apply_player_visibility(player, false)
	return true

func dismount() -> void:
	if not rider_node or not is_instance_valid(rider_node):
		rider_player_id = -1
		rider_node = null
		return
	var spawn_offset := -global_transform.basis.z * 0.5
	rider_node.global_position = global_position + spawn_offset
	_apply_player_visibility(rider_node, true)
	rider_player_id = -1
	rider_node = null
	_update_rider_texture()

func _get_rider_input() -> Vector2:
	if rider_player_id < 0:
		return Vector2.ZERO
	var pid := rider_player_id
	# Gamepad left stick (öncelikli)
	var stick_x := Input.get_joy_axis(pid, JOY_AXIS_LEFT_X)
	var stick_y := Input.get_joy_axis(pid, JOY_AXIS_LEFT_Y)
	if abs(stick_x) > 0.15 or abs(stick_y) > 0.15:
		return Vector2(stick_x, stick_y)
	# Gamepad D-pad
	var dpad_x := -1.0 if Input.is_joy_button_pressed(pid, JOY_BUTTON_DPAD_LEFT) else (1.0 if Input.is_joy_button_pressed(pid, JOY_BUTTON_DPAD_RIGHT) else 0.0)
	var dpad_y := -1.0 if Input.is_joy_button_pressed(pid, JOY_BUTTON_DPAD_UP) else (1.0 if Input.is_joy_button_pressed(pid, JOY_BUTTON_DPAD_DOWN) else 0.0)
	if dpad_x != 0.0 or dpad_y != 0.0:
		return Vector2(dpad_x, dpad_y)
	# Klavye
	var prefix := INPUT_PREFIX % pid
	return Vector2(
		Input.get_axis(prefix + "move_left", prefix + "move_right"),
		Input.get_axis(prefix + "move_up", prefix + "move_down")
	)

func _input_to_camera_relative(input_dir: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return Vector3(input_dir.x, 0, input_dir.y).normalized()
	var forward := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	forward.y = 0; right.y = 0
	if forward.length_squared() < 0.001:
		forward = Vector3(0, 0, -1)
	if right.length_squared() < 0.001:
		right = Vector3(1, 0, 0)
	return (forward.normalized() * -input_dir.y + right.normalized() * input_dir.x).normalized()

func _update_facing(input_x: float) -> void:
	if not flip_on_move or input_x == 0:
		return
	var sprite := $Sprite3D as Sprite3D
	if sprite:
		sprite.flip_h = input_x < 0

func _update_rider_texture() -> void:
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return
	if rider_player_id >= 0 and RIDER_TEXTURES.has(rider_player_id):
		sprite.texture = RIDER_TEXTURES[rider_player_id]
	else:
		sprite.texture = EMPTY_TEXTURE

func _apply_player_visibility(player: Node3D, visible: bool) -> void:
	player.visible = visible
	player.set_process(visible)
	player.set_physics_process(visible)
	for child in player.get_children():
		var cs := child as CollisionShape3D
		if cs:
			cs.disabled = not visible
