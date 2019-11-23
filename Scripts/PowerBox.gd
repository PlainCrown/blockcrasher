extends KinematicBody2D

"""Reveals, moves and deletes power boxes.
Also responsible for setting the correct sprite for each power box."""

export (int, "small_paddles", "small_bricks", "big_paddles", "extra_ball", "big_balls", \
"paddle_shot", "paddle_shift") var box_power setget set_power

const DROP_SPEED = 200

var motion := Vector2(0, 0)
var frozen := true setget reveal
var direction := 1


# warning-ignore:unused_argument
func _physics_process(delta: float) -> void:
	"""Moves the power box."""
	if not frozen:
		motion = move_and_slide(motion)
		motion = Vector2(0, DROP_SPEED * direction)
		
		"""Deletes the power box when it collides with a paddle and calls to activate the power-up."""
		if get_slide_count():
			frozen = true
			queue_free()
			$"..".activate_power(box_power)
			
		"""Deletes the power box if it goes off-screen."""
		if position.y < 0 or position.y > 920:
			queue_free()


func set_power(power: int) -> void:
	"""Sets the appropriate sprite for the power box."""
	box_power = power
	get_node("PowerSprite").region_rect = Rect2(power * 32, 0, 32, 32)


func reveal(boolean: bool) -> void:
	"""Unfreezes the power box and makes it visible."""
	frozen = boolean
	visible = true
