extends Line2D
class_name FishingCastLine

@export var cast_speed: float = 1600.0
@export var min_cast_time: float = 0.08
@export var cast_arc_height: float = 120.0
@export_range(6, 64, 1) var cast_curve_segments: int = 24

var _cast_elapsed: float = 0.0
var _cast_duration: float = 0.0
var _is_casting: bool = false

func _ready() -> void:
	top_level = true
	visible = false
	clear_points()

func begin_cast(start: Vector2, target: Vector2) -> void:
	_cast_elapsed = 0.0
	_is_casting = true
	var cast_distance := start.distance_to(target)
	_cast_duration = max(cast_distance / max(cast_speed, 1.0), min_cast_time)
	_update_points(start, target, 0.0)

func update_cast(delta: float, start: Vector2, target: Vector2) -> bool:
	if not _is_casting:
		return false

	_cast_elapsed += delta
	var progress = clamp(_cast_elapsed / _cast_duration, 0.0, 1.0)
	_update_points(start, target, progress)
	return progress >= 1.0

func cancel_cast() -> void:
	_is_casting = false
	_cast_elapsed = 0.0
	_cast_duration = 0.0
	visible = false
	clear_points()

func is_casting() -> bool:
	return _is_casting

func _update_points(start: Vector2, target: Vector2, progress: float) -> void:
	var control = _compute_cast_control(start, target)
	var point_count = max(cast_curve_segments, 6)
	var visible_points = max(2, int(ceil(float(point_count) * progress)) + 1)
	var cast_points := PackedVector2Array()
	cast_points.resize(visible_points)

	for index in visible_points:
		var denominator = max(visible_points - 1, 1)
		var t := progress * (float(index) / float(denominator))
		cast_points[index] = _quadratic_bezier(start, control, target, t)

	points = cast_points
	visible = true

func _compute_cast_control(start: Vector2, target: Vector2) -> Vector2:
	var midpoint := (start + target) * 0.5
	var arc := Vector2(0.0, -abs(cast_arc_height))
	return midpoint + arc

func _quadratic_bezier(start: Vector2, control: Vector2, finish: Vector2, t: float) -> Vector2:
	var inv_t := 1.0 - t
	return (inv_t * inv_t * start) + (2.0 * inv_t * t * control) + (t * t * finish)
