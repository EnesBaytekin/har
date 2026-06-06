extends Node

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := int(event.keycode)
		if key == KEY_F11 or (key == KEY_ENTER and event.alt_pressed):
			var win := get_window()
			if win.mode == Window.MODE_FULLSCREEN:
				win.mode = Window.MODE_WINDOWED
			else:
				win.mode = Window.MODE_FULLSCREEN
