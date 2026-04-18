extends Node2D

@export var star_lights: Array[PointLight2D]
const smallest_scale := Vector2(.01, .01)
const largest_scale := Vector2(20., 20.)

func _ready():
	print('fading overlay out...')
	fade_overlay_out(1.)

func fade_overlay_in(time: float):
	print("fading in!!")
	for star_light in star_lights:
		star_light.scale = largest_scale
		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_IN)
		#tween.set_trans(Tween.TRANS_QUINT)
		tween.tween_property(star_light, "scale", smallest_scale, time)
		tween.set_parallel(true)
		
	# is this the worst code ever?
	await get_tree().create_timer(time).timeout

func fade_overlay_out(time: float):
	for star_light in star_lights:
		star_light.scale = smallest_scale
		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_QUINT)
		tween.tween_property(star_light, "scale", largest_scale, time)
		tween.set_parallel(true)
	
	# is this the worst code ever?
	await get_tree().create_timer(time).timeout
