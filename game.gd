extends Node2D

@export var first_scene : PackedScene
@export var first_id : int

var current_scene : Node2D = null
var player_scene : PackedScene = preload("res://player.tscn")
var player : Player

func do_go_to_scene(scene : PackedScene, id : int):
	# remove the scene if one's loaded
	if current_scene != null:
		# TODO: Some kind of transition
		remove_child(current_scene)
		current_scene.free()
		# player will be freed with the scene
	# insert the new scene
	current_scene = scene.instantiate()
	add_child(current_scene)
	# put the player in
	player = player_scene.instantiate()
	current_scene.find_child("Player %d" % id).add_child(player)

func go_to_scene(scene_name : String, id : int):
	do_go_to_scene(load(scene_name), id)

func _ready():
	do_go_to_scene(first_scene, first_id)
