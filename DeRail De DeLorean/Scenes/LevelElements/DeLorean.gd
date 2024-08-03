extends Node3D

@export var max_speed: float = 58.0
@export var max_reverse_speed: float = -6.7
@export var acceleration: float = 4.8
@export var brake_deceleration: float = 20.0
@export var natural_deceleration: float = 3.0
@export var reverse_acceleration: float = 2.4
@export var turn_speed: float = 90.0
@export var turn_deceleration: float = 1.0
@export var min_turn_speed: float = 20.0
@onready var raycast = $Area3D/RayCast3D
var is_autonomous = true  # Set this to true when the car is in autonomous mode
var is_obstacle_detected = false
var is_racing_mode: bool = false
var is_offroad: bool = false
var offroad_steering_angle: float = 15.0 
var has_crashed = false

@export var lane_change_speed: float = 2.0  # Normal lane change speed
@export var racing_lane_change_speed: float = 7  # Faster lane change for racing mode
var original_lane: float  # To store the original lane position
var overtaking: bool = false  # To track if we're currently overtaking
var overtake_timer: float = 0.0  # Timer for overtaking maneuver
var target_lane_x: float = -2.78  # Initial target lane (right lane)
var is_lane_changing: bool = false  # To track if a lane change is in progress
var target_speed: float = 0.0 

var current_speed: float = 0.0
var direction: Vector3 = Vector3(0, 0, -1)
var current_sprite: Sprite3D
var collision_occurred: bool = false
var player_control: bool = false

var x_position_timer: Timer
var is_out_of_bounds: bool = false

@onready var audio_player = $AudioStreamPlayer

func _ready():
	current_sprite = $Sprite3D
	$Camera3D.current = true
	$Area3D.connect("body_entered", Callable(self, "_on_body_entered"))
	$Area3D.connect("area_entered", Callable(self, "_on_area_entered"))

	x_position_timer = Timer.new()
	x_position_timer.set_wait_time(5.0)
	x_position_timer.set_one_shot(true)
	x_position_timer.connect("timeout", Callable(self, "_on_x_position_timeout"))
	add_child(x_position_timer)

	audio_player.volume_db = -80  # Set initial volume to be inaudible

func _process(delta):
	if !has_crashed:
		if player_control:
			handle_input(delta)
		move_car(delta)
	update_sprite()
	update_audio_volume()

	# Check the x position
	if global_transform.origin.x > 6 or global_transform.origin.x < -6:
		if !is_out_of_bounds:
			is_out_of_bounds = true
			x_position_timer.start()
	else:
		if is_out_of_bounds:
			is_out_of_bounds = false
			x_position_timer.stop()
	
	if global_transform.origin.z <= -13:
		get_tree().change_scene_to_file("res://Scenes/de-ferred.tscn")
	
	if global_transform.origin.z > 8850:
		get_tree().change_scene_to_file("res://Scenes/de_livered.tscn")

func handle_input(delta):
	if current_speed != 0.0:
		var rotation_angle = 0.0
		var speed_factor = (max_speed - abs(current_speed)) / max_speed
		var effective_turn_speed = turn_speed * speed_factor + min_turn_speed * (1.0 - speed_factor)
		
		# Invert controls if reversing
		if current_speed > 0:
			if Input.is_action_pressed("ui_left"):
				rotation_angle = effective_turn_speed * delta
			elif Input.is_action_pressed("ui_right"):
				rotation_angle = -effective_turn_speed * delta
		else:
			if Input.is_action_pressed("ui_left"):
				rotation_angle = -effective_turn_speed * delta
			elif Input.is_action_pressed("ui_right"):
				rotation_angle = effective_turn_speed * delta
		
		if rotation_angle != 0.0:
			direction = direction.rotated(Vector3.UP, deg_to_rad(rotation_angle))
			current_speed -= turn_deceleration * delta
			if current_speed < max_reverse_speed:
				current_speed = max_reverse_speed
	
	if Input.is_action_pressed("ui_up"):
		current_speed += acceleration * delta
		if current_speed > max_speed:
			current_speed = max_speed
	elif Input.is_action_pressed("ui_down"):
		if current_speed > 0:
			current_speed -= brake_deceleration * delta
			if current_speed < 0:
				current_speed = 0
		else:
			current_speed -= reverse_acceleration * delta
			if current_speed < max_reverse_speed:
				current_speed = max_reverse_speed
	else:
		if current_speed > 0:
			current_speed -= natural_deceleration * delta
			if current_speed < 0:
				current_speed = 0
		elif current_speed < 0:
			current_speed += natural_deceleration * delta
			if current_speed > 0:
				current_speed = 0

func move_car(delta):
	if !collision_occurred:
		if is_autonomous:
			check_obstacle()
			if is_obstacle_detected and not is_racing_mode:
				current_speed -= brake_deceleration * delta
				if current_speed < 0:
					current_speed = 0
			else:
				# Adjust speed towards the target speed
				if current_speed < target_speed:
					current_speed += acceleration * delta
					if current_speed > target_speed:
						current_speed = target_speed
				elif current_speed > target_speed:
					current_speed -= brake_deceleration * delta
					if current_speed < target_speed:
						current_speed = target_speed
		
		# Smooth lane change transition
		if is_lane_changing and current_speed > 0:
			var current_x = global_transform.origin.x
			var distance_to_target = target_lane_x - current_x
			var effective_lane_change_speed = racing_lane_change_speed if is_racing_mode else lane_change_speed
			if abs(distance_to_target) > 0.1:
				var lane_change_step = effective_lane_change_speed * delta
				if abs(distance_to_target) < lane_change_step:
					lane_change_step = abs(distance_to_target)
				global_transform.origin.x += sign(distance_to_target) * lane_change_step
			else:
				is_lane_changing = false
				global_transform.origin.x = target_lane_x
		
		# Handle overtaking maneuver
		if overtaking:
			overtake_timer += delta
			if overtake_timer >= 1.0:  # Wait for 1 second before changing back
				target_lane_x = original_lane
				is_lane_changing = true
				overtaking = false
		
		if is_offroad:
			# Continue moving in the current direction (which is already steered)
			# You might want to add some randomness or terrain-based adjustments here
			pass
		
		# Normal movement
		translate(direction * current_speed * delta)

func set_target_speed(speed: float):
	target_speed = speed

func _on_body_entered(body):
	if body.is_in_group("guardrails"):
		trigger_crash(body)

func _on_area_entered(area):
	if area.get_parent().is_in_group("cars"):
		trigger_crash(area.get_parent())

func update_sprite():
	var angle = rad_to_deg(direction.angle_to(Vector3(0, 0, -1)))
	
	if is_offroad:
		# Adjust the angle for offroad mode
		angle += offroad_steering_angle
	
	if angle <= 22.5:
		current_sprite.texture = preload("res://Assets/DeLorean DMC-12/Back.png")
		current_sprite.flip_h = false
	elif angle <= 45:
		if direction.x < 0:
			current_sprite.texture = preload("res://Assets/DeLorean DMC-12/Back-Left.png")
		else:
			current_sprite.texture = preload("res://Assets/DeLorean DMC-12/Back-Right.png")
		current_sprite.flip_h = false
	elif angle <= 67.5:
		if direction.x < 0:
			current_sprite.texture = preload("res://Assets/DeLorean DMC-12/Back-Left-Fullturn.png")
		else:
			current_sprite.texture = preload("res://Assets/DeLorean DMC-12/Back-Right-Fullturn.png")
		current_sprite.flip_h = false
	elif angle <= 112.5:
		current_sprite.texture = preload("res://Assets/DeLorean DMC-12/Side.png")
		current_sprite.flip_h = direction.x > 0
	elif angle <= 135:
		if direction.x < 0:
			current_sprite.texture = preload("res://Assets/DeLorean DMC-12/Front-Left-Fullturn.png")
		else:
			current_sprite.texture = preload("res://Assets/DeLorean DMC-12/Front-Right-Fullturn.png")
		current_sprite.flip_h = false
	elif angle <= 157.5:
		if direction.x < 0:
			current_sprite.texture = preload("res://Assets/DeLorean DMC-12/Front-Left.png")
		else:
			current_sprite.texture = preload("res://Assets/DeLorean DMC-12/Front-Right.png")
		current_sprite.flip_h = false
	else:
		current_sprite.texture = preload("res://Assets/DeLorean DMC-12/Front.png")
		current_sprite.flip_h = false

func check_obstacle():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.get_parent().is_in_group("cars"):
			is_obstacle_detected = true
			if is_racing_mode and not overtaking:
				start_overtaking()
			return
	is_obstacle_detected = false

func start_overtaking():
	overtaking = true
	original_lane = target_lane_x
	target_lane_x = -target_lane_x  # Switch to the other lane
	is_lane_changing = true
	overtake_timer = 0.0

func start_offroad():
	is_offroad = true
	# Steer slightly to the right
	direction = direction.rotated(Vector3.UP, deg_to_rad(-offroad_steering_angle))
	# Update the sprite immediately
	update_sprite()

func end_offroad():
	is_offroad = false
	# You could add logic here to steer back onto the road if needed
	# Update the sprite immediately
	update_sprite()

func trigger_crash(object):
	if !has_crashed:
		has_crashed = true
		current_speed = 0
		collision_occurred = true
		print("Collision detected with: ", object.name)
		# Emit a signal to notify the Main scene about the crash
		get_parent().emit_signal("car_crashed")

func _on_x_position_timeout():
	if is_out_of_bounds:
		get_tree().change_scene_to_file("res://Scenes/de_flated.tscn")

func update_audio_volume():
	var speed_factor = abs(current_speed) / max_speed
	
	if current_speed == 0:
		audio_player.volume_db = -80  # Silence the audio when the car is idle
	else:
		audio_player.volume_db = lerp(-10, 5, speed_factor)  # Adjust the range as needed

