extends Control

"""Controls all the buttons in the main menu."""

onready var continue_button := $MarginContainer/VBoxContainer/Continue
onready var controls_page := $ControlsPage
onready var controls_exit := $ControlsExit


func _ready() -> void:
	"""Shows the continue button if the player was on any level other than the first one."""
	if Autoload.current_scene != null and Autoload.current_scene != "res://Scenes/LevelScenes/Level1.tscn":
		continue_button.visible = true
	else:
		continue_button.visible = false


func _on_Continue_pressed() -> void:
	"""Opens the furthest level the player has reached."""
# warning-ignore:return_value_discarded
	get_tree().change_scene(Autoload.current_scene)


func _on_Start_pressed() -> void:
	"""Opens the level select menu."""
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Scenes/LevelSelect.tscn")


func _on_Options_pressed() -> void:
	"""Opens the options menu."""
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Scenes/Options.tscn")


func _on_Controls_pressed() -> void:
	"""Shows the controls page."""
	controls_page.show()
	controls_exit.show()


func _on_ControlsExit_pressed() -> void:
	"""Hides the controls page when the back button is clicked."""
	controls_page.hide()
	controls_exit.hide()


func _unhandled_key_input(event: InputEventKey) -> void:
	"""Hides the controls page when the escape key is pressed."""
	if event.scancode == KEY_ESCAPE:
		controls_page.hide()
		controls_exit.hide()


func _on_Exit_pressed() -> void:
	"""Closes the game."""
	get_tree().quit()
