extends Node3D

@onready var delorean = $DeLorean
@onready var speed_label = $CanvasLayer/Speedometer/SpeedLabel

func _ready():
	pass

func _process(delta):
	update_speedometer()

func update_speedometer():
	var speed_mph = delorean.current_speed * 2.23694
	speed_label.text = str(int(speed_mph))
