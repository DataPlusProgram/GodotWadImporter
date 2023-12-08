extends Node


var animMeshPath = []
export(Dictionary) var info
export(WADG.TTYPE) var triggerType
export var lightValue = 0
var animTextures
var arr = []
var matMap = {}
var overlappingBodies = []
# Called when the node enters the scene tree for the first time.
func _ready():
	
	var mapNode = get_node("../../../")
	
	animTextures = $"../../../".getAnimTextures(self,animMeshPath)
	
	for path in info["targets"]:
		var n = mapNode.get_node(path)
		if n != null:
			var mat  = n.mesh.surface_get_material(0)
			
			if mat == null:
				continue
				
			var shader = mat.get_shader()
			if shader == null:
				continue
			
			
			var cur = mat.get_shader_param("tint")
			if cur == null:
				continue
			
			if !matMap.has(mat):
				matMap[mat] = mat.duplicate(true)
			
			n.mesh.surface_set_material(0,matMap[mat])
			


func _process(delta):
	
	#if get_node_or_null("trigger") != null:# X1 triggers will get deleted after first trigger
	#	for c in get_children():
	#		if c.get_class() == "Area":
#				for body in c.get_overlapping_bodies():
	#				bodyIn(body)
	for i in overlappingBodies:
		bodyIn(i)

func bodyIn(body):
	if "interactPressed" in body:
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR:
			if body.interactPressed != true:
				return
	
	on()
		

func bin(body):
	if body.get_class() == "StaticBody": return
	if !"interactPressed" in body: return
	
	overlappingBodies.append(body)
	
func bout(body):
	if overlappingBodies.has(body):
		overlappingBodies.erase(body)
	
func on():
	for i in matMap.keys():
		var mat = matMap[i]
		if lightValue == null:
			continue
		mat.set_shader_param("tint",Color(lightValue/256.0,lightValue/256.0,lightValue/256.0))
		
	for t in animTextures:
		t.current_frame = (t.current_frame+1)%2
			
	if triggerType == WADG.TTYPE.SWITCH1:
		queue_free()
