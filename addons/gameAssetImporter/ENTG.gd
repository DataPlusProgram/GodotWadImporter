class_name ENTG
extends Node


static func clearEntityOnDiskCache(game : String, tree : SceneTree) -> void:
	
	game = game.to_lower()
	
	if !tree.has_meta("entitiesOnDisk"):
		return
		
	var eod : Dictionary = tree.get_meta("entitiesOnDisk")
	
	if !eod.has(game) and !game.empty():
		print("cannot clear game:",game," as it doesn't exist")
		return
		
	if game.empty():
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

static func fetchEntitiesOnDisk( entity : String, tree : SceneTree, game : String):
	game = game.to_lower()
	
	if !tree.has_meta("entitiesOnDisk"):
		updateEntitiesOnDisk(tree)
		

	if !tree.has_meta("entitiesOnDisk"):
		return null
	
	var eod = tree.get_meta("entitiesOnDisk")
	
	if eod.empty():
		return null
	
	var targetGame = game
	
	
	if !eod.has(targetGame):
		for i in eod.keys():
			if eod[i].has(entity):
				targetGame = i
				break
				
	
	if targetGame.empty():
		return
	
	if !eod.has(targetGame):
		return
	
	if !eod[targetGame].has(entity):
		return
	
	
	var entry = eod[targetGame][entity]
	
	if typeof(entry[0]) != TYPE_STRING:
		return
	
	var scenePath =  entry[0]
	
		
	
	if entry[1] == null:
		entry[1] = ResourceLoader.load(scenePath,"",true)

	
	var ent = entry[1]
	
	
	if ent == null:#scene might have missing dependencies
		return null

	
	var inst = ent.instance()
	
	var instDupe =inst.duplicate()
	
	inst.queue_free()
	instDupe.filename = scenePath
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
	

static func getAllEntitiesForDirs(var dict : Dictionary):
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
		entityCreator = getCreatorScript(tree,cache.name.to_lower())
		
		if entityCreator == null:
			continue
	
	if entityCreator == null:
		return
		
	
	return entityCreator.get
	


static func fetchEntity(entityStrId : String,tree:SceneTree,game : String ,saveToDisk : bool) -> Node:
	entityStrId = entityStrId.to_lower()
	game = game.to_lower()
	
	var t : Node = fetchEntitiesOnDisk(entityStrId,tree,game)

	
	if t != null:
		
		if Engine.editor_hint and !saveToDisk:
			t.set_script(null)
			for i in t.get_children():
				i.set_meta("hidden",true)
				#
		if Engine.editor_hint and saveToDisk:
			t.set_script(null)
			
			for i in t.get_children():
				i.set_meta("hidden",true)
			#	t.remove_child(i)
				
		return t
	
	if saveToDisk and Engine.editor_hint:
		return createAndSaveEntityToDisk(tree,entityStrId,game)

	var caches  = fetchEntityCaches(tree,game)
	
	if caches.empty():
		caches = fetchEntityCaches(tree,"")
	
	var dupe = null
	
	
	
	for cache in caches:
		for entity in cache.get_children():
			if entity.name == entityStrId:
				if !Engine.editor_hint:
					dupe = entity.duplicate(7)
					return dupe
				else:
					dupe =  entity.duplicate()
					return dupe
	
	
	if dupe != null:
		return dupe
	
	for cache in caches:
		var entityCreator = getCreatorScript(tree,cache.name.to_lower())
		if entityCreator == null:
			continue
		
		if !is_instance_valid(entityCreator):
			continue
		
		if entityCreator.hasEntity(entityStrId):
			var ent = entityCreator.createEntity(entityStrId)
			
			if ent == null:
				return null
			
			if Engine.editor_hint:#in this case it will exist in the world and need to be turned on
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
			
			return dupe

				
	return null

static func createAndSaveEntityToDisk(tree,entityStrId,game) -> Node:
	game = game.to_lower()
	
	if !tree.has_meta("entitiesOnDisk"):
		print("eod not found ret")
		return null
	
	
	var entitiesOnDisk = tree.get_meta("entitiesOnDisk")
	if entitiesOnDisk.has(game):
		entitiesOnDisk = entitiesOnDisk[game]
		
		
	var creatorScript = null
		
	if tree.has_meta("creatorScripts"):
		var gameCreatorScripts = tree.get_meta("creatorScripts")
		if !game.empty():
			if gameCreatorScripts.has(game):
				creatorScript =  gameCreatorScripts[game]
		else:
			creatorScript =  gameCreatorScripts.values()[0]
				
				
	if creatorScript == null:
		print("creatorScript not found")
		return null
		
		
	
	var entityInfo = creatorScript.getEntityInfo(entityStrId)
	var ent = creatorScript.createEntity(entityStrId)

	
	var destPath = getEntityDestPath(entityInfo,game)
	
	var splits = destPath.replace("res://","").split("/")
	var running = "res:/"
	
	var dir = Directory.new()
	dir.open("res://")
	
	for i in splits:
		if i.find(".tscn") != -1:
			break
		running += "/" + i

		createDirIfNotExist(running,dir)

	ent.filename = destPath
	
	
	
	
	for i in ent.get_children():#this might be bad
		i.owner = ent
		#ent.remove_child(i)
		#i.queue_free()
	
	var p = PackedScene.new()
	p.pack(ent)
	ResourceSaver.save(destPath,p)
	

	
	var eod = tree.get_meta("entitiesOnDisk")
		
		
	if !eod.has(game):
		if game.empty():
			print("trying to fetch entity:",entityStrId," on disk with empty gameName:",game)
		else:
			print("trying to fetch entity:",entityStrId," on disk with empty gameName:",game)
				
			
		
	eod[game][entityStrId] = [destPath,ResourceLoader.load(destPath,"",true)]
	
	var inst = eod[game][entityStrId][1].instance()
	var ret = inst.duplicate()
	inst.queue_free()
	ret.filename = destPath
	
	
	for i in ret.get_children():
		i.owner = null#the testing
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
	
	
static func fetchEntityCaches(tree : SceneTree, game : String = "",singleReturn : bool = false):
	var ret = []
	game = game.to_lower()
	
	for i in tree.get_nodes_in_group("entityCache"):
		if i.name == game or game.empty():
			if singleReturn:
				return i
			else:
				ret.append(i)
			
	if tree.has_meta("entityCacheOrphans"):
		for i in tree.get_meta("entityCacheOrphans"):
			if i.name == game or game.empty():
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

static func saveNodeAsScene(node,path = "res://dbg/"):
	
	recursiveOwn(node,node)
	var packedScene = PackedScene.new()
	packedScene.pack(node)
	
	if path.find(".tscn") != -1:
		ResourceSaver.save(path,packedScene)
	else:
		ResourceSaver.save(path+node.name+".tscn",packedScene)

static func recursiveVisible(node,value,classFilter=""):
	
	if "visible" in node:
		if !classFilter.empty():
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

	node.filename = ""

	for i in node.get_children():
		recursiveDestroyFilename(i)
		
static func allInDirectory(path,filter=null):
	var files = []
	var dir = Directory.new()
	var res = dir.open(path)
	
	if res != 0:
		return []
		
	dir.list_dir_begin()

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


		
static func spawn(tree : SceneTree,entityStr : String,pos: Vector3,rot : Vector3,game : String="",entityParentNode : Node = null,toDisk : bool = false):
	entityStr = entityStr.to_lower()
	
	var entity : Node = fetchEntity(entityStr,tree,game,toDisk)
	
	if entity == null:
		return null
	
	if entity.is_in_group("player"):
		recursiveVisible(entity,true,"CanvasLayer")
		
	

	if entityParentNode == null:
		entityParentNode = tree.get_root()

	if !Engine.editor_hint:
		entityParentNode.call_deferred("add_child",entity)

	else:
		entityParentNode.add_child(entity)
	
	
	var creatorScript = getCreatorScript(tree,game)
			
	if creatorScript != null:
		if creatorScript.has_method("setEntityPos"):
			creatorScript.setEntityPos(entity,pos,rot,entityParentNode)
		else:
			entity.translation = pos
	else:
		entity.translation = pos
		entity.rotation_degrees = rot
	
	entity.visible = true
	return entity


static func setEntityCreatorScriptForGame(tree : SceneTree,game : String, script : Node) -> void :

	if !tree.has_meta("creatorScripts"):#if creator script dict isn't initialized, init
		tree.set_meta("creatorScripts",{})
		
	tree.get_meta("creatorScripts")[game] = script#we set the script for the game
	
	return
	


#static func addGameEntityCacheDisk(tree :SceneTree,game : String,builder : Node):
#
#	if !tree.has_meta("gameEntityCreatorScript"):
#		tree.set_meta("gameEntityCreatorScript",{})
#
#	tree.get_meta("gameEntityCreatorScript")[game] = builder

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

static func getEntityDict(var tree,var gameName):
	gameName = gameName.to_lower()
	var gameCreatorScript = getCreatorScript(tree,gameName)
	
	if gameCreatorScript != null:
		return gameCreatorScript["thingDirectory"]
	
	return null

static func getEntitiesCategorized(var tree,var gameName ):
	var ents = getEntityDict(tree,gameName)
	var ret = {"misc":[]}
	for i in ents:
		if ents[i].has("category"):
			var cat = ents[i]["category"]
			
			if !ret.has(cat):
				ret[cat] = []
				
			ret[cat].append(i)
		else:
			ret["misc"].append(i)
			
	return ret
	
static func getCreatorScript(var tree,var gameName):
	if !tree.has_meta("creatorScripts"):
		return null
		
	if !tree.get_meta("creatorScripts").has(gameName.to_lower()):
		return null
	
	var creatorScript = tree.get_meta("creatorScripts")[gameName.to_lower()]
	
	return creatorScript

static func fetchRuntimeEntityCacheNode(cacheParentNode,creatorScript,tree,gameName):
	gameName = gameName.to_lower()

	for i in tree.get_nodes_in_group("entityCache"):
		if i.name == gameName:
			return i
	
	if cacheParentNode != null:
		for i in cacheParentNode.get_children():
			if i.name == gameName:
				return i
	
	var eCache : Viewport = Viewport.new()
	eCache.world = World.new()
	eCache.name = gameName
	eCache.add_to_group("entityCache",true)
	eCache.set_meta("entityCreator",creatorScript)
	
	#eCache.script = load("res://Cache.gd")
	cacheParentNode.add_child(eCache)
		
	return eCache


static func createCache(gameName,creatorScript):
	var eCache : Viewport = Viewport.new()
	eCache.world = World.new()
	eCache.name = gameName
	eCache.add_to_group("entityCache",true)
	eCache.set_meta("entityCreator",creatorScript)
	
	return eCache

static func fetchRuntimeOrphanEntityCacheNode(tree : SceneTree,gameName : String):
	gameName = gameName.to_lower()
	
	
	if !tree.has_meta("entityCacheOrphans"):
		tree.set_meta("entityCacheOrphans",[])
		
		
	
	var cacheArr =  tree.get_meta("entityCacheOrphans")
	
	var cache = null
	
	for i in cacheArr:
		if i.name == gameName:
			return i
			
			
	if cache == null:#here we create a new entity cache
		var eCache = Spatial.new()
		eCache.name = gameName
		
		tree.get_meta("entityCacheOrphans").append(eCache)
		#tree.get_root().call_deferred("add_child",eCache)
		print("orphan game cache:",eCache, " added")
		
		return eCache

static func createEntityCacheForGame(var tree,var toDisk,var gameName,var creatorNode,var toBeParentNode = null):
	gameName = gameName.to_lower()
	
	if toBeParentNode == null:#test
		toBeParentNode = tree.get_root()
	
	setEntityCreatorScriptForGame(tree,gameName,creatorNode)
	
	if Engine.editor_hint: 
		if toDisk:#if we're to disk then no cache is created
			pass
			
		else:#we create a node as cache
			var cache = fetchRuntimeEntityCacheNode(toBeParentNode,creatorNode,tree,gameName)#self will be referenced when creating entities in editor but no runtime.
			return cache
		
		
	else:#orphan node is created for cache
		return fetchRuntimeOrphanEntityCacheNode(tree,gameName)


static func doesFileExist(path : String) -> bool:
	var f : File = File.new()
	var ret = f.file_exists(path)
	f.close()
	return ret
	

static func createDirIfNotExist(path,dir):
	if !dir.dir_exists(path):
		dir.make_dir(path)
		

static func doesDirExist(dirPath):
	var d = Directory.new();
	return d.dir_exists(dirPath)



static func getDirsInDir(dirPath):
	var dir = Directory.new()
	var ret = []
	
	if dir.open(dirPath) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while (file_name != ""):
			if file_name.find(".") == -1:
				ret.append(file_name)
			
			file_name = dir.get_next()


	return ret
	
static func getGenerator(scenePath):
	var packedScene =  ResourceLoader.load(scenePath,"",true)
	
	if packedScene == null:
		print("could not load scene:",scenePath)
		return
	
	var scene = packedScene.instance()
	
	if scene.get_node_or_null("Generator") == null:
		print("scene:", "has no generator")
		return
	
	
	
	
	return scene.get_node("Generator")

static func generatorInstance(scenePath,loader):
	
	var generator = getGenerator(scenePath)
	var scene = generator.get_parent()
	
	generator.loader = loader
	generator.initialize()
		
		
	if "dependantChildren" in generator:
		for i in generator.dependantChildren:
			scene.add_child(generatorInstance(i,loader))
	
	scene.remove_child(generator)
	generator.queue_free()
	return scene
