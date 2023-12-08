tool
extends Sprite3D

export var spritePath = ""

func _ready():
	
	#texture = load(spritePath)
	
	if Engine.editor_hint:
		visible = true
	else:
		visible = false
