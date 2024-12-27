@tool
extends Node3D

enum{
	PLAYER1,
	PLAYER2,
	PLAYER3,
	PLAYER4,
	DEATH_MATCH
}

signal goNextMapSignal
var canBake : bool  = true
@export var nextMapStr : String = ""  # (String, FILE, "*.tscn,*.scn")
@export var nextSecretMapStr:  String = ""  # (String, FILE, "*.tscn,*.scn")
@export var mapInfo: Dictionary = {}

var allPlayersPos : PackedVector3Array
var allPlayers : Array[Node] = []
var timeSec = 0
var bakeStart
var bakeEnd
var totalSecrets = 0
var aiEnts : Array = []
var spawns
var aiArrChanged : bool = false
var aiProcessBlocks : BalancedArray = BalancedArray.new()
var trackingCollision : BalancedArray = BalancedArray.new()
var disableNodes  : BalancedArray = BalancedArray.new()
var dTickTracker : float = 0
var aiArrIndex = 0
var updateAi : bool = false
var spawnsReady = false
var timer = Timer.new()
var isLoading = false
var birthDict : Dictionary = {}
var deathDict : Dictionary = {}

var itemCountDict : Dictionary = {}
var itemCollectDict : Dictionary = {}

var loadedBirthDict = {}
var loadedDeathDict = {}
var loadedItemCountDict = {}
var loadedItemCollectDict = {}

var secretsFound : float = 0.0
@export var midiPath = ""
@export var rawMidiData : PackedByteArray = []
@export var mapName : String
@export var gameName : String
#@onready var tree := get_tree()




var npcMapTrigger = {
	"E1M8" : ["baron of hell"],
	"MAP07": ["mancubus","arachnotron"]
	
}

func _ready():
	
	
	var a = Time.get_ticks_msec()
	aiProcessBlocks.maxSectionSize = 200
	trackingCollision.maxSectionSize = 200
	child_entered_tree.connect(childAdded)
	
	for c in get_children():
		childAdded(c)
	
	add_child(timer)
	timer.connect("timeout", Callable(self, "bakeAgain"))
	add_to_group("level",true)
	
	if Engine.is_editor_hint(): 
		return
	
	var tree = get_tree()
	if !rawMidiData.is_empty():
		var midiPlayer = ENTG.fetchMidiPlayer(tree)
		
		
		ENTG.setMidiPlayerData(midiPlayer,rawMidiData)
		
		
		if midiPlayer.get_parent() == null:
			midiPlayer.ready.connect(midiPlayer.play)
			get_parent().add_child(midiPlayer)
		else :
			midiPlayer.play()
		
	
	
	clearFullscreenImage()
	 
	bakeStart = Time.get_ticks_msec()
	
	if get_node_or_null("Geometry")!=null:
		bakeAgain()
		$"Geometry".connect("bake_finished", Callable(self, "bakeFinished"))
	
	
	timer.autostart = false
	spawnsReady = true

func bakeFinished():
	
	canBake = true
	bakeEnd = Time.get_ticks_msec()
	
	if bakeStart == null:
		bakeStart = Time.get_ticks_msec()
	var nextBake = max(0,1000-(bakeEnd-bakeStart))
	
	
	#print(nextBake/1000.0)
	
	if nextBake > 0:
		timer.wait_time = nextBake/1000.0
		timer.start()
	else:
		bakeAgain()

	
func bakeAgain():
	bakeStart = Time.get_ticks_msec()
	get_node("Geometry").bake_navigation_mesh()


func getSpawns(teamIdx,isDeathmatch = false):
	var spawnLocations = []
	
	if get_node_or_null("Entities") == null:
		return []
		
	
	for i in get_node("Entities").get_children():
		if i.has_meta("spawn"):
			if i.get_meta("team") == teamIdx:
				if i.has_meta("deathmatch") and isDeathmatch:
					spawnLocations.append({"pos":i.global_transform.origin,"rot":i.global_transform.basis.get_euler()})
				elif !i.has_meta("deathmatch") and !isDeathmatch:
					spawnLocations.append({"pos":i.global_transform.origin,"rot":i.global_transform.basis.get_euler()})
				
	return spawnLocations
	


func setFullscreenImage():
	var tree = get_tree()
	var buff = tree.get_nodes_in_group("fullscreenTexture")
	if !buff.is_empty():
		var tex = ImageTexture.new()
		var data = get_viewport().get_texture().get_image()
		data.flip_y()
		tex.create_from_image(data)
		buff[0].texture=tex
		
func clearFullscreenImage():
	var tree = get_tree()
	var buff = tree.get_nodes_in_group("fullscreenTexture")
	if !buff.is_empty():
		buff[0].texture = null

func _physics_process(delta):
	
	
	if Engine.is_editor_hint(): 
		return
	
	#print(aiProcessBlocks.array)
	
	var tree = get_tree()
	allPlayers = tree.get_nodes_in_group("player")
	allPlayersPos.clear()
	
	for i in allPlayers:
		allPlayersPos.append(i.global_position)
	
	if spawnsReady:
		timeSec += delta
	
	
	trackingColTick()
	
	for i in birthDict:
		
		if !deathDict.has(i):
			continue
		
		
		
		var t = birthDict[i] - deathDict[i]
		
		
		if t <= 0:
			if npcMapTrigger.has(name) and !isLoading:
				for tagetNpcStr in npcMapTrigger[name]:
					for o in tree.get_nodes_in_group("npcTrigger"):
						var target = o.targetNpc
						if i == target:
							o.activate()
				
			if name == "E2M8" and i == "cyberdemon" and !isLoading:
				var modes = tree.get_nodes_in_group("gameMode")
					
				if modes.size() > 0:
					modes[0].nextMap(self)
				isLoading = true
				return

			
	dTickTracker += delta
	
	#if true:#dTickTracker >= 1.0/35.0:
		#
		#var newAiArray = []
		#
		#
		#
		#if !aiProcessBlocks.is_empty():
			#
#
			#
			#for i in aiProcessBlocks[aiArrIndex].size():
				#var node = aiProcessBlocks[aiArrIndex][i]
				#if is_instance_valid(node):
					#node.doTick = true
					#newAiArray.append(node)
	#
					#
			#
			#aiProcessBlocks[aiArrIndex] = newAiArray
			#aiArrIndex = (aiArrIndex+1)%aiProcessBlocks.size()
			#dTickTracker = 0
		
	
	
	#if aiArrChanged:
		#sortAiArray(40)
	
	if get_node_or_null("Geometry") == null:
		return
	
		
	if canBake:
		bakeStart = Time.get_ticks_msec()
		canBake = false
	
	
	var blockHalf = getAiForThisTick()
	
	if !blockHalf.is_empty():
		aiTick(delta,blockHalf)
		setAiTooFar(blockHalf)
	
	setTooFar()
	


var curAiProc = []
var batchA = []
var batchB = []
var newBatch = false

func getAiForThisTick():
	var splitSize = aiProcessBlocks.array.size()
	
	
	if batchA.is_empty() and batchB.is_empty():
		curAiProc = aiProcessBlocks.getNext().duplicate()
		batchA = curAiProc.slice(0,curAiProc.size()/2)
		batchB = curAiProc.slice(curAiProc.size()/2,curAiProc.size())
		newBatch = true
	var curBlockHalf
	if !batchA.is_empty():
		curBlockHalf = batchA
		batchA =[]
	elif !newBatch:
		curBlockHalf = batchB
		batchB = []
	else:
		newBatch = false
		return []
		
	return curBlockHalf

func aiTick(delta,curBlockHalf):

	#var newAiArray = []
	var splitSize = aiProcessBlocks.array.size()
	
	
	#if batchA.is_empty() and batchB.is_empty():
		#curAiProc = aiProcessBlocks.getNext().duplicate()
		#batchA = curAiProc.slice(0,curAiProc.size()/2)
		#batchB = curAiProc.slice(curAiProc.size()/2,curAiProc.size())
		#newBatch = true
	#var curBlockHalf
	#if !batchA.is_empty():
		#curBlockHalf = batchA
		#batchA =[]
	#elif !newBatch:
		#curBlockHalf = batchB
		#batchB = []
	#else:
		#newBatch = false
		#return
		
	for i in curBlockHalf.size():
		var node = curBlockHalf[i]
		if is_instance_valid(node):
			node.doTick = true
			node._physics_process(delta*splitSize)
			
			#newAiArray.append(node)
		else:
			aiProcessBlocks.eraseFromItemFromSection(curAiProc,curBlockHalf[i])
			
func getKillPercent():
	var total : float = 0.0
	var deathCount : float = 0.0
	
	
	for i in birthDict:
		total += birthDict[i]
	
	
	if total == 0:
		return 1.0
	
	for i in deathDict:
		deathCount += deathDict[i]
		
	return deathCount/total
	
func getItemPercent():
	var total : float = 0.0
	var collectCount : float = 0.0
	
	
	for i in itemCountDict:
		total += itemCountDict[i]
	
	
	if total == 0:
		return 1.0
	
	for i in itemCollectDict:
		collectCount += itemCollectDict[i]
		
	return collectCount/total

#func getItemPercent():
	#var collectedCount : float = 0.0
	#
	#for i in itemCountDict:
		#var itemNode = get_node_or_null(i)
		#
		#if itemNode == null:
			#collectedCount +=1
		#elif !is_instance_valid(itemNode):
			#collectedCount +=1
			#
	#return collectedCount/itemCountDict.size() 

func getSecretPercent():
	if totalSecrets == 0:
		return 1.0
	return secretsFound/totalSecrets
	

#func sortAiArray(splitSize):
	#var t = aiEnts.size()
	#var aSize = ceil(aiEnts.size()/splitSize)
	#var bSize = floor(aiEnts.size()/splitSize)
	#
	#aiProcessBlocks.clear()
	#aiArrChanged = false
	#
	#aiProcessBlocks = sizePerArray(aiEnts,splitSize)
	#var x = aiProcessBlocks.size()
	
	

#func sizePerArray(arr : Array, targetSize : int) -> Array:
	#var ret = [arr]
	#var i = 0
	#while i < ret.size():
		#if ret[i].size() > targetSize:
			#var subArr = ret[i]
			#ret.erase(subArr)
			#var arrSize : int = subArr.size()
			#var aSize = ceil(arrSize/2.0)
			#var bSize = floor(arrSize/2.0)
			#ret.append(subArr.slice(0,aSize))
			#ret.append(subArr.slice(bSize,arrSize))
			#i = 0
			#continue
			#
		#i += 1
			#
		#
	#return ret
	

func nextMap(secret = false):
	
	var tree = get_tree()
	
	var midiPlayer = ENTG.fetchMidiPlayer(tree)
	midiPlayer.stop()
	
	
	#var nextMap = WADG.incMap(mapName,secret)
	var wadLoader = get_node_or_null("../WadLoader")
	

	var nxtMapStr = nextMapStr
	
	if secret:
		nxtMapStr = nextSecretMapStr
	
	if ENTG.doesDirExist(nextMapStr):
		var newMap = load(nxtMapStr).instantiate()
		get_parent().add_child(newMap)
		queue_free()

	elif wadLoader == null:
		return
	else:
		if wadLoader.patchTextureEntries == null:
			wadLoader.createMap(nxtMapStr)
		else:
			wadLoader.createMap(nxtMapStr,{"reloadWads":false})

	ENTG.clearEntityCaches(tree)
	queue_free()
	

	
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
	
	for i in tree.get_nodes_in_group("player"):
		if "inventory" in i:
			var inventory : Dictionary = i.inventory
			for item in inventory.keys():
				if inventory[item].has("persistant"):
					if inventory[item].persistant == false:
						inventory.erase(item)
	await tree.physics_frame

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
		
		if  mat.get_shader_parameter("texture_albedo") != null:
			var texture = mat.get_shader_parameter("texture_albedo")
			
			if "current_frame" in texture:
				animTextures.append(texture)
					
			
			
	return animTextures

func registerAi(ref):
	aiEnts.append(ref)
	
	for i in aiEnts:
		if i == null:
			aiEnts.erase(i)
		if !is_instance_valid(i):
			aiEnts.erase(i)
	
	aiProcessBlocks.add(ref)
	
	#aiArrChanged = true



func serializeSave():
	var dict =  {"saveType":"level","gameName":gameName,"levelName":mapName}
	
	dict["itemCountDict"] = itemCountDict
	dict["itemCollectDict"] =itemCollectDict
	dict["birthDict"] = birthDict
	dict["deathDict"] = deathDict
	dict["timeSec"] = timeSec
	
	return dict

func serializeLoad(data):
	aiEnts = []
	var targets = ["baron of Hell","arachnotron","mancubus","Cyberdemon"]
	
	for i in get_meta_list():
		for j in targets:
			if i == j:
				set_meta(i,0)

			
		
		
	loadedItemCountDict = data["itemCountDict"]
	loadedItemCollectDict = data["itemCollectDict"]
	loadedBirthDict = data["birthDict"]
	loadedDeathDict = data["deathDict"]
	timeSec = data["timeSec"]
	#for i in data["enemiesLeft"].keys():
		#set_meta(i,data["enemiesLeft"][i])
		

func registerItemCreation(itemName : String):

	if !itemCountDict.has(itemName):
		itemCountDict[itemName] = 0
	
	itemCountDict[itemName] += 1
	
func registerItemDeletion(itemName):
	
	if !itemCollectDict.has(itemName):
		itemCollectDict[itemName] = 0
	
	itemCollectDict[itemName] += 1
	
func registerBirth(npcName : String):
	if !birthDict.has(npcName):
		birthDict[npcName] = 0
		
	birthDict[npcName] += 1
	
func registerDeath(npcName : String):
	
	if !deathDict.has(npcName):
		deathDict[npcName] = 0
		
	deathDict[npcName] += 1
	var per = getKillPercent()
	

func childAdded(child : Node):
	
	if "mapHandlesDisable" in child:
		if child.mapHandlesDisable:
			disableNodes.add(child)
	
	var addSignal = true
	
	for sig in child.get_signal_connection_list("child_entered_tree"):

		if sig["callable"].get_object() == self:
			addSignal = false
	
	if addSignal:
		child.child_entered_tree.connect(childAdded)
	
	
	for i in child.get_children():
		childAdded(i)
	
	
	
	if !child is StaticBody3D:
		return
	
	trackingCollision.add(child)
	#trackingCollision.append(child)
	

func loadFinished():
	birthDict = loadedBirthDict
	deathDict = loadedDeathDict
	itemCountDict = loadedItemCountDict
	itemCollectDict = loadedItemCollectDict

func setTooFar():
	#var allNodes : Array[Node] = tree.get_nodes_in_group("mapCanDisable")
	
	var allNodes = disableNodes.getNext()
	for i : Node3D in allNodes:
		
		if !is_instance_valid(i):
			disableNodes.eraseFromItemFromSection(allNodes,i)
			continue
			
		var canEnable := false
		
		
		if allPlayersPos.is_empty():
			return
		
		for pos : Vector3 in allPlayersPos:
			var diff : Vector3 = i.global_position - pos
			if diff.length() <= i.activationDistance:
				canEnable = true
				break
			
		
		if canEnable:
			if !is_instance_valid(i):
				breakpoint
			
			if i.isEnabled == false:
				i.enable()
				i.isEnabled = true
				
		else:
			if i.isEnabled == true:
				i.disable()
				i.isEnabled = false
			

func setAiTooFar(blockHalf):
	
	var curProcess = blockHalf#aiProcessBlocks.getNext()
	var toRemove = []
	for idx in curProcess.size():
		var npc = curProcess[idx]
		
		if npc == null:
			toRemove.push_front(idx)
			continue
		
		if !is_instance_valid(npc):
			curProcess.eraseFromItemFromSection(npc,curProcess)
			breakpoint
		
		var canEnable = false
		
		for pos : Vector3 in allPlayersPos:
			var diff : Vector3 = npc.global_position - pos
			var len := diff.length()
				
			if diff.length() <= 125:
				canEnable = true
		
		if canEnable:
			if npc.enabled == false:
				npc.enable()
					
		elif npc.enabled == true:
			npc.disable()
				

	
	if toRemove.size() != 0:
		for i in toRemove:
			curProcess.remove_at(i)
				
				

func trackingColTick():
	return
	#if !spawnsReady:
	#	return
	var camera := get_viewport().get_camera_3d()
	
	if camera == null:
		return
	var cameraPos : Vector3 = camera.global_position
	
	var cubBlock =  trackingCollision.getNext()
	for i : StaticBody3D in cubBlock:
		#if (cameraPos - i.global_position).length() > 130:
		if (cameraPos.x - i.global_position.x) > 130 or (cameraPos.y - i.global_position.y) > 130:
			if i.process_mode != Node.PROCESS_MODE_DISABLED:
				i.process_mode = Node.PROCESS_MODE_DISABLED
				for c in i.get_children():
					if c is CollisionShape3D:
						#c.queue_free()
						c.disabled = true
		else:
			if i.process_mode != Node.PROCESS_MODE_INHERIT:
				i.process_mode = Node.PROCESS_MODE_INHERIT
				for c in i.get_children():
					if c is CollisionShape3D:
						#c.queue_free()
						c.disabled = false
			
