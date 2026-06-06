extends CharacterBody3D

## Hareket hızı (koşarken)
@export var speed: float = 3.0
## Yorulunca bekleme süresi (saniye)
@export var rest_time: float = 3.0
## Koşma süresi (saniye)
@export var chase_time: float = 5.0
## Oyuncuya ne kadar yaklaşınca hasar verir
@export var attack_range: float = 1.5
## Hasar verme aralığı (saniye)
@export var attack_cooldown: float = 1.5
## Ateşten kaçma mesafesi
@export var fire_fear_range: float = 5.0
## Hasar miktarı
@export var damage: int = 1

enum State { IDLE, CHASING, RESTING, FLEEING }

var _state: State = State.IDLE
var _state_timer: float = 0.0
var _attack_timer: float = 0.0
var _anim_time: float = 0.0
var _target: Node3D = null
var _nearest_fire: Node3D = null

const ANIM_SPEED: float = 10.0
const BEAR_TEXTURE := preload("res://assets/sprites/bear.png")

func _ready():
	$Sprite3D.texture = BEAR_TEXTURE
	$Sprite3D.hframes = 4
	_state = State.IDLE
	_state_timer = 1.0  # 1 saniye bekle sonra kovalamaya başla

func _process(delta: float) -> void:
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return

	if velocity.length_squared() > 0.5:
		_anim_time += delta * ANIM_SPEED
		sprite.frame = int(_anim_time) % 4
	else:
		_anim_time = 0.0
		sprite.frame = 0

func _physics_process(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_state_timer -= delta

	# En yakın oyuncuyu ve ateşi bul
	_target = _find_nearest_player()
	_nearest_fire = _find_nearest_fire()

	# Ateşe çok yaklaştıysak kaç
	if _nearest_fire and global_position.distance_to(_nearest_fire.global_position) < fire_fear_range:
		_state = State.FLEEING

	match _state:
		State.IDLE:
			velocity = Vector3.ZERO
			if _state_timer <= 0 and _target:
				_state = State.CHASING
				_state_timer = chase_time

		State.CHASING:
			if _target:
				var dir := (_target.global_position - global_position)
				dir.y = 0
				var dist := dir.length()
				if dist > 0.5:
					velocity = dir.normalized() * speed
					_update_facing(dir.normalized())
				else:
					velocity = Vector3.ZERO

				# Hasar ver
				if dist < attack_range and _attack_timer <= 0:
					if _target.has_method("take_damage"):
						_target.take_damage(damage)
					_attack_timer = attack_cooldown
			else:
				velocity = Vector3.ZERO

			if _state_timer <= 0:
				_state = State.RESTING
				_state_timer = rest_time
				velocity = Vector3.ZERO

		State.RESTING:
			velocity = Vector3.ZERO
			if _state_timer <= 0:
				_state = State.CHASING
				_state_timer = chase_time

		State.FLEEING:
			if _nearest_fire:
				var away := global_position - _nearest_fire.global_position
				away.y = 0
				if away.length_squared() > 0.1:
					velocity = away.normalized() * speed
					_update_facing(away.normalized())
				else:
					velocity = Vector3.ZERO
				# Yeterince uzaklaştıysak normal state'e dön
				if away.length() > fire_fear_range * 1.5:
					_state = State.IDLE
					_state_timer = 1.0
			else:
				_state = State.IDLE
				_state_timer = 1.0

	move_and_slide()

func _update_facing(dir: Vector3) -> void:
	var sprite := $Sprite3D as Sprite3D
	if not sprite or dir.x == 0:
		return
	sprite.flip_h = dir.x < 0

func _find_nearest_player() -> Node3D:
	var best: Node3D = null
	var best_dist := INF
	for n in get_tree().get_nodes_in_group(&"players"):
		if not is_instance_valid(n):
			continue
		var d := global_position.distance_squared_to(n.global_position)
		if d < best_dist:
			best_dist = d
			best = n
	return best

func _find_nearest_fire() -> Node3D:
	# Wagon'ların fire_level'ına bakarız
	var best: Node3D = null
	var best_dist := INF
	var all := get_tree().get_nodes_in_group("wagons")
	for n in all:
		if not is_instance_valid(n) or not n.has_method("get_fire_level"):
			continue
		if n.get_fire_level() <= 0:
			continue
		var d := global_position.distance_squared_to(n.global_position)
		if d < best_dist:
			best_dist = d
			best = n
	return best
