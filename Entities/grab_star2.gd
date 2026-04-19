class_name GrabStar2 extends Star

@export var stretch_constant = 30
@onready var daAudio = $daAudio

func activate():
	GameManager.player.tether_to(self)
	daAudio.play()
