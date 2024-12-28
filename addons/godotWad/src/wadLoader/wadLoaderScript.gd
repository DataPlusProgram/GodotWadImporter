@tool
class_name WAD_Map
extends Node3D

var is64 = false



signal mapCreated
signal resDone
signal playerCreated
signal fileWaitDoneSignal
signal clearCache

var directory : DirAccess
var lumps = []
var file : FileAccess
var hasCollision = true
var maps = {} 
var info = {}
var isHexen = false

enum LUMP{
	name,
	file,
	offset,
	size,
}

enum FLOORMETHOD{
	old,
	new,
	three,
}

enum DIFFICULTY{
	none,
	easy,
	medium,
	hard
}

enum  INVISIBLE_WALLS{
	enabled,
	disabled
}

var editorInterface
var editorFileSystem
var plugin = null
var patchTextureEntries = {}
var palletes = []
var colorMaps  = []
var patchNames : Dictionary = {}
var flatTextureEntries = {}
var fileLookup := []
var zipFileLookup := []
var midiListPre = {}
var midiList = {}
var musListPre = {}
var musList = {}
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
var mapToMusic = {} 
var params = []
var config : String = ""

@onready var prevPos = [position,position,position]
@onready var options = null#
@onready var thingParser = $ThingParser
enum MERGE{DISABLED,WALLS,WALLS_AND_FLOOR,WALLS_AND_FLOOR_2}
enum MIP{ON,OFF,EXCLUDE_FOR_TRANSPARENT}
enum NAV{OFF,SINGLE_MESH,LARGE_MESH}
var dontUseShader = false


@onready var toDisk : bool = false

@export var KEEP_WALLS_CONVEX = true
@export var wads : Array= []   # (Array,String,FILE,"*.wad")
@export var scaleFactor: Vector3 = Vector3(0.03125,0.038,0.03125)
#export(Array,String,FILE,"*.pk3") var pk3s = [] 

@export_category("Rendering")
@export var textureFiltering = false : set = setTextureFiltering 
@export var emmisionBasedLighting = true
@export var useInstanceShaderParam : bool = true
@export var textureFilterSkyBox = false
@export var renderNullTextures = false
@export var mipMaps: MIP = MIP.ON

@export_category("Gameplay")
@export var npcsDisabled = false
@export var difficultyFlags: DIFFICULTY = DIFFICULTY.medium
@export var invisibleWalls: INVISIBLE_WALLS = INVISIBLE_WALLS.enabled

@export_category("Mesh Options")
@export var mergeMesh: MERGE = MERGE.WALLS_AND_FLOOR
@export var meshSimplify = true
@export var unwrapLightmap = true
@export var maxMaterialPerMesh = 4

@export_category("Skybox Settings")
@export var createSurroundingSkybox = true
@export var skyCeil: SKYVIS = SKYVIS.ENABLED
@export var skyWall: SKYVIS = SKYVIS.ENABLED

enum SKYVIS {DISABLED,ENABLED}
@export var generateNav: NAV = NAV.OFF


@export_category("Occllusion Settings")
@export var addOccluder = true
@export var occMin: float = 2.0
@export var occluderBBclip: float = 30
@export var maxOccluderCount: int = 250

@onready var directories = []  # (Array,String,DIR)
@onready var thingSheet : gsheet = null
@onready var typeDict : gsheet = null
@onready var sectorSpecials : Dictionary = {}

var floorMethod = FLOORMETHOD.three
var generateFloorMap = false #unused
@onready var resourceManager : Node = $ResourceManager
@onready var materialManager : Node = $MaterialManager

@export var numberCharDict = {
	37: ["STTPRCNT", Vector2i(0, 0)],
	45: ["STTMINUS", Vector2i(0, 6)],
	48: ["STTNUM0", Vector2i(0, 0)],
	49: ["STTNUM1", Vector2i(0, 0)],
	50: ["STTNUM2", Vector2i(0, 0)],
	51: ["STTNUM3", Vector2i(0, 0)],
	52: ["STTNUM4", Vector2i(0, 0)],
	53: ["STTNUM5", Vector2i(0, 0)],
	54: ["STTNUM6", Vector2i(0, 0)],
	55: ["STTNUM7", Vector2i(0, 0)],
	56: ["STTNUM8", Vector2i(0, 0)],
	57: ["STTNUM9", Vector2i(0, 0)],
}

@export var fontChars = {
	33: ["STCFN033", Vector2i(0, 0)],
	34: ["STCFN034", Vector2i(0, 0)],
	35: ["STCFN035", Vector2i(0, 0)],
	36: ["STCFN036", Vector2i(0, 0)],
	37: ["STCFN037", Vector2i(0, 0)],
	38: ["STCFN038", Vector2i(0, 0)],
	39: ["STCFN039", Vector2i(0, 0)],
	40: ["STCFN040", Vector2i(0, 0)],
	41: ["STCFN041", Vector2i(0, 0)],
	42: ["STCFN042", Vector2i(0, 0)],
	43: ["STCFN043", Vector2i(2, 2)],
	44: ["STCFN044", Vector2i(0, 0)],
	45: ["STCFN045", Vector2i(0, 4)],
	46: ["STCFN046", Vector2i(0, 8)],
	47: ["STCFN047", Vector2i(0, 0)],
	48: ["STCFN048", Vector2i(0, 0)],
	49: ["STCFN049", Vector2i(0, 0)],
	50: ["STCFN050", Vector2i(0, 0)],
	51: ["STCFN051", Vector2i(0, 0)],
	52: ["STCFN052", Vector2i(0, 0)],
	53: ["STCFN053", Vector2i(0, 0)],
	54: ["STCFN054", Vector2i(0, 0)],
	55: ["STCFN055", Vector2i(0, 0)],
	56: ["STCFN056", Vector2i(0, 0)],
	57: ["STCFN057", Vector2i(0, 0)],
	58: ["STCFN058", Vector2i(0, 0)],
	59: ["STCFN059", Vector2i(0, 0)],
	60: ["STCFN060", Vector2i(0, 0)],
	61: ["STCFN061", Vector2i(0, 2)],
	62: ["STCFN062", Vector2i(0, 0)],
	63: ["STCFN063", Vector2i(0, 0)],
	64: ["STCFN064", Vector2i(0, 0)],
	65: ["STCFN065", Vector2i(0, 0)],
	66: ["STCFN066", Vector2i(0, 0)],
	67: ["STCFN067", Vector2i(0, 0)],
	68: ["STCFN068", Vector2i(0, 0)],
	69: ["STCFN069", Vector2i(0, 0)],
	70: ["STCFN070", Vector2i(0, 0)],
	71: ["STCFN071", Vector2i(0, 0)],
	72: ["STCFN072", Vector2i(0, 0)],
	73: ["STCFN073", Vector2i(0, 0)],
	74: ["STCFN074", Vector2i(0, 0)],
	75: ["STCFN075", Vector2i(0, 0)],
	76: ["STCFN076", Vector2i(0, 0)],
	77: ["STCFN077", Vector2i(0, 0)],
	78: ["STCFN078", Vector2i(0, 0)],
	79: ["STCFN079", Vector2i(0, 0)],
	80: ["STCFN080", Vector2i(0, 0)],
	81: ["STCFN081", Vector2i(0, 0)],
	82: ["STCFN082", Vector2i(0, 0)],
	83: ["STCFN083", Vector2i(0, 0)],
	84: ["STCFN084", Vector2i(0, 0)],
	85: ["STCFN085", Vector2i(0, 0)],
	86: ["STCFN086", Vector2i(0, 0)],
	87: ["STCFN087", Vector2i(0, 0)],
	88: ["STCFN088", Vector2i(0, 0)],
	89: ["STCFN089", Vector2i(0, 0)],
	90: ["STCFN090", Vector2i(0, 0)],
	91: ["STCFN091", Vector2i(0, 0)],
	92: ["STCFN092", Vector2i(0, 0)],
	93: ["STCFN093", Vector2i(0, 0)],
	94: ["STCFN094", Vector2i(0, 0)],
	95: ["STCFN095", Vector2i(0, 8)],
	97: ["STCFN065", Vector2i(0, 0)],
	98: ["STCFN066", Vector2i(0, 0)],
	99: ["STCFN067", Vector2i(0, 0)],
	100: ["STCFN068", Vector2i(0, 0)],
	101: ["STCFN069", Vector2i(0, 0)],
	102: ["STCFN070", Vector2i(0, 0)],
	103: ["STCFN071", Vector2i(0, 0)],
	104: ["STCFN072", Vector2i(0, 0)],
	105: ["STCFN073", Vector2i(0, 0)],
	106: ["STCFN074", Vector2i(0, 0)],
	107: ["STCFN075", Vector2i(0, 0)],
	108: ["STCFN076", Vector2i(0, 0)],
	109: ["STCFN077", Vector2i(0, 0)],
	110: ["STCFN078", Vector2i(0, 0)],
	111: ["STCFN079", Vector2i(0, 0)],
	112: ["STCFN080", Vector2i(0, 0)],
	113: ["STCFN081", Vector2i(0, 0)],
	114: ["STCFN082", Vector2i(0, 0)],
	115: ["STCFN083", Vector2i(0, 0)],
	116: ["STCFN084", Vector2i(0, 0)],
	117: ["STCFN085", Vector2i(0, 0)],
	118: ["STCFN086", Vector2i(0, 0)],
	119: ["STCFN087", Vector2i(0, 0)],
	120: ["STCFN088", Vector2i(0, 0)],
	121: ["STCFN089", Vector2i(0, 0)],
	122: ["STCFN090", Vector2i(0, 0)]
}



@export var fontCharsHexen = {
	33: ["FONTA01", Vector2i(0, 0)],
	34: ["FONTA02", Vector2i(0, 0)],
	35: ["FONTA03", Vector2i(0, 0)],
	36: ["FONTA04", Vector2i(0, 0)],
	37: ["FONTA05", Vector2i(0, 0)],
	38: ["FONTA06", Vector2i(0, 0)],
	39: ["FONTA07", Vector2i(0, 0)],
	40: ["FONTA08", Vector2i(0, 0)],
	41: ["FONTA09", Vector2i(0, 0)],
	42: ["FONTA10", Vector2i(0, 0)],
	43: ["FONTA11", Vector2i(0, 0)],
	44: ["FONTA12", Vector2i(0, 0)],
	45: ["FONTA13", Vector2i(0, 0)],
	46: ["FONTA14", Vector2i(0, 0)],
	47: ["FONTA15", Vector2i(0, 0)],
	48: ["FONTA16", Vector2i(0, 0)],
	49: ["FONTA17", Vector2i(0, 0)],
	50: ["FONTA18", Vector2i(0, 0)],
	51: ["FONTA19", Vector2i(0, 0)],
	52: ["FONTA20", Vector2i(0, 0)],
	53: ["FONTA21", Vector2i(0, 0)],
	54: ["FONTA22", Vector2i(0, 0)],
	55: ["FONTA23", Vector2i(0, 0)],
	56: ["FONTA24", Vector2i(0, 0)],
	57: ["FONTA25", Vector2i(0, 0)],
	58: ["FONTA26", Vector2i(0, 0)],
	59: ["FONTA27", Vector2i(0, 0)],
	60: ["FONTA28", Vector2i(0, 0)],
	61: ["FONTA29", Vector2i(0, 0)],
	62: ["FONTA30", Vector2i(0, 0)],
	63: ["FONTA31", Vector2i(0, 0)],
	97: ["FONTAY33", Vector2i(0,0)],
	98: ["FONTAY34", Vector2i(0, 0)],
	99: ["FONTAY35", Vector2i(0, 0)],
	100: ["FONTAY36", Vector2i(0, 0)],
	101: ["FONTAY37", Vector2i(0, 0)],
	102: ["FONTAY38", Vector2i(0, 0)],
	103: ["FONTAY39", Vector2i(0, 0)],
	104: ["FONTAY40", Vector2i(0, 0)],
	105: ["FONTAY41", Vector2i(0, 0)],
	106: ["FONTAY42", Vector2i(0, 0)],
	107: ["FONTAY43", Vector2i(0, 0)],
	108: ["FONTAY44", Vector2i(0, 0)],
	109: ["FONTAY45", Vector2i(0, 0)],
	110: ["FONTAY46", Vector2i(0, 0)],
	111: ["FONTAY47", Vector2i(0, 0)],
	112: ["FONTAY48", Vector2i(0, 0)],
	113: ["FONTAY49", Vector2i(0, 0)],
	114: ["FONTAY50", Vector2i(0, 0)],
	115: ["FONTAY51", Vector2i(0, 0)],
	116: ["FONTAY52", Vector2i(0, 0)],
	117: ["FONTAY53", Vector2i(0, 0)],
	118: ["FONTAY54", Vector2i(0, 0)],
	119: ["FONTAY55", Vector2i(0, 0)],
	120: ["FONTAY56", Vector2i(0, 0)],
	121: ["FONTAY57", Vector2i(0, 0)],
	122: ["FONTAY58", Vector2i(0, 0)]
}



@export var fontHexenMenu = {
33: ["FONTB01", Vector2i(0, 0)],
	34: ["FONTB02", Vector2i(0, 0)],
	35: ["FONTB03", Vector2i(0, 0)],
	36: ["FONTB04", Vector2i(0, 0)],
	37: ["FONTB05", Vector2i(0, 0)],
	38: ["FONTB06", Vector2i(0, 0)],
	39: ["FONTB07", Vector2i(0, 0)],
	40: ["FONTB08", Vector2i(0, 0)],
	41: ["FONTB09", Vector2i(0, 0)],
	42: ["FONTB10", Vector2i(0, 0)],
	43: ["FONTB11", Vector2i(0, 0)],
	44: ["FONTB12", Vector2i(0, 0)],
	45: ["FONTB13", Vector2i(0, 0)],
	46: ["FONTB14", Vector2i(0, 0)],
	47: ["FONTB15", Vector2i(0, 0)],
	48: ["FONTB16", Vector2i(0, 0)],
	49: ["FONTB17", Vector2i(0, 0)],
	50: ["FONTB18", Vector2i(0, 0)],
	51: ["FONTB19", Vector2i(0, 0)],
	52: ["FONTB20", Vector2i(0, 0)],
	53: ["FONTB21", Vector2i(0, 0)],
	54: ["FONTB22", Vector2i(0, 0)],
	55: ["FONTB23", Vector2i(0, 0)],
	56: ["FONTB24", Vector2i(0, 0)],
	57: ["FONTB25", Vector2i(0, 0)],
	58: ["FONTB26", Vector2i(0, 0)],
	59: ["FONTB27", Vector2i(0, 0)],
	60: ["FONTB28", Vector2i(0, 0)],
	61: ["FONTB29", Vector2i(0, 0)],
	62: ["FONTB30", Vector2i(0, 0)],
	63: ["FONTB31", Vector2i(0, 0)],
	97: ["FONTB33", Vector2i(0,0)],
	98: ["FONTB34", Vector2i(0, 0)],
	99: ["FONTB35", Vector2i(0, 0)],
	100: ["FONTB36", Vector2i(0, 0)],
	101: ["FONTB37", Vector2i(0, 0)],
	102: ["FONTB38", Vector2i(0, 0)],
	103: ["FONTB39", Vector2i(0, 0)],
	104: ["FONTB40", Vector2i(0, 0)],
	105: ["FONTB41", Vector2i(0, 0)],
	106: ["FONTB42", Vector2i(0, 0)],
	107: ["FONTB43", Vector2i(0, 0)],
	108: ["FONTB44", Vector2i(0, 0)],
	109: ["FONTB45", Vector2i(0, 0)],
	110: ["FONTB46", Vector2i(0, 0)],
	111: ["FONTB47", Vector2i(0, 0)],
	112: ["FONTB48", Vector2i(0, 0)],
	113: ["FONTB49", Vector2i(0, 0)],
	114: ["FONTB50", Vector2i(0, 0)],
	115: ["FONTB51", Vector2i(0, 0)],
	116: ["FONTB52", Vector2i(0, 0)],
	117: ["FONTB53", Vector2i(0, 0)],
	118: ["FONTB54", Vector2i(0, 0)],
	119: ["FONTB55", Vector2i(0, 0)],
	120: ["FONTB56", Vector2i(0, 0)],
	121: ["FONTB57", Vector2i(0, 0)],
	122: ["FONTB58", Vector2i(0, 0)]
}


var configToThings  : Dictionary= {
	"Doom" : ["res://addons/godotWad/resources/things.tres"],
	"Hexen": ["res://addons/godotWad/resources/hexenThings.tres"],
	"Hexen Mod": ["res://addons/godotWad/resources/hexenThings.tres"],
	"SRBC" : ["res://addons/godotWad/resources/things.tres","res://addons/godotWad/scenes/srb/srbc/srbcThings.tres"],
	"fallback" : ["res://addons/godotWad/resources/things.tres"],
} 

var configToEntites : Dictionary ={
	"Doom" : ["res://addons/godotWad/resources/weapons.tres"],
	"Hexen": ["res://addons/godotWad/resources/weaponsHexen.tres"],
	"Hexen Mod": ["res://addons/godotWad/resources/weaponsHexen.tres"],
	"fallback":["res://addons/godotWad/resources/weapons.tres"],
}

var configToLineTypes  : Dictionary= {
	"Doom" : ["res://addons/godotWad/resources/lineTypes.tres"],
	"Hexen" : ["res://addons/godotWad/resources/lineTypesHexen.tres"],
	"Hexen Mod": ["res://addons/godotWad/resources/lineTypesHexen.tres"],
	"fallback" : ["res://addons/godotWad/resources/lineTypes.tres"],
	"SRBC" : ["res://addons/godotWad/resources/lineTypes.tres","res://addons/godotWad/resources/lineTypesSRBC.tres"],
}

var configToSectorSpecial : Dictionary = {
	"Doom" : ["res://addons/godotWad/resources/sectorSpecials.tres"],
	"fallback" : ["res://addons/godotWad/resources/sectorSpecials.tres"]
}

var configTo

var mapThread
var saveThread : Thread 
var resourceThread
var assetsDone = false
var tailPrimed = false
var mapName  = "E1M1"


func _ready():
	
	if  RenderingServer.get_rendering_device() == null:
		useInstanceShaderParam = false
	
	var e = resourceManager.connect("fileWaitDone", Callable(self, "fileWaitDone"))
	var musicList  = load("res://addons/godotWad/resources/songMap.tres").getAsDict()
	
	for mapName : String in musicList.keys():
		mapToMusic[mapName] = musicList[mapName]["0"]
	
	options = load("res://addons/godotWad/loaderOptions.tscn").instantiate()
	
	if options != null:
		options.target = self
	

	if !Engine.is_editor_hint():
		EGLO.registerConsoleCommands(get_tree(),"res://addons/godotWad/commandLine.gd")

func fileWaitDone():
	emit_signal("fileWaitDoneSignal")


var ui = null
func createMapThread(mapName,threaded):
	self.ui = ui
	if mapThread != null:
		mapThread.wait_to_finish()
	mapThread = Thread.new()
	self.threaded = threaded
	mapThread.start(Callable(self, "createMap").bind(mapName), Thread.PRIORITY_HIGH)

var trueTotalStart 

func getOptions():
	return options
	#return load("res://addons/godotWad/loaderOptions.tscn").instance()

func createMapPreview(mapName,metaData : Dictionary = {},reloadWads : bool= false, cacheParent : Node = null):
	

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
	
	metaData["collision"] = false
	var map = createMap(mapName,metaData,true,cacheParent)
	
	
	
	
	skyCeil =  iSkyCeil
	skyWall = iSkyWall
	addOccluder = iaddOccluder
	meshSimplify = imeshSimplify
	mergeMesh = imergeMesh
	
	return map
	

func createMapBlank(mapName,metaData : Dictionary = {},reloadWads = true) -> Node3D:
	metaData["blankMap"] = true
	return createMap(mapName,metaData,reloadWads)


func createMap(mapName,metaData : Dictionary = {},reloadWads = true,cacheParent : Node = null) -> Node3D:
	
	var startTime = Time.get_ticks_msec()
	
	if metaData.has("reloadWads"):
		reloadWads = metaData["reloadWads"]
	

	trueTotalStart = startTime
	resourceManager.waitingForFiles = []
	
	thingCheck(wads)
	
	if wadInit == false:
		reloadWads = true
	
	self.mapName = mapName

	
	mapNode = Node3D.new()
	
	
	var wadLoadTime = Time.get_ticks_msec()
	var t1 = Time.get_ticks_msec()
	
	if reloadWads:#this is only false when you are changing from one level to another
		loadWads()
	
	loadDirs(directories)
	
	SETTINGS.setTimeLog(get_tree(),"wad load time",wadLoadTime)
	
	
	if colorMaps.size() == 0:
		$"LumpParser".parseColorMapDummy()
	
	
	var allMaps : PackedStringArray = []
	var caseSensIdx = []
	var parsedMaps = 0
	
	for i in maps.keys():
		allMaps.append(i.to_lower())
		caseSensIdx.append(i)


	if !allMaps.has(mapName) and !maps.has(mapName):
		print("map name ",mapName," not found")
		return
	
	if !maps.has(mapName):
		for i in maps.keys():
			if i.to_lower() == mapName.to_lower():
				mapName = i
				break
	
	var targetMap = maps[mapName]
	

	var mapParseStart = Time.get_ticks_msec()

	$"LumpParser".parseMap(targetMap)
	
	targetMap["name"] = mapName
	SETTINGS.setTimeLog(get_tree(),"parseMap",mapParseStart)
	
	
	
	var postProcStart = Time.get_ticks_msec()
	$"LumpParser".postProc(targetMap)
	SETTINGS.setTimeLog(get_tree(),"postProcTime",postProcStart)
	SETTINGS.setTimeLog(get_tree(),"createMapPre",startTime)
	
	

	return createMapTail(metaData,cacheParent)
	

func createMapTail(metaData : Dictionary,cacheParent = null):
	
	
	
	var startTime : int  = Time.get_ticks_msec()
	var fme : Dictionary = $LumpParser.flatMatEntries
	var wme : Dictionary =  $LumpParser.wallMatEntries
	
	
	
	var tailFetchStart : int = Time.get_ticks_msec()
	
	if Engine.is_editor_hint():
		for textureName in fme.keys():
			for textureEntry in fme[textureName]:#each mat param of a given texture
				var lightLevel : int = textureEntry[0]
				var scrollVector : Vector2 = textureEntry[1]
				var alpha : int = textureEntry[2]
				resourceManager.fetchFlat(textureName)
				

		for textureName in wme.keys():
			for textureEntry in wme[textureName]:#each mat param of a given texture
				var lightLevel : int = textureEntry[0]
				var scrollVector = textureEntry[1]
				var alpha = textureEntry[2]
				var texture =resourceManager.fetchPatchedTexture(textureName)
			
#
	
		SETTINGS.setTimeLog(get_tree(),"tailFetching",tailFetchStart)
		
		
		var texName : String = $ImageBuilder.getSkyboxTextureForMap(mapName) 
		materialManager.fetchSkyMat(texName,true)
	
	if !maps.has(mapName):
		for i in maps.keys():
			if i.to_lower() == mapName.to_lower():
				mapName = i
				break
	
	maps[mapName]["createSurroundingSkybox"] = createSurroundingSkybox
	
	
	var a = Time.get_ticks_msec()
	
	hasCollision = true
	
	if metaData.has("collision"):
		hasCollision = metaData["collision"]
	
	$"LevelBuilder".createLevel(maps[mapName],mapName,mapNode,hasCollision)
	SETTINGS.setTimeLog(get_tree(),"levelBuilder",startTime)
	#print("create level time:",Time.get_ticks_msec()-a)
	a = Time.get_ticks_msec()
	
	
	mapNode.set_script(load("res://addons/godotWad/src/levelNode.gd"))
	mapNode.mapName = mapName.to_lower()
	mapNode.gameName = gameName
	
	var targetSong = ""
	
	if mapToMusic.has(mapName):
		targetSong = mapToMusic[mapName]
	elif musList.keys().size() > 0:
		targetSong = musList.keys()[0]
	
	
	if !toDisk:
		var data = resourceManager.fetchMidiOrMus(targetSong)
		if data != null:
			mapNode.rawMidiData = data
	else:
		resourceManager.fetchMus(targetSong)
		mapNode.midiPath = WADG.destPath+gameName+"/music/midi/"+targetSong+".mid"
	
	
	a = Time.get_ticks_msec() 
	get_parent().add_child(mapNode)
	#print("ready times:",Time.get_ticks_msec()-a)
	
	mapNode.set_owner(get_parent())


	for c in mapNode.get_children():
		if c.name != "Surrounding Skybox":
			c.set_owner(mapNode)
			recursiveOwn(c,mapNode)
	
	
	a = Time.get_ticks_msec()
	
	#print("pre create things")
	
	if !metaData.has("blankMap"):
		thingParser.createThings(maps[mapName]["thingsParsed"],cacheParent)
	else:
		var entityNode : Node3D = Node3D.new()
		entityNode.name = "Entities"
		mapNode.add_child(entityNode)

	
	#if !Engine.is_editor_hint():
	#	ENTG.clearEntityCaches(get_tree())

	
	#SETTINGS.setTimeLog(get_tree(),"thing creation",a)
	
	#for i in maps[mapName]:
		#if i.find("Parsed") != -1:
			#maps[mapName][i] = null
			#maps[mapName].erase(i)
			#
	emit_signal("mapCreated") #//needed
	
	
	#SETTINGS.setTimeLog(get_tree(),"createMapTail",startTime)
	#SETTINGS.setTimeLog(get_tree(),"total",trueTotalStart)
	
	
	#printTimings()
	return mapNode

func initialize(wadArr,config,gameName):
	self.config = config

	thingSheet = null
	typeDict = null

	if configToThings.has(config):
		for i in configToThings[config]:
			addThingsDict(load(i))
	else:
		for i in configToThings["fallback"]:
			addThingsDict(load(i))
	
	
	
	
	if configToLineTypes.has(config):
		for i in configToLineTypes[config]:
			var dict = load(i)
			addTypesDict(load(i))
	else:
		for i in configToLineTypes["fallback"]:
			var dict = load(i)
			addTypesDict(load(i))
			
	
	
	
	if configToSectorSpecial.has(config):
		for i in configToSectorSpecial[config]:
			sectorSpecials.merge(load(i).getAsDict(true),false)
	else:
		for i in configToSectorSpecial["fallback"]:
			sectorSpecials.merge(load(i).getAsDict(true),false)
	#if idxToErase != -1:
	#	wadArr.remove_at(idxToErase)
	params = [wadArr,gameName]
	self.gameName = gameName
	
	if gameName.substr(0,5) == "hexen":
		isHexen = true
	
	thingCheck(wadArr)
	wads = wadArr
	
	for i : String in wads:
		
		if i.right(1) == "/":
			directories.append(i)
		
		if DirAccess.dir_exists_absolute(i):
			directories.append(i + "/")
		
		if i.get_extension() == "pk3":
			directories.append(i)
	
	
	
	
	var entitySheetsToLoad : Array = []
	
	if configToEntites.has(config):
		entitySheetsToLoad = configToEntites[config]
	else: 
		entitySheetsToLoad = configToEntites["fallback"]
	
	thingParser.initThingDirectory(thingSheet,entitySheetsToLoad)
	
	
	maps = {}
	info["maps"] = maps.keys()
	info["entities"] =thingParser.entityDirectory.keys()

	#;ENTG.createEntityCacheForGame(get_tree(),toDisk,gameName,self,mapNode)
	loadWads()
	
	

func getCreatorScript():
	return thingParser

func spawn(idStr : String, pos = Vector3.ZERO, rot = 0, parentNode : Node = null) -> Node:
	if parentNode == null:
		parentNode = mapNode
		
	return ENTG.spawn(get_tree(),idStr,pos,Vector3(0,rot,0),"doom",parentNode)
	#return $ThingParser.spawn(idStr,pos,Vector3(0,rot-90,0))


func thingCheck(wadArr):
	if gameName == "Doom64":
		is64 = true
	else:
		is64 = false
	

var pLoadedWads = []

func loadWads():
	
	var sameWadsAsLastTime = true
	
	if pLoadedWads.size() == wads.size():
		for i in wads.size():
			if wads[i] != pLoadedWads[i]:
				sameWadsAsLastTime = false
	else:
		sameWadsAsLastTime = false
		
	
	if sameWadsAsLastTime:
		return
	
	if !Engine.is_editor_hint():
		toDisk = false
	
	#if wadInit == false:
	for wad : String in wads:
		
		if wad.is_empty():
			continue
		
		if wad.get_extension() == "roo":
			loadRoo(wad)
		var a = Time.get_ticks_msec()
		loadWAD(wad)
	#	print("load wad timne:",Time.get_ticks_msec()-a)
		
	
	info["maps"] = []
	
	wadInit = true
	pLoadedWads = wads
	ENTG.createEntityCacheForGame(get_tree(),toDisk,gameName,self,mapNode)

	
func loadDirs(dirs):
	for d in dirs:
		loadDir(d)
	

func dirFileList(path):
	var files = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547

	while true:
		var file = dir.get_next()
		if file == "":
			break
		#elif not file.begins_with("."):
		files.append(file)

	dir.list_dir_end()

	return files

func zipFileList(path : String, zip : ZIPReader) -> PackedStringArray:
	var ret : PackedStringArray = []
	
	var reader := zip
	var err = reader.open(path)
	
	if err != OK:
		return ret
	
	var files = reader.get_files()
	
	
	for i : String in files:
		if i.count("/") == 0:
			ret.append(i)
		
		if i.count("/") == 1:
			var dir = i.split("/")[0]
			if !ret.has(dir):
				ret.append(dir)
		
	
	
	return ret

func zipGetFilesInDir(zip : ZIPReader, dir : StringName) -> PackedStringArray:
	var ret : PackedStringArray = []
	
	
	var files := zip.get_files()
	
	for filePath : String in files:
		
		if filePath == dir:
			continue
		
		if filePath.begins_with(dir):
			ret.append(filePath)
	
	return ret

func loadDir(dirPath : String):
	var a = Time.get_ticks_msec()
	var files : PackedStringArray= []
	var zip : ZIPReader = null
	if dirPath.get_extension() == "pk3":
		zip = ZIPReader.new()
		files = zipFileList(dirPath,zip)
		
		
	else:
		files = dirFileList(dirPath)
	
	
	for f in files:
		var fLower : String = f.to_lower()
		var ext = f.get_extension()
		
		if ext == &"jpg" or ext == &"png":
			resourceManager.fetchTextureFromFile(dirPath + "/" +f)
		
		elif fLower == &"texture1.lump":
			var file = FileAccess.open(dirPath+f,FileAccess.READ)
			if !zip:
				$LumpParser.parseTextureLump(["",file,0,file.get_length()])
			else:
				$LumpParser.parseTextureLumpZip(zip,f)
				#$LumpParser.parseTextureLump(["",file,0,file.get_length()])
		
		elif fLower == "pnames.lump":
			var file: = FileAccess.open(dirPath+f,FileAccess.READ)
			if !zip:
				$LumpParser.parsePatchNames(["",file,0,file.get_length()])
			else:
				$LumpParser.parsePatchNamesZip(zip,f)
		
		elif fLower == "maps":
			var mapDir = f
			if !zip:
				for mapFile : String in WADG.getAllFlat(dirPath+mapDir):
					if mapFile.get_extension() == "wad" or  mapFile.get_extension() == "WAD":
						var file = FileAccess.open(mapFile,FileAccess.READ)
						var mapName = mapFile.get_file().split(".")[0].to_upper()
						mapFileParse(file,mapName)
			else:
				for mapFile : String in zipGetFilesInDir(zip,mapDir+"/"):
					if mapFile.get_extension() == &"wad" or  mapFile.get_extension() == &"WAD":
						mapFileParseZip(zip,mapFile)
						
				
		
		elif fLower == "flats":
			if !zip:
				for flatFile : String in WADG.getAllFlat(dirPath+f):
					if flatFile.get_extension() == "png":
						flatTextureEntries[flatFile.get_file().split(".")[0].to_upper()] = flatFile
			else:
				for patchFile : String in zipGetFilesInDir(zip,f + "/"):
					if patchFile.get_extension() == "png":
						var patchName = patchFile.get_file().split(".")[0].to_upper()
						flatTextureEntries[patchName] = dirPath+"/"+patchFile
		elif fLower == "patches":
			if !zip:
				for patchFile : String in WADG.getAllFlat(dirPath+f):
					if patchFile.get_extension() == "png":
						var patchName = patchFile.get_file().split(".")[0].to_upper()
						flatTextureEntries[patchName] = patchFile
				
			else:
				for patchFile : String in zipGetFilesInDir(zip,"patches/"):
					if patchFile.get_extension() == "png":
						var patchName = patchFile.get_file().split(".")[0].to_upper()
						patchTextureEntries[patchName] = dirPath+"/"+patchFile
		elif fLower == "textures":
			for patchFile : String in zipGetFilesInDir(zip,f+"/"):
				if patchFile.get_extension() == "png":
					var patchName = patchFile.get_file().split(".")[0].to_upper()
					patchTextureEntries[patchName] = dirPath+"/"+patchFile
				

	SETTINGS.setTimeLog(get_tree(),"loadDir",a)
		
			

func mapFileParse(file,mapName):
	var magic = file.get_buffer(4).get_string_from_ascii()
	var numLumps = file.get_32()
	var directoryOffset = file.get_32()
	var mapLumps : Dictionary = {}
	file.seek(directoryOffset)
	
	
	for i in numLumps:
		var offset = file.get_32()
		var size = file.get_32()
		var name =file.get_buffer(8).get_string_from_ascii()

		mapLumps[name] = {"file":file,"offset":offset,"size":size}
	
	maps[mapName] = mapLumps


func mapFileParseZip(zip : ZIPReader,path : String):
	#var a = Time.get_ticks_msec()
	var bytes : PackedByteArray = zip.read_file(path)
	var curPos : int = 0
	var magic = bytes.slice(curPos,curPos+4).get_string_from_ascii()
	curPos += 4
	
	var numLumps = bytes.decode_u32(curPos)
	curPos += 4
	var directoryOffset = bytes.decode_u32(curPos)
	curPos = directoryOffset
	
	var mapName : StringName = path.get_file().split(".")[0].to_upper()
	var mapLumps : Dictionary = {}
	
	
	for i in numLumps:
		var offset = bytes.decode_u32(curPos)
		curPos += 4
		var size = bytes.decode_u32(curPos)
		curPos += 4
		var lumpName = bytes.slice(curPos,curPos+8).get_string_from_ascii().to_upper()
		curPos += 8
		
		mapLumps[lumpName] = {"zip":[zip,path],"offset":offset,"size":size}
	
	maps[mapName] = mapLumps
	#SETTINGS.setTimeLog(get_tree(),"mapFileParseZip",a)


func pluginFetchNames():
	
	var mapNames = []
	maps = {}
	clear()
	for wad in wads:
		if wad.is_empty():
			continue
		
		var localmapNames = fetchmapNamesDirOrWad(wad)
		for mapName in localmapNames:
			if !mapNames.has(mapName):
				mapNames.append(mapName)
				
	return mapNames
		

func fetchmapNamesDirOrWad(path):
	
	
	if DirAccess.dir_exists_absolute(path):
		if DirAccess.dir_exists_absolute(path + "/maps"):
			var all = WADG.getAllFlat(path + "/maps")
			var maps = []
			
			for map : String in all:
				if map.get_extension().to_lower() == "wad":
					maps.append(map.get_file())
			
			
			return maps
		else:
			return []
	
	
	file = FileAccess.open(path,FileAccess.READ)
	
	if file == null:
		return
	
	#
	
	var magic : String = file.get_buffer(4).get_string_from_ascii()
	var numLumps : int = file.get_32()
	var directoryOffset : int = file.get_32()
	
	
	
	file.seek(directoryOffset)

	getAllLumps(file,numLumps)
	$"LumpParser".populateMapDict(lumps)
	return maps.keys()
	
	#var isUDMF = isUDMF()
	
	#if !isUDMF:
	#	$"LumpParser".parseLumps(lumps)
	#	return maps
	#else:
	#	$"LumpParser".parseLumps(lumps)
	#	if lumps[0].has("name"):
	#		return [lumps[0]["name"]]
	#	else:
	#		return []
	
	

func loadWAD(path : StringName):
	if path.find(".") == -1:
		parseDir(path)
	

	file = FileAccess.open(path,FileAccess.READ)
	
	if  file == null:
	#if file.loadFile(path) == false:
		print("file:",path," not found")
		return
	
	#var isUDMF = isUDMF()
	var magic = file.get_buffer(4).get_string_from_ascii()
	var numLumps = file.get_32()
	var directoryOffset = file.get_32()
	
	
	file.seek(directoryOffset)
	var a = Time.get_ticks_msec()
	$"LumpParser".parseLumps(lumps,isHexen)
	if path.get_extension().to_upper() != "PK3":
		getAllLumps(file,numLumps)

	var isUDMF = isUDMF()
	
	

	$"LumpParser".parseLumps(lumps,isHexen)
		
	#else:#it's UDMF we add the map of that umdf to the maplist
		#var curMap = {"isTextmap":true}
		#$"LumpParser".parseLumps(lumps)
		#curMap =  $"LumpParser".textMap
		#maps[curMap[0]] = curMap[1]
		
	

func getAllLumps(file,numLumps):
	
	if !fileLookup.has(file):
		fileLookup.append(file)
	
	var curFileIndex = fileLookup.find(file)
	
	var lump_size = 4 + 4 + 8  # 4 bytes for offset, 4 bytes for size, 8 bytes for name
	var totalSize = numLumps * lump_size
	var pPost = file.get_position()
	var buffer: PackedByteArray =  file.get_buffer(totalSize)
	#file.seek(pPost)
#
	#
	for i in range(numLumps):
		var base_index = i * lump_size
		var offset = buffer.decode_u32(base_index)
		var size = buffer.decode_u32(base_index + 4)
		var name = buffer.slice(base_index + 8, base_index + 16).get_string_from_ascii()
		lumps.append([name, curFileIndex, offset, size])


	
	#for i in numLumps:
		#var offset = file.get_32()
		#var size = file.get_32()
		#var name : StringName =file.get_buffer(8).get_string_from_ascii()

		#lumps.append([name,curFileIndex,offset,size])
	
	
	#var curPost = file.get_position()
	#breakpoint
	

func sortLumps():
	var numLumps = lumps.size()
	var lumpIdx = 0
	var key = lumpIdx
	
	while lumpIdx < numLumps:#for each lump
		var lumpName = lumps[lumpIdx][LUMP.name]
		if lumpName.length()<3:#if lump name is less than 3 we its not a map lump
			lumpIdx += 1
			continue
			
		if (lumpName[0] == "E" and lumpName[2] == "M") or lumpName.substr(0,3) == "MAP":#we have a new map lump at lumpIdx
			lumpIdx = sortMapLumps(lumpIdx)
			continue

		lumpIdx += 1

func sortMapLumps(idx):
	var mapInfos = ["THINGS","LINEDEFS","SIDEDEFS","VERTEXES","SEGS","SSECTORS","NODES","SECTORS","REJECT","BLOCKMAP","BEHAVIOR","SCRIPTS"]
	var mapName : String =  lumps[idx][LUMP.name]#we go to the lump index of map name
	var curMap : Dictionary = {}
	idx += 1
	
	var numLumps = lumps.size()
	while(idx < numLumps):#from map index to to last lump index (usually we will just terminate once we find a lump thats not in the mapInfos)
		var lumpName = lumps[idx][LUMP.name]
		if mapInfos.has(lumpName):
			curMap[lumpName] =  {"file":lumps[idx][LUMP.file],"offset":lumps[idx][LUMP.offset],"size":lumps[idx][LUMP.size]}
			idx +=1 
		else:
			maps[mapName] = curMap
			return idx#no longer reading nodes that pertain to the map
	
	maps[mapName] = curMap
	return idx


func waitForDirToExist(path):
	var waitThread = Thread.new()
	
	waitThread.start(Callable(self, "waitForDirToExistTF").bind(path))
	waitThread.wait_to_finish()
	
func waitForDirToExistTF(path):
	var dir = DirAccess.open(path)
	while !dir.dir_exists(path):
		OS.delay_msec(10)
		

func createGameMode(curEntTxt,curMeta,curConfig,curGameName):
	var mode = $gameModeCreator.createGameMode(curEntTxt,curMeta,curConfig,curGameName)
	return mode

func createGameModePreview(path,meta):
	return $gameModeCreator.createGameModePreview(path,meta)

func waitForResourceToExist(resPath):
	var waitThread = Thread.new()
	waitThread.start(Callable(self, "waitForResourceToExistTF").bind(resPath))
	waitThread.wait_to_finish()
	
	

func waitForResourceToExistTF(resPath):
	#var fileE = File.new()
	while !(FileAccess.file_exists(resPath)):
		OS.delay_msec(16.67)
		

func getCredits():
	var creds : PackedStringArray = []
	creds.append("Midi Player: arlez80 - https://bitbucket.org//arlez80//godot-midi-player-g4")
	creds.append("Midi Code: Alan Roe - https://github.com/alan-roe")
	creds.append("Object-inspector: 4d49 - https://github.com/4d49/object-inspector")
	creds.append("Controller Icons Plugin: rsubtil - https://github.com/rsubtil/controller_icons/")
	
	return creds
func saveCurMapAsScene(arr):
	var mapNode = arr[0]
	var mapName = arr[1]
	
	
	recursiveOwn(mapNode,mapNode)
	#var fileE = File.new()
	
	
	
	
	var nodeAsTSCN = PackedScene.new()

	nodeAsTSCN.pack(mapNode)
	
	var resPath =WADG.destPath+gameName+ "/maps/" + mapName +".tscn"
	#var resPath =WADG.destPath+get_parent().gameName+ "/maps/" + mapName +".tscn"
	
	if !FileAccess.file_exists(resPath):
		var dir = DirAccess.open(resPath)
		dir.remove(resPath)
	var err = ResourceSaver.save(resPath,nodeAsTSCN)
	
	
	if !FileAccess.file_exists(resPath):
		print("res path dosent exist waiting...")
		waitForResourceToExist(WADG.destPath+gameName+ "/maps/" + mapName +".tscn")
	#	waitForResourceToExist(WADG.destPath+get_parent().gameName+ "/maps/" + mapName +".tscn")
		
		
	#mapNode.name = "deleted"
	#mapNode.queue_free()
	
	var t = load(WADG.destPath+gameName+ "/maps/" + mapName +".tscn").instantiate()
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
		resourceManager.fetchPatchedTexture(i)
	
	for t in maps[mapName.to_upper()]["thingsParsed"]:
		var type = t["type"]
		
		
		if !thingSheet.hasKey(var_to_str(type)):
			print("type:",type," not found")
			continue
		
		var thingDict =thingSheet.getRow(var_to_str(type))
		
		if thingDict.has("sprites"):
			var sprites = thingDict["sprites"] 
			if sprites != [""]:
				
				if sprites.size() == 1:
					for sprName in sprites:
						resourceManager.fetchDoomGraphic(sprName)
				else:
					resourceManager.fetchAnimatedSimple(sprites[0] + "_anim",sprites)
		
		if thingDict.has("deathSprites"):
			if thingDict["deathSprites"] != [""]:
				for sprName in thingDict["deathSprites"]:
					resourceManager.fetchDoomGraphic(sprName)
		
		
	
	
	var uniqueThings : Array = []
	
	for i in maps[mapName.to_upper()]["thingsParsed"]:
		if !uniqueThings.has(i["type"]):
			uniqueThings.append(i["type"])
	
	var a = Time.get_ticks_msec()
	
	var sl = thingParser.getSpriteList(uniqueThings)

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
		texture =resourceManager.fetchFlat(textureName)
			
	for textureName in wme.keys():
		texture = resourceManager.fetchPatchedTexture(textureName)
		
	if editorInterface!= null:
		resourceManager.waitForFilesToExist(editorInterface)
			
			
	
	for animSprName in sl['animatedSprites']:
		resourceManager.fetchAnimatedSimple(animSprName,sl["animatedSprites"][animSprName])
		
	emit_signal("resDone")
	assetsDone = true

	return


func fetchFromSpriteList(sl):
	
	
	if sl.has("spritesFOV"):
		fovSpriteList = sl["spritesFOV"]
			
			
	for sprName in sl["sprites"]:
		if typeof(sprName) == TYPE_STRING:
			resourceManager.fetchDoomGraphic(sprName)

		
	for sprName in fovSpriteList:
		resourceManager.fetchDoomGraphic(sprName)
		
	for animSprName in sl['animatedSprites']:
		for i in sl["animatedSprites"][animSprName]:
			resourceManager.fetchDoomGraphic(i)

 

func createDirectories():

	
	var directory = DirAccess.open("res://")
	
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
	
	var dirs = thingSheet.getColumn("dest")
	
	thingParser.initThingDirectory()
	
	for i in thingParser.categories:
		#createDirIfNotExist(WADG.destPath+get_parent().gameName+"/entities/" + i,directory)
		createDirIfNotExist(WADG.destPath+gameName+"/entities/" + i,directory)
	
	for i in thingParser.categories:
		#waitForDirToExist(WADG.destPath+get_parent().gameName+"/entities/" + i)
		waitForDirToExist(WADG.destPath+gameName+"/entities/" + i)
	var directoriesToCreate : Array = []
	
	
	for entityEntry in thingParser.thingDirectory.values():
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
	return ["textures","materials","sounds","shaders","sprites","textures/animated","entities","fonts","maps","modes","music/midi","themes"]

func clear():
	wadInit = false
	spriteList = []
	fovSpriteList = []
	lumps = []
	musListPre = {}
	for i in resourceManager.entityC.values():
		i.queue_free()
	
	resourceManager.entityC = {}
	wadInit = false


func delete(node):
	node.name = "deleted"
	node.get_parent().remove_child(node)
	node.queue_free()

	
func isUDMF():
	for lump : Array in lumps:
		if lump[LUMP.name] == "TEXTMAP":
			return true
	
	return false
	#return file.scanForString("TEXTMAP",file.get_length())
#	return file.scanForString("namespace",32)

func parseDir(path):
	var dir = DirAccess.open(path)
	
	if dir.dir_exists("TEXTURES"):
		var t = list_files_in_directory(path +"/TEXTURES")
		for file in t:
			if file.find(".png") != -1:
				breakpoint


func list_files_in_directory(path):
	var files = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.find(".")!= -1:
			files.append(file)

	dir.list_dir_end()

	return files


func getEntityDict():
	return thingParser.getEntityDict()

func getMapNames():
	if maps.is_empty():
		pluginFetchNames()
		
	return maps.keys()

func getEntityInfo(entityName : String):
	
	return thingParser.getEntityInfo(entityName)




func getGameModes(wadArr = [],gameName = "Doom"):
	if wadArr.size() > 0:
		for i in wadArr:
			breakpoint
	


	
func getAllCategories():

	var ent = ENTG.getEntitiesCategorized(get_tree(),gameName)
	var sounds = resourceManager.audioLumps.keys()
	var textures = patchTextureEntries.keys()
	var gameModes = {}
	var music = {"mus":musListPre}
	
	if !midiListPre.is_empty():
		music["midi"] = midiListPre
	
	
	if !config.is_empty():
		if config == "SRBC":
			gameModes = {"main":"res://addons/godotWad/scenes/srb/srbc/SRBCmainMode.tscn"}
	
	if wads.size() > 0:
		if music["mus"].has("D_DM2TTL"):
			gameModes = {"main":"res://addons/godotWad/scenes/gameModes/templates/D2/D2mainMode.tscn"}
		elif music["mus"].has("D_INTRO"):
			gameModes = {"main":"res://addons/godotWad/scenes/gameModes/templates/D1/D1mainMode.tscn"}
		elif isHexen:
			gameModes = {"main":"res://addons/godotWad/scenes/hexen/gameModeHexen.tscn"}
		
	var mainMode = null
	
	if gameModes.has("main"):
		mainMode= gameModes["main"]
	return ["entities","maps","sounds","game modes","music","fonts","textures","themes"]
	#return {"entities":ent,"maps":maps.keys(),"sounds":sounds,"meta":{"main":{"path":mainMode}},"game modes":gameModes,"music":music,"fonts":getFonts(),"textures":getTextures(),"themes":getThemes()}

func getAllEntites():
	var ent = ENTG.getEntitiesCategorized(get_tree(),gameName)
	return ent

func getAllSounds():
	return resourceManager.audioLumps.keys()

func getAllMaps():
	return maps.keys()

func getAllMusic():
	var music = {"mus":musListPre}
	
	if !midiListPre.is_empty():
		music["midi"] = midiListPre
		
	return music
	
func getAllFonts():
	return getFonts()
	
func getAllTextures():
	return getTextures()
	
func getAllGameModes():
	var gameModes = {}
	var music = getAllMusic()
	if !config.is_empty():
		if config == "SRBC":
			gameModes = {"main":"res://addons/godotWad/scenes/srb/srbc/SRBCmainMode.tscn"}
	
	if wads.size() > 0:
		if music["mus"].has("D_DM2TTL"):
			gameModes = {"main":"res://addons/godotWad/scenes/gameModes/templates/D2/D2mainMode.tscn"}
		elif music["mus"].has("D_INTRO"):
			gameModes = {"main":"res://addons/godotWad/scenes/gameModes/templates/D1/D1mainMode.tscn"}
		elif isHexen:
			gameModes = {"main":"res://addons/godotWad/scenes/hexen/gameModeHexen.tscn"}
	
	return gameModes
	
	
func getAllThemes():
	return getThemes()

func fetchEntity(entityStr,tree):
	var entity =  ENTG.fetchEntity(entityStr,tree,gameName,false)
	if entity is Sprite3D:
		breakpoint
	return entity

func createSound(soundStr,meta = {}):
	return resourceManager.fetchSound(soundStr)
	return resourceManager.soundCache[soundStr]

func getFonts() -> Dictionary:
	
	if gameName.substr(0,5) == "hexen":
		return {"default":fontCharsHexen,"numbers":fontCharsHexen,"numbers-grayscale":fontCharsHexen,"menuText":fontHexenMenu}
		
	
	return {"default":fontChars,"numbers":numberCharDict,"numbers-grayscale":numberCharDict}


func getFont(str):
	return getFonts()[str]

func getThemes():
	return {"default":fetchDefaultTheme()}

func fetchDefaultTheme():
	
	var bgColor = Color(0.1294117718935, 0.14901961386204, 0.1803921610117,0.9)
	var foreColor = Color(0.14910000562668, 0.17447499930859, 0.20999999344349)
	#var foreColorHover = Color.GREEN_YELLOW
	var foreColorHover = foreColor.lightened(0.2)
	#var foreColorDisabled = Color.DIM_GRAY
	var foreColorDisabled = foreColor.darkened(0.5)
	var focusBorderThickness = 2
	var focusBorderColor = Color(0.599056661129, 0.00000143188981, 0.00000043317675)
	focusBorderColor = foreColor.lightened(0.2)
	#focusBorderColor.lightened(0.8)
	var highlightColor = Color.PURPLE
	var theme : Theme = Theme.new()
	var styleBox = StyleBoxFlat.new()
	var cornerRadiButton = Vector4(5,5,5,5)
	var cornerRadiTextEdit = Vector4(1,1,1,1)
	var marginLeft = 8
	styleBox.bg_color = bgColor
	var customFont = resourceManager.fetchBitmapFont("default")
	
	if customFont != null:
		theme.default_font = customFont
		#theme.set_font("font","Panel",customFont)
	
	styleBox.corner_radius_top_left = 2
	styleBox.corner_radius_top_right = 2
	styleBox.corner_radius_bottom_left = 2
	styleBox.corner_radius_bottom_right = 2
	styleBox.content_margin_left = marginLeft
	theme.set_stylebox("panel","Panel",styleBox)

	
	var styleBoxFore = StyleBoxFlat.new()
	styleBoxFore.bg_color = foreColor
	#styleBoxFore.corner_detail = 12
	styleBoxFore.corner_radius_top_left = cornerRadiButton.x
	styleBoxFore.corner_radius_top_right = cornerRadiButton.y
	styleBoxFore.corner_radius_bottom_left = cornerRadiButton.z
	styleBoxFore.corner_radius_bottom_right = cornerRadiButton.w
	styleBoxFore.content_margin_left = marginLeft
	theme.set_stylebox("normal","Button",styleBoxFore)
	
	
	var styleBoxForeFocus = StyleBoxFlat.new()
	styleBoxForeFocus.bg_color = foreColor
	styleBoxForeFocus.border_color = focusBorderColor
	styleBoxForeFocus.border_width_top = focusBorderThickness
	styleBoxForeFocus.border_width_bottom = focusBorderThickness
	styleBoxForeFocus.border_width_left = focusBorderThickness
	styleBoxForeFocus.border_width_right = focusBorderThickness
	styleBoxForeFocus.corner_radius_top_left = cornerRadiButton.x
	styleBoxForeFocus.corner_radius_top_right = cornerRadiButton.y
	styleBoxForeFocus.corner_radius_bottom_left = cornerRadiButton.z
	styleBoxForeFocus.corner_radius_bottom_right = cornerRadiButton.w
	styleBoxForeFocus.content_margin_left = marginLeft
	
	theme.set_stylebox("focus","Button",styleBoxForeFocus)
	
	var styleBoxForeHover = StyleBoxFlat.new()
	styleBoxForeHover.bg_color = foreColorHover
	styleBoxForeHover.corner_radius_top_left = cornerRadiButton.x
	styleBoxForeHover.corner_radius_top_right = cornerRadiButton.y
	styleBoxForeHover.corner_radius_bottom_left = cornerRadiButton.z
	styleBoxForeHover.corner_radius_bottom_right = cornerRadiButton.w
	styleBoxForeHover.content_margin_left = marginLeft
	theme.set_stylebox("hover","Button",styleBoxForeHover)
	
	
	
	
	var styleBoxForeDisabled = StyleBoxFlat.new()
	styleBoxForeDisabled.bg_color = foreColorDisabled
	styleBoxForeDisabled.corner_radius_top_left = cornerRadiButton.x
	styleBoxForeDisabled.corner_radius_top_right = cornerRadiButton.y
	styleBoxForeDisabled.corner_radius_bottom_left = cornerRadiButton.z
	styleBoxForeDisabled.corner_radius_bottom_right = cornerRadiButton.w
	theme.set_stylebox("disabled","Button",styleBoxForeDisabled)
	
	
	var styleBoxLineEdit = StyleBoxFlat.new()
	styleBoxLineEdit.bg_color = foreColor
	styleBoxLineEdit.border_color = focusBorderColor
	styleBoxLineEdit.corner_radius_top_left = cornerRadiTextEdit.x
	styleBoxLineEdit.corner_radius_top_right = cornerRadiTextEdit.y
	styleBoxLineEdit.corner_radius_bottom_left = cornerRadiTextEdit.z
	styleBoxLineEdit.corner_radius_bottom_right = cornerRadiTextEdit.w
	theme.set_stylebox("normal","LineEdit",styleBoxLineEdit)
	
	var styleBoxForeLineEditFocus = StyleBoxFlat.new()
	styleBoxForeLineEditFocus.bg_color = foreColor
	styleBoxForeLineEditFocus.border_color = focusBorderColor
	styleBoxForeLineEditFocus.border_width_top = focusBorderThickness
	styleBoxForeLineEditFocus.border_width_bottom = focusBorderThickness
	styleBoxForeLineEditFocus.border_width_left = focusBorderThickness
	styleBoxForeLineEditFocus.border_width_right = focusBorderThickness
	styleBoxForeLineEditFocus.corner_radius_top_left = cornerRadiTextEdit.x
	styleBoxForeLineEditFocus.corner_radius_top_right = cornerRadiTextEdit.y
	styleBoxForeLineEditFocus.corner_radius_bottom_left = cornerRadiTextEdit.z
	styleBoxForeLineEditFocus.corner_radius_bottom_right = cornerRadiTextEdit.w
	theme.set_stylebox("focus","LineEdit",styleBoxForeLineEditFocus)
	theme.set_color("selection_color","LineEdit",highlightColor)
	var styleBoxLineEditDisabled = StyleBoxFlat.new()
	
	styleBoxLineEditDisabled.bg_color = foreColorDisabled
	theme.set_stylebox("read_only","LineEdit",styleBoxLineEditDisabled)
	theme.set_color("selection_color","TextEdit",highlightColor)
	
	
	theme.set_stylebox("normal","TextEdit",styleBoxLineEdit)
	theme.set_stylebox("focus","TextEdit",styleBoxForeLineEditFocus)
	theme.set_stylebox("read_only","TextEdit",styleBoxLineEditDisabled)
	
	
	var seperatorPanel = StyleBoxFlat.new()
	seperatorPanel.border_width_top = 1
	seperatorPanel.border_color = foreColorHover
	theme.set_stylebox("separator","HSeparator",seperatorPanel)
	theme.set_stylebox("separator","VSeparator",seperatorPanel)
	
	var popupPanel = styleBoxFore.duplicate()
	popupPanel.corner_radius_top_left = 0
	popupPanel.corner_radius_top_right = 0
	popupPanel.corner_radius_bottom_left = 0
	popupPanel.corner_radius_bottom_right = 0
	theme.set_stylebox("panel","PopupMenu",popupPanel)
	
	var popupSeperatorPanel = StyleBoxFlat.new()
	popupSeperatorPanel.bg_color = Color.GREEN
	popupSeperatorPanel.border_width_top = 1
	theme.set_stylebox("panel","Separator",popupSeperatorPanel)
	
	var panelTree = StyleBoxFlat.new()
	panelTree.bg_color = bgColor.lightened(0.1)
	theme.set_stylebox("panel","Tree",panelTree)
	theme.set_stylebox("panel","TabContainer",panelTree)
	
	
	
	var tabPanelSelected = StyleBoxFlat.new()
	tabPanelSelected.border_width_top = 2
	tabPanelSelected.border_width_top = 0
	tabPanelSelected.border_width_left = 0
	tabPanelSelected.border_width_right = 0
	tabPanelSelected.bg_color = foreColor
	theme.set_stylebox("tab_selected","TabContainer",tabPanelSelected)
	
	
	#var optionButton : StyleBoxFlat= popupPanel.duplicate()
	#optionButton.content_margin_left = 4
	#theme.set_stylebox("normal","OptionButton",optionButton)
	
	#var optionButtonHover : StyleBoxFlat= styleBoxForeHover.duplicate()
	#optionButtonHover.content_margin_left = 4
	#theme.set_stylebox("normal","OptionButton",optionButtonHover)
	
#	theme.set_stylebox("normal","focus",panelTree)
	#theme.set_stylebox("focus","TextEdit",styleBoxForeLineEditFocus)
	
	
	
	return theme

func getTextures():
	return patchTextureEntries.keys()


func createFontDisk(fontName,meta):
	fetchFont(fontName,meta)

func fetchFont(fontname,meta):
	var disableToDisk = false
	
	return resourceManager.fetchBitmapFont(fontname)

func createThemeDisk(themeName,meta):
	var destPath = meta["destPath"] + themeName + ".tres"
	ResourceSaver.save(meta["info"],destPath)


func createTexture(textureName : String,meta : Dictionary):
	var txt =  resourceManager.fetchPatchedTexture(textureName)
	
	if txt == null:
		return resourceManager.fetchDoomGraphic(textureName)
		
		
	if txt.get_class() == "AnimatedTexture":
		return txt
	
	
	return resourceManager.fetchPatchedTexture(textureName).image
	
	
	
	return null
	
func createTextureDisk(textureName : String,meta : Dictionary,editorInterface):
	resourceManager.fetchPatchedTexture(textureName)


func createMidi(soundStr,meta = {}) -> PackedByteArray:
	if musListPre.has(soundStr):
		return resourceManager.createMidiFromMus(soundStr)
	elif midiListPre.has(soundStr):
		return resourceManager.getRawMidiData(soundStr)
	return []
	
func createMidiOnDisk(soundStr,meta = {},editorInterface = null):
	var subPath = meta["cat"].replace("/mus","/midi")
	var destPath =  WADG.destPath+gameName+"/"+subPath
	var midi = createMidi(soundStr)
	var file = FileAccess.open(destPath + "/" + soundStr + ".mid",FileAccess.WRITE)
	file.store_buffer(midi)
	file.close()
	

func getConfigs():
	return ["Doom","Doom Mod","Hexen","Hexen Mod","SRBC"]

func getReqs(configName):
	
	configName = configName.to_lower()
	
	var iwad = {
		"UIname" : "IWAD path:",
		"required" : true,
		"ext" : ["*.wad","*.pk3","/"],
		"multi" : false,
		"fileNames" : ["doom.wad","doom2.wad","freedoom1.wad","freedoom2.wad","plutonia.wad","tnt.wad"],
		"hints" : ["steam,Ultimate Doom/base","steam,Master Levels of Doom/doom2","steam,Final Doom/base","steam,Doom 2/base","steam,Doom 2/finaldoombase"]
	}
	
	var pwad = {
		"UIname" : "PWAD path:",
		"required" : false,
		"ext" : ["*.wad","*.pk3","/"],
		"multi" : true,
		"fileNames" : [],
		"hints" : []
	}
	
	var hexen = {
		"UIname" : "IWAD path:",
		"required" : true,
		"ext" : ["*.wad"],
		"multi" : false,
		"fileNames" : ["hexen.wad","/"],
		"hints" : []
	}
	
	var srbcIwad = {
		"UIname" : "SRB2XMAS.WAD path:",
		"required" : true,
		"ext" : ["*.wad",],
		"multi" : false,
		"fileNames" : ["SRB2XMAS.WAD"],
		"hints" : []
	}
	
	var srbcPwad = {
		"UIname" : "xmassupp.wad path:",
		"required" : true,
		"ext" : ["*.wad",],
		"multi" : false,
		"fileNames" : ["xmassupp.wad"],
		"hints" : []
	}
	
	#skyCeil =  SKYVIS.DISABLED
	#skyWall = SKYVIS.DISABLED
	
	if configName == "doom": 
		return [iwad]
	elif configName == "hexen":
		return [hexen]
	elif configName == "hexen mod":
		return [hexen,pwad]
	elif configName == "srbc":
		return [srbcIwad,srbcPwad]
	else:
		return [iwad,pwad]
	

func getLoader():
	return resourceManager
	
func getEntityCreator():
	return thingParser

func createFontResourcesOnDisk(fontStr,meta,editorInteface):#this is uneeded
	thingParser.createFontResourcesOnDisk(fontStr,editorInteface)

func createEntityResourcesOnDisk(entStr,meta,editorInteface):
	thingParser.createEntityResourcesOnDisk(entStr,editorInteface)


func createMapResourcesOnDisk(mapname,meta,editorInteface,startFileWaitThread = true):
	thingParser.createMapResourcesOnDisk(mapname,editorInteface,startFileWaitThread)
	
func createGameModeResourcesOnDisk(gName,meta,editorInterface):
	$gameModeCreator.createGameModeResourcesOnDisk(gName,meta,editorInterface)
	if Engine.is_editor_hint():
		thingParser.startFileWaitThread(editorInterface)
	else:
		emit_signal("fileWaitDoneSignal")

func createGameModeDisk(gName,meta,tree,gameName):
	return $gameModeCreator.createGameModeDisk(gName,meta,tree,gameName)
	

func setEntityPos(entity : Node3D ,pos : Vector3,rot : Vector3,parentNode : Node) -> void:
	return thingParser.setEntityPos(entity ,pos ,rot ,parentNode )

func loadRoo(path):
	
	var file : FileAccess = FileAccess.open(path,FileAccess.READ)
	
	
	var magic = file.get_buffer(4).get_string_from_ascii()
	var version = file.get_32()
	var security = file.get_32()
	var mainInfoOffset = file.get_32()
	var mainServerOffset = file.get_32()
	
	parseRooMainInfo(file,mainInfoOffset)
	#var isUDMF = isUDMF()
	#var magic = file.get_String(4)
	#var numLumps = file.get_32()
	#var directoryOffset = file.get_32()
	
	

func parseRooMainInfo(file : FileAccess,offset):
	file.seek(offset)
	
	var w = file.get_32()
	var h = file.get_32()
	#var dataLen = file.get_32()
	#var security = file.get_32()
	
	var nodeOffset= file.get_32()
	var clientWallOffset= file.get_32()
	var wallOffset= file.get_32()
	var sidedefOffset= file.get_32()
	var sectorOffset= file.get_32()
	var thingOffset = file.get_32()
	
	
	file.seek(clientWallOffset)
	var numLinesClient = file.get_32()
	for i in numLinesClient:
		var f132 = file.get_32()
		var g132 = file.get_32()
		var a312 = file.get_32()
		
		var e332 = file.get_32()
		var f332 = file.get_32()
		var g332 = file.get_32()
		var a332 = file.get_32()
		var f3323 = file.get_32()
		var g3324 = file.get_32()
		var a3323 = file.get_32()
		
		
	
	file.seek(sidedefOffset)
	var numSideDef = file.get_16()
	
	for i in numSideDef:
	
		var id = file.get_16()
		var midTextureId = file.get_16()
		var upperTextureId = file.get_16()
		var lowerTextureId = file.get_16()
		var wallFlags = file.get_16()
		var animSpeed = file.get_8()
	#breakpoint
	
	file.seek(wallOffset)
	var numLines = file.get_16()
	for i in numLines:
		var frontSideIdx = file.get_16()
		var backSideIdx = file.get_16()
		var xOffset = file.get_16()
		var oSideXoffset = file.get_16()
		var yOffset = file.get_16()
		var oSideYoffset = file.get_16()
		
		var secIndex = file.get_16()
		var oSecIndex = file.get_16()
		
		var start = Vector2(get_32s(file),get_32s(file))
		var end = Vector2(get_32s(file),get_32s(file))
		#var a3 = get_32s(file)
		breakpoint
	
	file.seek(sectorOffset)
	var a = file.get_16()
	var sectorTag = file.get_16()
	var floorTextureID = file.get_16()
	var ceilTextureID = file.get_16()
	var texOffsetX = file.get_16()
	var texOffsetY = file.get_16()
	var floorH = file.get_16()
	var ceilH = file.get_16()
	var e = file.get_16()
	var f = file.get_16()
	var g = file.get_16()
	var u = file.get_16()
	breakpoint 
	

func get_32s(file) -> int:
	
	#var ret = data.slice(pos,pos+2)
	#var ret = file.get_buffer(2)
	var ret = file.get_32()
	if ret <= 2147483647:
		return ret
	else:
		
		return ret - 4294967296
		
		
func addThingsDict(bSheet : gsheet):
	
	if thingSheet == null:
		thingSheet = bSheet 
		return
	
	var a = bSheet.data
	var b = thingSheet.data
	
	for i in a.keys():
		var entry : Dictionary = a[i]
		if entry.has("name"):
			if !entry["name"].is_empty():
				b[i] = entry

func addTypesDict(bSheet : gsheet):
	
	if typeDict == null:
		typeDict = bSheet 
		return
	
	var a = bSheet.data
	var b = typeDict.data
	
	for i in a.keys():
		var entry : Dictionary = a[i]
		if entry.has("str"):
			if !entry["str"].is_empty():
				b[i] = entry
		
func setTextureFiltering(value):
	textureFiltering = value
	
	if !is_inside_tree():
		return
	
	var v = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	if textureFiltering:
		v = BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR
	
	setTextureFilteringAll(v)
	#if textureFiltering == false:
	#	SETTINGS.setSetting(get_tree(),"textureFiltering",BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST)
	#else:
		#SETTINGS.setSetting(get_tree(),"textureFiltering",BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR)
	#

func setTextureFilteringAll(value):
	SETTINGS.setSetting(get_tree(),"textureFiltering",value)
	SETTINGS.setSetting(get_tree(),"textureFilteringGeometry",value)
	SETTINGS.setSetting(get_tree(),"textureFilteringSprite",value)
	SETTINGS.setSetting(get_tree(),"textureFilteringFov",value)
	SETTINGS.setSetting(get_tree(),"textureFilteringSky",value)
	SETTINGS.setSetting(get_tree(),"textureFilteringUI",value)
	

func printTimings():
	var t = get_tree().get_meta("timings")
	for i in t:
		print(i,":",t[i])
	
