extends Node

var player: Player
var tether: StarSelector
var retrying: bool = false

func retry_room():
	if retrying: return
	retrying = true
	print("retrying...")
	# play fadeout
	# respawn player
	player.die()
	await play_fade_in_cutscene()
	get_tree().reload_current_scene()
	await get_tree().scene_changed
	retrying = false

func play_fade_in_cutscene():
	var nd := get_tree().current_scene.get_node("FadeOverlay")
	if is_instance_valid(nd):
		await get_tree().create_timer(.3).timeout
		if is_instance_valid(nd):
			await nd.fade_overlay_in(.5)
	
func play_fade_out_cutscene():
	pass


const RETRY_TIMER_LEN := 1.
var retry_timer := 0.

func _process(delta: float) -> void:
	if Input.is_action_pressed("retry"):
		retry_timer += delta
		if retry_timer > RETRY_TIMER_LEN and RETRY_TIMER_LEN != 0.:
			retry_room()
	else:
		retry_timer = 0.
