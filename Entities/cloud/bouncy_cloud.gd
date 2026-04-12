extends Node2D

@export var bounce_velocity: float = -1500.0
@export var squash_scale: Vector2 = Vector2(1.2, 0.75)
@export var squash_time: float = 0.08
@export var rebound_time: float = 0.14

@onready var cloud_sprite: Sprite2D = $Sprite2D
@onready var bounce_area: Area2D = $BounceArea

var _base_scale: Vector2
var _squash_tween: Tween

func _ready() -> void:
	_base_scale = cloud_sprite.scale if cloud_sprite != null else Vector2.ONE
	if bounce_area != null and not bounce_area.body_entered.is_connected(_on_bounce_area_body_entered):
		bounce_area.body_entered.connect(_on_bounce_area_body_entered)

func _on_bounce_area_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return

	var player := body as Player
	if player.tethered:
		player.untether()

	player.velocity.y = min(player.velocity.y, bounce_velocity)
	_play_squash()

func _play_squash() -> void:
	if cloud_sprite == null:
		return

	if _squash_tween != null:
		_squash_tween.kill()

	_squash_tween = create_tween()
	_squash_tween.tween_property(cloud_sprite, "scale", _base_scale * squash_scale, squash_time)
	_squash_tween.tween_property(cloud_sprite, "scale", _base_scale, rebound_time)
