class_name GrabStar2 extends Star

var length: float

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.is_pressed():
			activate()

func activate():
	length = position.distance_to(GameManager.player.position)
	
