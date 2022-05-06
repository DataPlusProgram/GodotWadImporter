tool
extends Spatial
class_name WAD_Map


signal mapCreated
signal resDone
signal playerCreated
var directory : Directory
var lumps = []
var file

var maps = {} 


var editorInterface : EditorInterface
var editorFileSystem : EditorFileSystem
var textureEntries = {}
var palletes = []
var colorMaps = []
var patchNames = []
var patchTextureEntries = {}
var mapNames = []
var mapNode = null
var waiting = true

var wadInit = false
var floorPlan = true
var threaded = false

enum MERGE{DISABLED,WALLS,WALLS_AND_FLOOR}
enum MIP{ON,OFF,EXCLUDE_FOR_TRANSPARENT}
export var toDisk = false
export(Array,String,FILE,"*.wad") var wads = [] 
export var textureFiltering = false
export var textureFilterSkyBox = false
export var entitiesEnabled = false
export var disableRuntime = true
export var mapName  = "E1M1"
export(MERGE) var mergeMesh = MERGE.WALLS_AND_FLOOR
export(MIP) var mipMaps = MIP.EXCLUDE_FOR_TRANSPARENT
var dontUseShader = false
export var createSurroundingSkybox = true
export var unwrapLightmap = false

enum SKYVIS {DISABLED,ENABLED}

export(SKYVIS) var skyCeil = SKYVIS.ENABLED
export(SKYVIS) var skyWall = SKYVIS.ENABLED
export var maxMaterialPerMesh = 4
export var renderNullTextures = false


var mapThread
var resourceThread
var assetsDone = false
var tailPrimed = false

func _ready():
	
	yield(get_parent(), "ready")
	if mapName.length() == 0:
		return
	if !Engine.editor_hint:
		toDisk = false

	if !get_parent().has_node(mapName) and !Engine.is_editor_hint() and !disableRuntime:
		#createMap(mapName)
		createMap(mapName)
		
	#threadedLoadingOfAssets()
		

func createMapThread(mapName):
	mapThread = Thread.new()
	threaded = true
	mapThread.start(self,"createMap",mapName,Thread.PRIORITY_HIGH)
	
	
func createMap(newmapName,reloadWads = true ):
	#if mapName == newmapName:
	#	if !maps.empty():
	#		if maps[mapName].has("isHexen"):
	#			"attempting to reload current map. skipping..."	
	#			return
			
	mapName = newmapName
	$"ImageBuilder".mapName = mapName
	$"ResourceManager".mapName = mapName
	
	if toDisk:
		createDirectories()

	if reloadWads:#this is only false when you are changing from one level to another
		loadWads()
	
	if colorMaps.size() == 0:
		$"LumpParser".parseColorMapDummy()
	
	
	maps[mapName]["name"] = mapName
	$"LumpParser".parseMap(maps[mapName])
	$"LumpParser".postProc(maps[mapName])
	
	if threaded:
		print("----starting threaded loading of assets")
		threadedLoadingOfAssets()
		return
		
	
	preloadAssests()
	createMapTail()

	


func createMapTail():
	maps[mapName]["createSurroundingSkybox"] = createSurroundingSkybox
	
	var mapNode = $"LevelBuilder".createLevel(maps[mapName],mapName)
	mapNode.set_script(load("res://addons/godotWad/src/mapNode.gd"))
	
	get_parent().add_child(mapNode)
	
	print("seting map node owner")
	
	mapNode.set_owner(get_parent())
	
	print("setting all map children owner")
	for c in mapNode.get_children():
		if c.name != "Surrounding Skybox":
			c.set_owner(mapNode)
			recursiveOwn(c,mapNode)
	
	
	$"ThingParser".createThings(maps[mapName]["THINGS"])
	
	if toDisk:
		print("saving to disk")
		saveCurMapAsScene(mapNode,mapName)
	

	emit_signal("mapCreated")

func loadWads():
	if !Engine.editor_hint:
		toDisk = false
	
	if wadInit == false:
		for wad in wads:
			loadWAD(wad)	
	
	wadInit = true
	
	
func _physics_process(delta):
	if assetsDone == true:
		if !get_parent().has_node(mapName) and !Engine.is_editor_hint():
			print("lets create map")
			createMapTail()
			assetsDone = false

func pluginFetchNames():
	mapNames = []
	maps = {}
	clear()
	for wad in wads:
		var localmapNames = fetchmapNames(wad)
		for mapName in localmapNames:
			if !mapNames.has(mapName):
				mapNames.append(mapName)
				
	return mapNames
		

func fetchmapNames(path):
	file = load("res://addons/godotWad/src/DFile.gd").new()
	if file.loadFile(path) == false:
		return
	var magic = file.get_String(4)
	var numLumps = file.get_32()
	var directoryOffset = file.get_32()
	file.seek(directoryOffset)
	
	getAllLumps(file,numLumps)
	sortLumps()
	
	return maps.keys()

func loadWAD(path):
	clear()
	print("load wad:",path)
	file = load("res://addons/godotWad/src/DFile.gd").new()
	if file.loadFile(path) == false:
		return
	var magic = file.get_String(4)
	var numLumps = file.get_32()
	var directoryOffset = file.get_32()
	file.seek(directoryOffset)
	
	getAllLumps(file,numLumps)
	sortLumps()
	$"LumpParser".parseLumps(lumps)
	

	

	

func getAllLumps(file,numLumps):
	for i in numLumps:
		var offset = file.get_32u()
		var size = file.get_32u()
		var name = file.get_String(8)
		#if name == "BEHAVIOR":
		#	breakpoint
		lumps.append({"name":name,"file":file,"offset":offset,"size":size})

func sortLumps():
	var numLumps = lumps.size()
	var lumpIdx = 0
	var key = lumpIdx
	
	while lumpIdx < numLumps:
		var lumpName = lumps[lumpIdx]["name"]
		if lumpName.length()<3:
			lumpIdx += 1
			continue
			
		if (lumpName[0] == "E" and lumpName[2] == "M") or lumpName.substr(0,3) == "MAP":
			lumpIdx = sortMapLumps(lumpIdx)
			continue

		lumpIdx += 1

func sortMapLumps(idx):
	var mapInfos = ["THINGS","LINEDEFS","SIDEDEFS","VERTEXES","SEGS","SSECTORS","NODES","SECTORS","REJECT","BLOCKMAP","BEHAVIOR","SCRIPTS"]
	var mapName =  lumps[idx]["name"]#we go to the lump index of map name
	var curMap = {}
	idx += 1
	
	var numLumps = lumps.size()
	while(idx < numLumps):#or we breakout
		var lumpName = lumps[idx]["name"]
		if mapInfos.has(lumpName):
			curMap[lumpName] =  {"file":lumps[idx]["file"],"offset":lumps[idx]["offset"],"size":lumps[idx]["size"]}
			idx +=1 
		else:
			maps[mapName] = curMap
			return idx#no longer reading nodes that pertain to the map
	
	maps[mapName] = curMap
	return idx


func waitForDirToExist(path):
	var waitThread = Thread.new()
	
	waitThread.start(self,"waitForDirToExistTF",path)
	waitThread.wait_to_finish()
	
func waitForDirToExistTF(path):
	var dir = Directory.new()
	while !dir.dir_exists(path):
		OS.delay_msec(100)
		editorFileSystem.scan()

func waitForResourceToExist(resPath):
	var waitThread = Thread.new()
	waitThread.start(self,"waitForResourceToExistTF",resPath)
	waitThread.wait_to_finish()
	
	

func waitForResourceToExistTF(resPath):
	var fileE = File.new()
	while !(fileE.file_exists(resPath)):
		OS.delay_msec(200)
		editorFileSystem.scan()


func saveCurMapAsScene(mapNode,mapName):
	
	
	
	recursiveOwn(mapNode,mapNode)
	var fileE = File.new()
	
	
	
	
	var nodeAsTSCN = PackedScene.new()

	nodeAsTSCN.pack(mapNode)
	var resPath = "res://wadFiles/" + mapName +".tscn"
	
	if !fileE.file_exists(resPath):
		var dir = Directory.new()
		dir.remove(resPath)
	var err = ResourceSaver.save(resPath,nodeAsTSCN)
	
	
	
	
	
	if !fileE.file_exists(resPath):
		print("res path dosent exist waiting...")
		waitForResourceToExist("res://wadFiles/" + mapName +".tscn")
		
		
	mapNode.name = "deleted"
	mapNode.queue_free()
	var t = load("res://wadFiles/" + mapName +".tscn").instance()
	t.name = mapName
	
	get_parent().add_child(t)
	t.set_owner(get_parent())
	t.name = mapName




func recursiveOwn(node,newOwner):
	if newOwner != node:
		node.set_owner(newOwner)
	
	for i in node.get_children():
		recursiveOwn(i,newOwner)


func createPlayerController():
	createDirectories()
	print("------------------creating char----------------------")

	loadWads()
	var conArr = []
	print("instancing player scene...")
	var player = load("res://addons/godotWad/scenes/player/player.tscn").instance()
	print("done")
	print("player node:",player)
	var gunManager = player.get_node("Camera/gunManager")

	print("starting gun manager")
	for i in gunManager.get_children():
		if "weaponName" in i:
			#print(i.name,",",i.transform)
			
			var conPath = gun(i.filename)
			print("instacing ",conPath)
			var con = load(conPath).instance()
			print("done instacning ",conPath)
			con.transform = i.transform
			
			delete(i)
			
			for c in con.get_children():
				delete(c)
			
			
			conArr.append(con)
			
	
	for i in gunManager.get_children():
		if "weaponName" in i:
			delete(i)
	
	for i in conArr:
		#i.translation.z = -0.25
		#i.translation.y = -10
		gunManager.add_child(i)#these guys make thhreads

	
	for i in player.get_node("Camera").get_children():
		if i.filename.length() > 0:
			for j in i.get_children():
				delete(j)
			
	for i in player.get_node("Step-Upper").get_children():
		delete(i)

	
	recursiveOwn(player,player)
	var pack = PackedScene.new()
	print("saving scene..")
	pack.pack(player)
	ResourceSaver.save("res://wadFiles/player/player.tscn",pack)
	emit_signal("playerCreated","res://wadFiles/player/player.tscn")
	return "res://wadFiles/player/player.tscn"


	

func threadedLoadingOfAssets():
	resourceThread = Thread.new()
	resourceThread.start(self,"preloadAssests")
	


func preloadAssests():
	var fme = $LumpParser.flatMatEntries
	var wme =  $LumpParser.wallMatEntries
	var skyBoxDisabled = false
	
	if skyCeil == 0 and skyWall == 0 and createSurroundingSkybox == false:
		skyBoxDisabled = true
	
	if createSurroundingSkybox:
		$"ResourceManager".fetchSkyMat(true)
		$"ResourceManager".fetchSkyMat(false)
	
	elif fme.has("F_SKY1") and !skyBoxDisabled:
		$"ResourceManager".fetchSkyMat(true)
		$"ResourceManager".fetchSkyMat(false)
		
	elif wme.has("F_SKY1") and !skyBoxDisabled:
		$"ResourceManager".fetchSkyMat(true)
		$"ResourceManager".fetchSkyMat(false)
	
	
	
	for type in maps[mapName]["THINGS"]:
		if  !$ThingParser.thingsDict.has(type):
			print("type:",type," not found")
			continue
		
		var thingDict = $ThingParser.thingsDict[type]
		
		if thingDict.has("sprites"):
			if thingDict["sprites"] != [""]:
				for sprName in thingDict["sprites"]:
					$ResourceManager.fetchPatch(sprName)
		
		if thingDict.has("deathSprites"):
			if thingDict["deathSprites"] != [""]:
				for sprName in thingDict["deathSprites"]:
					$ResourceManager.fetchPatch(sprName)
		
	
	for textureName in fme.keys():
		var texture = null
		
		if textureName == "F_SKY1":
			continue
		
		texture = $ResourceManager.fetchFlat(textureName)
		
		if texture == null:#we don't have flat so we look for a wall
			texture = $ResourceManager.fetchTexture(textureName,true)
		
		for textureEntry in fme[textureName]:#each mat param of a given texture
			var lightLevel = textureEntry[0]
			var scrollVector = textureEntry[1]
			$"ResourceManager".fetchMaterial(textureName,texture,lightLevel,scrollVector,1.0,0,0)
			
			
	for textureName in wme.keys():
		var texture = null
		
		if textureName == "F_SKY1":
			continue
		
		texture = $ResourceManager.fetchTexture(textureName)
		
		for textureEntry in wme[textureName]:#each mat param of a given texture
			var lightLevel = textureEntry[0]
			var scrollVector = textureEntry[1]
			var alpha = textureEntry[2]
			
			$"ResourceManager".fetchMaterial(textureName,texture,lightLevel,scrollVector,alpha,0,0)
		
	emit_signal("resDone")
	assetsDone = true
	
	print("---assets internal function done")
	tailPrimed = true
	return

func createDirectories():
	
	var directory = Directory.new()
	
	directory.open("res://")
	createDirIfNotExist("wadFiles",directory)
	
	directory.open("res://wadFiles")
	createDirIfNotExist("textures",directory)
	createDirIfNotExist("player",directory)
	createDirIfNotExist("materials",directory)
	createDirIfNotExist("sounds",directory)
	createDirIfNotExist("sprites",directory)
	createDirIfNotExist("textures/animated",directory)
func createDirIfNotExist(path,dir):
	if !dir.dir_exists(path):
		dir.make_dir(path)
	

func clear():
	wadInit = false
	lumps = []
	#$ImageBuilder.flatCache = {}

func delete(node):
	node.name = "deleted"
	node.get_parent().remove_child(node)
	node.queue_free()


func gun(path):
	print("instacncing  con ",path,"..")
	var con = load(path).instance()#we crete the runtime version
	print("done")
	var t = con.get_node("Node")
	t.loaderPath = $"ResourceManager".get_path()
	
	get_parent().add_child(con)
	
	if Engine.editor_hint:
		con.get_node("Node").initialize(toDisk)
	
	delete(con.get_node("Node"))
	
	recursiveOwn(con,con)
	
	print("saaving gun...")
	var pack = PackedScene.new()
	pack.pack(con)
	ResourceSaver.save("res://wadFiles/player/"+con.weaponName+".tscn",pack)
	
	#con = load("res://dbg/"+con.weaponName+".tscn").instance()
	print("done")
	return "res://wadFiles/player/"+con.weaponName+".tscn"
