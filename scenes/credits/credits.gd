extends Control

const SCROLL_SPEED: float = 60.0
const CREDITS_END_Y: float = -900.0

var _scrolling: bool = true


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	MusicManager.play_menu_music()

	var shader := load("res://assets/shaders/menu_bg.gdshader")
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.render_priority = -1
	var bg := ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.material = mat
	add_child(bg)
	move_child(bg, 0)

	$BackButton.pressed.connect(_on_back)
	$BackButton.grab_focus()


func _process(delta: float) -> void:
	if not _scrolling:
		return

	var credits_container := $CreditsContainer as Control
	credits_container.position.y -= SCROLL_SPEED * delta

	if credits_container.position.y <= CREDITS_END_Y:
		credits_container.position.y = CREDITS_END_Y
		_scrolling = false
		await get_tree().create_timer(1.5).timeout
		_goto_menu()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return
	var key := int(event.keycode)
	if key == KEY_ESCAPE:
		_goto_menu()
	if key == KEY_ENTER or key == KEY_SPACE:
		if _scrolling:
			_scrolling = false
			await get_tree().create_timer(1.5).timeout
		_goto_menu()


func _on_back() -> void:
	_goto_menu()


func _goto_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
