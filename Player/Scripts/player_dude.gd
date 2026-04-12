class_name Player extends CharacterBody2D

@export var player_sprite : Sprite2D
@export var animation_player: AnimationPlayer
@export var fishing_cast_origin_left: Marker2D
@export var fishing_cast_origin_right: Marker2D
@export_range(1, 32, 1) var one_way_platform_layer: int = 3

const SPEED = 300.0
const JUMP_VELOCITY = -1000.0
const JUMP_VISUAL_TIME = 0.12

var tethered: GrabStar2 = null
var tether_length: float = 0
var rigid: RigidBody2D = null
var _jump_visual_timer: float = 0.0
var _default_collision_mask: int = 1

func _ready():
	GameManager.player = self
	_default_collision_mask = collision_mask
	_set_one_way_collision_enabled(true)
	if animation_player == null:
		animation_player = get_node_or_null("AnimationPlayer")
	if fishing_cast_origin_left == null:
		fishing_cast_origin_left = get_node_or_null("FishingCastOriginLeft")
	if fishing_cast_origin_right == null:
		fishing_cast_origin_right = get_node_or_null("FishingCastOriginRight")

func _physics_process(delta):
	if tethered:
		tether_process(delta)
	else:
		normal_process(delta)

	_jump_visual_timer = max(_jump_visual_timer - delta, 0.0)
	_update_animation()
	
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
			_jump_visual_timer = JUMP_VISUAL_TIME
	
	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		_set_sprite_direction(direction)
		velocity.x = move_toward(velocity.x, direction * SPEED, delta * 2000.)
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
		_jump_visual_timer = JUMP_VISUAL_TIME
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
	_set_one_way_collision_enabled(false)
	rigid = RigidBody2D.new()
	rigid.lock_rotation = true
	rigid.collision_mask = collision_mask
	rigid.collision_layer = collision_layer
	get_parent().add_child(rigid)
	rigid.position = position
	var shape = CollisionShape2D.new()
	shape.shape = CapsuleShape2D.new()
	shape.shape.radius = 32
	shape.shape.height = 128
	rigid.add_child(shape)
	
	# get the players velocity that is tangent to the swinging arc
	var tether_dir = position.direction_to(star.position)
	var tangent_dir = Vector2(-tether_dir.y, tether_dir.x).normalized()
	var speed = velocity.dot(tangent_dir)
	rigid.linear_velocity = speed * tangent_dir

func untether():
	tethered = null
	rigid.queue_free()
	_set_one_way_collision_enabled(true)

func _update_animation() -> void:
	if animation_player == null:
		return

	if tethered != null:
		_play_animation("pull")
	elif _jump_visual_timer > 0.0 or not is_on_floor():
		_play_animation("jump")
	else:
		_play_animation("idle")

func _play_animation(animation_name: StringName) -> void:
	if animation_player.current_animation == animation_name and animation_player.is_playing():
		return
	animation_player.play(animation_name)

func get_cast_origin() -> Vector2:
	if player_sprite != null and player_sprite.flip_h:
		if fishing_cast_origin_left != null:
			return fishing_cast_origin_left.global_position
	else:
		if fishing_cast_origin_right != null:
			return fishing_cast_origin_right.global_position
	return global_position

func _set_one_way_collision_enabled(enabled: bool) -> void:
	var one_way_bit := 1 << (one_way_platform_layer - 1)
	if enabled:
		collision_mask = _default_collision_mask | one_way_bit
	else:
		collision_mask = _default_collision_mask & ~one_way_bit
	if rigid != null:
		rigid.collision_mask = collision_mask
