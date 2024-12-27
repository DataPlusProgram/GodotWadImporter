extends Control


func _input(event):
	if !visible:
		return
	
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			visible = false
	
