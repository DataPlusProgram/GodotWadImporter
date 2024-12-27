@tool
extends Node3D


var yeilding = false
var overlappingBodies : Array[Node] = []
var walkOverBodies : Array = []

@export var triggerType : WADG.TTYPE # (WADG.TTYPE)
@export var secret: bool = false
@onready var isEditor : bool = Engine.is_editor_hint()

func _physics_process(delta):
	if isEditor:
		return
	if yeilding:
		return

	for body in overlappingBodies:
		bodyIn(body)

	for body in walkOverBodies:
		bodyIn(body)
		
	walkOverBodies = []


func bin(body):
	if !overlappingBodies.has(body):
		overlappingBodies.append(body)

func bout(body):
	
	if overlappingBodies.has(body):
		overlappingBodies.erase(body)

func bodyIn(body):
	
	if body.get_class() != "StaticBody3D":
		if "interactPressed" in body:
			if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR:
				if body.interactPressed == false: return
			
			activate()
			
			


func activate():
	set_physics_process(false)
	var curMap = get_node("../../../")
	if "modeName" in curMap.get_parent():
		curMap.get_parent().nextMap(curMap,secret)
	else:
		curMap.nextMap()

func walkOverTrigger(body):
	if !walkOverBodies.has(body):
		walkOverBodies.append(body)

func incMap(mapName):
	
	
	if mapName[0] == 'E' and mapName[2] == 'M':
		return WADG.incrementDoom1Map(mapName,secret)
	
	if mapName.substr(0,3) == "MAP":
		return WADG.incrementDoom2Map(mapName,secret)
