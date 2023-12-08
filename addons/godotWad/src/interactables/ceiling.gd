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
var speed = Vector3(0,2,0)
export(DIR) var direction
var state 
var change = 0
export(WADG.TEXTUREDRAW) var triggerType
export(WADG.DEST) var dest 
export(float) var globalScale = 1
export(String) var animMeshPath = ""
var topH
var bottomH
var curH
var animTextures = []
var initialSpeed
var ceilingCast : ShapeCast = null
var ceiling = null


func _ready():
	var s = OS.get_system_time_msecs()
	speed *= globalScale
	info["targetNodes"] = []
	animTextures = $"../../../".getAnimTextures(self,animMeshPath)
	

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
		elif node.has_meta("type"):
			if node.get_meta("type") == "upper": info["targetNodes"].append(node)
			
	if ceiling != null:
		
		ceilingCast = WADG.createCastShapeForBody(ceiling.get_child(0),Vector3(0,-0.1,0))
		WADG.incTimeLog(get_tree(),"castShapes",s)
		
		
	initialSpeed = speed


func _physics_process(delta):
	
	if get_node_or_null("trigger") != null:# X1 triggers will get deleted after first trigger
		for c in get_children():
			if c.get_class() == "Area":
				for body in c.get_overlapping_bodies():
					bodyIn(body)
	
	
	if state == STATE.GOING_UP:
		if curH< topH:
			curH += speed.y
		
			for node in info["targetNodes"]:
				node.translation.y += speed.y
				
		if curH >= topH:
			state = STATE.TOP
			
				
	if state == STATE.GOING_DOWN:
		var flag = false
		
		if ceilingCast !=null:
			ceilingCast.force_shapecast_update()
			ceilingCast.enabled = false
			
			for i in ceilingCast.get_collision_count():
				if !ceilingCast.get_collider(i).has_meta("floor"):
					if ceilingCast.get_collider(i).get_class() != "StaticBody":
						speed = Vector3(0,0,0)
						flag = true
		
		if flag == false:
			speed = initialSpeed
		
		if curH > bottomH:
			curH -= speed.y
			
			for node in info["targetNodes"]:
				node.translation.y -= speed.y
		
		if curH <= bottomH:
			state = STATE.BOTTOM
	else: 
		if ceilingCast != null:
			ceilingCast.enabled = false
			speed = initialSpeed
	


func bodyIn(body):
	if body.get_class() != "StaticBody":
		
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
			if "interactPressed" in body:
				if body.interactPressed == false:
					return
		
		
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
		
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.WALK1: 
			for i in get_children():
				if i.get_class() == "Area":
					i.queue_free()

