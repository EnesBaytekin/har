extends Control

func _ready():
	$PlayButton.pressed.connect(_on_play)
	$QuitButton.pressed.connect(_on_quit)
	$PlayButton.grab_focus()

func _on_play():
	get_tree().change_scene_to_file("res://scenes/intro_cinematic/intro_cinematic.tscn")

func _on_quit():
	get_tree().quit()
