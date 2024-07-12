extends Node3D

@onready var delorean = $DeLorean
@onready var speed_label = $CanvasLayer/Speedometer/SpeedLabel
@onready var prompt_node = $CanvasLayer/Prompt
@onready var line_edit = $CanvasLayer/Prompt/LineEdit
@onready var send_button = $CanvasLayer/Prompt/SendButton
@onready var dialogue_container = $CanvasLayer/DialogueContainer

func _ready():
	send_button.connect("pressed", Callable(self, "_on_send_button_pressed"))
	print("Ready function executed")

func _process(delta):
	update_speedometer()

func update_speedometer():
	var speed_mph = delorean.current_speed * 2.23694
	speed_label.text = str(int(speed_mph))

func _on_send_button_pressed():
	var user_input = line_edit.text.strip_edges()  # Remove any leading or trailing whitespace
	if user_input == "":
		print("Text field is empty. Not sending.")
		return
	print("Send button pressed with input: ", user_input)
	line_edit.text = ""
	prompt_node.visible = false
	_handle_user_input(user_input)

func _handle_user_input(user_input: String):
	# Create a dialogue resource from a test string
	var dialogue_text = "~ start\nGemini: Hi. This is a test message."
	print("Creating dialogue resource")
	var dialogue_resource = DialogueManager.create_resource_from_text(dialogue_text)
	
	if dialogue_resource:
		print("Dialogue resource created successfully")
		show_dialogue(dialogue_resource, "start")
	else:
		print("Failed to create dialogue resource")

func show_dialogue(resource, title):
	print("Showing dialogue")
	DialogueManager.show_dialogue_balloon(resource, title)
	prompt_node.visible = true
	print("Dialogue displayed, prompt visible again")



