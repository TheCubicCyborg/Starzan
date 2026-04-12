extends Area2D

@export var star_selector_sprite: Sprite2D
var base_selector_sprite_scale: Vector2
@export var lerp_speed: float = 100.

var star_in_range: Node2D
var star_position: Vector2

var lerp_factor: float = 0.

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if not star_selector_sprite:
		push_warning("continuing without custom cursor")
	else:
		base_selector_sprite_scale = star_selector_sprite.scale

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position = get_global_mouse_position()
	
	if star_position:
		star_selector_sprite.global_position = lerp(global_position, star_position, lerp_factor)
	else:
		star_selector_sprite.global_position = global_position

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if star_in_range and event is InputEventMouseButton:
		if event.is_pressed():
			print("im totally activating this star: %s" % star_in_range)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_MOUSE_EXIT:
			monitoring = false
			visible = false
		NOTIFICATION_WM_MOUSE_ENTER:
			global_position = get_global_mouse_position()
			monitoring = true
			visible = true


func _on_area_entered(area: Area2D) -> void:
	if area is Star:
		print("this area just entered: %s" % area.name)
		star_in_range = area
		star_position = star_in_range.global_position	
		star_entered()


func _on_body_entered(body: Node2D) -> void:
	if body is YankStar:
		print("this body just entered: %s" % body.name)
		star_in_range = body
		star_position = star_in_range.global_position
		star_entered()

func _on_area_exited(area: Area2D) -> void:
	if area == star_in_range:
		star_in_range = null
		print("this body just exited: %s" % area.name)
		star_exited()

func _on_body_exited(body: Node2D) -> void:
	if body == star_in_range:
		star_in_range = null
		print("this body just exited: %s" % body.name)
		star_exited()

var _mouse_position_tween: Tween
func star_entered():
	if _mouse_position_tween:
		_mouse_position_tween.kill()
	_mouse_position_tween = create_tween()
	_mouse_position_tween.set_trans(Tween.TRANS_QUART)
	_mouse_position_tween.set_ease(Tween.EASE_OUT)
	_mouse_position_tween.tween_property(self, "lerp_factor", 1., .5)
	_mouse_position_tween.set_parallel()
	_mouse_position_tween.tween_property(star_selector_sprite, "scale", 2 * base_selector_sprite_scale, .5)

func star_exited():
	if _mouse_position_tween:
		_mouse_position_tween.kill()
	_mouse_position_tween = create_tween()
	_mouse_position_tween.set_trans(Tween.TRANS_QUART)
	_mouse_position_tween.set_ease(Tween.EASE_OUT)
	_mouse_position_tween.tween_property(self, "lerp_factor", 0., .5)
	_mouse_position_tween.set_parallel()
	_mouse_position_tween.tween_property(star_selector_sprite, "scale", base_selector_sprite_scale, .5)
