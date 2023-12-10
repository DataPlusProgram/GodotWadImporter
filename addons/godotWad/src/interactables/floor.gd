extends Spatial


export(int) var type
export(Dictionary) var info
var active = true
var endState 
export var speed = 40
export(WADG.DEST) var dest 
export(WADG.DIR) var direction 
export(WADG.TTYPE) var triggerType
export(String) var animMeshPath = ""
var state 
export var textureChange = false
var floorNode = null
var ceiling = null
export var loop = false 
export(Vector3) var globalScale = Vector3(0,1,0)
var initialSpeed
var topH
var bottomH
var animMats = []
var animTextures = []
var newTexture = null
var newSectorIdx = 0
var newSectorType = 0
var startDelay = -1
var floorCast: ShapeCast = null
var ceilingCast : ShapeCast = null
enum STATE{
	TOP,
	GOING_DOWN,
	BOTTOM,
	GOING_UP
}

func _ready():
	
	speed *= globalScale.y
	if has_meta("loop"): loop = true
	if !get_parent().has_meta("curH"):
		get_parent().set_meta("curH",0)


	
	
	var destH = WADG.getDest(dest,info["sectorInfo"],globalScale.y)
	var floorH = info["sectorInfo"]["floorHeight"]
	
	var i = info["sectorInfo"]
	
	get_parent().set_meta("curH",floorH) 
	
	
	if loop:
		floorH =  info["sectorInfo"]["lowestNeighFloorInc"]
		destH =  info["sectorInfo"]["highestNeighFloorInc"]
		

		
	
	bottomH = min(floorH,destH)
	topH = max(floorH,destH)
	
	
	
	
	
	animTextures = $"../../../".getAnimTextures(self,animMeshPath)
	

	if direction == WADG.DIR.UP:
		if floorH >= destH:
			state = STATE.TOP
			endState = STATE.BOTTOM
		else:
			state = STATE.BOTTOM
			endState = STATE.TOP
		
	
	
	if direction == WADG.DIR.DOWN:
		if floorH <= destH:
			state = STATE.BOTTOM
			endState = STATE.TOP
		else:
			state = STATE.TOP
			endState = STATE.BOTTOM
	
	info["targetNodes"] = []
	
	if direction == WADG.DIR.DOWN and destH > floorH:
		direction = WADG.DIR.UP
		speed += speed*5
		
	
	for t in info["targets"]:
		var mapNode = get_parent().get_parent().get_parent()
		var node = mapNode.get_node(t)
		
		
		if node.has_meta("floor"): 
			info["targetNodes"].append(node)
			floorNode = node
			for j in node.get_parent().get_children():
				if j.has_meta("ceil"):
					ceiling = j
			
		
		
		elif node.has_meta("type"):
			if node.get_meta("type") == "lower": info["targetNodes"].append(node)
			
			
		if floorNode != null and ceiling != null:
			var s = OS.get_system_time_msecs()
			floorCast = WADG.createCastShapeForBody(floorNode.get_child(0),Vector3(0,0.1,0))
			ceilingCast = WADG.createCastShapeForBody(ceiling.get_child(0),Vector3(0,-0.1,0))
			WADG.incTimeLog(get_tree(),"castShapes",s)
			
	initialSpeed = speed
	



func _physics_process(delta):
	
	if active == false:
		return
	
	
	if state == STATE.GOING_UP:
		if floorCast != null and ceilingCast != null:
			var lowList = []
			var highList = []
			
			ceilingCast.debug_shape_custom_color =Color.purple
			floorCast.debug_shape_custom_color = Color.black
			
			
			floorCast.enabled = true
			floorCast.force_shapecast_update()
			#floorCast.enabled = false
			for i in floorCast.get_collision_count():
				if !floorCast.get_collider(i).has_meta("ceil"):
					##WADG.drawSphere($"/root",floorCast.get_collision_point(i))
					lowList.append(floorCast.get_collider(i))
			
			
			ceilingCast.enabled = true
			ceilingCast.force_shapecast_update()
			#ceilingCast.enabled = false
			
			for i in ceilingCast.get_collision_count():
				if !ceilingCast.get_collider(i).has_meta("floor"):
					highList.append(ceilingCast.get_collider(i))
			
			var flag = false
			
			for i in highList:
				if i.get_class() == "StaticBody":
					continue
				if lowList.has(i):
					speed = 0
					flag = true
					break
			
			if flag == false:
				speed = initialSpeed
			
		else:
			speed = initialSpeed
	else:
		if floorCast != null:
			floorCast.enabled = false
		if ceilingCast != null:
			ceilingCast.enabled = false
		
	if state == STATE.GOING_DOWN:
		if get_node_or_null("closeSound")!= null:
			if !get_node("closeSound").playing:
				get_node("closeSound").play()
		
		if floorNode != null:
			if floorNode.get_node_or_null("closeSound"):
				if !floorNode.get_node("closeSound").playing:
					floorNode.get_node("closeSound").play()
		
				
				
				
	if state == STATE.GOING_UP:
		if get_node_or_null("openSound")!= null: 
			if !get_node("openSound").playing:
				get_node("openSound").play()
				
				
		if floorNode.get_node_or_null("openSound"):
			if !floorNode.get_node("openSound").playing:
				floorNode.get_node("openSound").play()


	if state == STATE.GOING_UP:
		if getCurH() < topH:
			incCurH(speed*delta)
			changeNodesY(info["targetNodes"],speed*delta)

		if getCurH() >= topH:
			state = STATE.TOP
			
			if get_parent().has_meta("curOwner"): 
				get_parent().set_meta("curOwner",null)
			
			if loop: 
				state = STATE.GOING_DOWN
				
			
				
	if state == STATE.GOING_DOWN:
		
		if getCurH() > bottomH:
			incCurH(-speed*delta)
			
			for node in info["targetNodes"]:
				node.translation.y -= speed*delta
		
		if  getCurH() <= bottomH:
			state = STATE.BOTTOM
			
			if get_parent().has_meta("curOwner"): 
				get_parent().set_meta("curOwner",null)
			

			if floorNode != null:
				if newTexture != null:
					if textureChange == true:
						changeTexture(floorNode.mesh,newTexture,newSectorIdx)
						floorNode.set_meta("damage",WADG.getDamageInfoFromSectorType(newSectorType))
				else:
					print("missing floor node for texture change")
			
			if loop:
				 state = STATE.GOING_UP


func body_entered(body,texture,sectorIdx,sectorType = -1):
	

	
	newTexture = texture
	newSectorIdx = sectorIdx
	newSectorType = sectorType
	
	
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR:
		if "interactPressed" in body:
			if body.interactPressed == false:
				return
			else:
				for i in animTextures:
					i.current_frame = 1
				if get_node_or_null("buttonSound") != null and state != endState:
					if getCurH() <= bottomH or getCurH() >= topH:
						get_node("buttonSound").play()
	
	if newTexture != null and textureChange and direction == WADG.DIR.UP:
		changeTexture(floorNode.mesh,newTexture,newSectorIdx)
		floorNode.set_meta("damage",WADG.getDamageInfoFromSectorType(newSectorType))
		
	
	if body.get_class() != "StaticBody":
		activate()
		
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.WALK1: 
			for i in get_children():
				if i.get_class() == "Area":
					i.queue_free()
		

	
func activate():
	
	
	if active == false and loop == true:
		active = true
		
	var curH = getCurH()
	
	if !loop:
		if direction == WADG.DIR.UP and curH >= topH: return
		if direction == WADG.DIR.DOWN and curH <= bottomH: return
	
	
	if get_parent().has_meta("curOwner"): 
		if get_parent().get_meta("curOwner") != null:
			return
	
	if !get_parent().has_meta("curOwner"): 
		get_parent().set_meta("curOwner",self)
	
	

	
	if state == STATE.TOP: 
		state = STATE.GOING_DOWN
		if get_node_or_null("closeSound")!= null: 
			var n = get_node("closeSound")
			n.play()
				
				
				
	elif state == STATE.BOTTOM: 
		state = STATE.GOING_UP
		if get_node_or_null("openSound")!= null: 
			get_node("openSound").play()
			
			


func changeTexture(mesh,texture,sectorInfo):
	var mat = null
	
	if get_node_or_null("../../../../WadLoader/ResourceManager") != null:
		var light = sectorInfo["lightLevel"]
		
		var tex = $"../../../../WadLoader/ResourceManager".fetchFlatRuntime(newTexture)
		
		mat = $"../../../../WadLoader/ResourceManager".fetchMaterial(newTexture,tex,light,Vector2.ZERO,0)
	
	mesh.surface_set_material(0,mat)

func getCurH():
	return get_parent().get_meta("curH")
	
	
func incCurH(amt):
	var curH = getCurH()
	get_parent().set_meta("curH",curH+amt)

func printState():
	if state == STATE.BOTTOM: print("bottom")
	if state == STATE.GOING_UP: print("goingUP")
	if state == STATE.TOP: print("top")
	if state == STATE.GOING_DOWN: print("goingDOWN")


func getMeshOfNode(node):
	var arr = []
	
	if node.get_class() == "MeshInstance":
		arr.append(node)
	
	for c in node.get_children():
		arr += getMeshOfNode(c)
	
	return arr

func changeNodesY(nodes,amt):
	for node in nodes:
		if node.get_parent().get_class() != "Spatial":
			node.get_parent().translation.y += amt
		else:
			node.translation.y += amt
			

