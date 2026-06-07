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
@export var flip_on_move: bool = true
## Maksimum can
@export var max_health: int = 5

enum ItemType { NONE = -1, WOOD = 0, STONE = 1, COAL = 2, APPLE = 3 }

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
	ItemType.APPLE: preload("res://assets/sprites/item_apple.png"),
}

var _pickaxe_texture: Texture2D = null

var carried_item_type: int = -1
var _nearby_items: Array[Node] = []
var _nearby_interactables: Array[Node] = []

var _anim_time: float = 0.0
const ANIM_SPEED: float = 10.0
var _is_pickaxing: bool = false
var _normal_texture: Texture2D = null

## Can sistemi
var health: int = 5
var _invincible_timer: float = 0.0
const INVINCIBLE_TIME: float = 1.0


func _ready():
	health = max_health
	_update_texture()
	_update_health_bar()
	add_to_group("players")
	$PickupArea.area_entered.connect(_on_item_area_entered)
	$PickupArea.area_exited.connect(_on_item_area_exited)
	$InteractArea.body_entered.connect(_on_interact_body_entered)
	$InteractArea.body_exited.connect(_on_interact_body_exited)

func _process(delta: float) -> void:
	_invincible_timer = maxf(_invincible_timer - delta, 0.0)

	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return

	if _is_pickaxing:
		return

	if velocity.length_squared() > 0.01:
		_anim_time += delta * ANIM_SPEED
		sprite.frame = int(_anim_time) % 4
	else:
		_anim_time = 0.0
		sprite.frame = 0

func _physics_process(_delta: float) -> void:
	var input_dir := _get_input()
	var prefix := INPUT_PREFIX % player_id

	# X / E / Gamepad X: Item al/bırak
	if Input.is_action_just_pressed(prefix + "item"):
		if carried_item_type >= 0:
			_drop_item()
		elif _nearby_items.size() > 0:
			_pickup_item()

	# A / F / Gamepad A: Kullan/Vur
	if Input.is_action_just_pressed(prefix + "interact"):
		_do_use()

	# B / R / Gamepad B: Ata bin/in
	if Input.is_action_just_pressed(prefix + "mount"):
		for n in _nearby_interactables:
			if not is_instance_valid(n):
				continue
			if n.has_method("mount_player"):
				n.mount_player(self)
				return

	if input_dir.length() > 0.15:
		var direction := _input_to_camera_relative(input_dir)
		velocity = direction * speed
		_update_facing(input_dir.x)
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity = Vector3.ZERO

	move_and_slide()

## A tuşu: Eldeki item'ı kullan, boşsa vur/kaz.
func _do_use():
	if carried_item_type >= 0:
		# Odun/kömür varsa önce ateşe atmayı dene
		if carried_item_type == ItemType.WOOD or carried_item_type == ItemType.COAL:
			if _try_feed_fire():
				return
		if carried_item_type == ItemType.STONE:
			_throw_stone()
		elif carried_item_type == ItemType.APPLE:
			_try_feed_horse()
		return

	# Elde item yoksa vur/kaz
	for n in _nearby_interactables:
		if not is_instance_valid(n):
			continue
		if n.has_method("hit"):
			n.hit(player_id)
			_play_pickaxe_anim()
			return

## Yakındaki wagon'un ateşine odun/kömür atar.
func _try_feed_fire() -> bool:
	if carried_item_type != ItemType.WOOD and carried_item_type != ItemType.COAL:
		return false
	for n in _nearby_interactables:
		if not is_instance_valid(n):
			continue
		if n.has_method("add_fuel"):
			var d := global_position.distance_squared_to(n.global_position)
			if d < 12.0:
				var amount := 0.5 if carried_item_type == ItemType.WOOD else 1.0
				n.add_fuel(amount)
				carried_item_type = -1
				_update_carried_sprite()
				return true
	return false

## Taşı fırlat
func _throw_stone():
	if carried_item_type != ItemType.STONE:
		return
	carried_item_type = -1
	_update_carried_sprite()
	var dir := -global_transform.basis.z
	dir.y = 0
	if dir.length_squared() < 0.001:
		dir = Vector3.FORWARD
	dir = dir.normalized()
	var stone_scene := preload("res://scenes/item/thrown_stone.tscn")
	var stone := stone_scene.instantiate()
	stone.global_position = global_position + dir * 0.5 + Vector3.UP * 0.3
	stone.linear_velocity = dir * 8.0 + Vector3.UP * 1.0
	get_tree().current_scene.add_child(stone)

## Yakındaki ata elma yedirir.
func _try_feed_horse():
	if carried_item_type != ItemType.APPLE:
		return
	for n in _nearby_interactables:
		if not is_instance_valid(n):
			continue
		if n.has_method("feed"):
			var d := global_position.distance_squared_to(n.global_position)
			if d < 9.0:
				n.feed(40.0)
				carried_item_type = -1
				_update_carried_sprite()
				return

func _update_health_bar():
	var fill := $HealthBarFill as Sprite3D
	if not fill:
		return
	var ratio := float(health) / float(max_health)
	var w := ratio * 64.0
	fill.region_rect.size.x = w
	fill.offset.x = (64.0 - w) / -2.0

func take_damage(amount: int) -> void:
	if _invincible_timer > 0:
		return
	_invincible_timer = INVINCIBLE_TIME
	health -= amount
	if health <= 0:
		health = 0
		health = max_health
	_update_health_bar()
	var sprite := $Sprite3D as Sprite3D
	if sprite:
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		var orig := sprite.position.x
		tween.tween_property(sprite, "position:x", orig + 0.2, 0.04)
		tween.tween_property(sprite, "position:x", orig - 0.15, 0.04)
		tween.tween_property(sprite, "position:x", orig, 0.04)

func _update_texture():
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return
	if PLAYER_TEXTURES.has(player_id):
		sprite.texture = PLAYER_TEXTURES[player_id]

func _update_carried_sprite():
	var cs := $CarriedItem as Sprite3D
	if not cs:
		return
	if carried_item_type >= 0 and ITEM_TEXTURES.has(carried_item_type):
		cs.texture = ITEM_TEXTURES[carried_item_type]
		cs.visible = true
	else:
		cs.visible = false

func _play_pickaxe_anim():
	if _is_pickaxing:
		return
	_is_pickaxing = true
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		_is_pickaxing = false
		return
	if not _pickaxe_texture:
		_pickaxe_texture = load("res://assets/sprites/player_pickaxe.png")
	if not _pickaxe_texture:
		_is_pickaxing = false
		return
	_normal_texture = sprite.texture
	sprite.texture = _pickaxe_texture
	sprite.hframes = 2
	sprite.frame = 0
	var tween := create_tween()
	tween.tween_interval(0.08)
	tween.tween_callback(func():
		if is_instance_valid(sprite):
			sprite.frame = 1
	)
	tween.tween_interval(0.08)
	tween.tween_callback(_revert_texture)

func _revert_texture():
	var sprite := $Sprite3D as Sprite3D
	if not sprite or not is_instance_valid(sprite):
		_is_pickaxing = false
		_normal_texture = null
		return
	sprite.texture = _normal_texture if _normal_texture else PLAYER_TEXTURES.get(player_id, null)
	if sprite.texture:
		sprite.hframes = 4
	sprite.frame = 0
	_is_pickaxing = false
	_normal_texture = null

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

func _drop_item():
	if carried_item_type < 0:
		return
	var scene := preload("res://scenes/item/dropped_item.tscn")
	var di := scene.instantiate() as DroppedItem
	di.item_type = carried_item_type
	di.global_position = global_position
	get_tree().current_scene.add_child(di)
	carried_item_type = -1
	_update_carried_sprite()

# --- Signal handlers ---

func _on_item_area_entered(area: Area3D) -> void:
	var di := area.get_parent() as DroppedItem
	if di and di not in _nearby_items:
		_nearby_items.append(di)

func _on_item_area_exited(area: Area3D) -> void:
	var di := area.get_parent() as DroppedItem
	if di:
		_nearby_items.erase(di)

func _on_interact_body_entered(body: Node) -> void:
	if body == self:
		return
	if body not in _nearby_interactables:
		_nearby_interactables.append(body)

func _on_interact_body_exited(body: Node) -> void:
	_nearby_interactables.erase(body)

# --- Input helpers ---

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
	return (forward.normalized() * -input_dir.y + right.normalized() * input_dir.x).normalized()

func _update_facing(input_x: float) -> void:
	if not flip_on_move or input_x == 0:
		return
	var sprite := $Sprite3D as Sprite3D
	if sprite:
		sprite.flip_h = input_x < 0

func _get_input() -> Vector2:
	# Gamepad left stick (öncelikli)
	var stick_x := Input.get_joy_axis(player_id, JOY_AXIS_LEFT_X)
	var stick_y := Input.get_joy_axis(player_id, JOY_AXIS_LEFT_Y)
	if abs(stick_x) > 0.15 or abs(stick_y) > 0.15:
		return Vector2(stick_x, stick_y)

	# Gamepad D-pad (buton olarak)
	var dpad_x := -1.0 if Input.is_joy_button_pressed(player_id, JOY_BUTTON_DPAD_LEFT) else (1.0 if Input.is_joy_button_pressed(player_id, JOY_BUTTON_DPAD_RIGHT) else 0.0)
	var dpad_y := -1.0 if Input.is_joy_button_pressed(player_id, JOY_BUTTON_DPAD_UP) else (1.0 if Input.is_joy_button_pressed(player_id, JOY_BUTTON_DPAD_DOWN) else 0.0)
	if dpad_x != 0.0 or dpad_y != 0.0:
		return Vector2(dpad_x, dpad_y)

	# Klavye
	var prefix := INPUT_PREFIX % player_id
	return Vector2(
		Input.get_axis(prefix + "move_left", prefix + "move_right"),
		Input.get_axis(prefix + "move_up", prefix + "move_down")
	)
