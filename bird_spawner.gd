@tool
extends Node2D

@onready var bird_tscn := preload("res://Entities/bird.tscn")
@export_group("Bird Emitter")
@export var bird_spawn_period_sec: float = 3.
@export_group("Bird Properties")
@export var bird_speed: float = 100.
@export var bird_lifetime: float = 5.
@export var bird_move_dir: Vector2 = Vector2.RIGHT

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		$Sprite2D.queue_free()
	spawn_routine()

func spawn_routine():
	while true:
		spawn_bird()
		await get_tree().create_timer(bird_spawn_period_sec).timeout

func spawn_bird():
	var bird = bird_tscn.instantiate()
	add_child(bird)
	bird.init(bird_move_dir, bird_speed, bird_lifetime)
