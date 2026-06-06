extends CharacterBody3D

## Ağacın toplam canı (kaç vuruşta kesileceği)
@export var max_health: int = 5
## Vuruş başına can kaybı
@export var damage_per_hit: int = 1

var health: int
var _chopped: bool = false
var _nearby_players: Array[Node] = []

const INPUT_PREFIX = "p%d_"
const DROPPED_ITEM = preload("res://scenes/item/dropped_item.tscn")

const ALIVE_TEXTURE := preload("res://assets/sprites/tree.png")
const CUT_TEXTURE := preload("res://assets/sprites/tree_cut.png")

func _ready():
	health = max_health
	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	if _chopped:
		return

	for player in _nearby_players:
		if not is_instance_valid(player):
			continue
		var pid := player.get("player_id") as int
		if pid >= 0 and Input.is_action_just_pressed(INPUT_PREFIX % pid + "interact"):
			_take_damage(pid)
			break

## Vuruş alındığında çağrılır.
func _take_damage(_hitter_id: int) -> void:
	if _chopped:
		return

	health -= damage_per_hit

	# Sarsılma efekti
	_shake()

	if health <= 0:
		_chop()

func _shake() -> void:
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return

	# Kısa bir sarsılma animasyonu
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	var orig_pos := sprite.position
	# Hafifçe sağa-sola salla
	tween.tween_property(sprite, "position:x", orig_pos.x + 0.15, 0.04)
	tween.tween_property(sprite, "position:x", orig_pos.x - 0.12, 0.04)
	tween.tween_property(sprite, "position:x", orig_pos.x + 0.08, 0.04)
	tween.tween_property(sprite, "position:x", orig_pos.x, 0.04)

func _chop() -> void:
	_chopped = true
	var sprite := $Sprite3D as Sprite3D
	if sprite:
		sprite.texture = CUT_TEXTURE
	# Collision'ı kaldır (içinden geçilebilir olsun)
	$CollisionShape3D.disabled = true
	# Odun düşür (ItemType.WOOD = 0)
	_spawn_item(0)

func _spawn_item(item_type: int) -> void:
	var di := DROPPED_ITEM.instantiate() as DroppedItem
	di.item_type = item_type
	di.global_position = global_position
	get_tree().current_scene.add_child(di)

func _on_body_entered(body: Node) -> void:
	if body == self:
		return
	if "player_id" in body and body not in _nearby_players:
		_nearby_players.append(body)

func _on_body_exited(body: Node) -> void:
	_nearby_players.erase(body)
