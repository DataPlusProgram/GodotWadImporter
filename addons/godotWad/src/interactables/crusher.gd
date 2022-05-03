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

var type
export(Dictionary) var info
var endHeight
var active = true
var speed = 2
export(DIR) var dir

export var category = 0
var change = 0
var top
var bottom 
export(WADG.TTYPE) var triggerType

# Called when the node enters the scene tree for the first time.
func _ready():
	
	info["targetNodes"] = []
	
	
	info["endHeight"] = info["sectorInfo"]["floorHeight"]+8
	setCurY(info["sectorInfo"]["ceilingHeight"])


	bottom = info["sectorInfo"]["floorHeight"]
	top = info["sectorInfo"]["ceilingHeight"]

	if !get_parent().has_meta("active"): get_parent().set_meta("active",false)
	if !get_parent().has_meta("owner"): get_parent().set_meta("owner",false)

	for t in info["targets"]:
		var mapNode = get_parent().get_parent().get_parent()
		var node = mapNode.get_node(t)
		if node.has_meta("ceil"): info["targetNodes"].append(node)
		elif node.has_meta("type"):
			if node.get_meta("type") == "upper": info["targetNodes"].append(node)
		
	if dir == WADG.DIR.UP: setState(STATE.CLOSED)
	if dir == WADG.DIR.DOWN: setState(STATE.OPEN)
	
	if category == WADG.LTYPE.STOPPER:
		breakpoint
	


func _physics_process(delta):
		
	if get_node_or_null("trigger") != null:# X1 triggers will get deleted after first trigger
		for c in get_children():
			if c.get_class() == "Area":
				for body in c.get_overlapping_bodies():
					bodyIn(body)
	

	if typeof(get_parent().get_meta("owner")) == TYPE_BOOL: 
		return
	
	var curY = getCurY()
	
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
		
		if getState() == STATE.OPEN: 
			setState(STATE.CLOSING)
			if get_node_or_null("closeSound")!= null: get_node("closeSound").play()
			
		elif getState() == (STATE.CLOSED): 
			setState(STATE.OPENING)
			if get_node_or_null("openSound")!= null: get_node("openSound").play()
		
		if triggerType == WADG.TTYPE.DOOR1 or triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.WALK1: 
			for i in get_children():
				i.queue_free()


func getState():
	return get_parent().get_meta("state")
	
func setState(state):
	return get_parent().set_meta("state",state)
	
func getCurY():
	return get_parent().get_meta("curY")

func setCurY(y):
	return get_parent().set_meta("curY",y)
	
func incCurY(amt):
	setCurY(getCurY() + amt)



func printState(state):
	if state == STATE.OPEN: print("top")
	elif state == STATE.OPENING: print("goingUp")
	elif state == STATE.CLOSED: print("closed")
	elif state == STATE.CLOSING: print("goingDown")

