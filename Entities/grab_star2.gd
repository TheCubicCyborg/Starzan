class_name GrabStar2 extends Star

@export var stretch_constant = 30
@onready var daAudio = $daAudio
#func _input_event(viewport, event, shape_idx):
	#if event is InputEventMouseButton:
		#if event.is_pressed():
			#activate()

func activate():
	GameManager.player.tether_to(self)
	daAudio.play()
