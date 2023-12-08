extends Spatial


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


var type
export(Dictionary) var info
var endHeight
var active = true
var speed : float = 2
export(DIR) var direction
export(Vector3) var globalScale = Vector3.ONE
export var category = 0
var change = 0
var top
var bottom 

export(WADG.TTYPE) var triggerType

var floorCast: ShapeCast = null
var ceilingCast : ShapeCast = null
var floorNode
var ceilingNode
var initialSpeed
# Called when the node enters the scene tree for the first time.
func _ready():
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
		var s = OS.get_system_time_msecs()
		floorCast = WADG.createCastShapeForBody(floorNode.get_child(0),Vector3(0,0.1,0))
		ceilingCast = WADG.createCastShapeForBody(ceilingNode.get_child(0),Vector3(0,-0.1,0))
		
		WADG.incTimeLog(get_tree(),"castShapes",s)
	
	initialSpeed = speed

func _physics_process(delta):
	
	var state = getState()
	
	if getState() == STATE.CLOSING and ceilingCast != null:
		ceilingCast.enabled = true
		ceilingCast.force_shapecast_update()

		
		var flag = false
		for i in ceilingCast.get_collision_count():
			var collider = ceilingCast.get_collider(i)
			var parent = collider.get_parent()
		
			
			if !parent.has_meta("floor"):
				if parent.get_class() != "StaticBody" and collider.get_class() != "StaticBody":
					flag = true
					speed = 0
					if state == STATE.CLOSING:
						
						if collider.has_method("takeDamage"):
							var dict = {"amt":10,"iMS":300,"specific":"crusher","source":self}
							collider.takeDamage(dict)
							
			if collider.get_class() == "RigidBody":
				setState(STATE.OPENING)
				
				

					
		if flag == false:
			speed = initialSpeed
		
	else:
		speed = initialSpeed
	
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
				node.translation.y += speed
				
	if curY >= top:
			setState(STATE.OPEN)
			setState(STATE.CLOSING)
			
				
	if getState() == STATE.CLOSING:
		if curY > bottom:
			incCurY(-speed)
			
			for node in info["targetNodes"]:
				node.translation.y -= speed
		
	if curY <= bottom:
		setState(STATE.CLOSED)
		setState(STATE.OPENING)


func bodyIn(body):
	
	if typeof(get_parent().get_meta("owner")) != TYPE_BOOL: 
		return
	
	if body.get_class() != "StaticBody":
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
			if "interactPressed" in body:
				if body.interactPressed == false:
					return
		
		get_parent().set_meta("active",null)
		get_parent().set_meta("owner",self)
		
		
		
		if triggerType == WADG.TTYPE.DOOR1 or triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.WALK1: 
			for i in get_children():
				if i.get_class() == "Area":
					i.queue_free()


func getState():
	return get_parent().get_meta("state")
	
func setState(state):
	return get_parent().set_meta("state",state)
	
func getCurY():
	return get_parent().get_meta("curY")

func setCurY(y):
	return get_parent().set_meta("curY",y)
	
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
			
	if body.get_class() == "StaticBody": return
	
	
	if !overlappingBodies.has(body):
		overlappingBodies.append(body)
	
	
func bout(body):
	
	if overlappingBodies.has(body):
		overlappingBodies.erase(body)
