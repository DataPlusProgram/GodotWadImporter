@tool
extends Node3D

@onready var parent = get_parent()
@onready var isEditor = Engine.is_editor_hint()
@export var type: int
@export var info: Dictionary
var active = true
var endState 
@export var speed = 40
@export var dest  :WADG.DEST
@export var direction  :WADG.DIR
@export var triggerType :WADG.TTYPE
@export var animMeshPath: Array = []
var state 
@export var textureChange = false
var floorNode = null
var ceiling = null
@export var loop = false 
@export var globalScale: Vector3 = Vector3(0,1,0)
@export var cumulative = false
@export var crushes= 0.0
@export var damage  = 0.0
@export var allSectorTuples : Array[Array] = []
var walkOverBodies : Array = []
var initialSpeed
var topH
var bottomH
var animMats = []
var animTextures = []
var newTexture = null
var newSectorIdx = 0
var stage = 0
@export var newSectorType : Dictionary
var startDelay = -1
var floorCast: ShapeCast3D = null
var ceilingCast : ShapeCast3D = null
var areasDisabled = false
var overwriteTexture  = null
var iFameDict : Dictionary = {}
enum STATE{
	TOP,
	GOING_DOWN,
	BOTTOM,
	GOING_UP
}

	
func _ready():
	
	
	if isEditor:
		return
	
	add_to_group("levelObject",true)
	
	speed *= globalScale.y
	if has_meta("loop"): loop = true
	if !get_parent().has_meta("curH"):
		get_parent().set_meta("curH",0)


	
	
	var destH = WADG.getDest(dest,info["sectorInfo"],globalScale.y)
	
	if cumulative:
		destH = WADG.getDestStages(dest,info["sectorInfo"]["floorHeight"],allSectorTuples,globalScale.y,0)
	
	var floorH = info["sectorInfo"]["floorHeight"]
	
	var i = info["sectorInfo"]
	
	get_parent().set_meta("curH",floorH) 
	
	
	if loop:
		floorH =  info["sectorInfo"]["lowestNeighFloorInc"]
		destH =  info["sectorInfo"]["highestNeighFloorInc"]
		

		
	
	bottomH = min(floorH,destH)
	topH = max(floorH,destH)
	
	#if animMeshPath.size() > 0:
	#	breakpoint
	animTextures = $"../../../".getAnimTextures(self,animMeshPath)
	


	checkState(floorH,destH)
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
			
	
	initialSpeed = speed
	
	if floorNode != null and ceiling != null:
		var s = Time.get_ticks_msec()
		
		if floorNode.get_child_count() == 0:
			return
		
		if ceiling.get_child_count() == 0:
			return
		
		floorCast = WADG.createCastShapeForBody(floorNode.get_child(0),Vector3(0,0.1,0))
		ceilingCast = WADG.createCastShapeForBody(ceiling.get_child(0),Vector3(0,-0.1,0))
		
		var delta = 1.0/Engine.physics_ticks_per_second
		
		floorCast.position.y = speed*delta*2 #stop the floor before it will be insecapeable
		ceilingCast.position.y = -speed*delta*2
		
		if floorCast != null:
			floorCast.enabled = false
		if ceilingCast != null:
			ceilingCast.enabled = false
		SETTINGS.incTimeLog(get_tree(),"castShapes",s)
			
	
	
func walkOverTrigger(body):
	if !walkOverBodies.has(body):
		walkOverBodies.append(body)

func checkState(floorH,destH):
	if direction == WADG.DIR.UP:
		if floorH >= destH:
			state = STATE.TOP
			endState = STATE.BOTTOM
		elif state != STATE.GOING_DOWN and state != STATE.GOING_UP:
			state = STATE.BOTTOM
			endState = STATE.TOP
				
		
		
	if direction == WADG.DIR.DOWN:
		if floorH <= destH:
			state = STATE.BOTTOM
			endState = STATE.TOP
		elif state != STATE.GOING_DOWN and state != STATE.GOING_UP:
			state = STATE.TOP
			endState = STATE.BOTTOM
	

func _physics_process(delta):
	
	for body in walkOverBodies:
		bodyIn(body)
		
	walkOverBodies = []
	
	
	
	if active == false:
		return
	
	
	if state == STATE.GOING_UP:
		if floorCast != null and ceilingCast != null:
			var lowList = []
			var highList = []
			
			ceilingCast.debug_shape_custom_color =Color.PURPLE
			
			
			floorCast.enabled = true
			floorCast.force_shapecast_update()
			floorCast.enabled = false
			
			for i in floorCast.get_collision_count():
				if !floorCast.get_collider(i).has_meta("ceil"):
					##WADG.drawSphere($"/root",floorCast.get_collision_point(i))
					lowList.append(floorCast.get_collider(i))
			
			
			ceilingCast.enabled = true
			ceilingCast.force_shapecast_update()
			ceilingCast.enabled = false
			
			
			for i in ceilingCast.get_collision_count():
				if !ceilingCast.get_collider(i).has_meta("floor"):
					highList.append(ceilingCast.get_collider(i))
			
			var flag = false
			
			for i in highList:
				if i.get_class() == "StaticBody3D":
					continue
				if lowList.has(i):
					
					
					#incCurH(-speed*delta*1.9)
			
					#for node in info["targetNodes"]:
					#	node.position.y -=speed*delta*1.9
					
					speed = 0
					flag = true
					
					if crushes != 0 :
						if i.has_method("takeDamage"):
							i.takeDamage({"amt":damage,"iFrameMS":crushes,"source" :self,"targetable" : false})
			
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
				
		if floorNode != null:
			if floorNode.get_node_or_null("openSound"):
				if !floorNode.get_node("openSound").playing:
					floorNode.get_node("openSound").play()


	if state == STATE.GOING_UP:
		if getCurH() < topH:
			incCurH(speed*delta)
			changeNodesY(info["targetNodes"],speed*delta)

		if getCurH() >= topH:
			state = STATE.TOP
			if cumulative:
				state = STATE.BOTTOM
				topH = min(info["sectorInfo"]["ceilingHeight"],topH+WADG.getDest(dest,info["sectorInfo"],globalScale.y))
			
			if get_parent().has_meta("curOwner"): 
				get_parent().set_meta("curOwner",null)
			
			if loop: 
				state = STATE.GOING_DOWN
				
		
		if floorNode != null:
			if newTexture != null:
				if textureChange == true:
					changeTexture(floorNode.mesh,newTexture,newSectorIdx)
					floorNode.set_meta("damage",WADG.getDamageInfoFromSectorType2(newSectorType))
			else:
				print("missing floor node for texture change")
				
			
				
	if state == STATE.GOING_DOWN:
		
		if getCurH() > bottomH:
			incCurH(-speed*delta)
			
			for node in info["targetNodes"]:
				node.position.y = max(node.position.y-(speed*delta),bottomH)
		
		if  getCurH() <= bottomH:
			state = STATE.BOTTOM
			
			if get_parent().has_meta("curOwner"): 
				get_parent().set_meta("curOwner",null)
			

			if floorNode != null:
				if newTexture != null:
					if textureChange == true:
						changeTexture(floorNode.mesh,newTexture,newSectorIdx)
						floorNode.set_meta("damage",WADG.getDamageInfoFromSectorType2(newSectorType))
				else:
					print("missing floor node for texture change")
			
			if loop:
				state = STATE.GOING_UP

func bin(body):
	pass

func bodyIn(body : PhysicsBody3D,texture : Texture2D = null,sectorIdx : int = -1,sectorType : Dictionary = {}):
	

	
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
		if floorNode != null:
			changeTexture(floorNode.mesh,newTexture,sectorType)
			floorNode.set_meta("damage",WADG.getDamageInfoFromSectorType2(newSectorType))
		
	
	if body.get_class() != "StaticBody3D":
		activate()
		
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.WALK1: 
			for i in get_children():
				if i.get_class() == "Area3D":
					i.monitoring = false
					i.monitorable = false
			
			areasDisabled = true
		

	
func activate():
	
	
	if active == false and loop == true:
		active = true
		
	var curH = getCurH()
	
	for child in get_children():
		if child.has_meta("fTextureName"):
			newTexture = child.get_meta("fTextureName")
		
		if child.has_meta("fType"):
			newSectorType = child.get_meta("fType")
	
	
	checkState(curH,WADG.getDest(dest,info["sectorInfo"],globalScale.y))#watch this for bugs
	
	if !loop:
		
		if cumulative and curH >= topH:
			stage += 1
			topH = WADG.getDestStages(dest,info["sectorInfo"]["floorHeight"],allSectorTuples,globalScale.y,stage)
			direction == WADG.DIR.UP
			state = STATE.BOTTOM
		else:
			if direction == WADG.DIR.UP and curH >= topH: return
			if direction == WADG.DIR.DOWN and curH <= bottomH: return
	
	
	
	
	if parent.has_meta("curOwner"): 
		if parent.get_meta("curOwner") != null:
			return
	
	if !parent.has_meta("curOwner"): 
		parent.set_meta("curOwner",self)
	
	

	
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
	
	#if get_node_or_null("../../../../WadLoader/ResourceManager") != null:
	#	var light = sectorInfo["lightLevel"]
	#	var lightAdjust = WADG.getLightLevel(light)
		#var tex = $"../../../../WadLoader/ResourceManager".fetchFlatRuntime(newTexture)
		
		#mat = $"../../../../WadLoader/MaterialManager".fetchGeometryMaterial(newTexture,tex,Color(lightAdjust,lightAdjust,lightAdjust),Vector2.ZERO,1,true)
	#	overwriteTexture = newTexture
	
	var newMat = mesh.surface_get_material(0).duplicate()
	newMat.set_shader_parameter("texture_albedo",texture)
	mesh.surface_set_material(0,newMat)

func getCurH():
	return parent.get_meta("curH")
	
	
func incCurH(amt):
	var curH = getCurH()
	parent.set_meta("curH",curH+amt)

func printState():
	if state == STATE.BOTTOM: print("bottom")
	if state == STATE.GOING_UP: print("goingUP")
	if state == STATE.TOP: print("top")
	if state == STATE.GOING_DOWN: print("goingDOWN")



func getMeshOfNode(node):
	var arr = []
	
	if node.get_class() == "MeshInstance3D":
		arr.append(node)
	
	for c in node.get_children():
		arr += getMeshOfNode(c)
	
	return arr

func changeNodesY(nodes,amt):
	for node in nodes:
		if node.get_parent().get_class() != "Node3D":
			node.get_parent().position.y = min(node.get_parent().position.y+amt,topH)
			#node.get_parent().position.y += amt
		else:
			node.position.y = min(node.position.y+amt,topH)
			#node.position.y += amt
			
func serializeSave():
	var yArr = []
	
	for i in info["targetNodes"].size():
		yArr.append(info["targetNodes"][i].position.y)
	
	var animtexturesFrames = []
	
	for i in animTextures:
		animtexturesFrames.append(i.current_frame)
	
	var dict= {"yArr":yArr,"state":state,"curH":getCurH(),"animTextureFrames":animtexturesFrames}
	
	dict["areasDisabled"] = areasDisabled
	
	dict["parOwner"] = null
	
	if get_parent().has_meta("curOwner"):
		if get_parent().get_meta("curOwner") != self:
			dict["parOwner"] =  get_parent()

	
	dict["overwriteTexture"] = overwriteTexture
	return dict
	
func serializeLoad(data : Dictionary):
	
	state = data["state"]
	
	get_parent().set_meta("curH",data["curH"]) 
	
	if data["parOwner"] == null:
		get_parent().set_meta("curOwner", null)
	
	for i in get_children():
		if i.get_class() == "Area3D":
			i.monitoring = !data["areasDisabled"]
			i.monitorable = !data["areasDisabled"]
	
	areasDisabled = data["areasDisabled"]
	
	for i in data["yArr"].size():
		info["targetNodes"][i].position.y = data["yArr"][i]
		
	for i in data["animTextureFrames"].size():
		animTextures[i].current_frame = int(data["animTextureFrames"][i])
	
	
	
