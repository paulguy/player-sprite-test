extends Resource
class_name TextboxLine

@export var text : String
@export var view_ratio : float = 1.0

func _init(p_text : String = "", p_view_ratio : float = 1.0):
	text = p_text
	view_ratio = p_view_ratio
