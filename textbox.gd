extends Node2D
class_name Textbox

# some necessary shenanigans
const TITLE_MARGIN : Vector2 = Vector2(5.0, 5.0)
const TITLEBAR_ADJUSTMENT : Vector2 = Vector2(0.0, 11.0)

@onready var textbox : NinePatchRect = $"Textbox"
@onready var textbox_text : RichTextLabel = $"Textbox/Textbox Text"
@onready var titlebar : NinePatchRect = $"Title"
@onready var titlebar_text : RichTextLabel = $"Title/Title T"

var border_margin : Vector2
var title_margin : Vector2
var text_line : TextboxLine = null

func calc_sizes() -> Vector2:
	if text_line == null:
		# not fully defined yet, so don't try to return anything useful
		return Vector2.ZERO

	var text_cache : Dictionary = TextboxCache.text_cache
	var text = text_line.text
	var ratio = text_line.view_ratio

	# force the title text to reduce to minimum
	titlebar_text.size = Vector2.ZERO

	# set the text, but try not to get it to adjust anything right away
	textbox_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	textbox_text.fit_content = false
	textbox_text.text = text

	if text_line in text_cache:
		textbox_text.size.x = text_cache[text_line]
		# turn wrapping back on
		textbox_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		textbox_text.fit_content = true
	else:
		# if a width still wasn't found in the cache, calculate it

		# get the max string length (wrapping hasn't happened)
		var text_width = textbox_text.get_content_width()

		# set max width to prevent wrapping
		textbox_text.size.x = text_width
		# set wrapping mode to start 
		textbox_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		textbox_text.fit_content = true
		# binary search for the width closest to the desired ratio
		var low = 0.0
		var high = text_width
		# this feels fragile...
		while abs(low - high) > 1.0:
			textbox_text.size.x = low + ((high - low) / 2)
			if float(textbox_text.get_content_width()) / float(textbox_text.get_content_height()) < ratio:
				low = textbox_text.size.x
			else:
				high = textbox_text.size.x
		text_cache[text_line] = textbox_text.size.x

	# TODO: This kinda sucks and doesn't always give ideal results...
	# make sure the sizes are the same and appropriate
	if titlebar_text.size.x + title_margin.x > textbox_text.size.x + border_margin.x:
		textbox_text.size.x = titlebar_text.size.x + title_margin.x - border_margin.x
	else:
		titlebar_text.size.x = textbox_text.size.x + border_margin.x - title_margin.x
	textbox_text.size.y = textbox_text.get_content_height()

	# set the box width around the border
	textbox.size = textbox_text.size + border_margin
	titlebar.size = titlebar_text.size + title_margin - TITLEBAR_ADJUSTMENT
	var total_size : Vector2 = Vector2(textbox.size.x, titlebar.size.y + textbox.size.y)
	textbox.position = Vector2(-total_size.x / 2.0, -textbox.size.y)
	titlebar.position = Vector2(-total_size.x / 2.0, -total_size.y)

	return total_size

func set_title(title_text : String) -> void:
	titlebar_text.text = title_text
	return calc_sizes()

func set_text(text : TextboxLine) -> Vector2:
	text_line = text
	return calc_sizes()

# Called when the node enters the scene tree for the first time.
func _ready():
	# get the fixed border size
	border_margin = Vector2(textbox.patch_margin_left + textbox.patch_margin_right,
							textbox.patch_margin_top + textbox.patch_margin_bottom)
	textbox_text.position = Vector2(textbox.patch_margin_left, textbox.patch_margin_top)
	title_margin = Vector2(TITLE_MARGIN.x + titlebar.patch_margin_right,
						   TITLE_MARGIN.y + titlebar.patch_margin_bottom)
	titlebar_text.position = TITLE_MARGIN
