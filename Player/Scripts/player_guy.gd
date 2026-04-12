extends RigidBody2D

var _input_vec: Vector2
var _current_star: GrabStar
var _pressed_jump_this_frame: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.grab_star_grabbed.connect(_on_grab_star_grabbed)
	SignalBus.grab_star_released.connect(_on_grab_star_released)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	_input_vec = Input.get_vector(
		"move_left", "move_right",
		"move_up", "move_down"
	).normalized()
	
	_input_vec.y = 0
	
	_pressed_jump_this_frame = Input.is_action_just_pressed("jump")

func _physics_process(delta: float) -> void:
	
	var move_force_amt: float = 1000.
	var pull_force_amt: float = 500.
	var jump_force_amt: float = 30000.
	
	if _pressed_jump_this_frame:
		_pressed_jump_this_frame = false
		apply_central_force(Vector2.UP * jump_force_amt)
		
	if _input_vec:
		apply_central_force(_input_vec * move_force_amt)
	
	if _current_star:
		var direction_to_star = (_current_star.global_position - global_position).normalized()
		apply_central_force(direction_to_star * pull_force_amt)
	
func _on_grab_star_grabbed(star: GrabStar):
	_current_star = star
	print("grabbed %s" % star.name)
	
func _on_grab_star_released(_s: GrabStar):
	if _current_star:
		print("released star %s" % _current_star.name)
		_current_star = null

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_released():
			_on_grab_star_released(_current_star)
