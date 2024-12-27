extends VBoxContainer


func _ready() -> void:
	if OS.has_feature("standalone"):
		queue_free()


func _process(delta):
	if OS.has_feature("standalone"):
		visible = false
		return
	
	var t = $"fps"
	$"fps".text = "fps:" + str(Engine.get_frames_per_second())
	$"drawCalls".text = "draw calls:" + str(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	#$"vertices".text = "vertices:" + str(Performance.get_monitor(Performance.RENDER_VERTICES_IN_FRAME))
	#$"material".text = "materials:" + str(Performance.get_monitor(Performance.RENDER_MATERIAL_CHANGES_IN_FRAME))
	
	$"objects".text = "objects:" + str(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	$"physTime".text = "physTime:" + str(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS))
	$"orphans".text = "orhpans:" + str(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	$"resource".text = "resource:" + str(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	$ram.text =  "ram:" + str(snapped(OS.get_static_memory_usage()/1048576.0,1.0))

	#Performance.get_monitor(Performance.)
