extends Node2D

signal zone_changed(from_index: int, to_index: int)

@export var zone_boundaries_y: PackedFloat32Array = PackedFloat32Array([-4000.0, -8000.0])
@export var transition_duration_sec: float = 0.5
@export var camera_fixed_x: float = 576.0
@export var camera_y_offset: float = -140.0
@export var camera_follow_smoothing: float = 16.0

@onready var player: Player = $PlayerDude
@onready var camera: Camera2D = $TowerCamera
@onready var zone_roots: Array[Node2D] = [$Zone1, $Zone2, $Zone3]

var _zone_backgrounds: Array[Node2D] = []
var _parallax_layers: Array[VerticalParallaxLayer] = []
var _active_zone_index: int = -1
var _transition_tween: Tween

func _ready() -> void:
	if not is_instance_valid(player):
		push_error("no player node.")
		return

	for zone in zone_roots:
		var background := zone.get_node_or_null("Background") as Node2D
		if background == null:
			continue
		_zone_backgrounds.append(background)
		_collect_parallax_layers(background)

	for layer in _parallax_layers:
		layer.capture_base_position()

	camera.enabled = true
	camera.global_position = Vector2(camera_fixed_x, player.global_position.y + camera_y_offset)

	_update_zone_for_position(player.global_position.y, true)
	_update_parallax(camera.global_position.y)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	_update_camera(delta)
	_update_zone_for_position(player.global_position.y, false)
	_update_parallax(camera.global_position.y)

func _update_camera(delta: float) -> void:
	var target := Vector2(camera_fixed_x, player.global_position.y + camera_y_offset)
	if camera_follow_smoothing <= 0.0:
		camera.global_position = target
		return

	var blend := 1.0 - exp(-camera_follow_smoothing * delta)
	camera.global_position = camera.global_position.lerp(target, blend)

func _update_zone_for_position(player_y: float, immediate: bool) -> void:
	var zone_index := _compute_zone_index(player_y)
	if zone_index == _active_zone_index:
		return

	var previous_zone := _active_zone_index
	_active_zone_index = zone_index
	_blend_backgrounds_to_zone(zone_index, immediate)
	zone_changed.emit(previous_zone, zone_index)

func _compute_zone_index(player_y: float) -> int:
	var zone_index := 0
	for boundary_y in zone_boundaries_y:
		if player_y < boundary_y:
			zone_index += 1

	return clamp(zone_index, 0, max(zone_roots.size() - 1, 0))

func _blend_backgrounds_to_zone(zone_index: int, immediate: bool) -> void:
	if is_instance_valid(_transition_tween):
		_transition_tween.kill()

	if immediate:
		for i in _zone_backgrounds.size():
			_set_canvas_item_alpha(_zone_backgrounds[i], 1.0 if i == zone_index else 0.0)
		return

	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	for i in _zone_backgrounds.size():
		var target_alpha := 1.0 if i == zone_index else 0.0
		_transition_tween.tween_property(_zone_backgrounds[i], "modulate:a", target_alpha, transition_duration_sec)

func _set_canvas_item_alpha(node: CanvasItem, alpha: float) -> void:
	var color := node.modulate
	color.a = alpha
	node.modulate = color

func _update_parallax(tracked_y: float) -> void:
	for layer in _parallax_layers:
		layer.apply_vertical_parallax(tracked_y)

func _collect_parallax_layers(node: Node) -> void:
	for child in node.get_children():
		if child is VerticalParallaxLayer:
			_parallax_layers.append(child)
		_collect_parallax_layers(child)
