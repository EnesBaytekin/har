extends CharacterBody3D

## Atın hareket hızı
@export var speed: float = 5.0
## Binme/inme için etkileşim mesafesi
@export var interaction_radius: float = 2.5
## Hareket yönüne göre sprite'ı flip et
@export var flip_on_move: bool = true

var rider_player_id: int = -1  # -1 = boş
var rider_node: Node3D = null
var _nearby_players: Array[Node] = []

const INPUT_PREFIX = "p%d_"

func _ready():
	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	if rider_player_id >= 0:
		# --- Binik hal: dismiss kontrolü ---
		if Input.is_action_just_pressed(INPUT_PREFIX % rider_player_id + "interact"):
			dismount()
			return

		var input_dir := _get_rider_input()
		if input_dir.length() > 0.15:
			var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
			velocity = direction * speed
			_update_facing(direction)
			look_at(global_position + direction, Vector3.UP)
		else:
			velocity = Vector3.ZERO
	else:
		# --- Boş hal: yakındaki oyunculardan binen var mı ---
		for player in _nearby_players:
			if not is_instance_valid(player):
				continue
			var pid := player.get("player_id") as int
			if pid >= 0 and Input.is_action_just_pressed(INPUT_PREFIX % pid + "interact"):
				mount(player)
				break

		velocity = Vector3.ZERO

	move_and_slide()

	# Binik oyuncuyu atın üzerinde tut
	if rider_node and is_instance_valid(rider_node):
		rider_node.global_position = global_position

func _get_rider_input() -> Vector2:
	if rider_player_id < 0:
		return Vector2.ZERO
	var prefix := INPUT_PREFIX % rider_player_id
	return Vector2(
		Input.get_axis(prefix + "move_left", prefix + "move_right"),
		Input.get_axis(prefix + "move_up", prefix + "move_down")
	)

func _update_facing(direction: Vector3) -> void:
	if not flip_on_move or direction.x == 0:
		return
	var sprite := $Sprite3D as Sprite3D
	if sprite:
		sprite.flip_h = direction.x < 0

func _on_body_entered(body: Node) -> void:
	if body == self:
		return
	if "player_id" in body and body not in _nearby_players:
		_nearby_players.append(body)

func _on_body_exited(body: Node) -> void:
	_nearby_players.erase(body)

## Oyuncuyu ata bindirir.
func mount(player: Node3D) -> bool:
	if rider_player_id >= 0:
		return false  # Zaten biri binmiş

	rider_node = player
	rider_player_id = player.get("player_id") as int

	# Oyuncu karakterini devre dışı bırak
	_apply_player_visibility(player, false)
	return true

## Oyuncuyu attan indirir.
func dismount() -> void:
	if not rider_node or not is_instance_valid(rider_node):
		rider_player_id = -1
		rider_node = null
		return

	# Oyuncuyu atın yanına (sağına) koy
	var spawn_offset := global_transform.basis.x * 2.0
	rider_node.global_position = global_position + spawn_offset

	# Oyuncuyu tekrar aktif et
	_apply_player_visibility(rider_node, true)

	rider_player_id = -1
	rider_node = null

func _apply_player_visibility(player: Node3D, visible: bool) -> void:
	player.visible = visible
	player.set_process(visible)
	player.set_physics_process(visible)

	# CollisionShape3D'yi bul ve disable/enable et
	for child in player.get_children():
		var cs := child as CollisionShape3D
		if cs:
			cs.disabled = not visible
