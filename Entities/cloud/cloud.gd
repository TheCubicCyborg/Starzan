extends Node2D

@onready var cloud_sprite : Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D
@export var one_way_margin: float = 8.0

func _ready() -> void:
	if collision_shape == null:
		return

	var rect := collision_shape.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		rect.size = Vector2(220, 24)
		collision_shape.shape = rect

	# Keep editor-authored size/offset; only force one-way platform behavior.
	collision_shape.one_way_collision = true
	collision_shape.one_way_collision_margin = one_way_margin
