@tool
extends Marker2D

@onready var sprite := $Sprite2D

func _ready() -> void:
	if not Engine.is_editor_hint():
		sprite.queue_free()
