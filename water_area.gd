extends Area2D
class_name WaterArea

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.entered_water()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.left_water()
