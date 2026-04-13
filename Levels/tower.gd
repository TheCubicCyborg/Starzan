extends Node2D

signal zone_changed(from_index: int, to_index: int)

@export var zone_boundaries_y: PackedFloat32Array = PackedFloat32Array([-4000.0, -8000.0])
@export var transition_duration_sec: float = 0.5
@export var camera_fixed_x: float = 960.0
@export var camera_y_offset: float = -140.0
@export var camera_follow_smoothing: float = 16.0
@export var zone_areas: Array[Area2D] = []
@export var music_player: AudioStreamPlayer
@export var zone_music: Array[AudioStream] = []
@export var music_fade_duration_sec: float = 0.6

@onready var player: Player = $PlayerDude
@onready var camera: Camera2D = $TowerCamera
@onready var zone_roots: Array[Node2D] = [$Zone1, $Zone2, $Zone3]
@onready var win_trigger: Area2D = $WinTrigger
@onready var win_screen: CanvasLayer = $WinScreen
@onready var restart_button: Button = $WinScreen/CenterContainer/Panel/VBoxContainer/RestartButton

var _zone_backgrounds: Array[Node2D] = []
var _parallax_layers: Array[VerticalParallaxLayer] = []
var _active_zone_index: int = -1
var _transition_tween: Tween
var _music_tween: Tween
var _has_won: bool = false

func _ready() -> void:
	if not is_instance_valid(player):
		push_error("no player node.")
		return

	get_tree().paused = false
	if win_screen != null:
		win_screen.visible = false
	if win_trigger != null and not win_trigger.body_entered.is_connected(_on_win_trigger_body_entered):
		win_trigger.body_entered.connect(_on_win_trigger_body_entered)
	if restart_button != null and not restart_button.pressed.is_connected(_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)
	if music_player == null:
		music_player = get_node_or_null("MusicPlayer") as AudioStreamPlayer
	if music_player == null:
		music_player = _find_first_audio_player(self)

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

	_connect_zone_area_signals()
	if zone_areas.is_empty():
		_update_zone_for_position(player.global_position.y, true)
	else:
		var initial_zone := _find_zone_for_player_from_areas()
		if initial_zone < 0:
			initial_zone = 0
		_set_active_zone(initial_zone, true)
	_update_parallax(camera.global_position.y)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	_update_camera(delta)
	if zone_areas.is_empty():
		_update_zone_for_position(player.global_position.y, false)
	else:
		_update_zone_from_areas()
	_update_parallax(camera.global_position.y)

func _update_camera(delta: float) -> void:
	var target := Vector2(camera_fixed_x, clamp(player.global_position.y + camera_y_offset,-INF,124))
	if camera_follow_smoothing <= 0.0:
		camera.global_position = target
		return

	var blend := 1.0 - exp(-camera_follow_smoothing * delta)
	camera.global_position = camera.global_position.lerp(target, blend)

func _update_zone_for_position(player_y: float, immediate: bool) -> void:
	var zone_index := _compute_zone_index(player_y)
	_set_active_zone(zone_index, immediate)

func _set_active_zone(zone_index: int, immediate: bool) -> void:
	zone_index = clamp(zone_index, 0, max(zone_roots.size() - 1, 0))
	if zone_index == _active_zone_index:
		return
	var previous_zone := _active_zone_index
	_active_zone_index = zone_index
	_blend_backgrounds_to_zone(zone_index, immediate)
	_play_zone_music(zone_index, immediate)
	zone_changed.emit(previous_zone, zone_index)

func _connect_zone_area_signals() -> void:
	for index in zone_areas.size():
		var area := zone_areas[index]
		if area == null:
			continue
		area.monitoring = true
		area.monitorable = true
		if is_instance_valid(player):
			area.collision_mask |= player.collision_layer
		var on_enter := Callable(self, "_on_zone_area_body_entered").bind(index)
		if not area.body_entered.is_connected(on_enter):
			area.body_entered.connect(on_enter)

func _find_zone_for_player_from_areas() -> int:
	for index in zone_areas.size():
		var area := zone_areas[index]
		if area == null:
			continue
		for body in area.get_overlapping_bodies():
			if body is Player:
				return index
	return -1

func _on_zone_area_body_entered(body: Node2D, zone_index: int) -> void:
	if body is Player:
		_set_active_zone(zone_index, false)

func _update_zone_from_areas() -> void:
	for index in zone_areas.size():
		var area := zone_areas[index]
		if area == null:
			continue
		if area.overlaps_body(player):
			_set_active_zone(index, false)
			return

func _play_zone_music(zone_index: int, immediate: bool) -> void:
	if music_player == null:
		return
	if zone_index < 0 or zone_index >= zone_music.size():
		return

	var next_stream := zone_music[zone_index]
	if next_stream == null:
		return
	if music_player.stream == next_stream and music_player.playing:
		return

	if is_instance_valid(_music_tween):
		_music_tween.kill()

	if immediate or music_fade_duration_sec <= 0.0 or not music_player.playing:
		music_player.stream = next_stream
		music_player.volume_db = 0.0
		music_player.play()
		return

	_music_tween = create_tween()
	_music_tween.tween_property(music_player, "volume_db", -40.0, music_fade_duration_sec * 0.5)
	_music_tween.tween_callback(func() -> void:
		music_player.stream = next_stream
		music_player.play()
	)
	_music_tween.tween_property(music_player, "volume_db", 0.0, music_fade_duration_sec * 0.5)

func _find_first_audio_player(node: Node) -> AudioStreamPlayer:
	for child in node.get_children():
		if child is AudioStreamPlayer:
			return child
		var nested := _find_first_audio_player(child)
		if nested != null:
			return nested
	return null

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

func _on_win_trigger_body_entered(body: Node2D) -> void:
	if _has_won:
		return
	if not (body is Player):
		return

	_has_won = true
	if win_screen != null:
		win_screen.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	get_tree().reload_current_scene()
