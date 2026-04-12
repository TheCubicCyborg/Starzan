extends Area2D

@export var star_selector_sprite: Sprite2D
@export var cast_line: Line2D
@export var activation_range: float = 500.0
@export var cast_speed: float = 1600.0
@export var min_cast_time: float = 0.08
@export var cast_arc_height: float = 120.0
@export_range(6, 64, 1) var cast_curve_segments: int = 24

var base_selector_sprite_scale: Vector2
var star_in_range: Star
var star_position: Vector2
var lerp_factor: float = 0.0
var in_activation_range: bool = false

var _cast_target: Star
var _cast_elapsed: float = 0.0
var _cast_duration: float = 0.0
var _cast_in_progress: bool = false

var _mouse_position_tween: Tween

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if not star_selector_sprite:
		push_warning("continuing without custom cursor")
	else:
		base_selector_sprite_scale = star_selector_sprite.scale

	if cast_line == null:
		cast_line = get_node_or_null("../CastLine")
	if cast_line != null:
		cast_line.top_level = true
		cast_line.visible = false
		cast_line.clear_points()

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

	if _cast_in_progress:
		_update_cast(delta)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if _cast_in_progress:
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
	_cast_elapsed = 0.0
	_cast_in_progress = true
	var start := _get_cast_origin()
	var end := _cast_target.global_position
	var cast_distance := start.distance_to(end)
	_cast_duration = max(cast_distance / max(cast_speed, 1.0), min_cast_time)
	_update_cast_line(start, end, 0.0)

func _update_cast(delta: float) -> void:
	if _cast_target == null or not is_instance_valid(_cast_target):
		_cancel_cast()
		return

	_cast_elapsed += delta
	var progress = clamp(_cast_elapsed / _cast_duration, 0.0, 1.0)
	var start = _get_cast_origin()
	var end = _cast_target.global_position
	_update_cast_line(start, end, progress)

	if progress >= 1.0:
		var target := _cast_target
		_cancel_cast()
		if target != null and is_instance_valid(target):
			target.activate()

func _cancel_cast() -> void:
	_cast_target = null
	_cast_in_progress = false
	_cast_elapsed = 0.0
	_cast_duration = 0.0
	if cast_line != null:
		cast_line.visible = false
		cast_line.clear_points()

func _get_cast_origin() -> Vector2:
	var player := GameManager.player
	if player == null:
		return global_position
	if player.has_method("get_cast_origin"):
		return player.get_cast_origin()
	return player.global_position

func _update_cast_line(start: Vector2, end: Vector2, progress: float) -> void:
	if cast_line == null:
		return

	var control := _compute_cast_control(start, end)
	var point_count = max(cast_curve_segments, 6)
	var visible_points = max(2, int(ceil(float(point_count) * progress)) + 1)
	var points := PackedVector2Array()
	points.resize(visible_points)

	for index in visible_points:
		var denominator = max(visible_points - 1, 1)
		var t := progress * (float(index) / float(denominator))
		points[index] = _quadratic_bezier(start, control, end, t)

	cast_line.points = points
	cast_line.visible = true

func _compute_cast_control(start: Vector2, end: Vector2) -> Vector2:
	var midpoint := (start + end) * 0.5
	var arc := Vector2(0.0, -abs(cast_arc_height))
	return midpoint + arc

func _quadratic_bezier(start: Vector2, control: Vector2, finish: Vector2, t: float) -> Vector2:
	var inv_t := 1.0 - t
	return (inv_t * inv_t * start) + (2.0 * inv_t * t * control) + (t * t * finish)
