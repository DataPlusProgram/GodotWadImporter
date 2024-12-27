@tool
extends Node



@export var interval: float = 1.0
@export var darkestNeighbour  : float = 1.0
@export var initialValue : float = 1.0
@export var meshPath: String = ""
@export var sectorIndex : = -1
@export var lightType : WADG.LIGHT_TYPE = WADG.LIGHT_TYPE.BLINK
@export var useInstanceShaderParam = false

@onready var mapNode = $"../../"
@onready var sectorInfo : Array=  mapNode.get_meta("polyIdxToInfo")


var timer = 0
var materialIdx = 0
var matsInSector = []
var meshInSector = []
var dir = -1
var isRandom = false
var curValue = initialValue
func _ready():
	
	
	if Engine.is_editor_hint():
		return
	
	var node = get_node(meshPath)
	var mesh = null
	
	if node is MultiMeshInstance3D:
		mesh =  node.multimesh.mesh
	else:
		mesh = node.mesh 
	
	
	
	if lightType != WADG.LIGHT_TYPE.STROBE:
		if initialValue < darkestNeighbour:
			queue_free()
	
	if !useInstanceShaderParam:
		addMeshToTracking(mesh)
	else:
		meshInSector.append(get_node(meshPath))
	
	for i in $"../../Geometry".get_children():
		if i.has_meta("sectorIdx"):
			if i.get_meta("sectorIdx") == sectorIndex:
				if i.get_class() == "MeshInstance3D":
					if !useInstanceShaderParam:
						addMeshToTracking(i.mesh)
					else:
						meshInSector.append(i)
				
	
	if get_node(meshPath).get_parent().name == "sector " + str(sectorIndex):
		for i in get_node(meshPath).get_parent().get_children():
			if i.get_class() == "MeshInstance3D":
				if i != self:
						if !useInstanceShaderParam:
							addMeshToTracking(i.mesh)
						else:
							meshInSector.append(i)
			else: 
				for c in i.get_children():
					if c.get_class() == "MeshInstance3D":
						if !useInstanceShaderParam:
							addMeshToTracking(c.mesh)
						else:
							meshInSector.append(c)
	
	if interval == -1:
		isRandom = true
		setRandomInterval()
		
	var lightAdjust = WADG.getLightLevel(initialValue)
	curValue = initialValue

		

func addMeshToTracking(mesh : ArrayMesh):

	for i in mesh.get_surface_count():
			
		var originalMat = mesh.surface_get_material(i)
		if originalMat == null:
			queue_free()
			return
		var runtimeMat = originalMat.duplicate()
		mesh.surface_set_material(i,runtimeMat)
		matsInSector.append(runtimeMat)

		
func setRandomInterval():
	var rand = randi_range(0,1)
	if rand == 0:
		interval = 1.0
	else:
		interval = 0.5
		
func _physics_process(delta):
	
	timer += delta
	var lightAdjust = WADG.getLightLevel(curValue)
	
	if timer > interval and lightType != WADG.LIGHT_TYPE.GLOW:
		if curValue == darkestNeighbour: 
			curValue = initialValue
		else: 
			curValue = darkestNeighbour
			
		
		
		
		for i in matsInSector:
			i.set_shader_parameter("sectorLight",Color(lightAdjust,lightAdjust,lightAdjust))
	
		for i : GeometryInstance3D in meshInSector:
			i.set("instance_shader_parameters/sectorLight",Color(lightAdjust,lightAdjust,lightAdjust))
		
		timer = 0
		if isRandom:
			setRandomInterval()
		
	if lightType == WADG.LIGHT_TYPE.GLOW:
		if dir == -1:
			curValue = max(curValue-1,darkestNeighbour)
			if curValue == darkestNeighbour: dir = 1
			
		if dir == 1:
			curValue = min(curValue+1,initialValue)
			if curValue == initialValue : dir = -1
		
		for i in matsInSector:
			if !useInstanceShaderParam:
				i.set_shader_parameter("sectorLight",Color(lightAdjust,lightAdjust,lightAdjust))
			else:
				i.set_shader_parameter("instance_shader_parameters/",Color(lightAdjust,lightAdjust,lightAdjust))
	
	sectorInfo[sectorIndex]["light"] = curValue
	#WADG.getSectorInfo(mapNode,sectorIndex)["light"] = curValue
