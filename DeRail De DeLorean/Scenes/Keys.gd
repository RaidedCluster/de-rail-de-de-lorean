extends Control

# URL for the Gemini 1.5 Flash API
const API_URL = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent"
# Path to the new scene
const MAIN_SCENE_PATH = "res://Scenes/Main.tscn"

# Prompt text
const PROMPT_TEXT = "I just got a DeLorean key 🚗🔑!"

func _ready():
	# Connect the Start button's pressed signal to the _on_Start_button_pressed function
	$Start.connect("pressed", Callable(self, "_on_Start_button_pressed"))
	
	# Connect the HTTPRequest node's request_completed signal to the _on_request_completed function
	$HTTPRequest.connect("request_completed", Callable(self, "_on_request_completed"))

func _on_Start_button_pressed():
	var api_key = $LineEdit.text.strip_edges()
	if api_key.is_empty():
		$FlagLabel.text = "What kinda car starts without a key?!"
		return
	
	make_api_call(api_key)

func make_api_call(api_key):
	var url_with_key = API_URL + "?key=" + api_key
	var headers = ["Content-Type: application/json"]
	var request_data = {
		"contents": [
			{
				"parts": [
					{
						"text": PROMPT_TEXT
					}
				]
			}
		]
	}
	var json_data = JSON.stringify(request_data)
	
	var error = $HTTPRequest.request(url_with_key, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		print("Failed to make HTTP request, error code: ", str(error))

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		var parse_error = json.parse(body.get_string_from_utf8())
		if parse_error == OK:
			var response_data = json.data
			Globals.api_key = $LineEdit.text.strip_edges()  # Store the API key in the singleton
			get_tree().change_scene_to_file(MAIN_SCENE_PATH)  # Change to the main scene
			print("Response: ", response_data)
		else:
			print("Failed to parse response: ", json.get_error_message())
	else:
		$FlagLabel.text = "Are you sure you got the right keys?"
		print("HTTP request failed with response code: ", str(response_code), " - ", body.get_string_from_utf8())
