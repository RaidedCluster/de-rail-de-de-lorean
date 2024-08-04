extends Node2D

@onready var next_button = $Next

func _ready():
	# Connect the button's pressed signal to our retry function
	next_button.connect("pressed", Callable(self, "_on_next_pressed"))

func _on_next_pressed():
	print("Next button pressed. Going to main scene...")
	# Change to the main scene
	get_tree().change_scene_to_file("res://Scenes/Keys.tscn")
