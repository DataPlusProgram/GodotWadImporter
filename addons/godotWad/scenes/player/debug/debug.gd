extends VBoxContainer




func _process(delta):
	var t = $"fps"
	$"fps".text = "fps:" + str(Engine.get_frames_per_second())
	$"drawCalls".text = "draw calls:" + str(Performance.get_monitor(Performance.RENDER_DRAW_CALLS_IN_FRAME))
	$"vertices".text = "vertices:" + str(Performance.get_monitor(Performance.RENDER_VERTICES_IN_FRAME))
	$"material".text = "materials:" + str(Performance.get_monitor(Performance.RENDER_MATERIAL_CHANGES_IN_FRAME))
	$"objects".text = "objects:" + str(Performance.get_monitor(Performance.RENDER_OBJECTS_IN_FRAME))
	$"physTime".text = "physTime:" + str(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS))
	$"processTime".text = "orhpans:" + str(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	$"resource".text = "resource:" + str(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	
