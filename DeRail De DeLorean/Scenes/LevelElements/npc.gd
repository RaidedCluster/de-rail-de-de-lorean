extends Node3D

@export var lane: String = "left"  # "left" or "right" by default set to "left"
@export var max_speed: float = 55.0 / 2.23694  # Convert 55 mph to meters per second
@export var acceleration: float = 5.0  # Acceleration rate (meters per second squared)
@export var deceleration: float = 32.0  # Deceleration rate (meters per second squared)
@export var detection_distance: float = 10 # Distance to detect other cars

@export var front_sprite_path: String
@export var back_sprite_path: String

@onready var raycast = $Area3D/RayCast3D
@onready var sprite = $Sprite3D
@onready var area = $Area3D

var front_sprite: Texture
var back_sprite: Texture

var current_speed: float = 0.0
var direction: Vector3
var is_colliding: bool = false

func _ready():
	area.body_entered.connect(Callable(self, "_on_body_entered"))
	area.body_exited.connect(Callable(self, "_on_body_exited"))
	raycast.target_position = Vector3(0, 0, -detection_distance)  # Set the RayCast3D distance

	# Load textures from provided paths
	front_sprite = load(front_sprite_path)
	back_sprite = load(back_sprite_path)

	# Set initial direction and sprite based on lane
	set_direction_and_sprite_based_on_lane()

	# Ensure RayCast is enabled
	raycast.enabled = true
	# Exclude the car's own Area3D from detection
	raycast.add_exception(area)

func _process(delta):
	update_speed(delta)
	move_car(delta)
	check_collisions()
	check_despawn()

func update_speed(delta):
	if is_colliding:
		current_speed -= deceleration * delta
		if current_speed < 0:
			current_speed = 0
	else:
		current_speed += acceleration * delta
		if current_speed > max_speed:
			current_speed = max_speed

func move_car(delta):
	translate(direction * current_speed * delta)

func check_collisions():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider:
			var parent = collider.get_parent()
			if parent.is_in_group("cars"):
				is_colliding = true
				return
	is_colliding = false

func check_despawn():
	if global_transform.origin.z <= -50:
		queue_free()
		print("NPC despawned at: ", global_transform.origin)

func _on_body_entered(body):
	if body.is_in_group("cars"):
		is_colliding = true

func _on_body_exited(body):
	if body.is_in_group("cars"):
		is_colliding = false

func set_direction_and_sprite_based_on_lane():
	if lane == "left":
		direction = Vector3(0, 0, -1)  # Moving towards the player
		sprite.texture = front_sprite
	elif lane == "right":
		direction = Vector3(0, 0, 1)  # Moving away from the player
		sprite.texture = back_sprite

