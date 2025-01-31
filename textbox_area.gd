extends Area2D
class_name TextboxArea

@export var text_lines : Array[TextboxLine]
@export var freeze_player : bool = false
@export var cancelable : bool = true

@onready var sprite : Sprite2D = $"Attention Sprite"
@onready var anim : AnimationPlayer = $"Attention Sprite Anim"
@onready var textbox : Textbox = $"Textbox"
@onready var shape : CollisionShape2D = $"CollisionShape2D"

var player : Player = null
var textbox_showing : int = -1

func done():
	textbox_showing = -1
	textbox.visible = false
	player.process_mode = Node.PROCESS_MODE_INHERIT

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	textbox.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		anim.play(&"fade in")
		player = body

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		anim.play(&"fade out")
		if textbox_showing >= 0:
			done()
		player = null

func _process(_delta : float):
	if player != null:
		if Input.is_action_just_pressed("use"):
			textbox_showing += 1
			if textbox_showing == len(text_lines):
				done()
			else:
				if freeze_player:
					player.process_mode = Node.PROCESS_MODE_DISABLED
				textbox.visible = false
				var size : Vector2 = textbox.set_text(text_lines[textbox_showing])
				textbox.position = Vector2(size.x / -2.0, -size.y - (shape.shape.get_rect().size.y / 2.0))
				textbox.visible = true
		elif cancelable and Input.is_action_just_pressed("cancel"):
			done()
