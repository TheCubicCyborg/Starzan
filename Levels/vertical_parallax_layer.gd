extends Node2D
class_name VerticalParallaxLayer

@export_range(0.0, 1.0, 0.01) var parallax_factor: float = 0.5

var _base_global_position: Vector2

func _ready() -> void:
	_base_global_position = global_position

func capture_base_position() -> void:
	_base_global_position = global_position

func apply_vertical_parallax(tracked_y: float) -> void:
	var parallax_offset_y := tracked_y * (1.0 - parallax_factor)
	global_position = Vector2(_base_global_position.x, _base_global_position.y + parallax_offset_y)
