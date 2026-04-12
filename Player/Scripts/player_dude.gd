class_name Player extends CharacterBody2D

@export var player_sprite : Sprite2D

const SPEED = 300.0
const JUMP_VELOCITY = -800.0

var tethered: GrabStar2 = null
var tether_length: float = 0
var rigid: RigidBody2D = null

func _ready():
	GameManager.player = self

func _physics_process(delta):
	if tethered:
		tether_process(delta)
	else:
		normal_process(delta)
	
func _set_sprite_direction(direction: float):
	if direction < -0.01:
		player_sprite.flip_h = true	
	elif direction > 0.01:
		player_sprite.flip_h = false	

func normal_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		_set_sprite_direction(direction)
		velocity.x = direction * SPEED
	else:
		if not is_on_floor():
			velocity.x *= 0.9
		else:
			velocity.x *= 0.5
	
	move_and_slide()

func tether_process(delta):
		# Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
	
	position = rigid.position
	
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		untether()
		return
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		_set_sprite_direction(direction)
		rigid.apply_central_force(direction * Vector2.RIGHT * 100)
	
	var diff = tethered.position.distance_to(position) - tether_length
	if diff > 0:
		rigid.apply_central_force(to_local(tethered.position)*diff*diff)

func tether_to(star: GrabStar2):
	tethered = star
	tether_length = position.distance_to(star.position)
	rigid = RigidBody2D.new()
	rigid.lock_rotation = true
	get_parent().add_child(rigid)
	rigid.position = position
	var shape = CollisionShape2D.new()
	shape.shape = CapsuleShape2D.new()
	shape.shape.radius = 32
	shape.shape.height = 128
	rigid.add_child(shape)

func untether():
	tethered = null
	rigid.queue_free()
