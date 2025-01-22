extends Area2D
class_name DoorArea

# this can't be PackedScene because apparently 2 scenes can't refer to each
# other directly.
@export var destination_scene : String
@export var destination_id : int

var player_in_area : bool = false
@onready var game : Node2D = $"/root/Game"

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_area = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_area = false

func _process(_delta : float):
	if player_in_area and Input.is_action_just_pressed("use"):
		game.go_to_scene(destination_scene, destination_id)
