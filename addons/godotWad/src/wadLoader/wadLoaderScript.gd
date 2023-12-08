tool
class_name WAD_Map
extends Spatial

var is64 = false


signal mapCreated
signal resDone
signal playerCreated
signal fileWaitDone
signal clearCache

var directory : Directory
var lumps = []
var file

var maps = {} 
var info = {}

enum FLOORMETHOD{
	old,
	new,
	three,
}

enum DIFFICULTY{
	none
	easy,
	medium,
	hard
}

var editorInterface
var editorFileSystem
var plugin = null
var patchTextureEntries = {}
var palletes = []
var colorMaps = []
var patchNames = []
var flatTextureEntries = {}
var textmap
var mapNode = null
var waiting = true
var spriteList = []
var fovSpriteList = []
var wadInit = false
var floorPlan = true
var threaded = false
var gameName = "doom"
var targetLastPost = Vector3.ZERO

onready var prevPos = [translation,translation,translation]
onready var options = null#
enum MERGE{DISABLED,WALLS,WALLS_AND_FLOOR}
enum MIP{ON,OFF,EXCLUDE_FOR_TRANSPARENT}
enum NAV{OFF,SINGLE_MESH,LARGE_MESH}
export var toDisk = false
export(Array,String,FILE,"*.wad") var wads = [] 
#export(Array,String,FILE,"*.pk3") var pk3s = [] 
export(Array,String,DIR) var directories = [] 
export var textureFiltering = false
export var textureFilterSkyBox = false
export var npcsDisabled = false

export(DIFFICULTY) var difficultyFlags = DIFFICULTY.medium
export(MERGE) var mergeMesh = MERGE.WALLS_AND_FLOOR
export var meshSimplify = true
export(MIP) var mipMaps = MIP.EXCLUDE_FOR_TRANSPARENT
var dontUseShader = false
export var createSurroundingSkybox = false
export var unwrapLightmap = false

enum SKYVIS {DISABLED,ENABLED}
export(Vector3) var scaleFactor = Vector3(0.03125,0.038,0.03125)
export(SKYVIS) var skyCeil = SKYVIS.ENABLED
export(SKYVIS) var skyWall = SKYVIS.ENABLED
export(NAV) var generateNav = NAV.OFF
export var addOccluder = true
export var maxMaterialPerMesh = 4
export var renderNullTextures = false
export(float) var occMin = 2.0
export(float) var occluderBBclip = 30
var generateFloorMap = false #unused
export(int) var maxOccluderCount = 250
var floorMethod = FLOORMETHOD.three


var mapThread
var saveThread : Thread 
var resourceThread
var assetsDone = false
var tailPrimed = false
var mapName  = "E1M1"


func _ready():
	var e = get_node("ResourceManager").connect("fileWaitDone",self,"fileWaitDone")
	
	options = load("res://addons/godotWad/loaderOptions.tscn").instance()
	
	if options != null:
		options.target = self
	
	

func fileWaitDone():
	emit_signal("fileWaitDone")


var ui = null
func createMapThread(mapName,threaded):
	self.ui = ui
	if mapThread != null:
		mapThread.wait_to_finish()
	mapThread = Thread.new()
	self.threaded = threaded
	mapThread.start(self,"createMap",mapName,Thread.PRIORITY_HIGH)

var trueTotalStart 

func getOptions():
	return options
	#return load("res://addons/godotWad/loaderOptions.tscn").instance()

func createMapPreview(mapName,metaData : Dictionary = {},reloadWads = false):
	var iaddOccluder = addOccluder
	var imeshSimplify = meshSimplify
	var imergeMesh = mergeMesh
	var iSkyCeil = skyCeil
	var iSkyWall = skyWall
	
	mergeMesh = MERGE.DISABLED
	addOccluder = false
	meshSimplify = false
	
	skyCeil =  SKYVIS.DISABLED
	skyWall = SKYVIS.DISABLED
	
	
	var map = createMap(mapName,metaData,false)
	
	
	
	
	skyCeil =  iSkyCeil
	skyWall = iSkyWall
	addOccluder = iaddOccluder
	meshSimplify = imeshSimplify
	mergeMesh = imergeMesh
	
	return map
	

func createMap(mapName,metaData : Dictionary = {},reloadWads = true):
	
	var startTime = OS.get_system_time_msecs()
	
	if metaData.has("reloadWads"):
		reloadWads = metaData["reloadWads"]
	
	trueTotalStart = startTime
	$"ResourceManager".waitingForFiles = []
	
	thingCheck(wads)
	
	if wadInit == false:
		reloadWads = true
	
	self.mapName = mapName
	mapNode = Navigation.new()
	mapNode.cell_size = (scaleFactor.x/0.031)
	mapNode.cell_height = (scaleFactor.y/0.038) 
	
	ENTG.createEntityCacheForGame(get_tree(),toDisk,"Doom",$"ThingParser",mapNode)
	

	loadDirs(directories)
	if reloadWads:#this is only false when you are changing from one level to another
		loadWads()
	
	
	if colorMaps.size() == 0:
		$"LumpParser".parseColorMapDummy()
	
	
	if !maps.has(mapName):
		print("map name ",mapName," not found")
		return
	

	var targetMap = maps[mapName]
	targetMap["name"] = mapName

		
	if targetMap.has("isTextmap"):
		$"LumpParser".parseTextMap(targetMap)
	else:
		$"LumpParser".parseMap(targetMap)
	
	
	
	var postProcStart = OS.get_system_time_msecs()
	$"LumpParser".postProc(targetMap)
	WADG.setTimeLog(get_tree(),"postProcTime",postProcStart)
	
	#if toDisk:
	#	preloadAssests()
	#$"ResourceManager".saveAllSondsToDisk()
	
	WADG.setTimeLog(get_tree(),"createMapPre",startTime)
	
	
	return createMapTail()
	#if !threaded:
	##	return createMapTail()
	
	
	
	


func createMapTail():
	var startTime = OS.get_system_time_msecs()
	var fme = $LumpParser.flatMatEntries
	var wme =  $LumpParser.wallMatEntries
	
	
	var tailFetchStart = OS.get_system_time_msecs()
	for textureName in fme.keys():
		for textureEntry in fme[textureName]:#each mat param of a given texture
			var lightLevel = textureEntry[0]
			var scrollVector = textureEntry[1]
			var alpha = textureEntry[2]
			var texture = $ResourceManager.fetchFlat(textureName)
			#$"ResourceManager".fetchMaterial(textureName,texture,lightLevel,scrollVector,1.0,0,0)

	for textureName in wme.keys():
		for textureEntry in wme[textureName]:#each mat param of a given texture
			var lightLevel = textureEntry[0]
			var scrollVector = textureEntry[1]
			var alpha = textureEntry[2]
			#var texture = $ResourceManager.fetchFlat(textureName) ?
			var texture = $ResourceManager.fetchPatchedTexture(textureName)
			$"ResourceManager".fetchMaterial(textureName,texture,lightLevel,scrollVector,alpha,0,0)
#
	
	WADG.setTimeLog(get_tree(),"tailFetching",tailFetchStart)
	
	for textureName in spriteList:
		$ResourceManager.fetchSpriteMaterial(textureName)

	for textureName in fovSpriteList:
		$ResourceManager.fetchSpriteMaterial(textureName,true)
	
	
	var texName : String = $ImageBuilder.getSkyboxTextureForMap(mapName) 
	$"ResourceManager".fetchSkyMat(texName,true)
	maps[mapName]["createSurroundingSkybox"] = createSurroundingSkybox
	
	
	var a = OS.get_system_time_msecs()
	$"LevelBuilder".createLevel(maps[mapName],mapName,mapNode)
	a = OS.get_system_time_msecs()
	
	mapNode.set_script(load("res://addons/godotWad/src/mapNode.gd"))
	
	
	get_parent().add_child(mapNode)
	
	mapNode.set_owner(get_parent())


	a = OS.get_system_time_msecs()
	
	for c in mapNode.get_children():
		if c.name != "Surrounding Skybox":
			c.set_owner(mapNode)
			recursiveOwn(c,mapNode)
	
	
	a = OS.get_system_time_msecs()
	print("create things")
	$"ThingParser".createThings(maps[mapName]["THINGS"])
	
	WADG.setTimeLog(get_tree(),"thing creation",a)
	

	emit_signal("mapCreated")
	WADG.setTimeLog(get_tree(),"mapPost",startTime)
	WADG.setTimeLog(get_tree(),"total",trueTotalStart)
	
	
	return mapNode

func initialize(wadArr = [],gameName = "Doom"):
	self.gameName = gameName

	thingCheck(wadArr)
	wads = wadArr
	
	
	
	$"ThingParser".initThingDirectory()
	info["maps"] = maps.keys()
	info["entities"] = $"ThingParser".thingDirectory.keys()
	
	ENTG.createEntityCacheForGame(get_tree(),toDisk,gameName,$"ThingParser",mapNode)

	
	

func getCreatorScript():
	return $"ThingParser"

func spawn(var idStr : String,var pos = Vector3.ZERO,var rot = 0,parentNode : Node = null) -> Node:
	if parentNode == null:
		parentNode = mapNode
	return ENTG.spawn(get_tree(),idStr,pos,Vector3(0,rot,0),"doom",parentNode)
	#return $ThingParser.spawn(idStr,pos,Vector3(0,rot-90,0))


func thingCheck(wadArr):
	if gameName == "Doom64":
		is64 = true
	else:
		is64 = false
	
	
	for i in wadArr:
		if i.to_lower().get_file() == "hexen.wad":
			$"ThingParser".thingSheet = $"ThingParser".hexenThingSheet

func loadWads():
	if !Engine.editor_hint:
		toDisk = false
	
	#if wadInit == false:
	for wad in wads:
		
#		if OS.has_feature("standalone"):
#			print("orig path:",wad)
#			wad = wad.replace("res:///","")
#			var exePath = OS.get_executable_path()
#			exePath = exePath.substr(0,exePath.find_last("/"))
#			wad = ProjectSettings.globalize_path(exePath + "/" + wad)
#			print("globalized path")
#			print("in:",exePath + "/" + wad)
#			print("out:",wad)
#		else:
#			pass
		loadWAD(wad)
	
	info["maps"] = []
	

		
	wadInit = true
	ENTG.createEntityCacheForGame(get_tree(),toDisk,gameName,get_node("ThingParser"),mapNode)

	
func loadDirs(dirs):
	for d in dirs:
		loadDir(d)
	
func loadPk3s(paths):
	for path in paths:
		loadPk3(path)
		
func loadPk3(path):
	var gdunzip = load('res://addons/gdunzip/gdunzip.gd').new()
	var loaded = gdunzip.load(path)
	var uncompressed = gdunzip.uncompress("Textures/")
	
	for i in gdunzip.files.keys():
		var dict = gdunzip.files[i]
		var fPath = dict["file_name"]
		if fPath.find("Textures") != -1:
			var data = gdunzip.uncompress(fPath)
			if !data.empty():
				pass
	

func dirFileList(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	return files

func loadDir(dirPath):
	var files = dirFileList(dirPath)
	for f in files:
		var ext = f.get_extension()
		if ext == "jpg" or ext == "png" or ext.empty():
			$"ResourceManager".fetchTextureFromFile(dirPath + "/" +f)


func pluginFetchNames():
	
	var mapNames = []
	maps = {}
	clear()
	for wad in wads:
		if wad.empty():
			continue
		
		var localmapNames = fetchmapNames(wad)
		for mapName in localmapNames:
			if !mapNames.has(mapName):
				mapNames.append(mapName)
				
	return mapNames
		

func fetchmapNames(path):
	file = load("res://addons/godotWad/src/DFile.gd").new()
	if file.loadFile(path) == false:
		return
		
		
	var isUDMF = isUDMF()
	
	var magic = file.get_String(4)
	var numLumps = file.get_32()
	var directoryOffset = file.get_32()
	file.seek(directoryOffset)
	getAllLumps(file,numLumps)
	
	if !isUDMF:
		$"LumpParser".parseLumps(lumps)
		sortLumps()
		
		
		
		return maps
	else:
		$"LumpParser".parseLumps(lumps)
		return [lumps[0]["name"]]
	
	

func loadWAD(path):
	#clear()
	if path.find(".") == -1:
		parseDir(path)
	
	
	
	#if file != null:
	#	print("clear dfile")
	#	file.queue_free()
	
	file = load("res://addons/godotWad/src/DFile.gd").new()
	if file.loadFile(path) == false:
		print("file:",path," not found")
		return
	
	var isUDMF = isUDMF()
	var magic = file.get_String(4)
	var numLumps = file.get_32()
	var directoryOffset = file.get_32()
	
	
	file.seek(directoryOffset)
	getAllLumps(file,numLumps)
	

	
	if !isUDMF:#if it's a vanilla doom format
		sortLumps()
		$"LumpParser".parseLumps(lumps)
		
	else:#it's UDMF
		var curMap = {"isTextmap":true}
		$"LumpParser".parseLumps(lumps)
		curMap["textLump"] = lumps[1]#udmf usually only have 1 map per file
		maps[lumps[0]["name"].to_upper()] = curMap
		
		
	

func getAllLumps(file,numLumps):
	for i in numLumps:
		var offset = file.get_32u()
		var size = file.get_32u()
		var name = file.get_String(8)

		lumps.append({"name":name,"file":file,"offset":offset,"size":size})
	

func sortLumps():
	var numLumps = lumps.size()
	var lumpIdx = 0
	var key = lumpIdx
	
	while lumpIdx < numLumps:#for each lump
		var lumpName = lumps[lumpIdx]["name"]
		if lumpName.length()<3:#if lump name is less than 3 we its not a map lump
			lumpIdx += 1
			continue
			
		if (lumpName[0] == "E" and lumpName[2] == "M") or lumpName.substr(0,3) == "MAP":#we have a new map lump at lumpIdx
			lumpIdx = sortMapLumps(lumpIdx)
			continue

		lumpIdx += 1

func sortMapLumps(idx):
	var mapInfos = ["THINGS","LINEDEFS","SIDEDEFS","VERTEXES","SEGS","SSECTORS","NODES","SECTORS","REJECT","BLOCKMAP","BEHAVIOR","SCRIPTS"]
	var mapName =  lumps[idx]["name"]#we go to the lump index of map name
	var curMap = {}
	idx += 1
	
	var numLumps = lumps.size()
	while(idx < numLumps):#from map index to to last lump index (usually we will just terminate once we find a lump thats not in the mapInfos)
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
		print("waiting for dir:",path)
		OS.delay_msec(10)
		

func createGameMode(curEntTxt,curMeta):
	var mode = $gameModeCreator.createGameMode(curEntTxt,curMeta)
	return mode

func createGameModePreview(path,meta):
	return $gameModeCreator.createGameModePreview(path,meta)

func waitForResourceToExist(resPath):
	var waitThread = Thread.new()
	waitThread.start(self,"waitForResourceToExistTF",resPath)
	waitThread.wait_to_finish()
	
	

func waitForResourceToExistTF(resPath):
	var fileE = File.new()
	while !(fileE.file_exists(resPath)):
		OS.delay_msec(16.67)
		


func saveCurMapAsScene(arr):
	var mapNode = arr[0]
	var mapName = arr[1]
	
	
	recursiveOwn(mapNode,mapNode)
	var fileE = File.new()
	
	
	
	
	var nodeAsTSCN = PackedScene.new()

	nodeAsTSCN.pack(mapNode)
	
	var resPath =WADG.destPath+gameName+ "/maps/" + mapName +".tscn"
	#var resPath =WADG.destPath+get_parent().gameName+ "/maps/" + mapName +".tscn"
	
	if !fileE.file_exists(resPath):
		var dir = Directory.new()
		dir.remove(resPath)
	var err = ResourceSaver.save(resPath,nodeAsTSCN)
	
	
	if !fileE.file_exists(resPath):
		print("res path dosent exist waiting...")
		waitForResourceToExist(WADG.destPath+gameName+ "/maps/" + mapName +".tscn")
	#	waitForResourceToExist(WADG.destPath+get_parent().gameName+ "/maps/" + mapName +".tscn")
		
		
	#mapNode.name = "deleted"
	#mapNode.queue_free()
	
	var t = load(WADG.destPath+gameName+ "/maps/" + mapName +".tscn").instance()
	t.name = mapName
	
	get_parent().add_child(t)
	t.set_owner(get_parent())
	t.name = mapName
	emit_signal("mapCreated")




func recursiveOwn(node,newOwner):
	if newOwner != node:
		node.set_owner(newOwner)
	
	for i in node.get_children():
		recursiveOwn(i,newOwner)



func preloadAssests() -> void:
	var fme = $LumpParser.flatMatEntries
	var wme =  $LumpParser.wallMatEntries
	var skyBoxDisabled = false
	
	
	if skyCeil == 0 and skyWall == 0 and createSurroundingSkybox == false:
		skyBoxDisabled = true
	
	var skys : Array = []
	
	
	
	for i in maps:
		if !skys.has($ImageBuilder.getSkyboxTextureForMap(i)):
			skys.append($ImageBuilder.getSkyboxTextureForMap(i))
	
	for i in skys:
		$ResourceManager.fetchPatchedTexture(i)
	
	for t in maps[mapName]["THINGS"]:
		var type = t["type"]
		
		
		if !$ThingParser.thingSheet.hasKey(var2str(type)):
			print("type:",type," not found")
			continue
		
		var thingDict =$ThingParser.thingSheet.getRow(var2str(type))
		
		if thingDict.has("sprites"):
			var sprites = thingDict["sprites"] 
			if sprites != [""]:
				
				if sprites.size() == 1:
					for sprName in sprites:
						$ResourceManager.fetchDoomGraphic(sprName)
				else:
					$ResourceManager.fetchAnimatedSimple(sprites[0] + "_anim",sprites)
		
		if thingDict.has("deathSprites"):
			if thingDict["deathSprites"] != [""]:
				for sprName in thingDict["deathSprites"]:
					$ResourceManager.fetchDoomGraphic(sprName)
		
		
	
	
	var uniqueThings : Array = []
	
	for i in maps[mapName]["THINGS"]:
		if !uniqueThings.has(i["type"]):
			uniqueThings.append(i["type"])
	
	var a = OS.get_system_time_msecs()
	
	var sl = $ThingParser.getSpriteList(uniqueThings)

	fetchFromSpriteList(sl)
	var texture = null
	

	for textureName in fme.keys():
		if !flatTextureEntries.has(textureName):
			if patchTextureEntries.has(textureName):
				if !wme.has(textureName):
					wme[textureName] = []
				
				for i in fme[textureName]:
					wme[textureName].append(i)
					fme[textureName].erase(i)
					
				fme.erase(textureName)
	
	for textureName in wme.keys():
		if !patchTextureEntries.has(textureName):
			if flatTextureEntries.has(textureName):
				if !fme.has(textureName):
					fme[textureName] = []
				
				for i in wme[textureName]:
					fme[textureName].append(i)
					wme[textureName].erase(i)
					
				wme.erase(textureName)
	

	for textureName in fme.keys():
		texture = $ResourceManager.fetchFlat(textureName)
			
	for textureName in wme.keys():
		texture = $ResourceManager.fetchPatchedTexture(textureName)
		
	
	if editorInterface!= null:
		$ResourceManager.waitForFilesToExist(editorInterface)
			
			
	
	for animSprName in sl['animatedSprites']:
		$ResourceManager.fetchAnimatedSimple(animSprName,sl["animatedSprites"][animSprName])
		
	emit_signal("resDone")
	assetsDone = true

	return


func fetchFromSpriteList(sl):
		
	if sl.has("spritesFOV"):
		fovSpriteList = sl["spritesFOV"]
			
			
	for sprName in sl["sprites"]:
		if typeof(sprName) == TYPE_STRING:
			$ResourceManager.fetchDoomGraphic(sprName)

		
	for sprName in fovSpriteList:
		$ResourceManager.fetchDoomGraphic(sprName)
		
	for animSprName in sl['animatedSprites']:
		for i in sl["animatedSprites"][animSprName]:
			$ResourceManager.fetchDoomGraphic(i)

 

func createDirectories():

	
	var directory = Directory.new()
	
	directory.open("res://")
	
	#var split = WADG.destPath+get_parent().gameName.lstrip("res://")
	var split = WADG.destPath+gameName.lstrip("res://")

	if split.length() > 0:
		var subDirs = split.split("/")
		
		for i in subDirs.size():
			var path = "res://"
			for j in i+1:
				directory.open(path)
				path += subDirs[j] + "/"
				print("create dir:",path)
				createDirIfNotExist(path,directory)
				
			directory.open(path)
	
	#directory.open(WADG.destPath+get_parent().gameName)
	directory.open(WADG.destPath+gameName)
	createDirIfNotExist("textures",directory)
	createDirIfNotExist("player",directory)
	createDirIfNotExist("materials",directory)
	createDirIfNotExist("sounds",directory)
	createDirIfNotExist("sprites",directory)
	createDirIfNotExist("textures/animated",directory)
	createDirIfNotExist("entities",directory)
	createDirIfNotExist("fonts",directory)
	createDirIfNotExist("maps",directory)
	
	var dirs = $ThingParser.thingSheet.getColumn("dest")
	
	$ThingParser.initThingDirectory()
	
	for i in $ThingParser.categories:
		#createDirIfNotExist(WADG.destPath+get_parent().gameName+"/entities/" + i,directory)
		createDirIfNotExist(WADG.destPath+gameName+"/entities/" + i,directory)
	
	for i in $ThingParser.categories:
		#waitForDirToExist(WADG.destPath+get_parent().gameName+"/entities/" + i)
		waitForDirToExist(WADG.destPath+gameName+"/entities/" + i)
	var directoriesToCreate : Array = []
	
	
	for entityEntry in $ThingParser.thingDirectory.values():
		if entityEntry.has("category"):
			if !directoriesToCreate.has(entityEntry["category"]):
				directoriesToCreate.append(entityEntry["category"])
	
	

	for dir in directoriesToCreate:
		createDirIfNotExist("entities/"+dir,directory)
	

	
func createDirIfNotExist(path,dir):
	print("create dir:",dir)
	if !dir.dir_exists(path):
		dir.make_dir(path)
		
	

func getReqDirs():
	return ["textures","materials","sounds","sprites","textures/animated","entities","fonts","maps","modes"]

func clear():
	wadInit = false
	spriteList = []
	fovSpriteList = []
	lumps = []
	
	for i in $ResourceManager.entityC.values():
		i.queue_free()
	
	$ResourceManager.entityC = {}
	wadInit = false


func delete(node):
	node.name = "deleted"
	node.get_parent().remove_child(node)
	node.queue_free()

	
func isUDMF():
	return file.scanForString("TEXTMAP",file.get_len())
#	return file.scanForString("namespace",32)

func parseDir(path):
	var dir = Directory.new()
	dir.open(path)
	
	if dir.dir_exists("TEXTURES"):
		var t = list_files_in_directory(path +"/TEXTURES")
		for file in t:
			if file.find(".png") != -1:
				breakpoint


func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.find(".")!= -1:
			files.append(file)

	dir.list_dir_end()

	return files


func getEntityDict():
	return $ThingParser.getEntityDict()

func getEntityInfo(entityName : String):
	
	return $ThingParser.getEntityInfo(entityName)

func isHexen():
	return $LumpParser.isHexen

func getAll():
	pluginFetchNames() #this calls lump parser
	var ent = ENTG.getEntitiesCategorized(get_tree(),gameName)
	var sounds = $ResourceManager.soundCache.keys()
	var textures = patchTextureEntries.keys()
	var gameModes = {}
	
	
	if wads.size() > 0:
		if wads[0].to_lower().find("hexen") == -1:
			gameModes = {"main":"res://addons/godotWad/scenes/gameModes/main/mainMode_template.tscn"}
		
	
	return {"entities":ent,"maps":maps.keys(),"sounds":sounds,"meta":{"main":{"path":"res://addons/godotWad/scenes/gameModes/main/mainMode_template.tscn"}},"game modes":gameModes}
	
func fetchEntity(entityStr,tree):
	return ENTG.fetchEntity(entityStr,tree,gameName,false)

func createSound(soundStr,meta = {}):
	return $ResourceManager.soundCache[soundStr]

func getConfigs():
	return ["Doom","Doom Mod","Hexen"]

func getReqs(configName):
	
	configName = configName.to_lower()
	
	var iwad = {
		"UIname" : "IWAD path:",
		"required" : true,
		"ext" : "*.wad",
		"multi" : false,
		"fileNames" : ["doom.wad","doom2.wad","freedoom1.wad","freedoom2.wad","plutonia.wad","tnt.wad"],
		"hints" : ["steam,Ultimate Doom/base","steam,Master Levels of Doom/doom2","steam,Final Doom/base","steam,Doom 2/base","steam,Doom 2/finaldoombase"]
	}
	
	var pwad = {
		"UIname" : "PWAD path:",
		"required" : false,
		"ext" : "*.wad",
		"multi" : true,
		"fileNames" : [],
		"hints" : []
	}
	
	var hexen = {
		"UIname" : "IWAD path:",
		"required" : true,
		"ext" : "*.wad",
		"multi" : false,
		"fileNames" : ["hexen.wad"],
		"hints" : []
	}
	
	
	#skyCeil =  SKYVIS.DISABLED
	#skyWall = SKYVIS.DISABLED
	
	if configName == "doom": 
		return [iwad]
	elif configName == "hexen":
		return [hexen]
	else:
		return [iwad,pwad]
	


func createEntityResourcesOnDisk(entStr,meta,editorInteface):
	$"ThingParser".createEntityResourcesOnDisk(entStr,editorInteface)


func createMapResourcesOnDisk(mapname,meta,editorInteface,startFileWaitThread = true):
	$"ThingParser".createMapResourcesOnDisk(mapname,editorInteface,startFileWaitThread)
	
func createGameModeResourcesOnDisk(gName,meta,editorInterface):
	print("gme mode ei:",editorInterface)
	$gameModeCreator.createGameModeResourcesOnDisk(gName,meta,editorInterface)
	if Engine.editor_hint:
		$"ThingParser".startFileWaitThread(editorInterface)
	else:
		emit_signal("fileWaitDone")

func createGameModeDisk(gName,meta,tree,gameName):
	return $gameModeCreator.createGameModeDisk(gName,meta,tree,gameName)
