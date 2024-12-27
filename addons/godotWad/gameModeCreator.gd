@tool
extends Node
var scaleFactor

func createGameMode(path,meta,curConfig,curGameName):
	

	var a = Time.get_ticks_msec()
	var gameModePath : String = meta["path"]
	var ret = ENTG.generatorInstance(gameModePath,$"../ResourceManager")
	
	var wadL : WAD_Map = ret.get_node("WadLoader")
	wadL.wads = get_parent().wads
	
	if meta.has("loader"):
		var origLoader = meta["loader"]
		for property in origLoader.get_property_list():
			if property.has("usage") and property.usage & PROPERTY_USAGE_EDITOR:
				wadL.set(property["name"],origLoader.get(property["name"]))
	
	if Engine.is_editor_hint():
		for i in wadL.get_children():
			i.get_parent().remove_child(i)
	

	ret.name = ret.name.replace("_template","")
	ret.configName = curConfig
	
	if Engine.is_editor_hint():
		WADG.saveNodeAsScene(ret)

	return ret

func smallClear():
	ENTG.clearEntityCaches(get_tree())
	$"../LumpParser".sectorToRenderables = {}
	$"../LumpParser".wallMatEntries = {}
	$"../LumpParser".sectorToSides = {}
	$"../ResourceManager".materialCache = {}
	$"../ResourceManager".textureCache = {}

func createGameModeResourcesOnDisk(modeName,meta,editorInterface):
	var depends = {}
	
	
	$"../ThingParser".mergeDepends(getSpriteListOfMode(meta["path"]),depends)
	$"../ThingParser".mergeDepends($"../ThingParser".fetchAllEntityDepends("Playerguy"),depends)
	
	
	
	var targetMaps = getUncreatedMaps(meta["destPath"])

	print("target maps:",targetMaps)
	
	var count = 0
	for i in targetMaps:
		$"../ThingParser".mergeDepends($"../ThingParser".getMapDepends(i),depends)
		count += 1
			
	
	$"../ThingParser".fetchResourcesDisk(depends)
	if Engine.is_editor_hint():
		$"../ThingParser".startFileWaitThread(editorInterface)
	


func createGameModeDisk(gName,meta,tree,configName,gameName):
	var mapNames = get_parent().maps.keys()
	var destPath = meta["destPath"]
	
	var reloadWads = true
	var count = 1

	
	
	for i in getUncreatedMaps(destPath):
		var map = get_parent().createMap(i,{},reloadWads)
		map.nextMapTscn = destPath + "/maps/" + WADG.incMap(map.name) + ".tscn"
		
		ProjectSettings.set_setting("memory/limits/message_queue/max_size_mb",64)
		if !WADG.incMap(map.name,true).is_empty():
			map.nextSecretMapTscn = destPath + "/maps/" + WADG.incMap(map.name,true) + ".tscn"
		
		ENTG.saveNodeAsScene(map,destPath + "/maps/")
		map.queue_free()
		get_parent().maps.erase(i)
		reloadWads = false
		if count % 7  == 0:
			smallClear()
			
		count += 1
			
	var modeNode = createGameMode("",meta,configName,gameName)
	modeNode.mapPath = destPath + "/maps/"
	print("dest path:",destPath + "/modes/")
	ENTG.saveNodeAsScene(modeNode,destPath + "/modes/")
	var ret = ResourceLoader.load(destPath + "/modes/"+modeNode.name+".tscn","",0).instantiate()
	ret.filename = destPath + "/modes/"+modeNode.name+".tscn"
	
	ENTG.fetchEntity("Playerguy",get_tree(),gameName,true)
	
	return ret
	


func getUncreatedMaps(destPath):
	destPath += "/maps/"
	
	var mapExisting = ENTG.allInDirectory(destPath,"tscn")

	var targetMaps = []
	
	for i in mapExisting.size():
		mapExisting[i] = mapExisting[i].split(".")[0]
	
	for i in get_parent().maps.keys():
		if !mapExisting.has(i):
			targetMaps.append(i)
	
	return targetMaps
	

func createGameModePreview(path,meta):
	return $"../ResourceManager".fetchDoomGraphic("TITLEPIC")

func getSpriteListOfMode(scenePath):
	var generator = ENTG.getGenerator(scenePath)
	
	var ret = {}
	
	if generator == null:
		return ret
	
	if generator.has_method("getSpriteList"):
		$"../ThingParser".mergeDepends(generator.getSpriteList(),ret)
	
	if "entityDepends" in generator:
		for i in generator.entityDepends:
			$"../ThingParser".mergeDepends(getSpriteListOfMode(i),ret)
			
	return ret

func getGenerator(scenePath):
	var packedScene =  ResourceLoader.load(scenePath,"",0)
	
	if packedScene == null:
		print("could not load scene:",scenePath)
		return
	
	var scene = packedScene.instantiate()
	
	if scene.get_node_or_null("Generator") == null:
		print("scene:", "has no generator")
		return scene
		
	return scene.get_node("Generator")
