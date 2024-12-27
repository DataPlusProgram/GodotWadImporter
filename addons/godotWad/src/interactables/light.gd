@tool
extends Node


var animMeshPath = []
@export var info: Dictionary
@export var triggerType  :WADG.TTYPE
@export var lightValue = 0
@onready var mapNode = get_node("../../../")
var initializedMats = false
var animTextures
var arr = []
var matMap = {}
var overlappingBodies = []
var walkOverBodies : Array = []
var sectorInfo : Dictionary
var runtimeMaterials = []
var runtimeMeshInstance3D : Array[MeshInstance3D] = []
var sectorPolyInfo : Array= [] 
var sectorIndex = -1
@export var doesBlink = false
var isBlinking = false
@export var initialValue = -1
var curVaule = -1
var timer : float = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	if Engine.is_editor_hint():
		return
	
	#var test = WADG.funcGetMergedSectorMesh(mapNode.get_node("Geomtery"),sectorInfo["index"])

	animTextures = $"../../../".getAnimTextures(self,animMeshPath)
	

			
func walkOverTrigger(body):
	if !walkOverBodies.has(body):
		walkOverBodies.append(body)


func _physics_process(delta: float) -> void:

	
	if isBlinking:
		if timer > 0:
			timer -= delta
		
		if timer <= 0:
			if curVaule == initialValue:
				setLightValue(lightValue)
			else:
				setLightValue(initialValue)
				
			timer = 1.0
		
		
	for body in overlappingBodies:
		bodyIn(body)
	
	for body in walkOverBodies:
		bodyIn(body)
	
	walkOverBodies = []

func bodyIn(body):
	

	if "interactPressed" in body:
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR:
			if body.interactPressed != true:
				return
	
	activate()
		

func  initializeMats():
	
	if initialValue == -1:
		initialValue = sectorInfo["lightLevel"]
	sectorIndex = sectorInfo["index"]
	initializedMats = true
	for path in info["targets"]:
		var n = mapNode.get_node_or_null(path)
		if n != null:
			if doesMeshUseInstancedShaderVariables(n):
				runtimeMeshInstance3D.append(n)
			addMeshToTracking(n.mesh)
	
	var mergedMesh : Array[MeshInstance3D] = WADG.funcGetMergedSectorMeshInstance(mapNode.get_node("Geometry"),sectorIndex)
	
	if mergedMesh.size() > 0 and doesMeshUseInstancedShaderVariables(mergedMesh[0]):
		runtimeMeshInstance3D += mergedMesh
	else:
		for i in mergedMesh:
			addMeshToTracking(i.mesh)
	

func addMeshToTracking(mesh : ArrayMesh):
	for i in mesh.get_surface_count():
		
		var originalMat = mesh.surface_get_material(i)
		if originalMat == null:
			queue_free()
			return
		var runtimeMat = originalMat.duplicate()
		mesh.surface_set_material(i,runtimeMat)
		runtimeMaterials.append(runtimeMat)
	

func bin(body):
	if body.get_class() == "StaticBody3D": return
	if !"interactPressed" in body: return
	
	overlappingBodies.append(body)
	
func bout(body):
	if overlappingBodies.has(body):
		overlappingBodies.erase(body)
	
func activate():
	
	
	if doesBlink:
		isBlinking = true
		
	#if initializedMats == false:
	initializeMats()
	sectorPolyInfo = mapNode.get_meta("polyIdxToInfo")
	
	
	setLightValue(lightValue)

		
	for t in animTextures:
		t.current_frame = (t.current_frame+1)%2
			
	if triggerType == WADG.TTYPE.SWITCH1:
		queue_free()

func setLightValue(value : float):
	for mat in runtimeMaterials:
		mat.set_shader_parameter("sectorLight",Color(value/256.0,value/256.0,value/256.0))
	
	for m in runtimeMeshInstance3D:
		m.set("instance_shader_parameters/sectorLight",Color(value/256.0,value/256.0,value/256.0))
		
	
	curVaule = value
	
	if sectorIndex < sectorInfo.size():
		sectorPolyInfo[sectorIndex]["sectorLight"] = value
	
func doesMeshUseInstancedShaderVariables(meshInstance : MeshInstance3D) -> bool:
	var x = meshInstance.get("instance_shader_parameters/alpha")
	return x != null
