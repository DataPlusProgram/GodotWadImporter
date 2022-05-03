extends Spatial


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

export(int) var type
export(Dictionary) var info
var active = false
var speed = 2
export(DIR) var dir
var state 
var change = 0
export(WADG.TEXTUREDRAW) var triggerType
var dest

var topH
var bottomH
var curH

func _ready():
	

	info["targetNodes"] = []
	
	

	if dir == WADG.DIR.UP: 
		state = STATE.BOTTOM
		bottomH =  info["sectorInfo"]["floorHeight"]
		topH = WADG.getDest(dest,info["sectorInfo"])
		curH = bottomH
		
	if dir == WADG.DIR.DOWN: 
		state = STATE.TOP
		#bottomH =  info["sectorInfo"]["floorHeight"]
		bottomH = WADG.getDest(dest,info["sectorInfo"])
		topH = info["sectorInfo"]["ceilingHeight"]
		curH = topH
		
	
	
	for t in info["targets"]:
		var mapNode = get_parent().get_parent().get_parent()
		var node = mapNode.get_node(t)
		
		if node.has_meta("ceil"): info["targetNodes"].append(node)
		elif node.has_meta("type"):
			if node.get_meta("type") == "upper": info["targetNodes"].append(node)
			


func _physics_process(delta):
	
	
	
	if get_node_or_null("trigger") != null:# X1 triggers will get deleted after first trigger
		for c in get_children():
			if c.get_class() == "Area":
				for body in c.get_overlapping_bodies():
					bodyIn(body)
	
	
	if state == STATE.GOING_UP:
		if curH< topH:
			curH += speed
		
			for node in info["targetNodes"]:
				node.translation.y += speed
				
		if curH >= topH:
			state = STATE.TOP
			
				
	if state == STATE.GOING_DOWN:
		if curH > bottomH:
			curH -= speed
			
			for node in info["targetNodes"]:
				node.translation.y -= speed
		
		if curH <= bottomH:
			state = STATE.BOTTOM


func bodyIn(body):
	if body.get_class() != "StaticBody":
		
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
			if "interactPressed" in body:
				if body.interactPressed == false:
					return
					
		if state == STATE.TOP: 
			state = STATE.GOING_DOWN
			if get_node_or_null("closeSound")!= null: get_node("closeSound").play()
			
		elif state == STATE.BOTTOM: 
			state = STATE.GOING_UP
			if get_node_or_null("openSound")!= null: get_node("openSound").play()
		
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.WALK1: 
			for i in get_children():
				if i.get_class() == "Area":
					i.queue_free()

