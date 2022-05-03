extends Spatial


export(int) var type
export(Dictionary) var info
var active = true
var endState 
export var speed = 2
export(WADG.DEST) var dest 
export(WADG.DIR) var dir 
export(WADG.TTYPE) var triggerType
export var npcType = "none" 
export(String) var animMeshPath = ""
var state 
export var textureChange = false
var floorNode = null
var loop = false 

var topH
var bottomH
var animMats = []
var animTextures = []
var newTexture = null
var newSectorIdx = 0
enum STATE{
	TOP,
	GOING_DOWN,
	BOTTOM,
	GOING_UP
}

func _ready():

	
	if has_meta("loop"): loop = true
	if !get_parent().has_meta("curH"):
		get_parent().set_meta("curH",0)


	var destH = WADG.getDest(dest,info["sectorInfo"])
	var floorH = info["sectorInfo"]["floorHeight"]
	
	bottomH = min(floorH,destH)
	topH = max(floorH,destH)
	
	get_parent().set_meta("curH",floorH) 
	
	
	animTextures = $"../../../".getAnimTextures(self,animMeshPath)
	

		
	if dir == WADG.DIR.UP:
		if floorH >= destH:
			state = STATE.TOP
		else:
			state = STATE.BOTTOM
	
	
	if dir == WADG.DIR.DOWN:
		if floorH <= destH:
			state = STATE.BOTTOM
		else:
			state = STATE.TOP
	
	info["targetNodes"] = []
	
	for t in info["targets"]:
		var mapNode = get_parent().get_parent().get_parent()
		var node = mapNode.get_node(t)
		
		
		if node.has_meta("floor"): 
			info["targetNodes"].append(node)
			floorNode = node
		
		
		elif node.has_meta("type"):
			if node.get_meta("type") == "lower": info["targetNodes"].append(node)



func _physics_process(delta):
	
	
	if active == false:
		return
	
	

	if state == STATE.GOING_UP:
		if getCurH() < topH:
			incCurH(speed)
			
			for node in info["targetNodes"]:
				node.translation.y += speed
		
		if getCurH() >= topH:
			state = STATE.TOP
			if loop: 
				state = STATE.GOING_DOWN
				
			
				
	if state == STATE.GOING_DOWN:
		if getCurH() > bottomH:
			incCurH(-speed)
			
			for node in info["targetNodes"]:
				node.translation.y -= speed
		
		if  getCurH() <= bottomH:
			state = STATE.BOTTOM
			
			if floorNode != null:
				if newTexture != null:
					if textureChange == true:
						changeTexture(floorNode.mesh,newTexture,newSectorIdx)
				else:
					print("missing floor node for texture change")
			
			if loop:
				 state = STATE.GOING_UP


func body_entered(body,texture,sectorIdx):
	
	newTexture = texture
	newSectorIdx = sectorIdx
	if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR:
		if "interactPressed" in body:
			if body.interactPressed == false:
				return
			else:
				for i in animTextures:
					i.current_frame = 1
				if get_node_or_null("buttonSound") != null:
					if state != STATE.GOING_DOWN and state != STATE.GOING_UP:
						get_node("buttonSound").play()
	
	if newTexture != null and textureChange and dir == WADG.DIR.UP:
		changeTexture(floorNode.mesh,newTexture,newSectorIdx)
	
	if body.get_class() != "StaticBody":
		activate()
		
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.WALK1: 
			for i in get_children():
				if i.get_class() == "Area":
					i.queue_free()
		

func activate():
	if get_node_or_null("buttonSound") != null:
		get_node_or_null("buttonSound").play()
		
	var curH = getCurH()
	if dir == WADG.DIR.UP and curH >= topH: return
	if dir == WADG.DIR.DOWN and curH <= bottomH: return
		
		
		
	if state == endState:
		return
		
	if state == STATE.TOP: 
			state = STATE.GOING_DOWN
			if get_node_or_null("closeSound")!= null: 
				var n = get_node("closeSound")
				n.play()
				
				
				
	elif state == STATE.BOTTOM: 
			state = STATE.GOING_UP
			if get_node_or_null("openSound")!= null: get_node("openSound").play()
			


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
