extends Node2D

@onready var retry_button = $Retry

func _ready():
	# Connect the button's pressed signal to our retry function
	retry_button.connect("pressed", Callable(self, "_on_retry_pressed"))

func _on_retry_pressed():
	print("Retry button pressed. Returning to main scene...")
	# Change to the main scene
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")
