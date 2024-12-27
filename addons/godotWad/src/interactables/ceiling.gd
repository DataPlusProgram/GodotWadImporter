extends Node3D


enum DIR{
	UP,
	DOWN
}

enum STATE{
	TOP,
	GOING_UP,
	BOTTOM,
	GOING_DOWN
}

@export var type: int
@export var info: Dictionary
@export var damage = 0
var active = false
var speed = Vector3(0,2,0)
@export var direction: DIR
var state 
var change = 0
@export var triggerType : WADG.TEXTUREDRAW
@export var dest  : WADG.DEST
@export var globalScale : Vector3 = Vector3.ONE
@export var animMeshPath: Array = []
var topH
var bottomH
var curH
var animTextures = []
var initialSpeed
var ceilingCast : ShapeCast3D = null
var floorCast : ShapeCast3D = null
var ceiling = null
var floor = null
var targetNodes
var areasDisabled = false
var overlappingBodies : Array[Node] = []

var walkOverBodies : Array = []

func _ready():


	speed *= globalScale.y
	info["targetNodes"] = []
	animTextures = $"../../../".getAnimTextures(self,animMeshPath)
	add_to_group("levelObject",true)
	
	
	if direction == WADG.DIR.UP: 
		state = STATE.BOTTOM
		bottomH =  info["sectorInfo"]["floorHeight"]
		topH = WADG.getDest(dest,info["sectorInfo"],globalScale.y)
		curH = info["sectorInfo"]["ceilingHeight"]
		
	if direction == WADG.DIR.DOWN: 
		state = STATE.TOP
		

		bottomH = WADG.getDest(dest,info["sectorInfo"],globalScale.y)
		topH = info["sectorInfo"]["ceilingHeight"]
		curH = info["sectorInfo"]["ceilingHeight"]
		
	
	
	for t in info["targets"]:
		var mapNode = get_parent().get_parent().get_parent()
		var node = mapNode.get_node(t)
		
		if node.has_meta("ceil"): 
			info["targetNodes"].append(node)
			ceiling = node
		
		if node.has_meta("floor"):
			floor = node
			
		elif node.has_meta("type"):
			if node.get_meta("type") == &"upper": info["targetNodes"].append(node)
			
	if ceiling != null:
		ceilingCast = WADG.createCastShapeForBody(ceiling.get_child(0),Vector3(0,-0.1,0))
		
		if damage != 0 and floor != null:
			floorCast = WADG.createCastShapeForBody(floor.get_child(0),Vector3(0,1,0))
			floorCast.enabled = true
		
		
	initialSpeed = speed
	targetNodes = info["targetNodes"]


func walkOverTrigger(body):
	if !walkOverBodies.has(body):
		walkOverBodies.append(body)
		
func _physics_process(delta):
	
	
	#if get_node_or_null("trigger") != null:# X1 triggers will get deleted after first trigger
	#	for c in get_children():
	#		if c.get_class() == &"Area3D":
	for body in overlappingBodies:
		
		bodyIn(body)
	
	
	for body in walkOverBodies:
		bodyIn(body)
		
	walkOverBodies = []
	
	if state == STATE.GOING_UP:
		if curH< topH:
			curH += speed.y
		
			for node in info["targetNodes"]:
				node.position.y += speed.y
				
		if curH >= topH:
			state = STATE.TOP
			
				
	if state == STATE.GOING_DOWN:
		var flag = false
		
		if ceilingCast !=null:
			ceilingCast.force_shapecast_update()
			ceilingCast.enabled = false
			
			for i in ceilingCast.get_collision_count():
				var ceilCollider : Node3D = ceilingCast.get_collider(i)
				if !ceilCollider.has_meta("floor"):
					if ceilCollider.get_class() != "StaticBody3D":
						speed = Vector3(0,0,0)
						flag = true
						if damage != 0:
							for j in floorCast.get_collision_count():
								if floorCast.get_collider(j) ==  ceilCollider:
									if ceilCollider.has_method("takeDamage"):
										ceilCollider.takeDamage({"amt":damage})
		
		if flag == false:
			speed = initialSpeed
		
		if curH > bottomH:
			curH -= speed.y
			
			for node in info["targetNodes"]:
				node.position.y -= speed.y
		
		if curH <= bottomH:
			state = STATE.BOTTOM
	else: 
		if ceilingCast != null:
			ceilingCast.enabled = false
			speed = initialSpeed
	


func bin(body):
	
	if !overlappingBodies.has(body):
		overlappingBodies.append(body)

func bout(body):
	if overlappingBodies.has(body):
		overlappingBodies.erase(body) 

func bodyIn(body):
	
	if !"interactPressed" in body:
		return
	
	
	if body.get_class() != "StaticBody3D":
		
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR:
			if "interactPressed" in body:
				if body.interactPressed == false:
					return
			else:
				return
		
		
		
		
		for i in get_incoming_connections():
			var triggerNode : Node = i["signal"].get_object()
			triggerNode.disconnect("body_entered",i["callable"])
		
		for i in animTextures:
			i.current_frame = 1
			if get_node_or_null("buttonSound"):
				get_node("buttonSound").play()
		
		if state == STATE.TOP: 
			state = STATE.GOING_DOWN
			if get_node_or_null("closeSound")!= null: get_node("closeSound").play()
			
		elif state == STATE.BOTTOM: 
			state = STATE.GOING_UP
			if get_node_or_null("openSound")!= null: get_node("openSound").play()
		
		#if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.WALK1: 
			#for i in get_children():
				#areasDisabled = true
				#
				#if i.get_class() == &"Area3D":
					#i.monitoring = false
					#i.monitorable = false


func serializeSave():
	var yArr = []
	
	for i in targetNodes.size():
		yArr.append(targetNodes[i].position.y)
	
	var dict = {"yArr":yArr,"state":state,"curH":curH}
	
	dict["areasDisabled"] = areasDisabled
	return dict
	
func serializeLoad(data : Dictionary):
	
	state = data["state"]
	curH = data["curH"]
	
	for i in data["yArr"].size():
		targetNodes[i].position.y = data["yArr"][i]
	
	for i in get_children():
		if i.get_class() == "Area3D":
			i.monitoring = !data["areasDisabled"]
			i.monitorable = !data["areasDisabled"]
	
