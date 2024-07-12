extends Node3D

@onready var delorean = $DeLorean
@onready var speed_label = $CanvasLayer/Speedometer/SpeedLabel
@onready var prompt_node = $CanvasLayer/Prompt
@onready var line_edit = $CanvasLayer/Prompt/LineEdit
@onready var send_button = $CanvasLayer/Prompt/SendButton
@onready var dialogue_container = $CanvasLayer/DialogueContainer
@onready var http_request = $HTTPRequest

const API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
const API_KEY = "AIzaSyBWSwSx0h0_DN5fDP6SisErXu2smIKYadY"

var conversation_history = []

func _ready():
	send_button.connect("pressed", Callable(self, "_on_send_button_pressed"))
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))
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
	conversation_history.append({"role": "user", "text": user_input})
	make_api_call()

func make_api_call():
	var url_with_key = API_URL + "?key=" + API_KEY
	var headers = ["Content-Type: application/json"]
	var request_data = {
		"system_instruction": {
			"parts": [
				{
					"text": "You are Gemini, an ethical and knowledgeable AI assistant who helps users with various queries in a professional and respectful manner. You are integrated into a custom-built electric 1981 DeLorean. This is not a time-travelling DeLorean, it is an ordinary one. You and the passenger are on their way from Hill Valley to Silicon Valley from Route 66. Please talk in first person and assume the role of a voice assistant in the car. Don't overdo it and keep your responses concise. Silicon Valley is just 6.2 miles away."
				}
			]
		},
		"contents": [
			{
				"parts": [
					{
						"text": get_conversation_history()
					}
				]
			}
		],
		"safetySettings": [
			{
				"category": "HARM_CATEGORY_HARASSMENT",
				"threshold": "BLOCK_NONE"
			},
			{
				"category": "HARM_CATEGORY_HATE_SPEECH",
				"threshold": "BLOCK_NONE"
			},
			{
				"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
				"threshold": "BLOCK_NONE"
			},
			{
				"category": "HARM_CATEGORY_DANGEROUS_CONTENT",
				"threshold": "BLOCK_NONE"
			}
		]
	}
	var json_data = JSON.stringify(request_data)
	
	var error = http_request.request(url_with_key, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		print("Failed to make HTTP request, error code: ", str(error))

func get_conversation_history():
	var history_text = ""
	for entry in conversation_history:
		history_text += entry["role"] + ": " + entry["text"] + "\n"
	return history_text

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		var parse_error = json.parse(body.get_string_from_utf8())
		if parse_error == OK:
			var response_data = json.data
			print("Response: ", response_data)  # Debugging: Print the entire response data
			handle_api_response(response_data)
		else:
			print("Failed to parse response: ", json.get_error_message())
			handle_api_failure()
	else:
		print("HTTP request failed with response code: ", str(response_code), " - ", body.get_string_from_utf8())
		handle_api_failure()

func handle_api_response(response_data):
	var dialogue_text = ""
	if response_data.has("candidates"):
		var candidates = response_data["candidates"]
		if candidates.size() > 0:
			var finish_reason = candidates[0]["finishReason"]
			if finish_reason == "SAFETY" or finish_reason == "OTHER":
				print("Response blocked due to safety settings or other reasons")
				dialogue_text = "Sorry, I can't respond to that. Let's talk about something else."
			else:
				var content = candidates[0]["content"]
				if content.has("parts"):
					var parts = content["parts"]
					if parts.size() > 0:
						dialogue_text = parts[0]["text"]
						conversation_history.append({"role": "model", "text": dialogue_text})
	
	if dialogue_text == "":
		dialogue_text = "Sorry, I couldn't generate a response. Let's try something else."
	
	var dialogue_resource = DialogueManager.create_resource_from_text("~ start\nGemini: " + dialogue_text)
	if dialogue_resource:
		print("Dialogue resource created successfully")
		show_dialogue(dialogue_resource, "start")
	else:
		print("Failed to create dialogue resource")

func handle_api_failure():
	var dialogue_text = "Sorry, I couldn't generate a response due to an error. Let's try something else."
	var dialogue_resource = DialogueManager.create_resource_from_text("~ start\nGemini: " + dialogue_text)
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
