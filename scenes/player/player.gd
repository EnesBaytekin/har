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

# ItemType enum (dropped_item.gd ile aynı)
enum ItemType { NONE = -1, WOOD = 0, STONE = 1, COAL = 2 }

const INPUT_PREFIX = "p%d_"

const PLAYER_TEXTURES := {
	0: preload("res://assets/sprites/player1.png"),
	1: preload("res://assets/sprites/player2.png"),
	2: preload("res://assets/sprites/player3.png"),
	3: preload("res://assets/sprites/player4.png"),
}

const ITEM_TEXTURES := {
	ItemType.WOOD: preload("res://assets/sprites/item_wood.png"),
	ItemType.STONE: preload("res://assets/sprites/item_stone.png"),
	ItemType.COAL: preload("res://assets/sprites/item_coal.png"),
}

## Taşınan item türü (-1 = boş)
var carried_item_type: int = -1
var _nearby_items: Array[Node] = []

func _ready():
	_update_texture()
	$PickupArea.area_entered.connect(_on_pickup_area_entered)
	$PickupArea.area_exited.connect(_on_pickup_area_exited)

func _physics_process(_delta: float) -> void:
	var input_dir := _get_input()

	# Item alma/bırakma
	if Input.is_action_just_pressed(INPUT_PREFIX % player_id + "interact"):
		if carried_item_type >= 0:
			_drop_item()
		elif _nearby_items.size() > 0:
			_pickup_item()

	if input_dir.length() > 0.15:
		var direction := _input_to_camera_relative(input_dir)
		velocity = direction * speed
		_update_facing(input_dir.x)
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity = Vector3.ZERO

	move_and_slide()

func _update_texture():
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return
	if PLAYER_TEXTURES.has(player_id):
		sprite.texture = PLAYER_TEXTURES[player_id]

## Taşıma sprite'ını günceller.
func _update_carried_sprite():
	var cs := $CarriedItem as Sprite3D
	if not cs:
		return
	if carried_item_type >= 0 and ITEM_TEXTURES.has(carried_item_type):
		cs.texture = ITEM_TEXTURES[carried_item_type]
		cs.visible = true
	else:
		cs.visible = false

## Yerdeki en yakın item'ı alır.
func _pickup_item():
	if carried_item_type >= 0 or _nearby_items.size() == 0:
		return

	var nearest: DroppedItem = null
	var nearest_dist := 9999.0
	var pos := global_position
	for n in _nearby_items:
		if not is_instance_valid(n):
			continue
		var di := n as DroppedItem
		if not di:
			continue
		var d := pos.distance_squared_to(di.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = di

	if not nearest:
		return

	carried_item_type = nearest.item_type
	nearest.take()
	_update_carried_sprite()

## Taşınan item'ı yere bırakır.
func _drop_item():
	if carried_item_type < 0:
		return

	var scene := preload("res://scenes/item/dropped_item.tscn")
	var di := scene.instantiate() as DroppedItem
	di.item_type = carried_item_type
	di.global_position = global_position + global_transform.basis.x * 1.5

	get_tree().current_scene.add_child(di)

	carried_item_type = -1
	_update_carried_sprite()

func _on_pickup_area_entered(area: Area3D) -> void:
	var di := area.get_parent() as DroppedItem
	if di and di not in _nearby_items:
		_nearby_items.append(di)

func _on_pickup_area_exited(area: Area3D) -> void:
	var di := area.get_parent() as DroppedItem
	if di:
		_nearby_items.erase(di)

## Input yönünü kameranın bakış açısına göre dönüştürür.
func _input_to_camera_relative(input_dir: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return Vector3(input_dir.x, 0, input_dir.y).normalized()

	var forward := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	forward.y = 0
	right.y = 0

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
	var stick_x := Input.get_joy_axis(player_id, JOY_AXIS_LEFT_X)
	var stick_y := Input.get_joy_axis(player_id, JOY_AXIS_LEFT_Y)
	if abs(stick_x) > 0.15 or abs(stick_y) > 0.15:
		return Vector2(stick_x, stick_y)

	var prefix := INPUT_PREFIX % player_id
	return Vector2(
		Input.get_axis(prefix + "move_left", prefix + "move_right"),
		Input.get_axis(prefix + "move_up", prefix + "move_down")
	)
