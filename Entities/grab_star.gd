extends Area2D
class_name GrabStar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if not event is InputEventMouseButton:
		return
	var butt_event := event as InputEventMouseButton
	if butt_event.is_pressed():
		SignalBus.grab_star_grabbed.emit(self)
	if butt_event.is_released():
		SignalBus.grab_star_released.emit(self)
