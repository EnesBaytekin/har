extends CharacterBody3D

## Takip edilecek hedef (atın NodePath'i)
@export var target_node: NodePath
## At ile araba arasındaki AZAMİ mesafe (çember yarıçapı)
@export var max_distance: float = 2.0
## Vagonun toparlanma hızı (yüksek = daha sert çekiş)
@export var follow_speed: float = 6.0
## Ateş seviyesi (0=hiç yok, 4=maksimum)
@export var fire_level: int = 0:
	set(value):
		fire_level = clampi(value, 0, 4)
		_update_texture()
	get():
		return fire_level

const FIRE_TEXTURES := {
	0: preload("res://assets/sprites/wagon_fire_0.png"),
	1: preload("res://assets/sprites/wagon_fire_1.png"),
	2: preload("res://assets/sprites/wagon_fire_2.png"),
	3: preload("res://assets/sprites/wagon_fire_3.png"),
	4: preload("res://assets/sprites/wagon_fire_4.png"),
}

var _target: Node3D = null

func _ready():
	add_to_group("wagons")
	if target_node:
		_target = get_node(target_node) as Node3D
	_update_texture()

func get_fire_level() -> int:
	return fire_level

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := int(event.keycode)
		if key >= KEY_0 and key <= KEY_4:
			fire_level = key - KEY_0

func _update_texture():
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return
	if FIRE_TEXTURES.has(fire_level):
		sprite.texture = FIRE_TEXTURES[fire_level]

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
