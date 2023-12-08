tool
extends Control


var handleInputPar = false

func _input(event):
	
	for i in $Viewport.get_children():
		i.set_process_input(false)
	
	
	if !("position" in event):
		return
	
	
	var mPos = event.position
	mPos = event.global_position
	var pos = get_global_rect().position
	var dim = get_rect().size
	
	if Engine.editor_hint:
		if mPos.x < pos.x or mPos.x > (pos.x + dim.x): 
			return

		if mPos.y < pos.y or mPos.y > (pos.y + dim.y):
			return

	if !Engine.editor_hint:
		mPos = event.position
		if mPos.x < pos.x or mPos.x > (pos.x + dim.x): 
			return

		if mPos.y < pos.y or mPos.y > (pos.y + dim.y):
			return
		
	
	
	
	#for i in $Viewport.get_children():
	#	i.set_process_input(true)
	
	if $Viewport/CameraTopDown.visible:
		$Viewport/CameraTopDown._input(event)
		
	if $Viewport/Camera.visible:
		$Viewport/Camera._input(event)
