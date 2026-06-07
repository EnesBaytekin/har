extends Control

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var shader = load("res://assets/shaders/menu_bg.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.render_priority = -1
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.material = mat
	add_child(bg)
	move_child(bg, 0)

	$VBoxContainer/PlayButton.pressed.connect(_on_play)
	$VBoxContainer/CreditsButton.pressed.connect(_on_credits)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit)
	$VBoxContainer/PlayButton.grab_focus()

func _on_play():
	get_tree().change_scene_to_file("res://scenes/intro_cinematic/intro_cinematic.tscn")

func _on_credits():
	get_tree().change_scene_to_file("res://scenes/credits/credits.tscn")

func _on_quit():
	get_tree().quit()
