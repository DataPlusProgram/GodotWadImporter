tool
extends Sprite3D



func _ready():
	if Engine.editor_hint:
		visible = true
	else:
		visible = false
