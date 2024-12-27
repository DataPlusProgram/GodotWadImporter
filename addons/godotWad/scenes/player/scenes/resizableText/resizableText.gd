@tool
extends Control

var text = "" : set = setText
@export var scaleFactor = Vector2(1.0,1.0)

func _process(delta):
	var lDim = $Label.size
	var diffDiv = size/lDim
	$Label.scale = diffDiv * scaleFactor
	$Label.position.x = 0
	
func setText(txt):
	$Label.text = str(txt)

func setFont(font : FontFile):
	$Label.set("theme_override_fonts/font",font)
