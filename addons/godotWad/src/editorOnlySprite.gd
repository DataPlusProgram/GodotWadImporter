@tool
extends Sprite3D

@export var spritePath = ""

func _ready():
	
	#texture = load(spritePath)
	
	if Engine.is_editor_hint():
		visible = true
	else:
		visible = false
