extends Node3D

@export var point_a: NodePath
@export var point_b: NodePath
@export var rope_thickness: float = 0.06

var _mesh_instance: MeshInstance3D = null
var _box_mesh: BoxMesh = null
var _material: StandardMaterial3D = null

func _ready():
	_mesh_instance = MeshInstance3D.new()
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.29, 0.16, 0.06)
	_material.roughness = 0.9
	_box_mesh = BoxMesh.new()
	_box_mesh.material = _material
	_mesh_instance.mesh = _box_mesh
	add_child(_mesh_instance)

func _process(_delta: float) -> void:
	var a := get_node_or_null(point_a) as Node3D
	var b := get_node_or_null(point_b) as Node3D
	if not a or not b:
		return

	var a_pos := a.global_position
	var b_pos := b.global_position
	var mid := (a_pos + b_pos) * 0.5
	mid.y = 0.25
	global_position = mid

	var dir := b_pos - a_pos
	var dist := dir.length()
	dir.y = 0
	if dist < 0.01:
		return

	_box_mesh.size = Vector3(rope_thickness, rope_thickness, dist)

	if dir.length_squared() > 0.001:
		look_at(global_position + dir.normalized(), Vector3.UP)
