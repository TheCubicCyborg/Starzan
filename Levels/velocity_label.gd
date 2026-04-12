extends Label

func _ready():
	if !GameManager.player: set_process(false)

func _process(delta: float) -> void:
	var player := GameManager.player
	
	var kv := player._kinematic_velocity
	var rv := player._reeling_velocity
	
	text = """Kinematic Speed: %4.2d  %4.2d
	Reeling Speed: %4.2d  %4.2d """ % [kv.x, kv.y, rv.x, rv.y]
