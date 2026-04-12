extends Node2D

@export var player_scene: PackedScene = preload("res://Player/player_dude.tscn")
@export var player_spawn_marker_path: NodePath = NodePath("PlayerSpawn")

func _ready() -> void:
	if _find_existing_player() != null:
		return

	if player_scene == null:
		push_warning("No player_scene assigned for zone runtime spawn.")
		return

	var spawned_player := player_scene.instantiate() as Node2D
	if spawned_player == null:
		push_warning("Configured player_scene is not a Node2D and cannot be positioned.")
		return

	var spawn_position := global_position
	var spawn_marker := get_node_or_null(player_spawn_marker_path) as Marker2D
	if spawn_marker != null:
		spawn_position = spawn_marker.global_position

	get_tree().current_scene.add_child(spawned_player)
	spawned_player.global_position = spawn_position

func _find_existing_player() -> Player:
	var root := get_tree().current_scene
	if root == null:
		return null
	return _find_player_recursive(root)

func _find_player_recursive(node: Node) -> Player:
	if node is Player:
		return node
	for child in node.get_children():
		var found := _find_player_recursive(child)
		if found != null:
			return found
	return null
