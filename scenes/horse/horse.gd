extends CharacterBody3D

## Atın hareket hızı
@export var speed: float = 5.0
## Hareket yönüne göre sprite'ı flip et
@export var flip_on_move: bool = true

var rider_player_id: int = -1  # -1 = boş
var rider_node: Node3D = null

const INPUT_PREFIX = "p%d_"

const EMPTY_TEXTURE := preload("res://assets/sprites/horse.png")
const RIDER_TEXTURES := {
	0: preload("res://assets/sprites/horse_rider_0.png"),
	1: preload("res://assets/sprites/horse_rider_1.png"),
	2: preload("res://assets/sprites/horse_rider_2.png"),
	3: preload("res://assets/sprites/horse_rider_3.png"),
}

func _physics_process(_delta: float) -> void:
	if rider_player_id >= 0:
		# --- Binik hal: inme kontrolü ---
		if Input.is_action_just_pressed(INPUT_PREFIX % rider_player_id + "interact"):
			dismount()
			return

		var input_dir := _get_rider_input()
		if input_dir.length() > 0.15:
			var direction := _input_to_camera_relative(input_dir)
			velocity = direction * speed
			_update_facing(input_dir.x)
			look_at(global_position + direction, Vector3.UP)
		else:
			velocity = Vector3.ZERO

		move_and_slide()

		# Binik oyuncuyu atın üzerinde tut
		if rider_node and is_instance_valid(rider_node):
			rider_node.global_position = global_position

## Player tarafından çağrılır — ata bindirir.
func mount_player(player: Node3D) -> bool:
	if rider_player_id >= 0:
		return false  # Zaten biri binmiş

	rider_node = player
	rider_player_id = player.get("player_id") as int
	_update_rider_texture()
	_apply_player_visibility(player, false)
	return true

## Oyuncuyu attan indirir.
func dismount() -> void:
	if not rider_node or not is_instance_valid(rider_node):
		rider_player_id = -1
		rider_node = null
		return

	var spawn_offset := global_transform.basis.x * 2.0
	rider_node.global_position = global_position + spawn_offset
	_apply_player_visibility(rider_node, true)

	rider_player_id = -1
	rider_node = null
	_update_rider_texture()

func _get_rider_input() -> Vector2:
	if rider_player_id < 0:
		return Vector2.ZERO
	var prefix := INPUT_PREFIX % rider_player_id
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
