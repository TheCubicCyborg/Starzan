class_name LaunchStar extends Star

@export var stretch_constant = 30
@onready var daAudio = $daAudio
@export var max_launch_speed := 500.
@export var launch_accel := 1000.

func activate():
	GameManager.player.launch_to(self)
	daAudio.play()
