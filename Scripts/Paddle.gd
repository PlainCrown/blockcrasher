extends KinematicBody2D

"""Responsible for all movement and power-ups related to the paddles."""

onready var paddle_shot_scene := preload("res://Scenes/PaddleShot.tscn")
onready var reset_position := $ResetPosition
onready var paddle_sprite := $PaddleSprite
onready var paddle_collision := $PaddleCollision
onready var level := $".."

const SPEED := 520

var motion := Vector2(0, 0)
var frozen := false
var paddle_shot := false
var active_shift := false
var shot: KinematicBody2D


func _ready() -> void:
	"""Sets the color of the paddles."""
	paddle_sprite.modulate = Autoload.paddle_color


# warning-ignore:unused_argument
func _physics_process(delta: float) -> void:
	"""Moves the paddles along the x axis."""
	if not frozen:
		motion = move_and_slide(motion)
		if Input.is_action_pressed("ui_right"):
			motion.x = SPEED
		elif Input.is_action_pressed("ui_left"):
			motion.x = -SPEED
		else:
			motion.x = 0
		motion.y = 0


func reset() -> void:
	"""Freezes and resets the paddles to their default values."""
	frozen = true
	active_shift = false
	paddle_shot = false
	motion = Vector2(0, 0)
	paddle_sprite.scale.x = 2
	paddle_collision.scale.x = 1
	position = reset_position.position


func _on_ResetTimer_timeout() -> void:
	"""Unfreezes the paddles."""
	frozen = false


func shrink() -> void:
	"""Shrinks the paddles then the small_paddles power-up is activated.
	The call to reposition fixes a rare bug that places the paddles off-screen after picking up this power."""
	paddle_sprite.scale.x = 1.5
	paddle_collision.scale.x = 0.75
	reposition()


func expand() -> void:
	"""Expands the paddles then the big_paddles power-up is activated.
	The call to reposition fixes a rare bug that places the paddles off-screen after picking up this power."""
	paddle_sprite.scale.x = 3
	paddle_collision.scale.x = 1.5
	reposition()


func shift() -> void:
	"""Moves the paddles toward the center when the paddle_shift power-up is activated."""
	active_shift = true
	reposition()


func reposition() -> void:
	"""Repositions the paddles on the y axis."""
	if name == "PaddleUp":
		if active_shift:
			global_position = Vector2(global_position.x, 70)
		else:
			global_position = Vector2(global_position.x, 30)
	else:
		if active_shift:
			global_position = Vector2(global_position.x, 850)
		else:
			global_position = Vector2(global_position.x, 890)


func fire() -> void:
	"""Checks if there are any other active paddle shots in the scene to prevent multiple simultaneous shots."""
	for node in level.get_children():
		if "PaddleShot" in node.name:
			if not node.frozen:
				return
				
	"""Creates and fires a shot from a paddle after colliding with a ball if the paddle_shot power is active."""
	shot = paddle_shot_scene.instance()
	if name == "PaddleUp":
		if active_shift:
			shot.global_position = Vector2(global_position.x, 90)
		else:
			shot.global_position = Vector2(global_position.x, 50)
		shot.y_dir = 1
	else:
		if active_shift:
			shot.global_position = Vector2(global_position.x, 836)
		else:
			shot.global_position = Vector2(global_position.x, 876)
		shot.y_dir = -1
	level.add_child(shot, true)


func freeze_shot() -> void:
	"""Feezes the paddle shot if there is one."""
	if shot != null and is_instance_valid(shot):
		shot.frozen = true
