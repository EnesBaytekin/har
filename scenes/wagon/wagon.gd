extends CharacterBody3D

## Takip edilecek hedef (atın NodePath'i)
@export var target_node: NodePath
## At ile araba arasındaki ideal mesafe
@export var follow_distance: float = 1.5
## İzin verilen maksimum mesafe (bu aşılırsa araba hızla toparlanır)
@export var max_allowed_distance: float = 2.5
## Takip sertliği (yüksek = daha hızlı toparlanır)
@export var follow_stiffness: float = 4.0

var _target: Node3D = null

func _ready():
	if target_node:
		_target = get_node(target_node) as Node3D

func _physics_process(delta: float) -> void:
	var horse := _target
	if not horse or not is_instance_valid(horse):
		return

	# Atın arkasındaki ideal pozisyon
	# (at +Z yönü = arkası, çünkü look_at ile -Z baktığı yön)
	var ideal_pos := _calculate_ideal_position(horse)
	var displacement := ideal_pos - global_position
	var dist := displacement.length()

	if dist > _arrival_threshold():
		# displacement'i yatay düzleme izdüşüm
		displacement.y = 0
		var dir := displacement.normalized()
		# Mesafe arttıkça hız da artsın
		var speed := minf(follow_stiffness * 2.0, dist * follow_stiffness * delta * 8.0)
		velocity = dir * speed
		move_and_slide()
	else:
		velocity = Vector3.ZERO

func _calculate_ideal_position(horse: Node3D) -> Vector3:
	var behind := horse.global_transform.basis.z * follow_distance
	var pos := horse.global_position + behind
	pos.y = global_position.y  # kendi yüksekliğini koru
	return pos

func _arrival_threshold() -> float:
	return follow_distance * 0.1
