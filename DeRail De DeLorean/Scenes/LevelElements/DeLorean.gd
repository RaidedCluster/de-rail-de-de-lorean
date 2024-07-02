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

var current_speed: float = 0.0
var direction: Vector3 = Vector3(0, 0, -1)
var current_sprite: Sprite3D
var collision_occurred: bool = false

func _ready():
	current_sprite = $Sprite3D
	$Camera3D.current = true
	$Area3D.connect("body_entered", Callable(self, "_on_body_entered"))

func _process(delta):
	if !collision_occurred:
		handle_input(delta)
	move_car(delta)
	update_sprite()

func handle_input(delta):
	if current_speed != 0.0:
		var rotation_angle = 0.0
		var speed_factor = (max_speed - abs(current_speed)) / max_speed
		var effective_turn_speed = turn_speed * speed_factor + min_turn_speed * (1.0 - speed_factor)
		
		if Input.is_action_pressed("ui_left"):
			rotation_angle = effective_turn_speed * delta
		elif Input.is_action_pressed("ui_right"):
			rotation_angle = -effective_turn_speed * delta
		
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
		translate(direction * current_speed * delta)

func _on_body_entered(body):
	if body.is_in_group("guardrails"):
		current_speed = 0
		collision_occurred = true
		print("Collision detected with: ", body.name)

func update_sprite():
	var angle = rad_to_deg(direction.angle_to(Vector3(0, 0, -1)))
	
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
