extends Node2D

# Path to the Keys scene
const keys_scene_path = "res://Scenes/Keys.tscn"

func _ready():
	# Connect the Play button's pressed signal to the _on_Play_button_pressed function
	$Play.connect("pressed", Callable(self, "_on_Play_button_pressed"))

func _on_Play_button_pressed():
	# Change to the Keys scene
	get_tree().change_scene_to_file(keys_scene_path)
