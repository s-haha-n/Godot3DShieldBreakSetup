extends Node

func _ready() -> void:
	# Completely disable this node if we are not running a debug build
	if not OS.is_debug_build():
		set_process_input(false)
		queue_free() # Safely remove it from the tree in production
		return
	
	# Default behavior: Start with the mouse captured for the game
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	# We use _input instead of unhandled_input to ensure debug keys 
	# intercept inputs even if UI has focus.
	if not event is InputEventKey or not event.is_pressed():
		return

	match event.as_text_physical_keycode():
		"Escape":
			_toggle_mouse_capture()
		"R":
			_reload_current_level()
		"X":
			_quit_game()

func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _reload_current_level() -> void:
	# Godot 4 syntax to reload the active scene
	get_tree().reload_current_scene()

func _quit_game() -> void:
	get_tree().quit()
