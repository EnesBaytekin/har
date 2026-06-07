extends CharacterBody3D

## Hareket hızı
@export var speed: float = 5.0
## Maksimum can
@export var max_health: int = 100
## Saldırı hasarı
@export var damage: int = 20
## Saldırı mesafesi
@export var attack_range: float = 1.8
## Geri çekilme mesafesi
@export var retreat_distance: float = 4.0
## Ayı tespit mesafesi
@export var detection_range: float = 12.0

enum State { IDLE, HOWLING, PATROL, CHASING_BEAR, ATTACKING, RETREATING }

var _state: State = State.IDLE
var _state_timer: float = 0.0
var _attack_timer: float = 0.0
var _anim_time: float = 0.0
var _target_bear: Node3D = null
var _last_hit_pos: Vector3 = Vector3.ZERO
var _howl_cooldown: float = 0.0
var _patrol_target: Vector3 = Vector3.ZERO
var health: int = 100

const ANIM_SPEED: float = 12.0

func _ready():
	add_to_group("wolves")
	health = max_health
	$Sprite3D.texture = load("res://assets/sprites/wolf.png")
	$Sprite3D.hframes = 4
	_update_health_bar()
	_state = State.IDLE
	_state_timer = 2.0 + randf() * 3.0

func _process(delta: float) -> void:
	_howl_cooldown -= delta
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return
	if _state == State.ATTACKING or _state == State.HOWLING:
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
	_target_bear = _find_nearest_bear()

	match _state:
		State.IDLE:
			velocity = Vector3.ZERO
			if _state_timer <= 0:
				if _target_bear and global_position.distance_to(_target_bear.global_position) < detection_range:
					_state = State.CHASING_BEAR
				elif _howl_cooldown <= 0:
					_state = State.HOWLING
					_state_timer = 1.5
					SFXManager.play_sfx("wolf_au")
					var s := $Sprite3D as Sprite3D
					if s:
						s.texture = load("res://assets/sprites/wolf-au.png")
						s.hframes = 1
						s.frame = 0
				else:
					_state = State.PATROL
					_state_timer = 1.5 + randf() * 2.0
					_patrol_target = global_position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))

		State.HOWLING:
			velocity = Vector3.ZERO
			if _state_timer <= 0:
				var s := $Sprite3D as Sprite3D
				if s:
					s.texture = load("res://assets/sprites/wolf.png")
					s.hframes = 4
				_state = State.IDLE
				_state_timer = 4.0 + randf() * 6.0
				_howl_cooldown = 15.0

		State.PATROL:
			var dir := _patrol_target - global_position
			dir.y = 0
			if dir.length() > 0.5:
				velocity = dir.normalized() * speed * 0.5
				_update_facing(dir.normalized())
			else:
				velocity = Vector3.ZERO
			if _state_timer <= 0:
				_state = State.IDLE
				_state_timer = 2.0 + randf() * 4.0
			if _target_bear and global_position.distance_to(_target_bear.global_position) < detection_range:
				_state = State.CHASING_BEAR

		State.CHASING_BEAR:
			if _target_bear and is_instance_valid(_target_bear):
				var dir := (_target_bear.global_position - global_position)
				dir.y = 0
				var dist := dir.length()
				if dist > attack_range:
					velocity = dir.normalized() * speed
					_update_facing(dir.normalized())
				else:
					velocity = Vector3.ZERO
					_state = State.ATTACKING
					_state_timer = 2.0
			else:
				_state = State.IDLE
				_state_timer = 1.0

		State.ATTACKING:
			velocity = Vector3.ZERO
			if _attack_timer <= 0 and _target_bear and is_instance_valid(_target_bear):
				var dist := global_position.distance_to(_target_bear.global_position)
				if dist < attack_range * 2.0:
					if _target_bear.has_method("take_damage"):
						_target_bear.take_damage(damage)
					_attack_timer = 1.0
					_state = State.RETREATING
					_state_timer = 1.0
					_last_hit_pos = _target_bear.global_position
			if _state_timer <= 0:
				_state = State.RETREATING
				_state_timer = 1.0

		State.RETREATING:
			var away := global_position - _last_hit_pos
			away.y = 0
			if away.length() < retreat_distance and _target_bear and is_instance_valid(_target_bear):
				var dir = away.normalized()
				velocity = dir * speed * 1.3
				_update_facing(dir)
			else:
				velocity = Vector3.ZERO
				if _state_timer <= 0:
					_state = State.CHASING_BEAR

	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	_update_health_bar()
	if health <= 0:
		queue_free()

func _update_facing(dir: Vector3) -> void:
	var sprite := $Sprite3D as Sprite3D
	if not sprite or dir.x == 0:
		return
	sprite.flip_h = dir.x < 0

func _update_health_bar():
	var fill := $HealthBarFill as Sprite3D
	if not fill:
		return
	var ratio := float(health) / float(max_health)
	var w := ratio * 64.0
	fill.region_rect.size.x = w
	fill.offset.x = (64.0 - w) / -2.0

func _find_nearest_bear() -> Node3D:
	var best: Node3D = null
	var best_dist := INF
	for n in get_tree().get_nodes_in_group(&"bears"):
		if not is_instance_valid(n):
			continue
		var d := global_position.distance_squared_to(n.global_position)
		if d < best_dist:
			best_dist = d
			best = n
	return best
