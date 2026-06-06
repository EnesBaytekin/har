extends CharacterBody3D

## 0=Kömür var, 1=Kömür bitti taş kaldı, 2=Tamamen kazıldı
enum Stage { COAL, STONE, DEPLETED }

## Kaç vuruşta kömürün bittiği
@export var max_coal: int = 3
## Kaç vuruşta taşın bittiği
@export var max_stone: int = 3

var _stage: Stage = Stage.COAL
var _coal_left: int
var _stone_left: int

const DROPPED_ITEM = preload("res://scenes/item/dropped_item.tscn")

func _ready():
	_coal_left = max_coal
	_stone_left = max_stone
	_update_frame()

## Her state değişiminde çağrılır — coals.png'den row (stage) + random col
func _update_frame():
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return
	var row := int(_stage)  # COAL=0, STONE=1, DEPLETED=2
	var col := randi() % 2  # 0 veya 1 (rastgele varyasyon)
	sprite.frame = row * 2 + col  # hframes=2 olduğu için

## Player tarafından çağrılır — kayaya bir kazma vuruşu.
func hit(_hitter_id: int) -> void:
	if _stage == Stage.DEPLETED:
		return

	_shake()

	match _stage:
		Stage.COAL:
			_coal_left -= 1
			if _coal_left <= 0:
				_to_stone_stage()
		Stage.STONE:
			_stone_left -= 1
			if _stone_left <= 0:
				_to_depleted()

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

func _to_stone_stage() -> void:
	_stage = Stage.STONE
	_update_frame()
	_spawn_item(2)  # COAL

func _to_depleted() -> void:
	_stage = Stage.DEPLETED
	_update_frame()
	$CollisionShape3D.disabled = true
	_spawn_item(1)  # STONE

func _spawn_item(item_type: int) -> void:
	var di := DROPPED_ITEM.instantiate() as DroppedItem
	di.item_type = item_type
	di.global_position = global_position
	get_tree().current_scene.add_child(di)
