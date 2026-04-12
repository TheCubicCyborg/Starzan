extends Area2D

@export var star_selector_sprite: Sprite2D
@export var cast_line: FishingCastLine
@export var activation_range: float = 500.0

var base_selector_sprite_scale: Vector2
var star_in_range: Star
var star_position: Vector2
var lerp_factor: float = 0.0
var in_activation_range: bool = false

var _cast_target: Star
var _mouse_position_tween: Tween

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if not star_selector_sprite:
		push_warning("continuing without custom cursor")
	else:
		base_selector_sprite_scale = star_selector_sprite.scale

	if cast_line == null:
		cast_line = get_node_or_null("../CastLine") as FishingCastLine

func _process(delta: float) -> void:
	global_position = get_global_mouse_position()

	var player := GameManager.player
	if player != null:
		var distance_to_player := global_position.distance_to(player.global_position)
		in_activation_range = distance_to_player <= activation_range
	else:
		in_activation_range = false

	if star_selector_sprite != null:
		star_selector_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0) if in_activation_range else Color(0.453, 0.453, 0.453, 1.0)
		if star_in_range != null:
			star_position = star_in_range.global_position
			star_selector_sprite.global_position = global_position.lerp(star_position, lerp_factor)
		else:
			star_selector_sprite.global_position = global_position

	if cast_line != null and cast_line.is_casting():
		_update_cast(delta)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if cast_line != null and cast_line.is_casting():
		return
	if not (event is InputEventMouseButton):
		return
	if not event.is_pressed():
		return
	if star_in_range == null or not in_activation_range:
		return

	_begin_cast(star_in_range)

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
		star_in_range = area
		star_position = star_in_range.global_position
		star_entered()

func _on_body_entered(body: Node2D) -> void:
	if body is YankStar:
		star_in_range = body
		star_position = star_in_range.global_position
		star_entered()

func _on_area_exited(area: Area2D) -> void:
	if area == star_in_range:
		star_in_range = null
		star_exited()

func _on_body_exited(body: Node2D) -> void:
	if body == star_in_range:
		star_in_range = null
		star_exited()

func star_entered() -> void:
	if _mouse_position_tween:
		_mouse_position_tween.kill()
	_mouse_position_tween = create_tween()
	_mouse_position_tween.set_trans(Tween.TRANS_QUART)
	_mouse_position_tween.set_ease(Tween.EASE_OUT)
	_mouse_position_tween.tween_property(self, "lerp_factor", 1.0, 0.5)
	_mouse_position_tween.set_parallel()
	if star_selector_sprite != null:
		_mouse_position_tween.tween_property(star_selector_sprite, "scale", 2.0 * base_selector_sprite_scale, 0.5)

func star_exited() -> void:
	if _mouse_position_tween:
		_mouse_position_tween.kill()
	_mouse_position_tween = create_tween()
	_mouse_position_tween.set_trans(Tween.TRANS_QUART)
	_mouse_position_tween.set_ease(Tween.EASE_OUT)
	_mouse_position_tween.tween_property(self, "lerp_factor", 0.0, 0.5)
	_mouse_position_tween.set_parallel()
	if star_selector_sprite != null:
		_mouse_position_tween.tween_property(star_selector_sprite, "scale", base_selector_sprite_scale, 0.5)

func _begin_cast(target: Star) -> void:
	if target == null:
		return

	var player := GameManager.player
	if player == null:
		return

	if player.tethered:
		player.untether()

	_cast_target = target
	var start := _get_cast_origin()
	var finish := _cast_target.global_position
	if cast_line != null:
		cast_line.begin_cast(start, finish)
	else:
		_cast_target.activate()
		_cast_target = null

func _update_cast(delta: float) -> void:
	if _cast_target == null or not is_instance_valid(_cast_target):
		_cancel_cast()
		return

	var start := _get_cast_origin()
	var finish := _cast_target.global_position
	var reached_target := cast_line.update_cast(delta, start, finish)

	if reached_target:
		var target := _cast_target
		_cancel_cast()
		if target != null and is_instance_valid(target):
			target.activate()

func _cancel_cast() -> void:
	_cast_target = null
	if cast_line != null:
		cast_line.cancel_cast()

func _get_cast_origin() -> Vector2:
	var player := GameManager.player
	if player == null:
		return global_position
	if player.has_method("get_cast_origin"):
		return player.get_cast_origin()
	return player.global_position
