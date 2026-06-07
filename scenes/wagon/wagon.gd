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

var _target: Node3D = null
var _fire_anim_time: float = 0.0
const FIRE_ANIM_SPEED: float = 15.0

var _wagon_img: Image = null
var _fire_img: Image = null
var _cached_textures: Dictionary = {}

func _ready():
	add_to_group("wagons")
	if target_node:
		_target = get_node(target_node) as Node3D
	_wagon_img = Image.new()
	var wpath := ProjectSettings.globalize_path("res://assets/sprites/wagon.png")
	_wagon_img.load(wpath)
	_fire_img = Image.new()
	var fpath := ProjectSettings.globalize_path("res://assets/sprites/fire.png")
	_fire_img.load(fpath)
	_update_texture()

func get_fire_level() -> int:
	return fire_level

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := int(event.keycode)
		if key >= KEY_0 and key <= KEY_4:
			fire_level = key - KEY_0

func _process(delta: float) -> void:
	if fire_level <= 0:
		return
	_fire_anim_time += delta * FIRE_ANIM_SPEED
	var col := int(_fire_anim_time) % 5
	var cache_key := "l%d_f%d" % [fire_level, col]
	if not _cached_textures.has(cache_key):
		_cached_textures[cache_key] = _combine_textures(fire_level - 1, col)
	var sprite := $Sprite3D as Sprite3D
	if sprite:
		sprite.texture = _cached_textures[cache_key]

func _combine_textures(row: int, col: int) -> Texture2D:
	if not _fire_img or not _wagon_img:
		return load("res://assets/sprites/wagon.png")

	var fw := 45
	var fh := 45
	var fx := col * fw
	var fy := row * fh
	var fire_frame := _fire_img.get_region(Rect2(fx, fy, fw, fh))

	var combined := Image.create(52, 45, false, Image.FORMAT_RGBA8)
	combined.fill(Color(0, 0, 0, 0))
	combined.blit_rect(_wagon_img, Rect2(0, 0, 52, 27), Vector2(0, 18))
	combined.blend_rect(fire_frame, Rect2(0, 0, fw, fh), Vector2(3, 0))

	return ImageTexture.create_from_image(combined)

func _update_texture():
	var sprite := $Sprite3D as Sprite3D
	if not sprite:
		return
	if not _wagon_img:
		sprite.texture = load("res://assets/sprites/wagon.png")
		return

	# Her zaman 52×45 canvas kullan (fire level 0'da da aynı boyut)
	var combined := Image.create(52, 45, false, Image.FORMAT_RGBA8)
	combined.fill(Color(0, 0, 0, 0))
	combined.blit_rect(_wagon_img, Rect2(0, 0, 52, 27), Vector2(0, 18))

	if fire_level > 0 and _fire_img:
		var cache_key := "l%d_f0" % fire_level
		if not _cached_textures.has(cache_key):
			_cached_textures[cache_key] = _combine_textures(fire_level - 1, 0)
		if _cached_textures.has(cache_key):
			sprite.texture = _cached_textures[cache_key]
			_fire_anim_time = 0.0
			return

	sprite.texture = ImageTexture.create_from_image(combined)

func _physics_process(delta: float) -> void:
	var horse := _target
	if not horse or not is_instance_valid(horse):
		return
	var offset := global_position - horse.global_position
	offset.y = 0
	var dist := offset.length()
	if dist > max_distance:
		var dir := offset.normalized()
		var target := horse.global_position + dir * max_distance
		target.y = global_position.y
		var t := 1.0 - exp(-follow_speed * delta)
		var new_pos := global_position.lerp(target, t)
		velocity = (new_pos - global_position) / delta
	else:
		velocity = velocity.lerp(Vector3.ZERO, 1.0 - exp(-10.0 * delta))
	move_and_slide()
