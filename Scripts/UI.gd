extends Control

"""Controls the user interface and unlocks levels in the level scene.
Restarts the level by calling the reset functions in other scripts and respawning broken blocks.
Also responsible for the victory screen displayed when the last level is completed."""

export (NodePath) var ball

onready var scene := get_tree().get_current_scene().filename
onready var reset_request := $MarginContainer/ResetRequest
onready var game_complete := $GameComplete
onready var power_box_spawner := $"../PowerBoxSpawner"
onready var audio_player := $"../AudioStreamPlayer"
onready var reset_timer := $"../ResetTimer"
onready var paddle_up := $"../PaddleUp"
onready var paddle_down := $"../PaddleDown"
onready var level := $".."

const VICTORY_SOUND = preload("res://Sound/victory.wav")

var just_reset := false


func _ready() ->  void:
	"""Unlocks new levels in the level select menu, then calls to save the change to the save file."""
	Autoload.level_locked_dict[int(level.name)] = false
	Autoload.save_data()
	"""Empties the autoload broken_brick_array and sets the level sound effect volume."""
	Autoload.broken_brick_array = []
	audio_player.volume_db = Autoload.sfx_volume


func reset_request_function() -> void:
	"""Tells the player to press R to restart."""
	get_node(ball).pressed = true
	if not Autoload.victory:
		reset_request.text = "Press R to restart"
		reset_request.show()


func _unhandled_key_input(event: InputEventKey) -> void:
	"""Calls the restart function when R is pressed and informs the player that the game is restarting."""
	if event.scancode == KEY_R and just_reset == false:
		just_reset = true
		reset_request.text = "Restarting"
		reset_request.show()
		reset_game()
	elif event.scancode == KEY_ESCAPE:
		"""Returns to the level select menu and saves the scene path for the main menu continue button."""
# warning-ignore:return_value_discarded
		get_tree().change_scene("res://Scenes/LevelSelect.tscn")
		Autoload.current_scene = scene


func reset_game() -> void:
	"""Starts the restart timer."""
	reset_timer.start()
	
	"""Deletes all paddle shots."""
	for node in level.get_children():
		if "PaddleShot" in node.name:
			node.queue_free()
	
	"""Calls other scripts to reset their settings."""
	get_node(ball).reset = true
	power_box_spawner.reset()
	paddle_down.reset()
	paddle_up.reset()
	
	"""Resets the victory screen if it's active."""
	if Autoload.victory:
		Autoload.victory = false
		game_complete.visible = false
		get_node("../VictoryParticles").visible = false
		get_node("../VictoryParticles").emitting = false
	
	"""Resets all changes made to the blocks."""
	if not Autoload.broken_brick_array.empty():
		for brick in Autoload.broken_brick_array:
			brick.add_to_group("Brick")
			if brick.is_in_group("StrongestBrick"):
				brick.get_node("BrickSprite").play("Strongest")
				if brick.is_in_group("WeakBrick"):
					brick.remove_from_group("WeakBrick")
				if brick.is_in_group("MidBrick"):
					brick.remove_from_group("MidBrick")
				if brick.is_in_group("StrongBrick"):
					brick.remove_from_group("StrongBrick")
				if brick.is_in_group("StrongerBrick"):
					brick.remove_from_group("StrongerBrick")
			if brick.is_in_group("StrongerBrick"):
				brick.get_node("BrickSprite").play("Stronger")
				if brick.is_in_group("WeakBrick"):
					brick.remove_from_group("WeakBrick")
				if brick.is_in_group("MidBrick"):
					brick.remove_from_group("MidBrick")
				if brick.is_in_group("StrongBrick"):
					brick.remove_from_group("StrongBrick")
			elif brick.is_in_group("StrongBrick"):
				brick.get_node("BrickSprite").play("Strong")
				if brick.is_in_group("WeakBrick"):
					brick.remove_from_group("WeakBrick")
				if brick.is_in_group("MidBrick"):
					brick.remove_from_group("MidBrick")
			elif brick.is_in_group("MidBrick"):
				brick.get_node("BrickSprite").play("Mid")
				if brick.is_in_group("WeakBrick"):
					brick.remove_from_group("WeakBrick")
			brick.visible = true
			brick.get_node("BrickCollision").disabled = false
			for brick in get_tree().get_nodes_in_group("Brick"):
				brick.get_node("BrickSprite").scale = Vector2(2, 2)
				brick.get_node("BrickCollision").scale = Vector2(1, 1)
				brick.get_node("PowerIndicator").scale = Vector2(1, 1)
		Autoload.broken_brick_array = []


func _on_ResetTimer_timeout() -> void:
	"""Allows the player to restart the game again and hides the reset request label."""
	just_reset = false
	get_node(ball).pressed = false
	reset_request.hide()


func victory_function() -> void:
	"""Tells the player they have won when all bricks in the last level are broken.
	Also prevents other sound effects from playing and stops the reset request label from showing up."""
	Autoload.victory = true
	game_complete.visible = true
	get_node("../VictoryParticles").visible = true
	get_node("../VictoryParticles").emitting = true
	
	"""Plays the victory sound effect."""
	audio_player.stream = VICTORY_SOUND
	audio_player.pitch_scale = 1
	audio_player.play()


func replace_ball() -> void:
	"""Replaces the path to the original ball with a path to the extra_ball."""
	ball = get_path_to(power_box_spawner.new_ball)
