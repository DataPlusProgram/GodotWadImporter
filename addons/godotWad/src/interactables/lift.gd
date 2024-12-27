@tool
extends Node3D

enum STATE{
	TOP,
	GOING_DOWN,
	BOTTOM,
	GOING_UP
}



@export var info: Dictionary
@export var triggerType : WADG.TTYPE
@export var state: STATE  = STATE.TOP
@export var animMeshPath: Array = []
@export var globalScale: Vector3 
var animTextures = []
var endHeight
var active = false
var speed = 2
var targets = []
var isASwitch = false
var overlappingBodies : Array = []
var walkOverBodies : Array = []
var waitClose = -1
@export var waitOpen = -1
var floorNode 
var timeoutTimer : SceneTreeTimer = null
var areasDisbaled = false
var waiting = false


func _ready():
	
	if Engine.is_editor_hint():
		return
	
	speed *= globalScale
	info["endHeight"] = info["sectorInfo"]["lowestNeighFloorExc"] 
	info["targetNodes"] = []
	
	get_parent().set_meta("curH",info["sectorInfo"]["floorHeight"])  
	add_to_group("levelObject",true)
	
	for t in info["targets"]:
		var mapNode = get_parent().get_parent().get_parent()
		var node = mapNode.get_node(t)
		
		if node.has_meta("floor"): info["targetNodes"].append(node)
		elif node.has_meta("type"):
			if node.get_meta("type") != "upper": info["targetNodes"].append(node)


	animTextures = $"../../../".getAnimTextures(self,animMeshPath)
	
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
		isASwitch = true
		
		


func walkOverTrigger(body):
	if !walkOverBodies.has(body):
		walkOverBodies.append(body)

func openTime():
	state = STATE.GOING_UP
	waiting = false
	
func closeTime():
	state = STATE.GOING_DOWN
	waiting = false
	
	
func _physics_process(delta):
	if typeof(get_parent().get_meta("owner")) == TYPE_OBJECT:
		if get_parent().get_meta("owner") != self:
			return
		
	
	for body in overlappingBodies:
		bodyIn(body)
	
	
	for body in walkOverBodies:
		bodyIn(body)
		
	walkOverBodies = []
	
	if state == STATE.GOING_DOWN:
		
		if getCurH() > info["endHeight"]:
			incCurH(-speed)
		
		for node in info["targetNodes"]:
			node.position.y-= speed.y
			
		#if info["curY"] <= info["endHeight"]:
		if getCurH() <= info["endHeight"]:
	
			for node in info["targetNodes"]:
				node.position.y = info["endHeight"]
			
			state = STATE.BOTTOM
			if waitOpen != -1:
				#await get_tree().create_timer(waitClose).timeout
				timeoutTimer = get_tree().create_timer(waitOpen)
				waiting = true
				timeoutTimer.timeout.connect(openTime)
				
			
			
			
			
	if state == STATE.GOING_UP:
		

		
		if getCurH() < info["sectorInfo"]["floorHeight"]:
			incCurH(speed)
		
		for node in info["targetNodes"]:
			node.position.y+= speed.y
			
		#if info["curY"] >= info["sectorInfo"]["floorHeight"]:
		if getCurH() >= info["sectorInfo"]["floorHeight"]:
			
			for node in info["targetNodes"]:
				node.position.y = info["sectorInfo"]["floorHeight"]
			
			state = STATE.TOP
			get_parent().set_meta("owner",false)
			
			if waitClose != -1:
				timeoutTimer = get_tree().create_timer(waitClose)
				waiting = true
				timeoutTimer.timeout.connect(closeTime)
		
	
			

func bodyIn(body : PhysicsBody3D) -> void:
	
	
	if waiting == true:
		return
	
	if !"interactPressed" in body:
		return
	
	if typeof(get_parent().get_meta("owner")) != TYPE_BOOL: 
		return
	
	
	if body.get_class() == "StaticBody3D":
		return
	
	
	
	if isASwitch and "interactPressed" in body:
		if body.interactPressed == false:
			return
		else:
			if get_node_or_null("buttonSound") != null:
				if state != STATE.GOING_DOWN and state != STATE.GOING_UP:
					get_node("buttonSound").play()
				
			for i in animTextures:
				i.current_frame = 1
		
	get_parent().set_meta("owner",self)
		
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.WALK1 or triggerType == WADG.TTYPE.GUN1:
		for i in get_incoming_connections():
			
			var triggerNode = i["signal"].get_object()
			
			var str = triggerNode.get_class()
			
			if !triggerNode is SceneTreeTimer:
				triggerNode.disconnect("body_entered",i["callable"])

		
	if state == STATE.TOP:
		state = STATE.GOING_DOWN
		if get_node_or_null("openSound")!= null:
			get_node("openSound").global_position = body.position
			get_node("openSound").play()
					
				
				
	elif state == STATE.BOTTOM:
		state = STATE.GOING_UP
		if get_node_or_null("closeSound")!= null:
			get_node("closeSound").global_position = body.position
			get_node("closeSound").play()
			



func bout(body):
	if overlappingBodies.has(body):
		overlappingBodies.erase(body)

func bin(body):
	if !overlappingBodies.has(body):
		overlappingBodies.append(body)

func getCurH():
	return get_parent().get_meta("curH")

func incCurH(amt):
	var curH = getCurH()
	get_parent().set_meta("curH",curH+amt.y)

func serializeSave():
	var yArr = []
	
	for i in info["targetNodes"].size():
		yArr.append(info["targetNodes"][i].position.y)
	
	var animtexturesFrames = []
	
	for i in animTextures:
		animtexturesFrames.append(i.current_frame)
	
	var dict :Dictionary =  {"yArr":yArr,"state":state,"curH":getCurH(),"animTextureFrames":animtexturesFrames}
	
	
	dict["parOwner"] = null
	dict["areasDisabled"] = areasDisbaled
	
	if get_parent().has_meta("curOwner"):
		if get_parent().get_meta("curOwner") != self:
			dict["parOwner"] =  get_parent()
	
	if timeoutTimer != null:
		dict["timeOutLeft"] = timeoutTimer.time_left
		
	
	

	
	return dict
	
func serializeLoad(data : Dictionary):
	
	state = data["state"]
	
	get_parent().set_meta("curH",data["curH"]) 
	''
	for i in data["yArr"].size():
		info["targetNodes"][i].position.y = data["yArr"][i]
		
	for i in data["animTextureFrames"].size():
		animTextures[i].current_frame = int(data["animTextureFrames"][i])

	if data.has("timeOutLeft"):
		if timeoutTimer != null:
			timeoutTimer.disconnect("timeout",openTime)
		
		
		timeoutTimer = get_tree().create_timer(data["timeOutLeft"])
		
		if waitOpen != -1:
			timeoutTimer.timeout.connect(openTime)
		
		if waitClose != -1:
			timeoutTimer.timeout.connect(closeTime)
		
	
	if data["parOwner"] == null:
		get_parent().set_meta("curOwner", null)
	
	areasDisbaled = data["areasDisabled"]
	
	for i in get_children():
		if i.get_class() == "Area3D":
			i.monitoring = !data["areasDisabled"]
			i.monitorable = !data["areasDisabled"]
