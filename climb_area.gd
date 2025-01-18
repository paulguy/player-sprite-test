extends Area2D
class_name ClimbArea

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.entered_climbable()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.left_climbable()
