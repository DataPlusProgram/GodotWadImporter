@tool
extends Node3D

enum DIR{
	UP,
	DOWN
}

enum STATE{
	OPEN,
	OPENING,
	CLOSED,
	CLOSING
}
var overlappingBodies = []
var walkOverBodies : Array = []

var soundRef = null
var type
@export var info: Dictionary
var endHeight
var active = true
var speed : float = 0.8
@export var direction: DIR
@export var globalScale: Vector3 = Vector3.ONE
@export var category = 0
var change = 0
var top
var bottom 

@export var triggerType : WADG.TTYPE

var floorCast: ShapeCast3D = null
var ceilingCast : ShapeCast3D = null
var floorNode
var ceilingNode
var initialSpeed
var areasDisabled = false
@onready var isEditor = Engine.is_editor_hint()

func _ready():
	
	if isEditor: return
	
	add_to_group("levelObject",true)
	speed*= globalScale.y
	info["targetNodes"] = []
	
	
	info["endHeight"] = info["sectorInfo"]["floorHeight"]+8*globalScale.y
	setCurY(info["sectorInfo"]["ceilingHeight"])


	bottom = info["sectorInfo"]["floorHeight"]
	top = info["sectorInfo"]["ceilingHeight"]

	if !get_parent().has_meta("active"): get_parent().set_meta("active",false)
	if !get_parent().has_meta("owner"): get_parent().set_meta("owner",false)

	for t in info["targets"]:
		var mapNode = get_parent().get_parent().get_parent()
		var node = mapNode.get_node(t)
		if node.has_meta("ceil"): 
			info["targetNodes"].append(node)
			
			ceilingNode = node
			for j in node.get_parent().get_children():
				if j.has_meta("ceil"):
					floorNode = j
			
		elif node.has_meta("type"):
			if node.get_meta("type") == "upper": info["targetNodes"].append(node)
		
	if direction == WADG.DIR.UP: setState(STATE.CLOSED)
	if direction == WADG.DIR.DOWN: setState(STATE.OPEN)
	
	if category == WADG.LTYPE.STOPPER:
		breakpoint
		
	if floorNode != null and ceilingNode != null:
		var s = Time.get_ticks_msec()
		floorCast = WADG.createCastShapeForBody(floorNode.get_child(0),Vector3(0,0.1,0))
		ceilingCast = WADG.createCastShapeForBody(ceilingNode.get_child(0),Vector3(0,-0.1,0))
		
		SETTINGS.incTimeLog(get_tree(),"castShapes",s)
	
	initialSpeed = speed

func _physics_process(delta):
	if isEditor:
		return
	
	
	for body in walkOverBodies:
		bodyIn(body)
		
	walkOverBodies = []
	
	
	var state = getState()
	
	if getState() == STATE.CLOSING and ceilingCast != null:
		ceilingCast.enabled = true
		ceilingCast.force_shapecast_update()

		
		
		var flag = false
		for i in ceilingCast.get_collision_count():
			var collider = ceilingCast.get_collider(i)
			var parent = collider.get_parent()
		
			
			if !parent.has_meta("floor"):
				if parent.get_class() != "StaticBody3D" and collider.get_class() != "StaticBody3D":
					flag = true
					speed = 0
					if state == STATE.CLOSING:
						
						if collider.has_method("takeDamage"):
							var dict = {"amt":10,"iMS":300,"specific":"crusher","source":self}
							collider.takeDamage(dict)
							
			if collider.get_class() == "RigidBody3D":
				setState(STATE.OPENING)
				
				

					
		if flag == false:
			speed = initialSpeed
		
	else:
		speed = initialSpeed
	
	for body in overlappingBodies:
		if !is_instance_valid(body):
			overlappingBodies.erase(body)
	
	for body in overlappingBodies:
		bodyIn(body)

	if typeof(get_parent().get_meta("owner")) == TYPE_BOOL: 
		return
	
	
	var curY = getCurY()
	
	if getState() == STATE.OPENING or getState() == STATE.CLOSING:
		if get_node_or_null("openSound")!= null:
			
			if !get_node("openSound").playing:
				get_node("openSound").play()
	
	if getState() == STATE.OPENING:
		
		
		
		if curY < top:
			incCurY(speed)

			for node in info["targetNodes"]:
				node.position.y += speed
				
	if curY >= top:
		setState(STATE.OPEN)
		setState(STATE.CLOSING)
			
				
	if getState() == STATE.CLOSING:
		if curY > bottom:
			incCurY(-speed)
			
			for node in info["targetNodes"]:
				node.position.y -= speed
		
	if curY <= bottom:
		setState(STATE.CLOSED)
		setState(STATE.OPENING)


func walkOverTrigger(body):
	if !walkOverBodies.has(body):
		walkOverBodies.append(body)

func bodyIn(body : Node3D):
	
	if typeof(get_parent().get_meta("owner")) != TYPE_BOOL: 
		return
	
	if body.get_class() != "StaticBody3D" and body.is_in_group("player"):
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
			if "interactPressed" in body:
				if body.interactPressed == true:
					get_parent().set_meta("active",null)
					get_parent().set_meta("owner",self)
					
					
		if triggerType == WADG.TTYPE.WALK1 or triggerType == WADG.TTYPE.WALKR:
			get_parent().set_meta("active",null)
			get_parent().set_meta("owner",self)
		
		
		
		if triggerType == WADG.TTYPE.DOOR1 or triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.WALK1: 
			for i in get_children():
				areasDisabled = true
				if i.get_class() == "Area3D":
					i.monitoring = false
					i.monitorable = false


func getState():
	return get_parent().get_meta("state")
	
func setState(state):
	get_parent().set_meta("state",state)
	
func getCurY():
	return get_parent().get_meta("curY")

func setCurY(y):
	get_parent().set_meta("curY",y)
	
func incCurY(amt: float):
	setCurY(getCurY() + amt)



func printState(state):
	if state == STATE.OPEN: print("top")
	elif state == STATE.OPENING: print("goingUp")
	elif state == STATE.CLOSED: print("closed")
	elif state == STATE.CLOSING: print("goingDown")


func bin(body):
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
		if !"interactPressed" in body:
			return
			
	if body.get_class() == "StaticBody3D": return
	
	
	if !overlappingBodies.has(body):
		overlappingBodies.append(body)
	
	
func bout(body):
	
	if overlappingBodies.has(body):
		overlappingBodies.erase(body)

func serializeSave():
	var yArr = []

	for i in info["targetNodes"].size():
		yArr.append(info["targetNodes"][i].position.y)
	
	

	var dict : Dictionary = {"yArr":yArr,"direction":direction,"curH":getCurY()}
	dict["parOwner"] = get_parent().get_meta("owner")
	dict["state"] = getState()
	dict["areasDisabled"] = areasDisabled
	
	return dict

func serializeLoad(data : Dictionary):
	
	direction = data["direction"]
	
	setCurY(data["curH"])
	
	for i in data["yArr"].size():
		info["targetNodes"][i].position.y = data["yArr"][i]
	
	setState(data["state"])
	areasDisabled = data["areasDisabled"]
	get_parent().set_meta("owner",data["parOwner"])
	
	for i in get_children():
		if i.get_class() == "Area3D":
			i.monitoring = !areasDisabled
			i.monitorable = !areasDisabled
