extends NinePatchRect
class_name Textbox

@onready var textbox = $"Textbox Text"
var font
var border_margin

func set_text(text_line : TextboxLine) -> Vector2:
	var text_cache : Dictionary = TextboxCache.text_cache

	var text : String = text_line.text
	var ratio : float = text_line.view_ratio

	# produce the key for caching purposes
	#var key : Array = [text, ratio]

	# set the text, but try not to get it to adjust anything right away
	textbox.autowrap_mode = TextServer.AUTOWRAP_OFF
	textbox.fit_content = false
	textbox.text = text

	if text_line in text_cache:
		textbox.size.x = text_cache[text_line]
		# turn wrapping back on
		textbox.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		textbox.fit_content = true
	else:
		# if a width still wasn't found in the cache, calculate it

		# get the max string length (wrapping hasn't happened)
		var text_width = textbox.get_content_width()

		# set max width to prevent wrapping
		textbox.size.x = text_width
		# set wrapping mode to start 
		textbox.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		textbox.fit_content = true
		# binary search for the width closest to the desired ratio
		var low = 0.0
		var high = text_width
		# this feels fragile...
		while abs(low - high) > 1.0:
			textbox.size.x = low + ((high - low) / 2)
			if textbox.get_content_width() / textbox.get_content_height() < ratio:
				low = textbox.size.x
			else:
				high = textbox.size.x
		text_cache[text_line] = textbox.size.x

	# set the box width around the border
	size = Vector2(textbox.get_content_width(), textbox.get_content_height()) + border_margin

	return size

# Called when the node enters the scene tree for the first time.
func _ready():
	# get the fixed border size
	border_margin = Vector2(patch_margin_left + patch_margin_right,
							patch_margin_top + patch_margin_bottom)
	textbox.position = Vector2(patch_margin_left, patch_margin_top)
