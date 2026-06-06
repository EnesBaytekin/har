extends CharacterBody3D

## Ağacın toplam canı (kaç vuruşta kesileceği)
@export var max_health: int = 5
## Vuruş başına can kaybı
@export var damage_per_hit: int = 1

var health: int
var _chopped: bool = false

const DROPPED_ITEM = preload("res://scenes/item/dropped_item.tscn")

const ALIVE_TEXTURE := preload("res://assets/sprites/tree.png")
const CUT_TEXTURE := preload("res://assets/sprites/tree_cut.png")

func _ready():
	health = max_health

## Player tarafından çağrılır — ağaca bir vuruş.
func hit(_hitter_id: int) -> void:
	if _chopped:
		return

	health -= damage_per_hit
	_shake()

	# Her vuruşta %12 şansla elma düşsün
	if randf() < 0.12:
		_spawn_item(3)  # ItemType.APPLE

	if health <= 0:
		_chop()

func _shake() -> void:
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	var orig_pos := sprite.position
	tween.tween_property(sprite, "position:x", orig_pos.x + 0.15, 0.04)
	tween.tween_property(sprite, "position:x", orig_pos.x - 0.12, 0.04)
	tween.tween_property(sprite, "position:x", orig_pos.x + 0.08, 0.04)
	tween.tween_property(sprite, "position:x", orig_pos.x, 0.04)

func _chop() -> void:
	_chopped = true
	var sprite := $Sprite3D as Sprite3D
	if sprite:
		sprite.texture = CUT_TEXTURE
	$CollisionShape3D.disabled = true
	_spawn_item(0)  # ItemType.WOOD

func _spawn_item(item_type: int) -> void:
	var di := DROPPED_ITEM.instantiate() as DroppedItem
	di.item_type = item_type
	di.global_position = global_position
	get_tree().current_scene.add_child(di)
