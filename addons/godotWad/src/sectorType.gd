extends Node


export(int) var darkValue 
export(int) var brightValue
export(float) var interval = 1.0
export(String) var meshPath = ""
export(int) var type = 0
var curValue = brightValue
var timer = 0

var materialIdx = 0

var matsInSector = []
var dir = -1

var flickerTypes = [1,2,3,4,8,12,13,17]


func _ready():
	
	var mesh : ArrayMesh = get_node(meshPath).mesh 
	for i in mesh.get_surface_count():
		
		var originalMat = mesh.surface_get_material(i)

		var runtimeMat = originalMat.duplicate()
		mesh.surface_set_material(i,runtimeMat)
		matsInSector.append(runtimeMat)
	
		if type == 2: interval = 0.5
		if type == 3: interval = 1.0  
		if type == 4: interval = 0.5
		if type == 8: interval = 1.0
		
	if !flickerTypes.has(type):
		queue_free()
		
	
func _physics_process(delta):
	
	timer += delta
	
	if timer > interval and type != 8:
		if curValue == darkValue: 
			curValue = brightValue
		else: 
			curValue = darkValue
			
		
		for i in matsInSector:
			i.set_shader_param("tint",Color(curValue/256.0,curValue/256.0,curValue/256.0))
		timer = 0
		
	if type == 8:
		if dir == -1:
			curValue = max(curValue-1,darkValue)
			if curValue == darkValue: dir = 1
			
		if dir == 1:
			curValue = min(curValue+1,brightValue)
			if curValue == brightValue: dir = -1
		
		for i in matsInSector:
			i.set_shader_param("tint",Color(curValue/256.0,curValue/256.0,curValue/256.0))


func fetchMat(origMat):
	var par = get_parent()
	
	if !par.has_meta("matList"):
		var dict = {}
		par.set_meta("matList",dict)

	var dict = par.get_meta("matList")
	
	if !dict.has(origMat):
		dict[origMat] = origMat.duplicate()
		par.set_meta("matList",dict)
	
	return dict[origMat]
	
