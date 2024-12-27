extends LineEdit



func _unhandled_input(event):
	if !event is InputEventKey:
		return
	
	if event.key_label != KEY_ENTER:
		return
	
	if event.is_echo():
		return
	
	if event.pressed:
		return
		
	$"../../../../../../"._on_ButtonFind_pressed()
