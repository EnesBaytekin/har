extends CharacterBody3D

## Takip edilecek hedef (atın NodePath'i)
@export var target_node: NodePath
## At ile araba arasındaki AZAMİ mesafe (çember yarıçapı)
@export var max_distance: float = 2.0
## Vagonun toparlanma hızı (yüksek = daha sert çekiş)
@export var follow_speed: float = 6.0

var _target: Node3D = null

func _ready():
	if target_node:
		_target = get_node(target_node) as Node3D

func _physics_process(delta: float) -> void:
	var horse := _target
	if not horse or not is_instance_valid(horse):
		return

	# At ile vagon arasındaki yatay uzaklık
	var offset := global_position - horse.global_position
	offset.y = 0
	var dist := offset.length()

	if dist > max_distance:
		# Çember dışına çıktı → atın etrafındaki çemberin kenarına çek
		var dir := offset.normalized()
		var target := horse.global_position + dir * max_distance
		target.y = global_position.y

		# Üstel yumuşak geçişle hedefe yaklaş
		var t := 1.0 - exp(-follow_speed * delta)
		var new_pos := global_position.lerp(target, t)

		velocity = (new_pos - global_position) / delta
	else:
		# Çember içinde → yavaşça dur
		velocity = velocity.lerp(Vector3.ZERO, 1.0 - exp(-10.0 * delta))

	move_and_slide()
