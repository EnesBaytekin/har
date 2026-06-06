extends CharacterBody3D

## Kaç vuruşta kömürün bittiği
@export var max_coal: int = 3
## Vuruş başına kömür azalması
@export var coal_per_hit: int = 1

var _coal_left: int
var _mined_out: bool = false
var _nearby_players: Array[Node] = []

const INPUT_PREFIX = "p%d_"

const COAL_TEXTURE := preload("res://assets/sprites/coal_rock.png")
const EMPTY_TEXTURE := preload("res://assets/sprites/rock.png")

func _ready():
	_coal_left = max_coal
	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	if _mined_out:
		return

	for player in _nearby_players:
		if not is_instance_valid(player):
			continue
		var pid := player.get("player_id") as int
		if pid >= 0 and Input.is_action_just_pressed(INPUT_PREFIX % pid + "interact"):
			_mine(pid)
			break

func _mine(_hitter_id: int) -> void:
	if _mined_out:
		return

	_coal_left -= coal_per_hit
	_shake()

	if _coal_left <= 0:
		_exhaust()

func _shake() -> void:
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	var orig_pos := sprite.position
	tween.tween_property(sprite, "position:x", orig_pos.x + 0.12, 0.03)
	tween.tween_property(sprite, "position:x", orig_pos.x - 0.10, 0.03)
	tween.tween_property(sprite, "position:x", orig_pos.x + 0.06, 0.03)
	tween.tween_property(sprite, "position:x", orig_pos.x, 0.03)

func _exhaust() -> void:
	_mined_out = true
	var sprite := $Sprite3D as Sprite3D
	if sprite:
		sprite.texture = EMPTY_TEXTURE
	# Kaya kendisi kalsın, collision devam etsin (engel olarak)

func _on_body_entered(body: Node) -> void:
	if body == self:
		return
	if "player_id" in body and body not in _nearby_players:
		_nearby_players.append(body)

func _on_body_exited(body: Node) -> void:
	_nearby_players.erase(body)
