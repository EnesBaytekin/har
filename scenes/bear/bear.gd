extends CharacterBody3D

## Hareket hızı (koşarken)
@export var speed: float = 3.0
## Enrage hızı (taş çarpınca)
@export var enrage_speed: float = 6.0
## Yorulunca bekleme süresi (saniye)
@export var rest_time: float = 3.0
## Koşma süresi (saniye)
@export var chase_time: float = 5.0
## Oyuncuya ne kadar yaklaşınca hasar verir
@export var attack_range: float = 1.0
## Hasar verme aralığı (saniye)
@export var attack_cooldown: float = 1.5
## Ateşten kaçma taban mesafesi (fire_level=4 için)
@export var fire_fear_base: float = 2.0
## Maksimum can
@export var max_health: int = 100
## Hasar miktarı
@export var damage: int = 1
## Kurtlara verilen hasar (oyuncudan farklı)
@export var wolf_damage: int = 25
## Taş dikkat dağıtma süresi
@export var investigate_time: float = 4.0
## Enrage süresi
@export var enrage_time: float = 6.0

enum State { IDLE, CHASING, RESTING, FLEEING, INVESTIGATING, ENRAGED }

var _state: State = State.IDLE
var _state_timer: float = 0.0
var _attack_timer: float = 0.0
var _anim_time: float = 0.0
var _target: Node3D = null
var _nearest_fire: Node3D = null
var _investigate_target: Vector3 = Vector3.ZERO
var _enrage_target: Node3D = null
var _current_speed: float = 3.0
var health: int = 10

const ANIM_SPEED: float = 10.0
const BEAR_TEXTURE := preload("res://assets/sprites/bear.png")

func _ready():
	add_to_group("bears")
	health = max_health
	_update_health_bar()
	$Sprite3D.texture = BEAR_TEXTURE
	$Sprite3D.hframes = 4
	_current_speed = speed
	_state = State.IDLE
	_state_timer = 1.0

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

	_target = _find_nearest_target()
	_nearest_fire = _find_nearest_fire()

	var fear_radius := _get_fire_fear_radius()
	if _nearest_fire and global_position.distance_to(_nearest_fire.global_position) < fear_radius:
		if _state != State.ENRAGED:
			_state = State.FLEEING

	match _state:
		State.IDLE:
			velocity = Vector3.ZERO
			if _state_timer <= 0 and _target:
				_state = State.CHASING
				_state_timer = chase_time
				_current_speed = speed

		State.CHASING:
			if _target:
				var dir := (_target.global_position - global_position)
				dir.y = 0
				var dist := dir.length()
				if dist > attack_range:
					velocity = dir.normalized() * _current_speed
					_update_facing(dir.normalized())
				else:
					velocity = Vector3.ZERO

				if dist < attack_range and _attack_timer <= 0:
					if _target.has_method("take_damage") and is_instance_valid(_target):
						print("Bear attacks! dist=", dist, " damage=", damage)
						var dmg := damage
						if _target.is_in_group(&"wolves"):
							dmg = wolf_damage
						_target.take_damage(dmg)
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
				_current_speed = speed

		State.FLEEING:
			if _nearest_fire:
				var away := global_position - _nearest_fire.global_position
				away.y = 0
				if away.length_squared() > 0.1:
					velocity = away.normalized() * _current_speed
					_update_facing(away.normalized())
				else:
					velocity = Vector3.ZERO
				if away.length() > fear_radius * 2.0:
					_state = State.IDLE
					_state_timer = 1.0
			else:
				_state = State.IDLE
				_state_timer = 1.0

		State.INVESTIGATING:
			if _target:
				var to_player := _target.global_position - global_position
				to_player.y = 0
				var dist_sq := to_player.length_squared()
				if dist_sq < 25.0:
					var player_vel := Vector3.ZERO
					if _target.has_method(&"get_velocity"):
						player_vel = _target.get_velocity()
					if player_vel.length_squared() > 0.5:
						var moving_toward := player_vel.normalized().dot(to_player.normalized()) > 0.3
						if moving_toward:
							_state = State.CHASING
							_state_timer = chase_time
							_current_speed = speed

			var to_target := _investigate_target - global_position
			to_target.y = 0
			if to_target.length() > 0.5:
				velocity = to_target.normalized() * speed * 0.7
				_update_facing(to_target.normalized())
			else:
				velocity = Vector3.ZERO

			if _state_timer <= 0:
				_state = State.IDLE
				_state_timer = 1.0

		State.ENRAGED:
			if _enrage_target and is_instance_valid(_enrage_target):
				var dir := (_enrage_target.global_position - global_position)
				dir.y = 0
				var dist := dir.length()
				if dist > 0.5:
					velocity = dir.normalized() * _current_speed
					_update_facing(dir.normalized())
				else:
					velocity = Vector3.ZERO

				if dist < attack_range and _attack_timer <= 0:
					if _enrage_target.has_method("take_damage"):
						_enrage_target.take_damage(damage)
					_attack_timer = attack_cooldown * 0.7
			else:
				velocity = Vector3.ZERO

			if _state_timer <= 0:
				_state = State.CHASING
				_state_timer = chase_time
				_current_speed = speed

	move_and_slide()

func _get_fire_fear_radius() -> float:
	if not _nearest_fire or not _nearest_fire.has_method("get_fire_level"):
		return 0.0
	var level = int(_nearest_fire.get_fire_level())
	match level:
		4: return 2.5
		3: return 1.8
		2: return 1.2
		1: return 0.6
		_: return 0.0

func bear_notice_stone(pos: Vector3) -> void:
	if _state == State.ENRAGED:
		return
	_state = State.INVESTIGATING
	_investigate_target = pos
	_state_timer = investigate_time
	_current_speed = speed

## Oyuncu tarafından vuruldu — can azalır.
func hit(_hitter_id: int) -> void:
	health -= 1
	_update_health_bar()
	if health <= 0:
		queue_free()
		return
	if _state == State.INVESTIGATING or _state == State.IDLE:
		_state = State.CHASING
		_state_timer = chase_time
		_current_speed = speed

## Kurtlardan hasar al.
func take_damage(amount: int) -> void:
	health -= amount
	_update_health_bar()
	if health <= 0:
		queue_free()
		return
	# Kurt saldırırsa kovala
	_state = State.CHASING
	_state_timer = chase_time
	_current_speed = speed

func bear_hit_by_stone() -> void:
	_state = State.ENRAGED
	_state_timer = enrage_time
	_current_speed = enrage_speed
	_enrage_target = _find_nearest_target()

func _update_facing(dir: Vector3) -> void:
	var sprite := $Sprite3D as Sprite3D
	if not sprite or dir.x == 0:
		return
	sprite.flip_h = dir.x < 0

## Can bar'ını günceller.
func _update_health_bar():
	var fill := $HealthBarFill as Sprite3D
	if not fill:
		return
	var ratio := float(health) / float(max_health)
	var w := ratio * 64.0
	fill.region_rect.size.x = w
	fill.offset.x = (64.0 - w) / -2.0

func _find_nearest_target() -> Node3D:
	var best: Node3D = null
	var best_dist := INF
	for n in get_tree().get_nodes_in_group(&"players"):
		if not is_instance_valid(n):
			continue
		var d := global_position.distance_squared_to(n.global_position)
		if d < best_dist:
			best_dist = d
			best = n
	for n in get_tree().get_nodes_in_group(&"wolves"):
		if not is_instance_valid(n):
			continue
		var d := global_position.distance_squared_to(n.global_position)
		if d < best_dist:
			best_dist = d
			best = n
	return best

func _find_nearest_fire() -> Node3D:
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
