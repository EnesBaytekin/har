extends Node3D
class_name DroppedItem

## Item türleri
enum ItemType { NONE = -1, WOOD = 0, STONE = 1, COAL = 2, APPLE = 3, RAW_MEAT = 4, COOKED_MEAT = 5 }

## Bu dropped item'ın türü
@export var item_type: ItemType = ItemType.WOOD:
	set(value):
		item_type = value
		_update_texture()
	get():
		return item_type

const ITEM_TEXTURES := {
	ItemType.WOOD: preload("res://assets/sprites/item_wood.png"),
	ItemType.STONE: preload("res://assets/sprites/item_stone.png"),
	ItemType.COAL: preload("res://assets/sprites/item_coal.png"),
	ItemType.APPLE: preload("res://assets/sprites/item_apple.png"),
	ItemType.RAW_MEAT: preload("res://assets/sprites/item_meat_raw.png"),
	ItemType.COOKED_MEAT: preload("res://assets/sprites/item_meat_cooked.png"),
}

func _ready():
	_update_texture()

func _update_texture():
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return
	if ITEM_TEXTURES.has(item_type):
		sprite.texture = ITEM_TEXTURES[item_type]

## Bu item'ı yok eder (alındığında çağrılır).
func take() -> void:
	queue_free()
