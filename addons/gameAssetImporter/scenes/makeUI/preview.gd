@tool
extends Control


var handleInputPar = false

func _input(event):
	
	for i in $SubViewport.get_children():
		i.set_process_input(false)
	
	
	if !("position" in event):
		return
	
	if !("global_position" in event):
		return
	
	var mPos = event.position
	mPos = event.global_position
	var pos = get_global_rect().position
	var dim = get_rect().size
	
	if Engine.is_editor_hint():
		if mPos.x < pos.x or mPos.x > (pos.x + dim.x): 
			return

		if mPos.y < pos.y or mPos.y > (pos.y + dim.y):
			return

	if !Engine.is_editor_hint():
		mPos = event.position
		if mPos.x < pos.x or mPos.x > (pos.x + dim.x): 
			return

		if mPos.y < pos.y or mPos.y > (pos.y + dim.y):
			return
		
	
	
	
	#for i in $Viewport.get_children():
	#	i.set_process_input(true)
	
	if $SubViewport/CameraTopDown.visible:
		$SubViewport/CameraTopDown._input(event)
		
	if $SubViewport/Camera3D.visible:
		$SubViewport/Camera3D._input(event)
