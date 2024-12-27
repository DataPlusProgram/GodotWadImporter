@tool
extends Node3D

@export var info: Array
@export var inc: float = 0
@export var globalScale: Vector3 = Vector3.ONE

var stairGroups = []
var stairPos = []
var initStairPos = []
var type
var active = false
var triggerType = 0
var state  = STATE.TOP
var speed = 0.5
var areasDisabled = false
var walkOverBodies : Array = []
var overlappingBodies : Array[Node] = []

@onready var isEditor: bool =  Engine.is_editor_hint()

enum STATE{
	TOP,
	GOING_DOWN,
	BOTTOM,
	GOING_UP
}



var nodesToCasts = []

func _ready():
	if isEditor:
		return
	add_to_group("levelObject",true)
	
	
	inc *= globalScale.y
	speed *= globalScale
	for i in info:
		
		var nodesInStair = []
				
		for target in i["targets"]:
			
			var node =$"../../../".get_node(target)
			
			nodesInStair.append(node)
			initStairPos.append(node.position.y)
			
			if !node.has_meta("floor"):
				continue
			#print(node.name,",",node.get_meta_list())
			var castFloor = WADG.createCastShapeForBody(node.get_child(0),Vector3(0,0.1,0))
			var castCeil = WADG.createCastShapeForBody(node.get_child(0),Vector3(0,-0.1,0))
			
			castFloor.enabled = false
			castCeil.top_level = true
			castCeil.position.y = i["sectorInfo"]["ceilingHeight"] - 0.1
			castCeil.enabled = false
			#node.set_meta("ceilingCast",castCeil)
			nodesToCasts.append([castFloor,castCeil])
			
			for child in node.get_parent().get_children():
				if child.name.find("ceil") != -1:
					
					var ceilCast = WADG.createCastShapeForBody(child.get_child(0),Vector3(0,-0.1,0))
					ceilCast.enabled = false
					node.set_meta("ceilingCast",ceilCast)
			
		
			
		stairGroups.append(nodesInStair)
		stairPos.append(0)
			
	
	

func walkOverTrigger(body):
	if !walkOverBodies.has(body):
		if !(body is StaticBody3D):
			walkOverBodies.append(body)

func _physics_process(delta):
	
	if isEditor:
		return
	#if get_node_or_null("trigger") != null:# X1 triggers will get deleted after first trigger
	#if !areasDisabled:
	#	for c in get_children():
	#		if c.get_class() == "Area3D":
	#			for body in c.get_overlapping_bodies():
#					bodyIn(body)
	for body in overlappingBodies:
		bodyIn(body)
	
	
	for body in walkOverBodies:
		bodyIn(body)
		
	walkOverBodies = []
	
	if active:
		for idx in stairGroups.size():
			if stairPos[idx] < inc*(idx+1):
				for node in stairGroups[idx]:
					node.position.y += speed.y
					
					var casts = nodesToCasts[idx]
					var floorCast : ShapeCast3D= casts[0]
					var ceilCast : ShapeCast3D = casts[1]
					
					ceilCast.enabled = true
					ceilCast.force_shapecast_update()
					ceilCast.enabled = false
					
					if ceilCast.get_collision_count() <= 0:
						continue
					
					floorCast.enabled = true
					floorCast.force_shapecast_update()
					floorCast.enabled = false
					
					if floorCast.get_collision_count() <= 0:
						continue
					
					for colIdxCeil in ceilCast.get_collision_count():
						for colIdxFloor in floorCast.get_collision_count():
							var colA = ceilCast.get_collider(colIdxCeil)
							var colB = floorCast.get_collider(colIdxFloor)
							
							
							if colA == colB and !(colA is StaticBody3D):
								node.position.y -= speed.y
								continue
							
							#if ceilCast.get_collider(colIdxCeil) == floorCast.get_collider(colIdxFloor):
								
								
						

			stairPos[idx] += speed.y
		


func bin(body):
	if !overlappingBodies.has(body):
		if !(body is StaticBody3D):
			overlappingBodies.append(body)

func bout(body):
	if overlappingBodies.has(body):
		overlappingBodies.erase(body)

func bodyIn(body):
		
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
		if "interactPressed" in body:
			if body.interactPressed == false:
				return
			else:
				if get_node_or_null("buttonSound") != null:
					if state != STATE.GOING_DOWN and state != STATE.GOING_UP:
						get_node("buttonSound").play()
		
		
	active = true
	
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.WALK1: 
		for i in get_children():
			areasDisabled = true
			if i.get_class() == "Area3D":
				i.monitoring = false
				i.monitorable = false


func serializeSave():
	var yArr = []
	
	
	var animtexturesFrames = []
	
	var posArr = []
	
	#for idx in stairGroups.size():
	#	posArr.append(stairGroups[idx][0].position.y)
			
	
	
	
	var dict= {"yArr":yArr,"state":state,"curH":stairPos,"initH":initStairPos}
	
	dict["active"] = active
	dict["parOwner"] = null
	dict["areasDisabled"] = areasDisabled
	
	
	if get_parent().has_meta("curOwner"):
		if get_parent().get_meta("curOwner") != self:
			dict["parOwner"] =  get_parent()
			
	return dict
	
	
func serializeLoad(dict : Dictionary):
	
	var posList = dict["curH"]
	areasDisabled = dict["areasDisabled"]
	active = dict["active"]
	
	var k = 0
	for i in info:
		for target in i["targets"]:
			var node =$"../../../".get_node(target)
			node.position.y = dict["initH"][k]
			k += 1
	
	
	for idx in posList.size():
		for node in stairGroups[idx]:
			node.position.y += min(posList[idx],inc*(idx+1))
			
			stairPos[idx] = posList[idx]
	
	for i in get_children():
		if i.get_class() == "Area3D":
			i.monitoring = !areasDisabled
			i.monitorable = !areasDisabled
