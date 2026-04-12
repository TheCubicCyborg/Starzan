extends Node2D
class_name Bird

@onready var bird_sprite : AnimatedSprite2D = $Area2D/Sprite2D

var _move_dir: Vector2
var _speed: float
var _lifetime: float
var _bonk_strength: float

func init(move_dir: Vector2, move_speed: float, lifetime: float, bonk_strength: float):
	_move_dir = move_dir
	_speed = move_speed
	_lifetime = lifetime
	if _move_dir.x < -0.001:
		bird_sprite.flip_h = true
	else:
		bird_sprite.flip_h = false
	_bonk_strength = bonk_strength

func _physics_process(delta: float) -> void:
	global_position += _speed * delta * _move_dir
	
	_lifetime -= delta
	if _lifetime < 0:
		queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		var launch_vector := 1000. * (body.global_position - global_position).normalized()
		body.velocity = launch_vector
