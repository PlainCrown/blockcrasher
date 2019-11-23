extends Node

"""Creates and plays the music audio player.
Stores, saves and loads all values saved to the config.ini and save.dat files.
Also stores some global variables that are used across multiple scenes."""

onready var music_file := preload("res://Sound/music_track.ogg")
onready var config_path = "user://config.ini"
onready var save_path = "user://save.dat"

var music_player := AudioStreamPlayer.new()
# warning-ignore:unused_class_variable
var broken_brick_array := []
# warning-ignore:unused_class_variable
var victory := false

"""Variables saved to config.ini"""
var music_volume: int setget music_volume_change
var sfx_volume: int setget sfx_volume_change
var fullscreen: bool
var current_scene = null setget save_config
var paddle_color: Color setget color_change

"""Dictionary saved to save.dat"""
var level_locked_dict = {}


func _ready() -> void:
	"""Loads the config.ini and save.dat files.
	Switches to fullscreen if it has been turned on in the options menu."""
	load_config()
	if fullscreen:
		OS.window_fullscreen = true
	load_data()
	"""Creates and plays the music audio player which continues to play even when scenes are changed."""
	get_viewport().get_node("/root").call_deferred("add_child", music_player)
	music_player.stream = music_file
	music_player.volume_db = music_volume
	music_player.play()


func music_volume_change(value: int) -> void:
	"""Stores and adjusts the music volume setting."""
	music_volume = value
	if music_volume == -40:
		music_volume = -1000
	music_player.volume_db = music_volume


func sfx_volume_change(value: int) -> void:
	"""Stores and adjusts the sound effect volume setting."""
	sfx_volume = value
	if sfx_volume == -50:
		sfx_volume = -1000


func color_change(new_color: Color) -> void:
	"""Stores and adjusts the color of the paddles."""
	paddle_color = new_color


func save_config(scene_path) -> void:
	"""Saves the furthest played level for easy access through the continue button in the main menu."""
	if scene_path != null:
		if current_scene == null or int(scene_path) > int(current_scene):
			current_scene = scene_path
	"""Creates a config file and saves all user preferences in the options menu."""
	var config := ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("last_level", "current_scene", current_scene)
	config.set_value("paddle", "paddle_color", paddle_color)
	var err := config.save(config_path)
	"""Checks if the config file was saved successfully."""
	if err != OK:
		print("Error while saving config")


func load_config() -> void:
	"""Loads the config file."""
	var config := ConfigFile.new()
	var err := config.load(config_path)
	"""Sets options menu values to default if the config file fails to load or does not exist."""
	if err != OK:
		music_volume = -10
		sfx_volume = -20
		fullscreen = false
		current_scene = null
		paddle_color = Color(0.168627, 0.333333, 1, 1)
		print("Error while loading config. Default settings loaded.")
		return
	"""Sets option menu values to the values stored in the config file."""
	music_volume = config.get_value("audio", "music_volume")
	sfx_volume = config.get_value("audio", "sfx_volume")
	fullscreen = config.get_value("display", "fullscreen")
	current_scene = config.get_value("last_level", "current_scene")
	paddle_color = config.get_value("paddle", "paddle_color")


func save_data():
	"""Creates a save file."""
	var save_file := File.new()
	var err := save_file.open(save_path, File.WRITE)
	"""Checks if the save file was opened successfully."""
	if err != OK:
		print("Error while opening save file")
		return
	"""Saves the dictionary and closes the save file."""
	save_file.store_var(level_locked_dict)
	save_file.close()


func load_data():
	"""Loads the save file."""
	var save_file := File.new()
	var err := save_file.open(save_path, File.READ)
	"""Sets level menu values to default if the save file fails to load or does not exist."""
	if err != OK:
		level_locked_dict = {
			1: false,
			2: true,
			3: true,
			4: true,
			5: true,
			6: true,
			7: true,
			8: true,
			9: true,
			10: true,
			11: true,
			12: true,
			13: true,
			14: true,
			15: true,
			16: true,
			17: true,
			18: true,
			19: true,
			20: true,
			21: true,
			22: true,
			23: true,
			24: true,
			25: true,
			26: true,
			27: true,
			28: true,
			29: true,
			30: true
			}
		print("Error while loading save file. Default settings loaded.")
		return
	"""Sets level menu values to the values stored in the save file."""
	level_locked_dict = save_file.get_var()
	save_file.close()
