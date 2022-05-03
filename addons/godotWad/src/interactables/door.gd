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

export(int) var type
export(Dictionary) var info
var endHeight
var active = false
export var speed = 2
export(DIR) var dir
var state 
var change = 0
var floorNode
var kinematicIgnore = []
var animTextures = []
export(String) var floorPath
export(WADG.TTYPE) var triggerType
export(String) var animMeshPath = ""

export(int) var waitClose = -1
# Called when the node enters the scene tree for the first time.
func _ready():
	info["targetNodes"] = []
	
	
	if dir == DIR.UP:
		endHeight = info["sectorInfo"]["lowestNeighCeilExc"] - 4
		info["curY"] = info["sectorInfo"]["ceilingHeight"]
		
	elif dir == DIR.DOWN:
		endHeight = info["sectorInfo"]["floorHeight"] 
		info["curY"] = info["sectorInfo"]["ceilingHeight"]
	


	for t in info["targets"]:
		var mapNode = get_parent().get_parent().get_parent()
		var node = mapNode.get_node(t)
		
		
		if node.get_parent().get_class() == "KinematicBody":
			kinematicIgnore.append(node.get_parent())
			
		if node.has_meta("ceil"): info["targetNodes"].append(node)
		elif node.has_meta("type"):
			if node.get_meta("type") == "upper": 
				info["targetNodes"].append(node)
				
	
	
	animTextures = $"../../../".getAnimTextures(self,animMeshPath)
	
	var mapNode = get_parent().get_parent().get_parent()
	floorNode = mapNode.get_node(floorPath)
	
	if dir == WADG.DIR.UP: state = STATE.CLOSED
	if dir == WADG.DIR.DOWN: state = STATE.OPEN
	


func _physics_process(delta):
	
	
	if state == STATE.CLOSING:
		for i in info["targetNodes"]:
		
			var stopper : Area = i.get_node_or_null("area")
			
			if stopper != null:
				for col in stopper.get_overlapping_bodies():
					if col.get_class() == "KinematicBody":
						var par = col.get_parent()
						if !col.has_meta("env"):
							if state == STATE.CLOSING:
								state = STATE.OPENING
							
						
				
				for body in stopper.get_overlapping_bodies():
					print(body.name)
	
	if get_node_or_null("trigger") != null:# X1 triggers will get deleted after first trigger
		for c in get_children():
			if c.get_class() == "Area":
				for body in c.get_overlapping_bodies():
					bodyIn(body)
	
	#for body in get_node("trigger").get_overlapping_bodies():
		
	
	if state == STATE.CLOSED:
		return
	
	if state == STATE.OPENING:
		if info["curY"] < endHeight:
			info["curY"] += speed
			change += speed
		
			for node in info["targetNodes"]:
				if node.get_parent().get_class() != "Spatial":
					node.get_parent().translation.y += speed
					#node.get_parent().move_and_slide(Vector3(0,-speed,0))
				else:
					node.translation.y += speed
				#	print(node.name)
				#node.translation.y += speed
				
		if info["curY"] >= endHeight:
			state = STATE.OPEN
			
			if waitClose != -1:
				yield(get_tree().create_timer(waitClose),"timeout")
				state = STATE.CLOSING
			
				
	if state == STATE.CLOSING:
		if info["curY"] > info["sectorInfo"]["floorHeight"]:
			info["curY"] -= speed
			
			for node in info["targetNodes"]:
				if node.get_parent().get_class() != "Spatial":
					node.get_parent().translation.y -= speed
					#node.get_parent().move_and_slide(Vector3(0,-speed,0))
				else:
					node.translation.y -= speed
		
		if info["curY"] <= info["sectorInfo"]["floorHeight"]:
			state = STATE.CLOSED



func bodyIn(body):
	if !"interactPressed" in body:
		return
	
	var par = body.get_parent()
	if body.get_class() != "StaticBody" and !body.has_meta("env"):#!info["targetParents"].has(body.get_parent()):
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
			if "interactPressed" in body:
				if body.interactPressed == false:
					return
			else:
				return
		
		for i in animTextures:
			i.current_frame = 1
		
		if state == STATE.OPEN: 
			state = STATE.CLOSING
			if get_node_or_null("closeSound")!= null: 
				get_node("closeSound").play()
					
		elif state == STATE.CLOSED: 
			state = STATE.OPENING
			if get_node_or_null("openSound")!= null: 
				get_node("openSound").play()
				
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.WALK1: 
			for i in get_children():
				if i.get_class() == "Area":
					i.queue_free()
	
