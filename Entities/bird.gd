extends Node2D
class_name Bird

var _move_dir: Vector2
var _speed: float
var _lifetime: float

func init(move_dir: Vector2, move_speed: float, lifetime: float):
	_move_dir = move_dir
	_speed = move_speed
	_lifetime = lifetime

func _physics_process(delta: float) -> void:
	global_position += _speed * delta * _move_dir
	
	_lifetime -= delta
	if _lifetime < 0:
		queue_free()
