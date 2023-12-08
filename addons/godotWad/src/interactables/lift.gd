extends Spatial

enum STATE{
	TOP,
	GOING_DOWN,
	BOTTOM,
	GOING_UP
}



export(Dictionary) var info
export(WADG.TTYPE) var triggerType
export(STATE) var state  = STATE.TOP
export(String) var animMeshPath = ""
export(float) var globalScale = 1
var animTextures = []
var endHeight
var active = false
var speed = 2
var targets = []
var isASwitch = false
var overlappingBodies : Array = []
var waitClose = 2
var floorNode 

func _ready():
	
	speed *= globalScale
	info["endHeight"] = info["sectorInfo"]["lowestNeighFloorExc"] 
	#info["curY"] = info["sectorInfo"]["floorHeight"]
	get_parent().set_meta("curH",info["sectorInfo"]["floorHeight"]) 
	info["targetNodes"] = []
	
	
	for t in info["targets"]:
		var mapNode = get_parent().get_parent().get_parent()
		var node = mapNode.get_node(t)
		
		if node.has_meta("floor"): info["targetNodes"].append(node)
		elif node.has_meta("type"):
			if node.get_meta("type") != "upper": info["targetNodes"].append(node)


	animTextures = $"../../../".getAnimTextures(self,animMeshPath)
	
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
		isASwitch = true
		
		


func _physics_process(delta):
	if typeof(get_parent().get_meta("owner")) == TYPE_OBJECT:
		if get_parent().get_meta("owner") != self:
			return
		
		
	if get_node_or_null("trigger") != null:# X1 triggers will get deleted after first trigger
		for c in get_children():
			if c.get_class() == "Area":
				for body in overlappingBodies:
					bodyIn(body)

	
	if state == STATE.GOING_DOWN:
		#if info["curY"] > info["endHeight"]:
		#	info["curY"] -= speed
		
		if getCurH() > info["endHeight"]:
			incCurH(-speed)
		
		for node in info["targetNodes"]:
			node.translation.y-= speed.y
			
		#if info["curY"] <= info["endHeight"]:
		if getCurH() <= info["endHeight"]:
	
			for node in info["targetNodes"]:
				node.translation.y = info["endHeight"]
			
			state = STATE.BOTTOM
			if waitClose != -1:
				yield(get_tree().create_timer(waitClose),"timeout")
				state = STATE.GOING_UP
			
			
			
	if state == STATE.GOING_UP:
		
#		if info["curY"] < info["sectorInfo"]["floorHeight"]:
#			info["curY"] += speed
		
		
		if getCurH() < info["sectorInfo"]["floorHeight"]:
			incCurH(speed)
		
		for node in info["targetNodes"]:
			node.translation.y+= speed.y
			
		#if info["curY"] >= info["sectorInfo"]["floorHeight"]:
		if getCurH() >= info["sectorInfo"]["floorHeight"]:
			
			for node in info["targetNodes"]:
				node.translation.y = info["sectorInfo"]["floorHeight"]
			
			state = STATE.TOP
			get_parent().set_meta("owner",false)
		
	
			

func bodyIn(body : PhysicsBody) -> void:
	
		
	
	if !"interactPressed" in body:
		return
	
	if typeof(get_parent().get_meta("owner")) != TYPE_BOOL: 
		return
	
	
	if body.get_class() != "StaticBody":
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
	
		if state == STATE.TOP: 
				state = STATE.GOING_DOWN
				if get_node_or_null("openSound")!= null: 
					get_node("openSound").global_translation = body.translation
					get_node("openSound").play()
					
				
				
		elif state == STATE.BOTTOM: 
				state = STATE.GOING_UP
				if get_node_or_null("closeSound")!= null: 
					get_node("closeSound").global_translation = body.translation
					get_node("closeSound").play()
			
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.WALK1: 
			for i in get_children():
				if i.get_class() == "Area":
					i.queue_free()

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
