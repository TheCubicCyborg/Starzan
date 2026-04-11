extends RigidBody2D

var moving = false
var target: CollisionObject2D

@export var speed = 100
@export var max_speed = 600.0
@export var radius = 100
@export var start_angle = 0

var current_angle = 0.0
var orbit = false


func _input(event):
	if event is InputEventMouseButton :
		if event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			var mousepos = get_global_mouse_position()
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsRayQueryParameters2D.create(global_position, mousepos)
			var result = space_state.intersect_ray(query)
			
			if result:
				speed = 100
				var collider = result["collider"]
				
				if collider.is_in_group("star"):	
					moving = true
					target =  collider
					orbit = false
					print(collider)
				
		elif !event.pressed:
			orbit = false
			moving = false
			target = null
			


func _physics_process(delta):
	if moving:
		var direction = (target.global_position - global_position).normalized()
		apply_force(direction * speed)
		linear_velocity = linear_velocity.limit_length(max_speed)
		# Stop when close enough
		if global_position.distance_to(target.global_position) < radius:
			moving = false
			orbit = true
			linear_velocity = Vector2.ZERO
			start_angle = (global_position - target.global_position).angle()
	if orbit:
		current_angle += deg_to_rad(speed)*delta
		var x = target.global_position.x + cos(start_angle+current_angle)*radius
		var y = target.global_position.y + sin(start_angle+current_angle) *radius
		var desired_position = Vector2(x,y)
		linear_velocity = (desired_position - global_position) / delta
		if speed < max_speed:
			speed += 5
		
			
		
