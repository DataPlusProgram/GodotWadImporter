tool
extends Spatial

enum{
	PLAYER1,
	PLAYER2,
	PLAYER3,
	PLAYER4,
	DEATH_MATCH
}


var canBake : bool  = true
export(String, FILE, "*.tscn,*.scn") var nextMapTscn = null
export(String, FILE, "*.tscn,*.scn") var nextSecretMapTscn = null

export(Dictionary) var mapInfo = {}

var bakeStart
var bakeEnd
var aiEnts : Array = []
var spawns
var aiArrChanged : bool = false
var aiProcessBlocks : Array = []
var dTickTracker : float = 0
var aiArrIndex = 0
var updateAi : bool = false
var spawnsReady = false
var timer = Timer.new()


func _ready():
	add_child(timer)
	timer.connect("timeout",self,"bakeAgain")
	add_to_group("levels",true)
	
	if Engine.editor_hint: 
		return
	
	clearFullscreenImage()
	 
	#bakeStart = OS.get_system_time_msecs()
	
	if get_node_or_null("Geometry")!=null:
		#bakeAgain()
		get_node("Geometry").bake_navigation_mesh()
		$"Geometry".connect("bake_finished",self,"bakeFinished")
	
	
	
	timer.autostart = false
	
	#rebakePath()
	spawnsReady = true
	

func bakeFinished():
	
	canBake = true
	bakeEnd = OS.get_system_time_msecs()
	
	if bakeStart == null:
		bakeStart = OS.get_system_time_msecs()
	var nextBake = max(0,1000-(bakeEnd-bakeStart))
	
	
	#print(nextBake/1000.0)
	
	if nextBake > 0:
		timer.wait_time = nextBake/1000.0
		timer.start()
	else:
		bakeAgain()

	
	
func bakeAgain():
	bakeStart = OS.get_system_time_msecs()
	get_node("Geometry").bake_navigation_mesh()


func getSpawns(teamIdx):
	var spawnLocations = []
	
	if get_node_or_null("Entities") == null:
		return []
		
	
	for i in get_node("Entities").get_children():
		if i.has_meta("spawn"):
			if i.get_meta("team") == teamIdx:
				spawnLocations.append({"pos":i.global_transform.origin,"rot":i.global_transform.basis.get_euler()})
				
	return spawnLocations
	


func setFullscreenImage():
	var buff = get_tree().get_nodes_in_group("fullscreenTexture")
	if !buff.empty():
		var tex = ImageTexture.new()
		var data = get_viewport().get_texture().get_data()
		data.flip_y()
		tex.create_from_image(data)
		buff[0].texture=tex
		
func clearFullscreenImage():
	var buff = get_tree().get_nodes_in_group("fullscreenTexture")
	if !buff.empty():
		buff[0].texture = null

func _physics_process(delta):
	
	if Engine.editor_hint: 
		return
	
	var metaList = get_meta_list()
	for i in get_meta_list():
		
		var t = get_meta(i)
		if typeof(t) == TYPE_INT:
			if t <= 0:
				if name == "E1M8" and i == "baronOfHell":
					for o in get_tree().get_nodes_in_group("npcTrigger"):
						var target = o.targetNpc
						if i == target:
							o.activate()
							
				if name == "MAP07" and i == "mancubus":
					for o in get_tree().get_nodes_in_group("npcTrigger"):
						var target = o.targetNpc
						if i == target:
							o.activate()
							
				if name == "MAP07" and i == "arachnotron":
					for o in get_tree().get_nodes_in_group("npcTrigger"):
						var target = o.targetNpc
						if i == target:
							o.activate()
				
			
	dTickTracker += delta
	
	if true:#dTickTracker >= 1.0/35.0:
		
		var newAiArray = []
		
		
#		for i in aiProcessBlocks:
#			newAiArray.append([])
#			for j in i:
#				if j!= null:
#					if is_instance_valid(j):
#						newAiArray[i].push_back(j)
		
#		aiProcessBlocks = newAiArray
		
		if !aiProcessBlocks.empty():
			for i in aiProcessBlocks[aiArrIndex]:
				if is_instance_valid(i):
						i.doTick = true
						
#			for i in aiProcessBlocks.size():
#				if aiArrIndex != i:
#					for node in aiProcessBlocks[i]:
#						if is_instance_valid(node):
#							if node.get_node_or_null("cast")!= null:
#								node.get_node("cast").enabled = false
		
		
			aiArrIndex = (aiArrIndex+1)%aiProcessBlocks.size()
			dTickTracker = 0
		
	
	if aiArrChanged:
		sortAiArray(40)
	
	if get_node_or_null("Geometry") == null:
		return
	
		
	if canBake:
		bakeStart = OS.get_system_time_msecs()
		canBake = false
		
	if name == "E2M8" and has_meta("Cyberdemon"):
		if get_meta("Cyberdemon") <= 0:
				nextMap()

	

func sortAiArray(splitSize):
	var t = aiEnts.size()
	var aSize = ceil(aiEnts.size()/splitSize)
	var bSize = floor(aiEnts.size()/splitSize)
	
	aiProcessBlocks.clear()
	aiArrChanged = false
	
	aiProcessBlocks = sizePerArray(aiEnts,splitSize)
	var x = aiProcessBlocks.size()
	
	

func sizePerArray(var arr : Array, var targetSize : int) -> Array:
	var ret = [arr]
	var i = 0
	while i < ret.size():
		if ret[i].size() > targetSize:
			var subArr = ret[i]
			ret.erase(subArr)
			var arrSize : int = subArr.size()
			var aSize = ceil(arrSize/2.0)
			var bSize = floor(arrSize/2.0)
			ret.append(subArr.slice(0,aSize-1))
			ret.append(subArr.slice(bSize,arrSize-1))
			i = 0
			continue
			
		i += 1
			
		
	return ret
	

func nextMap(var secret = false):
	var mapName = name
	
	
	var nextMap = WADG.incMap(mapName,secret)
	var wadLoader = get_node_or_null("../WadLoader")
	
	if nextMapTscn != null:
		#setFullscreenImage()
		var nxtMapStr = nextMapTscn
		if secret:
			nxtMapStr = nextSecretMapTscn
			
		var newMap = load(nxtMapStr).instance()
		get_parent().add_child(newMap)
		queue_free()

	elif wadLoader == null:
		return
	else:
		if wadLoader.patchTextureEntries == null:
			wadLoader.createMap(nextMap)
		else:
			wadLoader.createMap(nextMap,{"reloadWads":false})

	ENTG.clearEntityCaches(get_tree())
	queue_free()
	
	
	#setFullscreenImage()
	
	

	
	for i in get_children():
		if i.name == "Entities":
			for ent in i.get_children():
				if !ent.is_in_group("player"):
					ent.queue_free()
				else:
					ent.get_parent().remove_child(ent)
					get_parent().add_child(ent)
		else:
			i.queue_free()
	
	for i in get_tree().get_nodes_in_group("player"):
		if "inventory" in i:
			var inventory : Dictionary = i.inventory
			for item in inventory.keys():
				if inventory[item].has("persistant"):
					if inventory[item].persistant == false:
						inventory.erase(item)
	yield(get_tree(), "physics_frame")

	
	


func getAnimTextures(caller,animMeshPath):
	var animTextures = []
	
	for path in animMeshPath:
		if caller.get_node_or_null(path) == null:
			return
		var p2 = path.replace("../../../","")
		var node = get_node(p2)
		
		if !node.has_meta("runtimeMat"):
		
			var mesh : ArrayMesh = node.mesh 
			var mat = mesh.surface_get_material(0)
		
			var newMat = mat.duplicate(true)
			
			mesh.surface_set_material(0,newMat)
			node.set_meta("runtimeMat",newMat)
		
		var mat = node.get_meta("runtimeMat")
		
		if  mat.get_shader_param("texture_albedo") != null:
			var texture = mat.get_shader_param("texture_albedo")
			
			if "current_frame" in texture:
				animTextures.append(texture)
					
			
			
	return animTextures

func registerAi(ref):
	aiEnts.append(ref)
	aiArrChanged = true
