extends RigidBody2D

"""Controls all of the ball's movement.
Also responsible for breaking blocks and playing ball-related sound effects."""

export (String, FILE, "*.tscn") var next_level

onready var level_name := $"..".name
onready var audio_player := $"../AudioStreamPlayer"
onready var power_box_spawner := $"../PowerBoxSpawner"
onready var reset_timer := $"../ResetTimer"
onready var paddle_up := $"../PaddleUp"
onready var paddle_down := $"../PaddleDown"
onready var UI := $"../UI"

const DROP_SOUND = preload("res://Sound/ball_drop.wav")
const COLLISION_SOUND = preload("res://Sound/collision.wav")
const SPEED = 410

var ball_restart_velocity := Vector2(80, -410)
var stored_linear_velocity := 0
var reset := false
var pressed := false
var ball_timer_on := false
var changed_levels := false


func _ready() -> void:
	"""Connects signals."""
# warning-ignore:return_value_discarded
	reset_timer.connect("timeout", self, "ball_reset")
# warning-ignore:return_value_discarded
	$BallTimer.connect("timeout", self, "speed_up")


# warning-ignore:unused_argument
func _physics_process(delta: float) -> void:
	"""Creates an array of objects that the ball collides with and searches it for specific objects."""
	var bodies := get_colliding_bodies()
	for body in bodies:
		if "Paddle" in body.name:
			"""Checks if the ball has already moved too far past the paddle on the y axis.
			Prevents the ball from bouncing on the paddle if it has."""
			if body.name == "PaddleDown" and global_position.y > body.global_position.y or \
			body.name == "PaddleUp" and global_position.y < body.global_position.y:
				return
			else:
				"""Makes the ball bounce on the paddles and allows the player to control its direction."""
				var direction: Vector2 = position - body.get_node("Anchor").global_position
				var velocity := direction.normalized() * SPEED
				set_linear_velocity(velocity)
				if body.paddle_shot == true:
					body.fire()
					
		"""Gives a collision between two balls the same momentum as bouncing against a paddle.
		This stops the balls from slowing down in the rare case of a collision."""
		if "Ball" in body.name:
			var direction: Vector2 = position - body.global_position
			var velocity := direction.normalized() * SPEED
			set_linear_velocity(velocity)
			
		"""Breaks blocks and adds them to the Autoload.gd broken brick array."""
		if body.is_in_group("Brick"):
			Autoload.broken_brick_array.append(body)
			if body.is_in_group("WeakBrick"):
				body.get_node("BrickCollision").disabled = true
				body.visible = false
				body.remove_from_group("Brick")
				"""Drops powers from broken blocks."""
				if body.is_in_group("PowerBrick"):
					power_box_spawner.drop_box(body.global_position)
			elif body.is_in_group("MidBrick"):
				body.add_to_group("WeakBrick")
				body.get_node("BrickSprite").play("Weak")
			elif body.is_in_group("StrongBrick"):
				body.add_to_group("MidBrick")
				body.get_node("BrickSprite").play("Mid")
			elif body.is_in_group("StrongerBrick"):
				body.add_to_group("StrongBrick")
				body.get_node("BrickSprite").play("Strong")
			elif body.is_in_group("StrongestBrick"):
				body.add_to_group("StrongerBrick")
				body.get_node("BrickSprite").play("Stronger")
				
		"""Plays the ball collision sound effect."""
		if not Autoload.victory:
			audio_player.stream = COLLISION_SOUND
			audio_player.pitch_scale = rand_range(0.92, 1)
			audio_player.play()
			
	"""Checks if there are any blocks left and switches to the next level or shows the victory screen
	if there aren't. The changed_levels variable prevents the change_scene function from being run 
	twice and causing a non-fatal error."""
	if not get_tree().get_nodes_in_group("Brick"):
		if level_name == "Level30" and not Autoload.victory:
			UI.victory_function()
		elif not Autoload.victory and not changed_levels:
			changed_levels = true
# warning-ignore:return_value_discarded
			get_tree().change_scene(next_level)
			
	"""Checks if there is only one ball when a ball drops off-screen."""
	if position.y < 0 or position.y > 920:
		if get_tree().get_nodes_in_group("Ball").size() == 1:
			"""Tells the player to restart the game, freezes all moving objects and plays the ball 
			drop sound effect."""
			if not pressed:
				UI.reset_request_function()
				power_box_spawner.freeze_children()
				paddle_down.freeze_shot()
				paddle_up.freeze_shot()
				paddle_down.frozen = true
				paddle_up.frozen = true
				"""Plays the ball drop sound effect."""
				if not Autoload.victory:
					audio_player.stream = DROP_SOUND
					audio_player.pitch_scale = 1
					audio_player.play()
		else:
			"""Replaces the original ball with the newly created extra_ball if the original ball
			dropped off-screen first."""
			if name == get_node(power_box_spawner.old_ball).name:
				UI.replace_ball()
				power_box_spawner.replace_old_ball()
			"""Deletes the ball."""
			remove_from_group("Ball")
			queue_free()
			
	"""Checks if the ball is moving too slowly for too long on the y axis by comparing it's 
	current vertical speed to its vertical speed 4 seconds later."""
	if linear_velocity.y > 0 and linear_velocity.y < 35 and not sleeping or \
	linear_velocity.y > -35 and linear_velocity.y < 0 and not sleeping:
		if not ball_timer_on:
			ball_timer_on = true
# warning-ignore:narrowing_conversion
			stored_linear_velocity = round(linear_velocity.y)
			$BallTimer.start()
			
	"""Stops edge-cases and bugs that make the ball exceed its maximum speed."""
	if linear_velocity.x > SPEED:
		linear_velocity.x = SPEED
	elif linear_velocity.x < -SPEED:
		linear_velocity.x = -SPEED
	elif linear_velocity.y > SPEED:
		linear_velocity.y = SPEED
	elif linear_velocity.y < -SPEED:
		linear_velocity.y = -SPEED


func speed_up() -> void:
	"""Speeds up the ball's vertical movement speed if it moves too slowly for 4 seconds in a row."""
	if round(linear_velocity.y) == stored_linear_velocity:
		if stored_linear_velocity <= 0:
			linear_velocity.y = -40
		else:
			linear_velocity.y = 40
		ball_timer_on = false


func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	"""Deletes the extra_ball if there is one while the original ball also exists.
	Then puts the only ball to sleep and resets its default values."""
	if reset:
		visible = false
		var ball_array := get_tree().get_nodes_in_group("Ball")
		if ball_array.size() > 1:
			ball_array[1].queue_free()
		sleeping = true
		$BallSprite.scale = Vector2(1, 1)
		$BallCollision.scale = Vector2(1, 1)
		var ball_restart_position := randomize_ball_start()
		state.transform = Transform2D(0, ball_restart_position)
		"""Delaying visibility hides some visual bugs."""
		yield(get_tree().create_timer(0.2), "timeout")
		visible = true


func randomize_ball_start() -> Vector2:
	"""Randomly picks one of two possible ball spawn locations and movement directions."""
	var random_dir := randi() % 2
	var random_pos := randi() % 2
	var pos := Vector2(0, 0)
	if random_pos == 0:
		pos = Vector2(340, 864)
	else:
		pos = Vector2(340, 56)
	if random_dir == 0:
		if random_pos == 0:
			ball_restart_velocity = Vector2(-80, -430)
		else:
			ball_restart_velocity = Vector2(-80, 430)
	else:
		if random_pos == 0:
			ball_restart_velocity = Vector2(80, -430)
		else:
			ball_restart_velocity = Vector2(80, 430)
	return pos


func ball_reset() -> void:
	"""Awakens the ball and gives it a movement direction."""
	reset = false
	sleeping = false
	linear_velocity = ball_restart_velocity
