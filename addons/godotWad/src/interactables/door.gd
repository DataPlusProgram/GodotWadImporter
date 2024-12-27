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

@export var type: int
var active = true
@export var speed = 2
@export var direction: DIR
var state 
var cast : ShapeCast3D = null
var animTextures = []
@export var floorPath: String
@export var triggerType : WADG.TTYPE
@export var animMeshPath: Array= []
@export var targets: Array = []
@export var sectorInfo: Dictionary = {}
@export var globalScale: Vector3 = Vector3(0.05,0.05,0.05)
@export var stayOpen: bool = false
@export var keyType: int = 9
@onready var parent : Node = get_parent()

var topH;
var bottomH;
var switchCooldown = 0
var ceiling = null
var floorNode = null
var openTimeoutTimer : SceneTreeTimer= null
var closeTimeoutTimer: SceneTreeTimer= null
var areasDisabled = false
@export var waitClose: int = -1
@export var waitOpen: int = -1

var areasDisbaled = false
var overlappingBodies = []
var overlappingBodiesActivated = []
var walkOverBodies = []
var targetNodes = []
var curH : float = 0
var nodeInitial = []
var yInitial = 0
@onready var isEditor = Engine.is_editor_hint()
func _ready():
	
	if isEditor:
		return
	
	add_to_group("levelObject",true)
	
	if !parent.has_meta("curH"):
		parent.set_meta("curH",0)
	
	speed *= globalScale.y * 60
	parent.set_meta("curH",sectorInfo["ceilingHeight"]) 

	topH = sectorInfo["lowestNeighCeilExc"] #- 4*globalScale.y
	bottomH = sectorInfo["floorHeight"] 
	yInitial = sectorInfo["ceilingHeight"]
		

	for t in targets:
		var mapNode = parent.get_parent().get_parent()
		var node = mapNode.get_node(t)
		
			
		if node.has_meta("ceil"): 
			if node.get_class() != "StaticBody3D":
				ceiling = node
				targetNodes.append(node)
				nodeInitial.append(node.position)
			
			
		elif node.has_meta("type"):
			if node.get_meta("type") == "upper": 
				targetNodes.append(node)
				nodeInitial.append(node.position)
				
	
	
	animTextures = $"../../../".getAnimTextures(self,animMeshPath)
	
	var mapNode =parent.get_parent().get_parent()

	if ceiling != null:
		var s = Time.get_ticks_msec()
		if ceiling.get_child_count() > 0:
			cast = WADG.createCastShapeForBody(ceiling.get_child(0),-Vector3(0,0.1,0))
			SETTINGS.incTimeLog(get_tree(),"castShapes",s)
	
	if direction == WADG.DIR.UP: 
		state = STATE.CLOSED
	if direction == WADG.DIR.DOWN: 
		state = STATE.OPEN

	
	
	

func bin(body):
	if body.get_class() == "StaticBody3D": return
	
	
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
		if !"interactPressed" in body:
			return
	
	if !overlappingBodies.has(body):
		overlappingBodies.append(body)

func bout(body):
	
	if overlappingBodies.has(body):
		overlappingBodies.erase(body)
	#	overlappingBodiesActivated.erase(body)

func closeTimeOut():
	state = STATE.CLOSING
	active = true
	playClosed()
		
func openTimeOut():
	state = STATE.OPENING
	active = true
	playOpen()

func _physics_process(delta):
		
	
	if isEditor:
		return

	if active == false:
		return
	switchCooldown = max(0,switchCooldown-delta)
	
	if cast != null:
		if state == STATE.OPENING or state == STATE.CLOSING: 
			cast.enabled = true
			cast.force_shapecast_update()
		else:
			cast.enabled = false
	
		for i in cast.get_collision_count():
			#var normal = WADG.normalToDegree(cast.get_collision_normal(i))
			var parent = cast.get_collider(i).get_parent()
			#if !parent.has_meta("floor")

			if cast.get_collider(i).get_class() != "StaticBody3D":
				var a= parent.has_meta("type")
				var b = parent.has_meta("floor")
				var t = parent.get_meta_list()
				if state == STATE.CLOSING:
					state = STATE.OPENING
		
		
		
	
	for i in overlappingBodies:
		if !is_instance_valid(i):
			overlappingBodies.erase(i)
		
	
	for body in walkOverBodies:
		bodyIn(body)
		
	walkOverBodies = []
	
	for i in overlappingBodies:
		bodyIn(i)
	
	curH = getCurH()
	
	
	
	if state == STATE.OPENING:
		if curH < topH:
			incCurH(speed*delta)
			var newH =  min(topH,curH+speed*delta)
			changeNodesY(targetNodes,newH-curH)
			curH = curH
			
				
		if curH >= topH:
			state = STATE.OPEN

			
			if waitClose != -1:
				#await get_tree().create_timer(waitClose).timeout
				closeTimeoutTimer = get_tree().create_timer(waitClose)
				closeTimeoutTimer.timeout.connect(closeTimeOut)
				active = false
				#await tree.create_timer(waitClose).timeout 
				#state = STATE.CLOSING
				
				#if get_node_or_null("closeSound")!= null: 
				#	get_node("closeSound").play()
				return

			
				
	if state == STATE.CLOSING:
		if curH > bottomH:
			incCurH(-speed*delta)
			curH-=speed*delta
			changeNodesY(targetNodes,-speed*delta)
		
		if curH  <= bottomH:
			state = STATE.CLOSED

			if waitOpen != -1:
				
				
				
				openTimeoutTimer = get_tree().create_timer(waitOpen)
				openTimeoutTimer.timeout.connect(openTimeOut)
				active = false
				return
				#await get_tree().create_timer(waitOpen).timeout
				
				
				
				
				#state = STATE.OPENING
				#
				#playOpen()
				return
	
	
	if curH <= bottomH and state == STATE.CLOSED:#some doors can start opeing from below the floor so we need this condition
		state = STATE.CLOSED
			
	if curH >= topH: 
		state = STATE.OPEN

		
	if state == STATE.CLOSED or state == STATE.CLOSED: 
		parent.set_meta("curOwner",null)



func walkOverTrigger(body):
	if !walkOverBodies.has(body):
		walkOverBodies.append(body)

func unlockAnimMesh(meshNode):
	meshNode.set_meta("lock",null)

func bodyIn(body):
	

	if keyType < 4:
		if !doesBodyHaveKey(body):
			if body.interactPressed == true:
				if body.has_method("popupText"):
					body.popupText("You need a " +WADG.keyNumberToColorStr(keyType) +" key to open this door")
			return
	
	if parent.has_meta("curOwner"):
		if parent.get_meta("curOwner") != self:
			return
	
	
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR or triggerType == WADG.TTYPE.DOOR or triggerType == WADG.TTYPE.DOOR1:
		if body.interactPressed == false:
			return
		
		#if "facingDir" in body: todo only open when facing?
		#	print(body.facingDir)
	
	
	if switchCooldown > 0:
		return
	
	switchCooldown = 1
	
	if get_node_or_null("buttonSound") != null:
		if getCurH() <= bottomH or getCurH() >= topH:
			get_node("buttonSound").play()
	
	for i in animTextures.size():
		var targetTexture = animTextures[i]
		var meshNode = get_node(animMeshPath[i])
		
		if !meshNode.has_meta("lock"):#cheap hack to stop multiple door scripts itt'ing the frame at the same time
			meshNode.set_meta("lock",true)
		else:
			continue
			
		get_tree().physics_frame.connect(unlockAnimMesh.bind(targetTexture))
		var t = (targetTexture.current_frame+1)%2
		targetTexture.current_frame = (targetTexture.current_frame+1)%2

	
	if !body.is_in_group("player") and !("interactPressed" in body):
		return 
		
	#if !overlappingBodiesActivated.has(body):
		#overlappingBodiesActivated.append(body)
		
		
	activate()  
	
	
	
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.DOOR1 or triggerType == WADG.TTYPE.WALK1: 
		for i in get_children():
			if i.get_class() == "Area3D":
				i.monitoring = false
				i.monitorable = false
		areasDisabled = true

	

func activate():

	
	if (state == STATE.OPEN or state == STATE.OPENING) and stayOpen == false:# and direction == DIR.DOWN: #if open and is a closer and !stayOpen -> close
		state = STATE.CLOSING

		if !parent.has_meta("curOwner"): 
			parent.set_meta("curOwner",self)
		
		playClosed()
					
	elif (state == STATE.CLOSED or state == STATE.CLOSING) and direction == DIR.UP: #if closed and is an opener -> open
		state = STATE.OPENING
		
		if getCurH() < topH:
			
			if !parent.has_meta("curOwner"):
				parent.set_meta("curOwner",self)
			
			#state = STATE.OPENING
			playOpen()
			
func changeNodesY(nodes,amt):
	for node in nodes:
		if !is_instance_valid(node):
			continue
		if node.get_parent().get_class() != "Node3D":
			node.get_parent().position.y += amt
		else:
			node.position.y += amt
			
func setNodesY(nodes,value):
	for nIdx in nodes.size():
		var node = nodes[nIdx]
		
		if node.get_parent().get_class() != "Node3D":
			node.get_parent().position.y = value
		else:
		
			var t= yInitial - value
			node.position.y = nodeInitial[nIdx].y - t
	
func getCurH():
	return parent.get_meta("curH")
	
	
func incCurH(amt):
	var curH = getCurH()
	parent.set_meta("curH",curH+amt)
	

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
 

func serializeSave():
	var yArr = []

	for i in targetNodes.size():
		if is_instance_valid(targetNodes[i]):
			yArr.append(targetNodes[i].position.y)
	
	var dict : Dictionary = {"yArr":yArr,"state":state,"curH":getCurH()}
	
	if closeTimeoutTimer != null:
		dict["closeTimeOutLeft"] = closeTimeoutTimer.time_left
	
	
	if openTimeoutTimer != null:
		dict["openTimeOutLeft"] = openTimeoutTimer.time_left
		
	dict["areasDisabled"] = areasDisabled
	return dict
	
func serializeLoad(data : Dictionary):
	
	state = data["state"]
	
	get_parent().set_meta("curH",data["curH"]) 
	
	for i in data["yArr"].size():
		targetNodes[i].position.y = data["yArr"][i]
	
	
	areasDisabled = data["areasDisabled"]
	
	if data.has("closeTimeOutLeft"):
		if closeTimeoutTimer != null:
			closeTimeoutTimer.disconnect("timeout",closeTimeOut)
			
		
		closeTimeoutTimer = get_tree().create_timer(data["closeTimeOutLeft"])
		closeTimeoutTimer.timeout.connect(closeTimeOut)
		
	if data.has("openTimeOutLeft"):
		if openTimeoutTimer != null:
			openTimeoutTimer.disconnect("timeout",openTimeOut)
			
		
		openTimeoutTimer = get_tree().create_timer(data["openTimeOutLeft"])
		openTimeoutTimer.timeout.connect(openTimeOut)
	
	for i in get_children():
		if i.get_class() == "Area3D":
			i.monitoring = !data["areasDisabled"]
			i.monitorable = !data["areasDisabled"]
