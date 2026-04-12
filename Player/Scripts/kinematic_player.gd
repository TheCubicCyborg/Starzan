extends CharacterBody2D
class_name Player

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@export var REELING_MAX_SPEED = 1200.
@export var MAX_GRAVITY = 800.

var _current_star: GrabStar
var _reeling_velocity: Vector2
var _reeling_current_speed: float
var _kinematic_velocity: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.player = self
	SignalBus.grab_star_grabbed.connect(_on_grab_star_grabbed)
	SignalBus.grab_star_released.connect(_on_grab_star_released)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		_kinematic_velocity += get_gravity() * delta
	# Jump
	if is_on_floor():
		if Input.is_action_just_pressed("ui_accept"):
			_kinematic_velocity.y = JUMP_VELOCITY
	

	tether_movement(delta)
	normal_movement(delta)
	
	velocity = _kinematic_velocity + _reeling_velocity

	move_and_slide()

func tether_movement(delta: float):
	if _current_star:
		var direction_to_current_star := (_current_star.global_position - global_position).normalized()
		_reeling_velocity = _reeling_velocity.move_toward(direction_to_current_star * REELING_MAX_SPEED, REELING_MAX_SPEED * delta)
	else:
		if is_on_floor():
			# apply strong friction
			_reeling_velocity.y = 0.
			_reeling_velocity = _reeling_velocity.move_toward(Vector2.ZERO, REELING_MAX_SPEED * delta) # idk
		else:
			_reeling_velocity = _reeling_velocity.move_toward(Vector2.ZERO, REELING_MAX_SPEED * delta * 0.001) # idk

func normal_movement(delta: float):
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		_kinematic_velocity.x = direction * SPEED
	else:
		_kinematic_velocity.x = move_toward(_kinematic_velocity.x, 0, SPEED)

func _on_grab_star_grabbed(star: GrabStar):
	_current_star = star
	print("grabbed %s" % star.name)

func _on_grab_star_released(_s: GrabStar):
	if _current_star:
		print("releasing %s" % _current_star)
		_current_star = null

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_released():
			_on_grab_star_released(_current_star)
