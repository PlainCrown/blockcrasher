extends Control

"""Displays the locked and unlocked textures of levels, as well as the level number label.
Also switches to the corresponding level scene when an icon is clicked on."""

export (bool) var locked
export (int) var level_number
export (String, FILE, "*.tscn") var level
export (Texture) var locked_texture
export (Texture) var unlocked_texture

onready var lock_button := $LockButton
onready var level_label := $LevelLabel


func _ready():
	"""Locks and unlocks levels depending on their boolean value stored in the autoload variable."""
	if not Autoload.level_locked_dict[level_number]:
		locked = false
	if locked:
		lock_button.texture_normal = locked_texture
	else:
		lock_button.texture_normal = unlocked_texture
		level_label.visible = true
		level_label.text = str(level_number)


func _on_LockButton_pressed():
	"""Switches to the corresponding level when an unlocked level icon is clicked."""
	if not locked:
# warning-ignore:return_value_discarded
		get_tree().change_scene(level)
