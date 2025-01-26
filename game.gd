extends Node2D

@export var first_scene : PackedScene
@export var first_id : int

var current_scene : Node2D = null
var player_scene : PackedScene = preload("res://player.tscn")
var player : Player
var player_child : Node2D

func do_go_to_scene(scene : PackedScene, id : int):
	# remove the scene if one's loaded
	if current_scene != null:
		# TODO: Some kind of transition
		# remove the player to avoid freeing
		player_child.remove_child(player)
		# remove the scene and free it
		remove_child(current_scene)
		# must be queue_free() because free() crashes randomly
		current_scene.queue_free()
	else:
		# create a player if there isn't one
		player = player_scene.instantiate()
	# insert the new scene
	current_scene = scene.instantiate()
	add_child(current_scene)
	# put the player in
	player_child = current_scene.find_child("Player %d" % id)
	player_child.add_child(player)
	# player to new location
	player.position = Vector2.ZERO
	# TODO: Do more to fix/maintain player state on transition.
	# Player uncrouches and then can't crouch until jumping.

func go_to_scene(scene_name : String, id : int):
	do_go_to_scene(load(scene_name), id)

func _ready():
	do_go_to_scene(first_scene, first_id)
