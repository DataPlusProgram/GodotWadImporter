tool
extends Node
var scaleFactor

func createGameMode(path,meta):
	var thePath = meta["path"]
	var ret = ENTG.generatorInstance(thePath,$"../ResourceManager")
	var wadL = ret.get_node("WadLoader")
	var w = get_parent().wads
	wadL.wads = get_parent().wads
	
	if Engine.editor_hint:
		for i in wadL.get_children():
			i.get_parent().remove_child(i)
	
	var maps = get_parent().maps

	if maps.has("E1M1"):
		ret.firstMap = "E1M1"
	ret.name = ret.name.replace("_template","")
	
	
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
	$"../ThingParser".mergeDepends($"../ThingParser".fetchAllDepends("Playerguy"),depends)
	
	
	
	var targetMaps = getUncreatedMaps(meta["destPath"])

	print("target maps:",targetMaps)
	
	var count = 0
	for i in targetMaps:
		print(i)
		$"../ThingParser".mergeDepends($"../ThingParser".getMapDepends(i),depends)
		count += 1
			
	
	$"../ThingParser".fetchResourcesDisk(depends)
	if Engine.editor_hint:
		$"../ThingParser".startFileWaitThread(editorInterface)
	


func createGameModeDisk(gName,meta,tree,gameName):
	var mapNames = get_parent().maps.keys()
	var destPath = meta["destPath"]
	
	var reloadWads = true
	var count = 1

	
	
	for i in getUncreatedMaps(destPath):
		var map = get_parent().createMap(i,{},reloadWads)
		map.nextMapTscn = destPath + "/maps/" + WADG.incMap(map.name) + ".tscn"
		
		ProjectSettings.set_setting("memory/limits/message_queue/max_size_mb",64)
		if !WADG.incMap(map.name,true).empty():
			map.nextSecretMapTscn = destPath + "/maps/" + WADG.incMap(map.name,true) + ".tscn"
		
		ENTG.saveNodeAsScene(map,destPath + "/maps/")
		map.queue_free()
		get_parent().maps.erase(i)
		reloadWads = false
		if count % 7  == 0:
			smallClear()
			
		count += 1
			
	var modeNode = createGameMode("",meta)
	modeNode.mapPath = destPath + "/maps/"
	print("dest path:",destPath + "/modes/")
	ENTG.saveNodeAsScene(modeNode,destPath + "/modes/")
	var ret = ResourceLoader.load(destPath + "/modes/"+modeNode.name+".tscn","",true).instance()
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
	
	if "dependantChildren" in generator:
		for i in generator.dependantChildren:
			$"../ThingParser".mergeDepends(getSpriteListOfMode(i),ret)
			
	return ret

func getGenerator(scenePath):
	var packedScene =  ResourceLoader.load(scenePath,"",true)
	
	if packedScene == null:
		print("could not load scene:",scenePath)
		return
	
	var scene = packedScene.instance()
	
	if scene.get_node_or_null("Generator") == null:
		print("scene:", "has no generator")
		return scene
		
	return scene.get_node("Generator")
