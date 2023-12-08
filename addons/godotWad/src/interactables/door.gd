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
var active = false
export var speed = 2
export(DIR) var direction
var state 
var cast : ShapeCast = null
var animTextures = []
export(String) var floorPath
export(WADG.TTYPE) var triggerType
export(String) var animMeshPath = ""
export(Array) var targets = []
export(Dictionary) var sectorInfo = {}
export(float) var globalScale = 0.05
export(bool) var stayOpen = false
export(String) var keyType = 9


var topH;
var bottomH;
var switchCooldown = 0
var ceiling = null
var floorNode = null
export(int) var waitClose = -1
export(int) var waitOpen = -1


var overlappingBodies = []
var overlappingBodiesActivated = []
var targetNodes = []
var curH : float = 0
var nodeInitial = []
var yInitial = 0
func _ready():
	
	
	if !get_parent().has_meta("curH"):
		get_parent().set_meta("curH",0)
	
	speed *= globalScale.y
	get_parent().set_meta("curH",sectorInfo["ceilingHeight"]) 

	topH = sectorInfo["lowestNeighCeilExc"] - 4*globalScale.y
	bottomH = sectorInfo["floorHeight"] 
	yInitial = sectorInfo["ceilingHeight"]
		

	for t in targets:
		var mapNode = get_parent().get_parent().get_parent()
		var node = mapNode.get_node(t)
		
			
		if node.has_meta("ceil"): 
			if node.get_class() != "StaticBody":
				ceiling = node
				targetNodes.append(node)
				nodeInitial.append(node.translation)
			
			
		elif node.has_meta("type"):
			if node.get_meta("type") == "upper": 
				targetNodes.append(node)
				nodeInitial.append(node.translation)
				
	
	
	animTextures = $"../../../".getAnimTextures(self,animMeshPath)
	
	var mapNode = get_parent().get_parent().get_parent()

	if ceiling != null:
		var s = OS.get_system_time_msecs()
		cast = WADG.createCastShapeForBody(ceiling.get_child(0),-Vector3(0,0.1,0))
		WADG.incTimeLog(get_tree(),"castShapes",s)
	
	if direction == WADG.DIR.UP: state = STATE.CLOSED
	if direction == WADG.DIR.DOWN: state = STATE.OPEN




	

func bin(body):
	if body.get_class() == "StaticBody": return
	
	
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
		if !"interactPressed" in body:
			return
	
	if !overlappingBodies.has(body):
		overlappingBodies.append(body)

func bout(body):
	
	if overlappingBodies.has(body):
		overlappingBodies.erase(body)
		overlappingBodiesActivated.erase(body)

func _physics_process(delta):
	switchCooldown = max(0,switchCooldown-delta)
	
	if cast != null:
		if state == STATE.OPENING or state == STATE.CLOSING: 
			cast.enabled = true
			cast.force_shapecast_update()
		else:
			cast.enabled = false
	
		for i in cast.get_collision_count():
			var normal = WADG.normalToDegree(cast.get_collision_normal(i))
			var parent = cast.get_collider(i).get_parent()
			#if !parent.has_meta("floor")

			if cast.get_collider(i).get_class() != "StaticBody":
				var a= parent.has_meta("type")
				var b = parent.has_meta("floor")
				var t = parent.get_meta_list()
				if state == STATE.CLOSING:
					state = STATE.OPENING
		
		#print(normal)
		
	
	for i in overlappingBodies:
		bodyIn(i)
	
	curH = getCurH()
	
	
	
	if state == STATE.OPENING:
		if curH < topH:
			incCurH(speed)
			curH+=speed
			changeNodesY(targetNodes,speed)
				
		if curH >= topH:
			state = STATE.OPEN

			
			if waitClose != -1:
				yield(get_tree().create_timer(waitClose),"timeout")
				state = STATE.CLOSING
				
				if get_node_or_null("closeSound")!= null: 
					get_node("closeSound").play()
				return

			
				
	if state == STATE.CLOSING:
		if curH > bottomH:
			incCurH(-speed)
			curH-=speed
			changeNodesY(targetNodes,-speed)
		
		if curH  <= bottomH:
			state = STATE.CLOSED

			if waitOpen != -1:
				yield(get_tree().create_timer(waitOpen),"timeout")
				state = STATE.OPENING
				
				playOpen()
				return
		
	if curH <= bottomH: 
		state = STATE.CLOSED
			
	if curH >= topH: 
		state = STATE.OPEN

		
	if state == STATE.CLOSED or state == STATE.CLOSED: 
		get_parent().set_meta("curOwner",null)


func bodyIn(body):
	
	if overlappingBodiesActivated.has(body):
		return  
		
	if keyType < 4:
		if !doesBodyHaveKey(body):
			return
	
	if get_parent().has_meta("curOwner"):
		if get_parent().get_meta("curOwner") != self:
			return
	
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
		if body.interactPressed == false:
			return
	
	
	
	if switchCooldown > 0:
		return
	
	
	switchCooldown = 1
	
	if get_node_or_null("buttonSound") != null:
		if getCurH() <= bottomH or getCurH() >= topH:
			get_node("buttonSound").play()
	
	for i in animTextures:
		var t = (i.current_frame+1)%2
		i.current_frame = (i.current_frame+1)%2


	if !body.is_in_group("player") and !("interactPressed" in body):
		return 
		
	if !overlappingBodiesActivated.has(body):
		overlappingBodiesActivated.append(body)
		activate()
	
	
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.WALK1: 
		for i in get_children():
			if i.get_class() == "Area":
				i.queue_free()

	

func activate():
	
	
	#if sectorInfo["index"] == 53:
	#	breakpoint
	
	
	if state == STATE.OPEN and stayOpen == false:# and direction == DIR.DOWN: #if open and is a closer and !stayOpen -> close
		state = STATE.CLOSING
		
		if !get_parent().has_meta("curOwner"): 
			get_parent().set_meta("curOwner",self)
		
		playClosed()
					
	elif state == STATE.CLOSED and direction == DIR.UP: #if closed and is an opener -> open
		
		if getCurH() < topH:
			
			if !get_parent().has_meta("curOwner"): 
				get_parent().set_meta("curOwner",self)
			
			state = STATE.OPENING
			playOpen()
			
func changeNodesY(nodes,amt):
	for node in nodes:
		if node.get_parent().get_class() != "Spatial":
			node.get_parent().translation.y += amt
		else:
			node.translation.y += amt
			
func setNodesY(nodes,value):
	for nIdx in nodes.size():
		var node = nodes[nIdx]
		
		if node.get_parent().get_class() != "Spatial":
			node.get_parent().translation.y = value
		else:
		
			var t= yInitial - value
			node.translation.y = nodeInitial[nIdx].y - t
	
func getCurH():
	return get_parent().get_meta("curH")
	
	
func incCurH(amt):
	var curH = getCurH()
	get_parent().set_meta("curH",curH+amt)
	

func playOpen():
	if get_node_or_null("openSound")!= null: 
		get_node("openSound").play()
		
func playClosed():
	if get_node_or_null("closeSound")!= null: 
		get_node("closeSound").play()
	
func doesBodyHaveKey(body):
	if "inventory" in body:
		var bodyInventory = body.inventory
			
		var keyNames = WADG.keyNunmberToNameArr(keyType)
		var ret = true
		for i in keyNames:
			if i in bodyInventory:
				if bodyInventory[i]["count"] > 0:
					ret = false
		if ret: return false
	else:
		return false
		
	return true
 

