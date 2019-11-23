extends Node2D

"""Generates power boxes, adds them as children, and activates the power-ups they contain."""

export (NodePath) var old_ball

onready var power_box := preload("res://Scenes/PowerBox.tscn")
onready var ball_scene := preload("res://Scenes/Ball.tscn")
onready var level := $".."
onready var paddle_up := $"../PaddleUp"
onready var paddle_down := $"../PaddleDown"

var power_array := [0, 1, 2, 3, 4, 5, 6]
var brick_array := []
var minimum_level_powers := 2
var big_balls := false
var new_ball: RigidBody2D


func _ready() -> void:
	"""Ensures true randomness and generates the first set of power-ups."""
	randomize()
	generate_powers()


func generate_powers() -> void:
	"""Generates the number of power-ups in the level."""
	if int(level.name) >= 21:
		minimum_level_powers = 4
	elif int(level.name) >= 11:
		minimum_level_powers = 3
	else:
		minimum_level_powers = 2
	var power_count := randi() % 3 + minimum_level_powers
	
	"""This delay prevents a fatal error caused by a bad order of operations."""
	yield(get_tree().create_timer(0.1), "timeout")
	
	"""Randomly chooses which blocks contain power-ups and makes their power indicators visible."""
	brick_array = get_tree().get_nodes_in_group("Brick")
	for power in power_count:
		var power_index := randi() % power_array.size()
		var brick_index := randi() % brick_array.size()
		brick_array[brick_index].add_to_group("PowerBrick")
		brick_array[brick_index].get_node("PowerIndicator").visible = true
		brick_array[brick_index].get_node("IndicatorAnimation").play("Move")
		spawn_powers(power_array[power_index], brick_array[brick_index].position)
		power_array.remove(power_index)
		brick_array.remove(brick_index)


func spawn_powers(power: int, location: Vector2) -> void:
	"""Adds the power box as a child and places it under the appropriate block."""
	var box := power_box.instance()
	box.box_power = power
	box.visible = false
	add_child(box)
	box.position = location


func drop_box(brick_location: Vector2) -> void:
	"""Unfreezes the power box when the block its under is broken.
	Also randomizes between moving up or down on the y axis."""
	var drop_direction := randi() % 2
	for box in get_children():
		if box.position == brick_location:
			if drop_direction == 0:
				box.direction = -1
			else:
				box.direction = 1
			box.frozen = false


func reset() -> void:
	"""Resets the changes made by the previous power-up generation."""
	power_array = [0, 1, 2, 3, 4, 5, 6]
	big_balls = false
	for brick in get_tree().get_nodes_in_group("PowerBrick"):
		brick.get_node("PowerIndicator").visible = false
		brick.get_node("IndicatorAnimation").stop()
		brick.remove_from_group("PowerBrick")
	
	"""Deletes the power boxes and calls to generate new ones."""
	for child in get_children():
		child.queue_free()
	generate_powers()


func freeze_children() -> void:
	"""Freezes the power boxes."""
	for child in get_children():
		if not child.frozen:
			child.frozen = true


func activate_power(box_power: int) -> void:
	"""Matches the power box to the corresponding power-up and activates it."""
	match box_power:
		0: # small_paddles
			paddle_up.shrink()
			paddle_down.shrink()
		1: # small_bricks
			for brick in get_tree().get_nodes_in_group("Brick"):
				brick.get_node("BrickSprite").scale = Vector2(1.5, 1.5)
				brick.get_node("BrickCollision").scale = Vector2(0.75, 0.75)
				brick.get_node("IndicatorAnimation").play("SmallMove")
		2: # big_paddles
			paddle_up.expand()
			paddle_down.expand()
		3: # extra_ball
			var extra_ball := ball_scene.instance()
			if big_balls:
				extra_ball.get_node("BallSprite").scale = Vector2(2, 2)
				extra_ball.get_node("BallCollision").scale = Vector2(2, 2)
			extra_ball.add_to_group("Ball")
			extra_ball.global_position = Vector2(340,864)
			extra_ball.next_level = get_node(old_ball).next_level
			level.add_child(extra_ball, true)
			new_ball = extra_ball
		4:	# big_balls
			big_balls = true
			for ball in get_tree().get_nodes_in_group("Ball"):
				ball.get_node("BallSprite").scale = Vector2(2, 2)
				ball.get_node("BallCollision").scale = Vector2(2, 2)
		5: # paddle_shot
			paddle_down.paddle_shot = true
			paddle_up.paddle_shot = true
		6: # paddle_shift
			paddle_up.shift()
			paddle_down.shift()


func replace_old_ball() -> void:
	"""Replaces the path to the original ball with a path to the extra_ball."""
	old_ball = get_path_to(new_ball)
