@tool
extends Node2D


@onready var bird_tscn := preload("res://Entities/Bird/bird.tscn")
@onready var shooting_star_tscn := preload("res://Entities/ShootingStar/shooting_star.tscn")

enum BirdType {
	Bird,
	ShootingStar,
}

@export_group("Bird Emitter")
@export var bird_type: BirdType = BirdType.Bird
@export var initial_spawn_delay: float = 0.
@export var bird_spawn_period_sec: float = 3.
@export var inverted: bool = false
@export_group("Bird Properties")
@export var bird_speed: float = 100.
@export var bird_lifetime: float = 5.
@export var bird_move_dir: Vector2 = Vector2.RIGHT
@export var bird_bonk_strength: float = 10000.
@export var is_killer_bird: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		$Sprite2D.queue_free()
		await get_tree().create_timer(initial_spawn_delay).timeout
		spawn_routine()

func spawn_routine():
	while true:
		spawn_bird()
		await get_tree().create_timer(bird_spawn_period_sec).timeout

func spawn_bird():
	var bird
	match bird_type:
		BirdType.Bird:
			bird = bird_tscn.instantiate()
		BirdType.ShootingStar:
			bird = shooting_star_tscn.instantiate()
	add_child(bird)
	bird.init(inverted, bird_speed, bird_lifetime, bird_bonk_strength, rotation, is_killer_bird)
