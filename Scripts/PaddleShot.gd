extends KinematicBody2D

"""Controls the movement and sound effects of the paddle shot.
Also responsible for breaking the blocks that the paddle shot hits."""

onready var power_box_spawner := $"../PowerBoxSpawner"
onready var audio_player := $AudioStreamPlayer

const SHOT_SOUND = preload("res://Sound/shot.wav")
const SHOT_COLLISION = preload("res://Sound/shot_collision.wav")
const SPEED = 250

var y_dir := -1
var frozen := false


func _ready():
	"""Sets the correct sound effect volume for the shot and plays the shot sound effect."""
	audio_player.volume_db = Autoload.sfx_volume
	if not Autoload.victory:
		audio_player.stream = SHOT_SOUND
		audio_player.play()


func _process(delta) -> void:
	"""Moves the shot and detects a collision."""
	if not frozen:
		var collision := move_and_collide(Vector2(0, y_dir * SPEED * delta))
		
		"""Freezes and hides the shot if it collides with a block."""
		if collision != null:
			frozen = true
			visible = false
			
			"""Plays the shot collision sound effect."""
			if not Autoload.victory:
				audio_player.stream = SHOT_COLLISION
				audio_player.play()
				
			"""Breaks the block that the shot collides with."""
			var object = collision.get_collider()
			Autoload.broken_brick_array.append(object)
			if object.is_in_group("WeakBrick"):
				object.get_node("BrickCollision").disabled = true
				object.visible = false
				object.remove_from_group("Brick")
				"""Drops powers from broken blocks."""
				if object.is_in_group("PowerBrick"):
					power_box_spawner.drop_box(object.global_position)
			elif object.is_in_group("MidBrick"):
				object.add_to_group("WeakBrick")
				object.get_node("BrickSprite").play("Weak")
			elif object.is_in_group("StrongBrick"):
				object.add_to_group("MidBrick")
				object.get_node("BrickSprite").play("Mid")
			elif object.is_in_group("StrongerBrick"):
				object.add_to_group("StrongBrick")
				object.get_node("BrickSprite").play("Strong")
			elif object.is_in_group("StrongestBrick"):
				object.add_to_group("StrongerBrick")
				object.get_node("BrickSprite").play("Stronger")
				
		"""Deletes the shot if it goes off-screen."""
		if position.y < 0 or position.y > 920:
			queue_free()


func _on_AudioStreamPlayer_finished():
	"""Deletes the shot when the shot collision sound effect ends."""
	if audio_player.stream == SHOT_COLLISION:
		queue_free()
