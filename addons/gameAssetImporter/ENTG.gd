class_name ENTG
extends Node
signal entityCreated
const consoleShowAction = "showConsole"
const consoleButtonScancode = KEY_Q

static func clearEntityOnDiskCache(game : String, tree : SceneTree) -> void:
	
	game = game.to_lower()
	
	if !tree.has_meta("entitiesOnDisk"):
		return
		
	var eod : Dictionary = tree.get_meta("entitiesOnDisk")
	
	if !eod.has(game) and !game.is_empty():
		print("cannot clear game:",game," as it doesn't exist")
		return
		
	if game.is_empty():
		tree.set_meta("entitiesOnDisk",null)
	
	eod[game] = {}
	return 

static func refreshEntityOnDiskCache(tree) -> void:
	if !tree.has_meta("entitiesOnDisk"):
		return
		
	var eod : Dictionary = tree.get_meta("entitiesOnDisk")
	
	for gameStr in eod.keys():
		
		var newDict = {}
		
		for entityStr in eod[gameStr]:
			if !doesFileExist(eod[gameStr][entityStr][0]):
				continue
				
			newDict[gameStr][entityStr] = eod[gameStr][entityStr]
			
		eod[gameStr] = newDict
	

static func updateEntitiesOnDisk(tree):
	
	
	var t = getAllEntityDirs()
	t = getAllEntitiesForDirs(t)
	tree.set_meta("entitiesOnDisk",t)


static var lastEodCheck = [null,null]#sting the game name and dictionary containing each entity entry for that game.
 
static func fetchEntitiesOnDisk( entity : StringName, tree : SceneTree, game : StringName) -> Node:
	
	var targetGameEntry : Dictionary = {}
	if lastEodCheck != null:
		if lastEodCheck[0] != null:
			if lastEodCheck[0] == game:
				if lastEodCheck[1].is_empty():#we've previously checked the eod dict and the game doesn't exist
					return
				targetGameEntry = lastEodCheck[1]
		
	if targetGameEntry.is_empty():
		if !tree.has_meta("entitiesOnDisk"):
			updateEntitiesOnDisk(tree)
			

		if !tree.has_meta("entitiesOnDisk"):
			return null
		
		var eod : Dictionary= tree.get_meta("entitiesOnDisk")
		
		if eod.is_empty():
			return null
		
		var targetGame : String = game
		
		
		
		if !eod.has(targetGame):
			for i in eod.keys():
				if eod[i].has(entity):
					targetGame = i
					break
					
		
		if targetGame.is_empty():
			return
		
		if !eod.has(targetGame):
			lastEodCheck = [targetGame,{}]
			return
	
		targetGameEntry = eod[targetGame]
	
	
		if game == targetGame:
			lastEodCheck = [targetGame,targetGameEntry]
	
	if !targetGameEntry.has(entity):
		return

	
	var entityEntry : Array = targetGameEntry[entity]
	
	if typeof(entityEntry[0]) != TYPE_STRING:
		return
	
	var scenePath : String=  entityEntry[0]
	
		
	
	if entityEntry[1] == null:
		entityEntry[1] = ResourceLoader.load(scenePath,"",0)

	
	var ent : PackedScene = entityEntry[1]
	
	
	if ent == null:#scene might have missing dependencies
		return null

	
	var inst : Node= ent.instantiate()
	var instDupe : Node =inst.duplicate()
	
	inst.queue_free()
	instDupe.scene_file_path = scenePath
	return instDupe



static func getAllEntityDirs() -> Dictionary:
	
	var ret = {} 
	
	for i in getAllInDirRecursive("res://game_imports/")["res://game_imports/"]:
		if typeof(i) == TYPE_DICTIONARY:
			var gameDir = i.keys()[0]
			var filesForGame = i[gameDir]
			var gameName = gameDir.get_file()
			
			for f in filesForGame:
				if typeof(f) == TYPE_DICTIONARY:
					var fileName = f.keys()[0].get_file()
					if fileName == "entities":
						ret[gameName] = f.keys()[0]
	return ret
	

static func getAllEntitiesForDirs(dict : Dictionary):
	
	
	
	var ret : Dictionary = {}
	
	for game in dict.keys():
		ret[game] = {}
		var all = getAllFlat(dict[game])
		for entFile in all:
			var entStr = entFile.get_file().get_basename()
			ret[game][entStr] = [entFile,null]
			
	return ret





static func fetchResourcesForEntity(entityStrId : String,tree:SceneTree,game : String):
	entityStrId = entityStrId.to_lower()
	game = game.to_lower()
	
	var caches  = fetchEntityCaches(tree,game)
	
	var entityCreator = null
	
	for cache in caches:
		entityCreator = getLoader(tree,cache.name.to_lower())
		
		if entityCreator == null:
			continue
	
	if entityCreator == null:
		return
		
	
	return entityCreator.get
	
	
static func createMapBlank(mapName : String,tree:SceneTree,game : String) -> Node:
	return createMap(mapName ,tree,game ,true)

static func createMap(mapName : String,tree:SceneTree,game : String,blank : bool = false) -> Node:
	
	var caches  = fetchEntityCaches(tree,game)
	
	for cache in caches:
		var t = cache.name.to_lower()
		var creator = getLoader(tree,cache.name.to_lower())
		if creator == null:
			continue
		
		if !is_instance_valid(creator):
			continue
		
		var maps = creator.getMapNames()
		
		for i in maps.size():
			maps[i] = maps[i].to_lower()
		
		if maps.has(mapName):
			if blank:
				return creator.createMapBlank(mapName)
			return creator.createMap(mapName)

		
	return null

static var cachedRequests : Dictionary = {}

static func printMapNames(tree:SceneTree,game : String,blank : bool = false):
	var runningStr := ""
	var caches  = fetchEntityCaches(tree,game)
	
	for cache in caches:
		var t = cache.name.to_lower()
		var creator = getLoader(tree,cache.name.to_lower())
		if creator == null:
			continue
		
		if !is_instance_valid(creator):
			continue
		
		var maps = creator.getMapNames()
		
		for i in maps:
			runningStr += "\n" + i
		
		

	return runningStr


static func fetchEntity(entityStrId : StringName,tree:SceneTree,game : String ,saveToDisk : bool,hideInCache : bool = false,specificCacheParent :  Node = null) -> Node:
	entityStrId = entityStrId.to_lower()
	game = game.to_lower()
	
	
	var isEditor : bool= Engine.is_editor_hint()
	
	var t : Node = fetchEntitiesOnDisk(entityStrId,tree,game)

	if t != null:
		
		if isEditor and !saveToDisk:
			t.set_script(null)
			for i in t.get_children():
				i.set_meta("hidden",true)
				#
		if isEditor and saveToDisk:
			t.set_script(null)
			
			for i in t.get_children():
				i.set_meta("hidden",true)
			#	t.remove_child(i)
		
		t.name = entityStrId
		tree.emit_signal("entityCreated",t)
		return t
	

	
	if saveToDisk and isEditor:
		var ent : Node =  createAndSaveEntityToDisk(tree,entityStrId,game)
		
		return ent
	
	
	var key : StringName = entityStrId + game#hopefully this doesn't cause problems with different trees
	var dupe : Node = null
	
	if cachedRequests.has(key):
		
		if !is_instance_valid(cachedRequests[key]):
			cachedRequests.erase(key)
		else:
			if !isEditor:
				dupe = cachedRequests[key].duplicate(7)
			else:
				dupe = cachedRequests[key].duplicate()
				
			forceResourcesUnique(dupe)#only does something if ent has forceResourcesUnique property 
			tree.emit_signal("entityCreated",dupe)
			return dupe

	
	
	var caches : Array = fetchEntityCaches(tree,game,false,specificCacheParent)#we check for caches related to the current game
	
	
	
	if caches.is_empty():#if no caches found for provided game then get every cache
		caches = fetchEntityCaches(tree,"")
	
	
	
	
	
	for cache : Node in caches:#here we check for cached entities
		for entity : Node in cache.get_children():
			if entity.name == entityStrId:
				if !isEditor:
					dupe = entity.duplicate(7)
				else:
					dupe =  entity.duplicate()
					
				forceResourcesUnique(dupe)#only does something if ent has forceResourcesUnique property 
				cachedRequests[key] = entity
				
				
				if cachedRequests.keys().size() > 20:
					cachedRequests.erase(cachedRequests.keys()[0])
				tree.emit_signal("entityCreated",dupe)
				return dupe
				
	
	for cache : Node in caches:# if no entity exists in caches then we make it
		
		var cacheName : String= cache.name.to_lower()
		var loader : Node= getLoader(tree,cacheName)
		
		
		if loader == null:
			continue
		
		if !is_instance_valid(loader):
			continue
	
	
		var entDict = loader.getEntityDict()
		if loader.getEntityDict().has(entityStrId):
			var entry : Dictionary = loader.getEntityDict()[entityStrId]
			var ent: Node = createEntity(entityStrId,entry,specificCacheParent,loader.getLoader(),loader.getEntityCreator())
			#var ent: Node = loader.createEntity(entityStrId,specificCacheParent)
			
			if ent == null:
				return null
			

			#if entry.has("depends"):
				#
				#var depends = entry["depends"]
				#var dependsMeta = []
				#
				#if ent.has_meta("entityDepends"):
					#addToEntityDepends(ent,depends)
				
			
			setGameAndName(ent,game,entityStrId)
			
			var entityGameName : String = game
			
			if entityGameName.is_empty():
				entityGameName = cacheName
			
			if hideInCache == true:
				ent.set_meta("hidden",true)
			
			if Engine.is_editor_hint():#in this case it will exist in the world and need to be turned on
				ent.set_physics_process(false)
				if ent.get("disabled") != null:
					ent.disabled = true
				
				if !saveToDisk:
					recursiveDestroyFilename(ent)
				else:
					recurisveRemoveNotOfOwner(ent,ent)
			
			
			recursiveVisible(ent,false,"CanvasLayer")
			cache.add_child(ent)
			ent.owner = cache
			
			dupe = ent.duplicate(7)
			forceResourcesUnique(dupe)#only does something if ent has forceResourcesUnique property 

			
			if hideInCache:
				dupe.set_meta("hidden",null)
			tree.emit_signal("entityCreated",dupe)
			return dupe
		else:
			breakpoint

				
	return null


static func fetchTexture(tree:SceneTree,textureName : String,gameName : String):
	gameName = gameName.to_lower()
	
	var entityCreator : Node= getLoader(tree,gameName)
		
	if entityCreator == null:
		return null
		
	if !is_instance_valid(entityCreator):
		return null
		
	if !entityCreator.has_method("createTexture"):
		return
		
	return entityCreator.createTexture(textureName,{})
	

static func getSoundManager(tree : SceneTree):
	
	if Engine.is_editor_hint():
		return
	
	if !tree.has_meta("soundManager"):
		var soundManger = load("res://addons/gameAssetImporter/scenes/soundManager/soundManager.tscn").instantiate()
		tree.get_root().call_deferred("add_child",soundManger)
		tree.set_meta("soundManager",soundManger)
		
		
	return tree.get_meta("soundManager")
		

static func playSound(tree : SceneTree,stream : AudioStream,caller : Node,dict : Dictionary):
	getSoundManager(tree).playSound(stream,caller,dict)

static func createAndSaveEntityToDisk(tree,entityStrId,game) -> Node:
	
	game = game.to_lower()
	
	if !tree.has_meta("entitiesOnDisk"):
		print("eod not found ret")
		return null
	
	
	var entitiesOnDisk = tree.get_meta("entitiesOnDisk")
	if entitiesOnDisk.has(game):
		entitiesOnDisk = entitiesOnDisk[game]
		
		
	var creatorScript = null
		
	if tree.has_meta("loaders"):
		var gameCreatorScripts = tree.get_meta("loaders")
		if !game.is_empty():
			if gameCreatorScripts.has(game):
				creatorScript =  gameCreatorScripts[game]
		else:
			creatorScript =  gameCreatorScripts.values()[0]
				
				
	if creatorScript == null:
		print("creatorScript not found")
		return null
		
		
	
	var entityInfo = creatorScript.getEntityDict()[entityStrId]
	
	#var entry : Dictionary = loader.getEntityDict()[entityStrId]
	var ent: Node = createEntity(entityStrId,entityInfo,null,creatorScript.getLoader(),creatorScript.getEntityCreator())
	
	
	#var ent = creatorScript.createEntity(entityStrId)

	setGameAndName(ent,game,entityStrId)


	var destPath = getEntityDestPath(entityInfo,game)
	
	var splits = destPath.replace("res://","").split("/")
	var running = "res:/"
	
	var dir = DirAccess.open("res://")
	
	for i in splits:
		if i.find(".tscn") != -1:
			break
		running += "/" + i

		createDirIfNotExist(running,dir)

	#ent.filename = destPath
	ent.scene_file_path = destPath
	
	
	for i in ent.get_children():#this might be bad
		i.owner = ent
		#ent.remove_child(i)
		#i.queue_free()
	
	
	var p = PackedScene.new()
	p.pack(ent)
	ResourceSaver.save(p,destPath)
	

	
	var eod = tree.get_meta("entitiesOnDisk")
		
		
	if !eod.has(game):
		if game.is_empty():
			print("trying to fetch entity:",entityStrId," on disk with empty gameName:",game)
		else:
			print("trying to fetch entity:",entityStrId," on disk with empty gameName:",game)
				
			
	eod[game][entityStrId] = [destPath,ResourceLoader.load(destPath,"",0)]
	
	var inst = eod[game][entityStrId][1].instantiate()
	var ret = inst.duplicate()
	inst.queue_free()
	#ret.filename = destPath
	ret.scene_file_path = destPath
	
	
	for i in ret.get_children():
		i.owner = null#testing
		#ret.remove_child(i)
		#i.queue_free()
	


	return ret
		
		
		
		
static func getAllInDirRecursive(path,filter=null):
	var all = allInDirectory(path,filter)
	var ret = {}
	ret[path] = []
	
	for i in all:
		if i.find(".") != -1:
			ret[path].append(path+"/"+i)
		else:
			ret[path].append(getAllInDirRecursive(path+"/"+i,filter))
	
	
	return ret
	

static func getDirFromDic(input,target : String):
	if typeof(input) == TYPE_DICTIONARY:
		
		for i in input.keys():
			var f = i.get_file()
			if f == target:
				return i

		for i in input.values():
			var got = getDirFromDic(i,target)
			if got !=null:
				return got
			
			
	
	if typeof(input) == TYPE_ARRAY:
		for i in input:
			var got = getDirFromDic(i,target)
			if got != null:
				return got
			
	return null
	
static func getAllFlat(path):
	var ret = []
	var all = allInDirectory(path)
	
	for i in all:
		if i.find(".") == -1:
			ret += getAllFlat(path + "/" + i)
		
		else:
			ret.append(path + "/" + i)
			
	return ret
	
	
static func fetchEntityCaches(tree : SceneTree, game : StringName = "",singleReturn = false,specificCacheParent = null):
	var ret :Array[Node]= []
	game = game.to_lower()
	
	for i in tree.get_nodes_in_group("entityCache"):
		if i.name == game or game.is_empty():
			if specificCacheParent != null:
				if i.get_parent() != specificCacheParent:
					continue
			if singleReturn:
				return i
			else:
				ret.append(i)
			
	if tree.has_meta("entityCacheOrphans"):
		for i in tree.get_meta("entityCacheOrphans"):
			if i.name == game or game.is_empty():
				if specificCacheParent != null:
					if i.get_parent() != specificCacheParent:
						continue
				if singleReturn:
					return i
				else:
					ret.append(i)
			
	return ret

static func getEntityDestPath(ent : Dictionary,game):
	var dPath = ("res://game_imports/"+game+"/entities/"+ent["name"]+".tscn").to_lower()

	if ent.has("category"):
		dPath = ("res://game_imports/"+game+"/entities/"+ent["category"]+"/"+ent["name"]+".tscn").to_lower()

	return dPath
	

static func clearEntityCaches(tree):
	for cache in fetchEntityCaches(tree):
		for child in cache.get_children():
			child.queue_free()
			
	
	clearEntityOnDiskCache("",tree)
	
	var toErase = []
	
	for i in cachedRequests:
		if cachedRequests[i] == null:
			toErase.append(cachedRequests[i])
		if !is_instance_valid(cachedRequests[i]):
			toErase.append(cachedRequests[i])
			
	for i in toErase:
		cachedRequests.erase(i)

static func saveNodeAsScene(node,path = "res://dbg/"):
	
	recursiveOwn(node,node)
	var packedScene = PackedScene.new()
	packedScene.pack(node)
	
	if path.find(".tscn") != -1:
		ResourceSaver.save(packedScene,path)
	else:
		ResourceSaver.save(packedScene,path+node.name+".tscn")

static func recursiveVisible(node,value,classFilter=""):
	
	if "visible" in node:
		if !classFilter.is_empty():
			if node.get_class() == classFilter:
				node.visible = value
			else:
				pass
				#node.visible = value
		else:
			node.visible = value
		
	for i in node.get_children():
		recursiveVisible(i,value,classFilter)
		
static func recursiveDestroyFilename(node):

	#node.filename = ""
	node.scene_file_path = ""
	for i in node.get_children():
		if i.has_meta("keepPath"):
			continue
		recursiveDestroyFilename(i)
		
static func allInDirectory(path,filter=null):
	var files = []
	var dir = DirAccess.open(path)
	
	if dir == null:
		return []
		
	dir.list_dir_begin()  # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547# TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			
			if file.find(".") == -1:
				files.append(file)
			else:
				if filter != null:
					var ext = file.split(".")
					if ext[ext.size()-1].find(filter)!= -1:
						files.append(file)
				else:
					files.append(file)

	dir.list_dir_end()

	return files
	
static func recursiveOwn(node,newOwner):
	
	for i in node.get_children():
		recursiveOwn(i,newOwner)
	
	
	if node != newOwner:#you get error if you set something as owning itself
		node.owner = newOwner



static func spawnMany(tree : SceneTree,entityStr : String,pos,rot,game : String="",entityParentNode : Node = null,toDisk : bool = false,hideInCache =false) -> Node:
	return null


static func spawn(tree : SceneTree,entityStr : String,pos,rot,game : String="",entityParentNode : Node = null,toDisk : bool = false,hideInCache =false,specifcCache : Node = null) -> Node:
	
	entityStr = entityStr.to_lower()
	game = game.to_lower()
	
	var entity : Node = fetchEntity(entityStr,tree,game,toDisk,hideInCache,specifcCache)
	if entity == null:
		return null
	
	
	if entity.is_in_group("player"):
		recursiveVisible(entity,true,"CanvasLayer")
		
	if typeof(entity.position) == TYPE_VECTOR2:
		if typeof(pos) == TYPE_VECTOR3:
			pos = Vector2(pos.x,pos.y)
	

	if entityParentNode == null:
		entityParentNode = tree.get_root()

	if !Engine.is_editor_hint():
		entityParentNode.call_deferred("add_child",entity)

	else:
		entityParentNode.add_child(entity)
	
	
	var creatorScript : Node = getLoader(tree,game)
			
	if creatorScript != null:
		if creatorScript.has_method("setEntityPos"):
			creatorScript.setEntityPos(entity,pos,rot,entityParentNode)
		else:
			
			entity.position = pos
	else:
		entity.position = pos
		if "rotationDegrees" in entity:
			entity.rotation_degrees = rot
	
	entity.visible = true
	entity.set_meta("hidden",null)
	
	
	return entity


static func recurisveRemoveNotOfOwner(node,targetOwner):
	
	var nom = node.name
	var nowner = node.owner
	
	var x = nowner
	
	if x != null:
		x = nowner.name
	
	
	
	if node.owner != targetOwner and node != targetOwner and node.owner != null:
		node.get_parent().remove_child(node)
		node.queue_free()
	
	for i in node.get_children():
		recurisveRemoveNotOfOwner(i,targetOwner)

static func getEntityDict(tree, gameName) -> Dictionary:
	gameName = gameName.to_lower()
	var loader = getLoader(tree,gameName)
	
	if loader != null:
		return loader.getEntityDict()
	
	return {}

static func getEntitiesCategorized(tree, gameName) -> Dictionary:
	var ents : Dictionary = getEntityDict(tree,gameName)
	var ret = {"misc":[]}
	
	for i : String in ents:
		if ents[i].has("category"):
			var cat = ents[i]["category"]
			
			if !ret.has(cat):
				ret[cat] = []
				
			ret[cat].append(i)
		else:
			ret["misc"].append(i)
			
	return ret
	
static func getLoader(tree : SceneTree, gameName : StringName) -> Node:
	
	if !tree.has_meta("loaders"):
		return null
		
	if !tree.get_meta("loaders").has(gameName):
		return null
	
	var creatorScript = tree.get_meta("loaders")[gameName]
	
	
	return creatorScript

static func fetchRuntimeEntityCacheNode(cacheParentNode : Node,creatorScript : Node,tree,gameName):
	
	gameName = gameName.to_lower()

	for i in tree.get_nodes_in_group("entityCache"):
		if i.name == gameName:
			if i.get_parent() == cacheParentNode:
				return i
	
	if cacheParentNode != null:
		for i in cacheParentNode.get_children():
			if i.name == gameName:
				return i
	
	var eCache : SubViewport = SubViewport.new()
	eCache.world_3d = World3D.new()
	eCache.name = gameName
	eCache.add_to_group("entityCache",true)

	
	#eCache.script = load("res://Cache.gd")
	cacheParentNode.add_child(eCache)
		
	return eCache


static func fetchRuntimeOrphanEntityCacheNode(tree : SceneTree,gameName : String):
	gameName = gameName.to_lower()
	
	
	if !tree.has_meta("entityCacheOrphans"):
		tree.set_meta("entityCacheOrphans",[])
		
		
	
	var cacheArr =  tree.get_meta("entityCacheOrphans")
	
	var cache = null
	
	for i in cacheArr:
		if i.name == gameName:
			return i#return existing
			
	if cache == null:#here we create a new entity cache
		var eCache = Node3D.new()
		eCache.name = gameName
		
		tree.get_meta("entityCacheOrphans").append(eCache)
		
		return eCache

static func createEntityCacheForGame(tree : SceneTree, toDisk : bool, gameName : String, loader : Node, toBeParentNode = null):
	gameName = gameName.to_lower()
	
	if toBeParentNode == null:#test
		toBeParentNode = tree.get_root()
	
	if !tree.has_meta("loaders"):#if creator script dict isn't initialized, init
		tree.set_meta("loaders",{})
		
	tree.get_meta("loaders")[gameName] = loader#we set the script for the game
	
	if Engine.is_editor_hint(): 
		if toDisk:#if we're to disk then no cache is created
			pass
			
		else:#we create a node as cache
			var cache = fetchRuntimeEntityCacheNode(toBeParentNode,loader,tree,gameName)#self will be referenced when creating entities in editor but no runtime.
			return cache
		
		
	else:#orphan node is created for cache
		return fetchRuntimeOrphanEntityCacheNode(tree,gameName)


static func removeEntityCacheForGame(tree : SceneTree, gameName : String):
	gameName = gameName.to_lower()
	if !tree.has_meta("loaders"):
		if tree.get_meta("loaders").has(gameName):
			tree.get_meta("loaders")[gameName].queue_free()
			tree.get_meta("loaders")[gameName] = null
			
	for i in tree.get_nodes_in_group("entityCache"):
		if i.name == gameName:
			i.queue_free()
			
	
	if tree.has_meta("entityCacheOrphans"):
		for i : Node in tree.get_meta("entityCacheOrphans"):
			if i.name == gameName:
				i.queue_free()
			
			tree.get_meta("entityCacheOrphans").erase(i)
			
	
static func doesFileExist(path : String) -> bool:
	#var f : File = File.new()
	var ret = FileAccess.file_exists(path)
	#f.close()
	return ret
	

static func createDirIfNotExist(path,dir):
	if !dir.dir_exists(path):
		dir.make_dir(path)
		

static func doesDirExist(dirPath) -> bool:
	return DirAccess.dir_exists_absolute(dirPath)




static func getDirsInDir(dirPath):
	var dir = DirAccess.open(dirPath)#
	var ret = []
	
	#if dir.open(dirPath) == OK:
	if dir!= null:
		dir.list_dir_begin()  # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547# TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var file_name = dir.get_next()
		
		while (file_name != ""):
			if file_name.find(".") == -1:
				ret.append(file_name)
			
			file_name = dir.get_next()


	return ret
	
static func getGenerator(scenePath) -> Array[Node]:
	var packedScene : PackedScene =  ResourceLoader.load(scenePath,"",0)
	
	if packedScene == null:
		print("could not load scene:",scenePath)
		return [null,null]
	
	var scene : Node = packedScene.instantiate()
	
	if scene.get_node_or_null("Generator") == null:
		return [null,scene]
	
	
	
	
	return [scene.get_node("Generator"),scene]
	
static func addToEntityDepends(entity,depends):
	var dependsMeta = []
				
	if entity.has_meta("entityDepends"):
		dependsMeta = entity.get_meta("entityDepends")
				
	if typeof(depends) == TYPE_ARRAY:
		dependsMeta += depends
	else:
		dependsMeta.append(depends)
				
	entity.set_meta("entityDepends",dependsMeta)
	


static func createEntity(entityName,entityEntry,specificCacheParent,resourceManager : Node,entityLoader : Node = null):
	var hidden = false
	var ent = null
	var parent = entityLoader.get_parent()
	
	#if entityLoader.npcsDisabled:
	#	if entityEntry.has("category"):
	#		if entityEntry["category"] == &"npcs":
	#			return null
	
	if entityEntry.has("depends"):
		
		var deps = entityEntry["depends"]
		
		if typeof(deps) != TYPE_ARRAY:
			deps = [deps]
		for i in deps:
			var cache = ENTG.fetchEntity(i,entityLoader.get_tree(),entityLoader.get_parent().gameName,entityLoader.get_parent().toDisk,false,specificCacheParent)
			
			if cache != null:
				cache.queue_free()
				

	if entityEntry.has("func"):
		if !entityEntry["func"].is_empty():
			var function = entityEntry["func"]

			if function!= "":
				ent = entityLoader.createFromCode(entityEntry,function)
				if ent == null:
					breakpoint
			

	elif entityEntry.has("sourceScene"):
		
		var postCreationFunction = null
		
		if entityEntry.has("postCreationFunction"):
			var funcToBind = Callable(entityLoader, entityEntry["postCreationFunction"])
			postCreationFunction = funcToBind.bind(entityEntry)
		
		
		if !entityEntry["sourceScene"].is_empty():
			
			ent = ENTG.generatorInstance(entityEntry["sourceScene"],resourceManager,entityLoader,parent.scaleFactor,postCreationFunction,specificCacheParent)
			if ent == null:
				breakpoint
	else:
		return
			
	ent.name = entityName

	
	if entityEntry.has("depends"):
		ENTG.addToEntityDepends(ent,entityEntry["depends"])

	return ent


static func generatorInstance(scenePath : String,resourceManager : Node,entityLoader : Node = null,scale : Vector3 = Vector3.ONE,postCreationFunction = null,specificCacheParent = null):
	

	var ret : Array[Node] = getGenerator(scenePath)
	
	var generator : Node = ret[0]
	var scene: Node = ret[1]
	
	if generator != null:

		generator.loader = resourceManager
		
		if "entityLoader" in generator:
			generator.entityLoader = entityLoader
		
		if "scaleFactor" in generator:
			generator.scaleFactor = scale
		
		if "cacheParent" in generator:
			generator.cacheParent = specificCacheParent
		
		generator.initialize()
		
		if "entityDepends" in generator:
			for entityStr : StringName in generator.entityDepends:
				ENTG.addToEntityDepends(scene,entityStr)
			
		if "dependantChildren" in generator:
			for i in generator.dependantChildren:
				if i.is_empty():
					continue
				
				var dependantInstanced = generatorInstance(i,resourceManager)
				dependantInstanced.set_meta("entityDepends",true)
				ENTG.addToEntityDepends(scene,i)
				scene.add_child(dependantInstanced)
				
		
		
		if postCreationFunction != null:
			postCreationFunction.call()
			
		
		if generator.get_parent() == null:
			breakpoint
		
		scene.remove_child(generator)
		generator.queue_free()
		
	
	if postCreationFunction != null:
		postCreationFunction.call(scene)
		
	
	return scene


static func createMidiPlayer(soundFontPath : String= "", loop :bool = true):
	
	var player : Node = load("res://addons/midi/MidiPlayer.tscn").instantiate()
	
	player.process_mode = Node.PROCESS_MODE_ALWAYS

	player.soundfont = soundFontPath
	player.loop = loop
	return player

static var pData


static func setMidiPlayerData(midiPlayer,midiData :PackedByteArray) -> void:
	

	if midiData.is_empty():
		print("empty arrray passed to midi player")
		return
	
	if !FileAccess.file_exists("res://addons/midi/SMF.gd"):
		if !FileAccess.file_exists("res://addons/midi/SMF.gdc"):
			print("midi player missing skipping...")
			return 
	

	if pData == midiData:
		midiPlayer.play(0)
		return
	pData = midiData
	
	var smfReader = load("res://addons/midi/SMF.gd").new()

	var result = smfReader.read_data(midiData)

	midiPlayer.smf_data = result.data


static func fetchMidiPlayer(tree : SceneTree):
	
	if !tree.has_meta("midiPlayer"):
		var midiPlayer = createMidiPlayer(SETTINGS.getSetting(tree,"soundFont"))
		tree.set_meta("midiPlayer",midiPlayer)
		tree.get_root().call_deferred("add_child",midiPlayer)
	
	return tree.get_meta("midiPlayer")


static func setGameAndName(node : Node,gameStr : String , entityStr : String) -> void:
	if "entityName" in node:
		node.entityName = entityStr
			
	if "gameName" in node:
		node.gameName = gameStr


static func showObjectInspector(node : Node,showInternal = false) -> Window:
	var inspector : Window = load("res://addons/gameAssetImporter/scenes/objectInspectorUI/objectInspectorUI.tscn").instantiate()
	
	
	if !node.is_inside_tree():
		await node.ready
	inspector.showInternal = showInternal
	inspector.set_object(node)
	
	
	node.get_tree().get_root().add_child(inspector)
	
	if inspector.isNewWindow:
		inspector.visible = true
		inspector.size.y *= 0.5
	else:
		inspector.popup_centered_ratio()
	
	return inspector

static func showObjectInspectorAsWindow(node : Node,showInternal = false) -> Window:
	if !node.is_inside_tree():
		await node.ready
	node.get_tree().get_root().get_viewport().gui_embed_subwindows = false
	return await showObjectInspector(node,showInternal)

static func createFontImage(characters : Dictionary) -> Image:
	var totalW : int = 0
	var totalY : int = 0
	var maxY : int = 0
	var fontImages : Array[Image] = []
		
	for texture : Texture in characters.values():
		
		if texture == null:
			continue
		
		totalW += texture.get_width()
		if texture.get_height() > maxY:
			maxY = texture.get_height()
			

	var img : Image = Image.create(totalW,maxY,false,Image.FORMAT_RGBA8)
	var runningWdith : int = 0
		
	for texture : Texture in characters.values():
		
		if texture == null:
			continue
		
		img.blit_rect(texture.get_image(),Rect2(0,0,texture.get_width(),texture.get_height()),Vector2(runningWdith,0))
		runningWdith += texture.get_width()
	
	
	img.save_png("res://dbg/test.png")
	return img

static func forceResourcesUnique(node : Node):
	if "forceResourcesUnique" in node:
		if node.forceResourcesUnique == true:
			return recursiveSubResourceDuplicate(node)
	elif node.has_meta("forceResourcesUnique"):
		return recursiveSubResourceDuplicate(node)
			
	return

static func recursiveSubResourceDuplicate(node : Node):
	
	for i in node.get_property_list():
		if i["hint"] == 17:
				var property = node.get(i.name)
				if property != null:
					
					var c = property.get_class()
					
					if c == "SphereShape3D" or c == "BoxShape3D" or c == "CylinderShape3D" or c == "CapsuleShape3D":
						node.set(i.name, property.duplicate(7))

	for i in node.get_children():
		recursiveSubResourceDuplicate(i)



static func createAndInitializeLoader(tree :SceneTree,configName : String,param : Array):
	var loaders = getLoaders()
	
	for i in loaders:
		var inst = load(i).instantiate()
		for gameName in inst.getConfigs():
			if gameName == configName:
				tree.get_root().call_deferred("add_child",inst)
				await(inst.ready)
				
				inst.initialize(param,configName,configName)
				createEntityCacheForGame(tree,false,configName,inst,tree)
				
				#tree.get_root().add_child(inst)
				return inst
	

static func initializeLader(tree,loader : Node,param,configName,gameName):
	loader.initialize(param,configName,configName)
	createEntityCacheForGame(tree,false,configName,loader,tree)
	if !loader.is_inside_tree():
		tree.get_root().call_deferred("add_child",loader)
	await(loader.ready)
	
	

static func getLoaders() -> Array[String]:
	
	var loadersPaths : Array[String] = []
	
	if !ENTG.doesDirExist("res://addons"):
		return loadersPaths
	
	for i in ENTG.getDirsInDir("res://addons"):
		
		var ret : Array[String] = []
		var dir = DirAccess.open("res://addons/"+i)
	
		var files = dir.get_files()
	
		for filePath : String in files:
			if filePath.find("_Loader") != -1:
				loadersPaths.append("res://addons/"+ i +"/" +filePath)
		
	return loadersPaths
