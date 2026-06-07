extends Node3D

## Ağaç sayısı
@export var tree_count: int = 300
## Kaya sayısı
@export var rock_count: int = 200
## Ayı spawn aralığı (saniye)
@export var bear_interval_min: float = 20.0
@export var bear_interval_max: float = 30.0
## Kurt spawn aralığı (saniye)
@export var wolf_interval_min: float = 15.0
@export var wolf_interval_max: float = 25.0
## Oyuncudan spawn mesafesi
@export var spawn_distance: float = 20.0
## Dünya sınırı
@export var world_half: float = 125.0

const TREE = preload("res://scenes/tree/tree.tscn")
const ROCK = preload("res://scenes/rock/rock.tscn")
const BEAR = preload("res://scenes/bear/bear.tscn")
const WOLF = preload("res://scenes/wolf/wolf.tscn")

var _bear_timer: float = 0.0
var _wolf_timer: float = 0.0

func _ready():
	randomize()

	# Target'ı rastgele bir yönde 110 birim uzağa koy
	var target := get_node("Target") as Node3D
	if target:
		var angle := randf() * TAU
		target.position = Vector3(cos(angle) * 110.0, 0, sin(angle) * 110.0)

	# Ağaçlar
	var trees_node := Node3D.new()
	trees_node.name = "Trees"
	add_child(trees_node)
	for i in tree_count:
		var t := TREE.instantiate()
		t.position = _rand_pos(3.0)
		trees_node.add_child(t)

	# Kayalar
	var rocks_node := Node3D.new()
	rocks_node.name = "Rocks"
	add_child(rocks_node)
	for i in rock_count:
		var r := ROCK.instantiate()
		r.position = _rand_pos(3.0)
		rocks_node.add_child(r)

	_bear_timer = randf_range(bear_interval_min, bear_interval_max)
	_wolf_timer = randf_range(wolf_interval_min, wolf_interval_max)

func _rand_pos(margin: float) -> Vector3:
	var x := randf_range(-world_half + margin, world_half - margin)
	var z := randf_range(-world_half + margin, world_half - margin)
	return Vector3(x, 0, z)

func _process(delta: float) -> void:
	_bear_timer -= delta
	_wolf_timer -= delta

	if _bear_timer <= 0:
		_bear_timer = randf_range(bear_interval_min, bear_interval_max)
		_spawn(BEAR)

	if _wolf_timer <= 0:
		_wolf_timer = randf_range(wolf_interval_min, wolf_interval_max)
		_spawn(WOLF)

func _spawn(scene: PackedScene):
	var player := _get_random_player()
	if not player:
		return
	var pos := _get_spawn_pos(player.global_position)
	if pos == Vector3.ZERO:
		return
	var inst := scene.instantiate()
	inst.position = pos
	get_tree().current_scene.add_child(inst)

func _get_spawn_pos(center: Vector3) -> Vector3:
	for attempt in 20:
		var angle := randf() * TAU
		var x := center.x + cos(angle) * spawn_distance
		var z := center.z + sin(angle) * spawn_distance
		if abs(x) < world_half and abs(z) < world_half:
			return Vector3(x, 0.5, z)
	return Vector3.ZERO

func _get_random_player() -> Node3D:
	var all := get_tree().get_nodes_in_group("players")
	if all.is_empty():
		return null
	return all[randi() % all.size()] as Node3D
