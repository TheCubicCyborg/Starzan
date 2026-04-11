extends Control

@onready var slider := $VBoxContainer/HBoxContainer/HSlider

func _ready():
	slider.value = 980.665
	print(PhysicsServer2D.area_get_param(
		get_viewport().find_world_2d().space,
		PhysicsServer2D.AREA_PARAM_GRAVITY
	))

func _on_h_slider_drag_ended(value_changed: bool) -> void:
	print("new value: ", slider.value)
	PhysicsServer2D.area_set_param(
		get_viewport().find_world_2d().space,
		PhysicsServer2D.AREA_PARAM_GRAVITY,
		slider.value
	)
