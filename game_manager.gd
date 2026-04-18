extends Node

var player: Player
var tether: StarSelector

func retry_room():
	print("retrying...")
	# play fadeout
	# respawn player
	player.die()
	await play_fade_in_cutscene()
	get_tree().reload_current_scene()
	# play fadein

func play_fade_in_cutscene():
	var nd := get_tree().current_scene.get_node("FadeOverlay")
	if nd:
		await get_tree().create_timer(.3).timeout
		await nd.fade_overlay_in(.5)
	
func play_fade_out_cutscene():
	pass
