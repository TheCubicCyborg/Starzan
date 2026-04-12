class_name YankStar extends StaticBody2D

var TEMP_PULL_LOCATION: Vector2 = Vector2(576.5,400)

var moving: bool = false
var away: bool = false #if moving, true -> moving away from home position, false -> moving to home position
var source: Vector2
var destination: Vector2
var wait_timer: float = 0
@export var wait_time: float = 2
@export_range(0,1.0) var away_weight: float = 0.5
@export_range(0,1.0) var return_speed: float = 5

func _ready():
	source = position

#func _input_event(viewport, event, shape_idx):
	#if event is InputEventMouseButton:
		#if event.is_pressed() and not moving and not away:
			#moving = true
			#away = true
			#destination = TEMP_PULL_LOCATION

func activate():
	pass

func _physics_process(delta):
	var start_position = position
	if moving:
		if away:
			position = lerp(position,destination,away_weight)
			if position.is_equal_approx(destination):
				position = destination
				moving = false
				wait_timer = wait_time
		else:
			position = position.move_toward(source,return_speed)
			if position.is_equal_approx(source):
				position = source
				moving = false 
	elif wait_timer > 0:
		wait_timer -= delta
		if wait_timer <= 0:
			wait_timer = 0
			moving = true
			away = false
	constant_linear_velocity = (position - start_position)/delta
	if constant_linear_velocity.y < 0:
		constant_linear_velocity.y = 0
	elif constant_linear_velocity.y > 0:
		constant_linear_velocity.y += get_gravity().y
