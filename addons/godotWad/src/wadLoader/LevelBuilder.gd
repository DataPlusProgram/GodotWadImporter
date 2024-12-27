@tool
extends Node

enum LINDEF_FLAG{
	BLOCK_CHARACTERS = 0x01,
	BLOCK_MONSTERS = 0x02,
	TWO_SIDED = 0x4,
	UPPER_UNPEGGED= 0x08,
	LOWER_UNPEGGED = 0x10,
	SECRET = 0x20,
	BLOCKS_SOUND = 0x40,
	NEVER_ON_AUTOMA = 0x80,
	ALWAYS_ON_AUTOMAP = 0x100,
	PASS_THROUGH = 0x200
}

enum TEXTUREDRAW{
	BOTTOMTOP,
	TOPBOTTOM,
	GRID,
}

enum DIR{
	UP,
	DOWN
}

enum KEY{
	RED,
	GREEN,
	BLUE,
	YELLOW,
}

enum DOORSPEED{
	NORMAL,
	FAST
}

enum LTYPE {
	DOOR,
	FLOOR,
	LIFT,
	CRUSHER,
	STAIR,
	EXIT,
	LIGHT,
	SCROLL,
	TELEPORT,
	CEILING,
	DUMMY,
	STOPPER,
	ALPHA
}


enum TTYPE{
	DOOR,
	DOOR1,
	SWITCH1,
	SWITCHR,
	WALK1,
	WALKR,
	GUN1,
	GUNR,
	NONE
}

enum DEST{
	LOWEST_ADJ_CEILING,
	LOWEST_ADJ_FLOOR,
	NEXT_HIGHEST_FLOOR,
	NEXT_LOWEST_FLOOR,
	up8,
	up24,
	up32,
	up512,
	NEXT_HIGHEST_FLOOR_up8,
	LOWEST_ADJ_CEILING_DOWN8,
	HIGHEST_ADJ_CEILING,
	FLOOR,
	FLOOR_up8,
	HIGHEST_ADJ_FLOOR,
	HIGHEST_NFLOOR_EXC
	
}


enum LIGHTCAT{
	LOWEST_ADJ = -1,
	HIGHEST_ADJ = -2,
	BLINK = -3
}



var typeToScript : Dictionary ={}


class interactionSectorSort:
	static func sort_asc(a,b):
		if a["type"] < b["type"]:
			return true
		return false

var sectorLightType = {
	1:{"interval":1.0},
	2:{"interval":0.5},
	3:{"interval":1.0},
	4:{"interval":1.0},
	12:{"interval":0.5},
	13:{"interval":1.0},
	17:{"interval":1.0},
}


var damageSectorTypes : PackedByteArray = [4,5,7,11,16]

@export var typeSheet: Resource = preload("res://addons/godotWad/resources/lineTypes.tres")
var typeDictHexen : Resource = preload("res://addons/godotWad/resources/lineTypesHexen.tres")



var mapTo666 = {
	"E1M8":{"type":23,"npcName":"baron of hell"},
	"E2M8":{"type":11,"npcName":"baron of hell"},
	"E3M8":{"type":11,"npcName":"baron of hell"},
	"MAP07":{"type":23,"npcName":"mancubus"},
}

var mapTo667= {
	"MAP07":{"type":30,"npcName":"arachnotron"},
	}

var scriptAttributes = [
	"trigger",
	"direction",
	"loop",
	"startDelay",
	"inc",
	"dest",
	"keyType",
	"waitOpen",
	"waitClose",
	"stayOpen",
	"triggerType",
	"speed",
	"secret"
]


var typeSounds :={
	LTYPE.FLOOR:["openSound","closeSound","DSSTNMOV","DSSTNMOV"],
	LTYPE.LIFT:["openSound","closeSound","DSPSTART","DSPSTOP"],
	LTYPE.DOOR:["openSound","closeSound","DSDOROPN","DSDORCLS"],
	LTYPE.CRUSHER:["openSound","closeSound","DSSTNMOV","DSSTNMOV"]
}



@onready var resourceManager : Node = $"../ResourceManager" 
@onready var materialManager : Node = $"../MaterialManager" 
@onready var par : WAD_Map = get_parent()

var sideDefs : Array[Dictionary]
var sectors : Array[Dictionary]
var verts : PackedVector2Array
var lines : Array[Dictionary]
var geomNode : Node= null
var sideNodePath : Dictionary= {}
var preInstancedMeshes: Dictionary = {}
var scaleFactor : Vector3
var mapName : String 
var mapNode : Node
var mapDict : Dictionary
var occluderCount : int = 0
var occludersByArea : Array= []
var hasCollision : bool = true

func _ready():

	set_meta("hidden",true)
	

func createLevel(mapDict : Dictionary,mapname : String,mapNodei : Node,hasCollision : bool) -> Node:
	scaleFactor = get_parent().scaleFactor
	typeToScript[LTYPE.CEILING] = "res://addons/godotWad/src/interactables/ceiling.gd"
	typeToScript[LTYPE.CRUSHER] = "res://addons/godotWad/src/interactables/crusher.gd"
	typeToScript[LTYPE.DOOR] = "res://addons/godotWad/src/interactables/door.gd"
	typeToScript[LTYPE.EXIT] =  "res://addons/godotWad/src/interactables/levelChange.gd"
	typeToScript[LTYPE.FLOOR] =  "res://addons/godotWad/src/interactables/floor.gd"
	typeToScript[LTYPE.LIFT] =  "res://addons/godotWad/src/interactables/lift.gd"
	typeToScript[LTYPE.STAIR] =  "res://addons/godotWad/src/interactables/stairs.gd"
	typeToScript[LTYPE.STOPPER] =  "res://addons/godotWad/src/interactables/stopper.gd"
	typeToScript[LTYPE.TELEPORT] =  "res://addons/godotWad/src/interactables/teleport.gd"
	typeToScript[LTYPE.LIGHT] =   "res://addons/godotWad/src/interactables/light.gd"
	triggerDict = {}
	
	self.mapDict =mapDict
	
	
	var n = Time.get_ticks_msec()
	initLowerTextureHeights(mapDict)
	initLowerTextureHeights2(mapDict)
	#print("init texture times:",Time.get_ticks_msec()-n)
	mapNode = mapNodei
	
	mapName = mapname
	
	occludersByArea = []

	mapNode.name = mapname
	mapNode.set_meta("map",true)
	
	
	get_parent().mapNode = mapNode
	mapNode.set_script(load("res://addons/godotWad/src/levelNode.gd"))
	
	
	mapNode.nextMapStr = WADG.incMap(mapname)
	mapNode.nextSecretMapStr = WADG.incMap(mapname,true)
	
	
	if Engine.is_editor_hint() and get_parent().toDisk:
		mapNode.nextMapStr = WADG.destPath+ get_parent().gameName+ "/maps/" + mapNode.nextMapStr +".tscn" 
		if !mapNode.nextSecretMapStr.is_empty():
			mapNode.nextSecretMapStr = WADG.destPath+ get_parent().gameName+ "/maps/" + mapNode.nextSecretMapStr +".tscn" 
	
	mapNode.transform = get_parent().transform
	geomNode = NavigationRegion3D.new()
	
	var navMesh = NavigationMesh.new()
	
	geomNode.navigation_mesh = navMesh
	
	navMesh.set_parsed_geometry_type( NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS)
	navMesh.set_sample_partition_type(NavigationMesh.SAMPLE_PARTITION_MONOTONE)
	navMesh.agent_radius = 0.50
	navMesh.agent_max_climb = 0.74999998

	geomNode.name = "Geometry"
	mapNode.add_child(geomNode)
	
	var specialNode = Node.new()
	specialNode.name = "SectorSpecials"
	mapNode.add_child(specialNode)
	
		
	var ineteractablesNode = Node3D.new()
	ineteractablesNode.name = "Interactables"
	mapNode.add_child(ineteractablesNode)
	
	
	
	preInstancedMeshes = {}
	sideNodePath   = {}

	sideDefs = mapDict["sideDefsParsed"]
	sectors = mapDict["sectorsParsed"]
	verts = mapDict["vertexesParsed"]
	lines = mapDict["lineDefsParsed"]
	
	var a = Time.get_ticks_msec()
	#
	if get_parent().floorMethod == get_parent().FLOORMETHOD.old:
		$"../FloorBuilder".instance(mapDict,geomNode,specialNode)
	elif get_parent().floorMethod == get_parent().FLOORMETHOD.new:
		$"../FloorBuilderNew".instance(mapDict,geomNode,specialNode)
	else:
		$"../FloorBuilder3".instance(mapDict,geomNode,specialNode)
		#print("floor creation time:",Time.get_ticks_msec()-a)
	
	#print("floor create time:",Time.get_ticks_msec()-a)
	
	#var t1 = Thread.new()
	#var t2 = Thread.new()
	
	
	#t1.start(createSaticWalls.bind(mapDict),Thread.PRIORITY_HIGH)
	
	#
	
	#t1.wait_to_finish()
	#t2.start(createDynamicWalls.bind(mapDict),Thread.PRIORITY_HIGH)
	#t2.wait_to_finish()
	a = Time.get_ticks_msec()
	var wallStart : int = Time.get_ticks_msec()
	for r : Dictionary in mapDict["staticRenderables"]:
		createStaticSide(r)
	#print("side create 1:",Time.get_ticks_msec()-a)
	#a = Time.get_ticks_msec()
	
	for r : Dictionary in mapDict["dynamicRenderables"]:
		createDynamicSide(r)
	#print("side create 2:",Time.get_ticks_msec()-a)
	

	SETTINGS.setTimeLog(get_tree(),"side create",wallStart)
	
	var mergeStart : int = Time.get_ticks_msec()
	
	a = Time.get_ticks_msec()
	if get_parent().mergeMesh != get_parent().MERGE.DISABLED:
		$"../MeshCombiner".merge(preInstancedMeshes,geomNode,mapName,hasCollision)
		#print("mesh combiner time:",Time.get_ticks_msec()-a)
	
	
	#t1.wait_to_finish()
	SETTINGS.setTimeLog(get_tree(),"mesh merge",mergeStart)
	
	
	var interactStart : int = Time.get_ticks_msec()
	createInteractables(mapDict["sectorToInteraction"],mapDict)

	SETTINGS.setTimeLog(get_tree(),"interact",interactStart)
	
	

	if mapDict["createSurroundingSkybox"]:
		createSurroundingSkybox(mapDict["BB"],mapDict["minDim"])
	
	
	

	
	if occludersByArea.size() > get_parent().maxOccluderCount:
		var overflow = occludersByArea.slice(get_parent().maxOccluderCount,occludersByArea.size()+1)
		for i in overflow:
			i[1].queue_free()
			
	
	
	return mapNode
	
	
func createSaticWalls( mapDict :Dictionary):
	for r : Dictionary in mapDict["staticRenderables"]:
		createStaticSide(r)
		
	

func createDynamicWalls( mapDict :Dictionary):
	for r : Dictionary in mapDict["dynamicRenderables"]:
		createDynamicSide(r)
	

func createStaticSide(renderable : Dictionary) -> void:
	var start : Vector2 = verts[renderable["startVertIdx"]]
	var end : Vector2=  verts[renderable["endVertIdx"]]
	var sector : Dictionary= sectors[renderable["sector"]]
	var oSectorIdx = renderable["oSector"]
	var type : String = renderable["type"]
	var dir : int= renderable["dir"]
	var fFloor :float= sector["floorHeight"]
	var fCeil : float= sector["ceilingHeight"]
	var textureName : String= renderable["texture"]
	var flags : int= renderable["flags"]
	var textureOffset : Vector2= renderable["textureOffset"]
	var lowerUnpegged : bool= (flags &  LINDEF_FLAG.LOWER_UNPEGGED) != 0
	var upperUnpegged : bool= (flags &  LINDEF_FLAG.UPPER_UNPEGGED) != 0
	var doubleSided : bool = (flags & LINDEF_FLAG.TWO_SIDED) != 0
	
	if renderable.has("udmfData"):
		var udmfData = renderable["udmfData"]
		if udmfData.has("twoSided"):
			doubleSided = udmfData["twoSided"]
		
		if udmfData.has("lowerUnpegged"):
			lowerUnpegged = true
			
		
		if udmfData.has("upperUnpegged"):
			lowerUnpegged = true
			
			
	
	if type == &"trigger":
		return



	var hasCollision : bool = flags & LINDEF_FLAG.BLOCK_CHARACTERS == 1
	
	if oSectorIdx == null:
		hasCollision = true
		
	
	
	if type != &"middle": hasCollision = true#only floating mids can be fake walls
	
	
	var floorDraw : TEXTUREDRAW= TEXTUREDRAW.TOPBOTTOM
	var midDraw : TEXTUREDRAW= TEXTUREDRAW.TOPBOTTOM
	var ceilDraw : TEXTUREDRAW= TEXTUREDRAW.BOTTOMTOP
	var lineIndex : TEXTUREDRAW= renderable["lineIndex"]

	
	if lowerUnpegged: 
		floorDraw = TEXTUREDRAW.GRID
		midDraw = TEXTUREDRAW.BOTTOMTOP
	
	if upperUnpegged:
		ceilDraw = TEXTUREDRAW.GRID
	
	var texture : Texture2D

	if textureName == &"F_SKY1":
		var textureSky = $"../ImageBuilder".getSkyboxTextureForMap(mapName)
		texture = resourceManager.fetchPatchedTexture(textureSky)
	else:
		if textureName != &"-":
			texture = resourceManager.fetchPatchedTexture(textureName)

	
		
	
	if texture == null and textureName != &"-":
		texture = resourceManager.fetchFlat(textureName)
	
	
	var oSectorSky = false
	if oSectorIdx != null:
		if sectors[oSectorIdx]["ceilingTexture"] == &"F_SKY1":
			oSectorSky = true
	
	
	
	if type == "skyUpper":
		if oSectorIdx != null:
			if sectors[oSectorIdx]["ceilingTexture"] == &"F_SKY1":
				return
		
	
		if fCeil < sector["highestNeighCeilInc"]:
			createMeshAndCol(start,end,fCeil,sector["highestNeighCeilInc"],sector["highestNeighCeilInc"],texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir,false,renderable["alpha"])
			return
		else:
			return

	
	
	
	if sector["ceilingTexture"] == &"F_SKY1" and type!=&"lower" and oSectorSky and renderable["oSide"]["upperName"] == "-" and oSectorIdx and type == "upper" :#if my ceiling is sky and I'm not lower and oSector is also sky then I'm sky 
		return # this stops the floating walls e.g. E1M1

	
	if oSectorIdx == null:#if oSector is null we only every render the mid
		if type == "middle":
		
			createMeshAndCol(start,end,fFloor,fCeil,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir,false,renderable["alpha"])
			return
		else:
			return
		
	
	var oSector = sectors[oSectorIdx]
	var oFloor = oSector["floorHeight"]
	var oCeil = oSector["ceilingHeight"]
	
	var lowFloor = min(fFloor,oFloor)
	var highFloor = max(fFloor,oFloor)
	var lowCeil = min(fCeil,oCeil)
	var highCeil = max(fCeil,oCeil)
	
	

	
	var shootThrough = false
	if oSector != null and doubleSided != false: shootThrough = true
	
	if type == "upper" or type == "lower":
		shootThrough = false#is there a case where you can shoot through an upper?
		
	if (type == &"middle" or type == &"invisibleWall") and !doubleSided:
		createMeshAndCol(start,end,fFloor,fCeil,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir,false,renderable["alpha"])
		return 
	
	
	if (type == &"middle" or type == &"invisibleWall") and doubleSided and (texture != null or type == &"invisibleWall") :#floating mid
		
		var h : float = 0.0
		
		if texture != null:
			h = texture.get_height() * scaleFactor.y

		
		if lowerUnpegged:
			createMeshAndCol(start,end,highFloor+textureOffset.y,highFloor+textureOffset.y+h,fCeil,texture,midDraw,Vector2(textureOffset.x,0),renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir,shootThrough,renderable["alpha"])
			return
		
		else:#lower unpegged and no pegged seems to be the same
			var a = lowCeil+textureOffset.y-h
			var b = highFloor
			
			if  type == &"invisibleWall":
				createMeshAndCol(start,end,max(a,b),fFloor,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir,shootThrough,renderable["alpha"])
			else:
				createMeshAndCol(start,end,max(a,b),lowCeil+textureOffset.y,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir,shootThrough,renderable["alpha"])
			return
		return
	
	if (type == &"upper" or type == &"invisibleWall") and fCeil > oCeil:#upper section
		if sector["ceilingTexture"] == &"F_SKY1" and  oSector["ceilingTexture"] == &"F_SKY1":
			return
			
		createMeshAndCol(start,end,lowCeil,highCeil,fCeil,texture,ceilDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir,shootThrough,renderable["alpha"],{},renderable["scroll"])
	
	if  (type == &"lower" or type == &"invisibleWall") and fFloor < oFloor:#lower section
		createMeshAndCol(start,end,lowFloor,highFloor,fCeil,texture,floorDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir,shootThrough,renderable["alpha"],{},renderable["scroll"])
	



func createDynamicSide(renderable : Dictionary) -> void:
	var dir = renderable["dir"]
	var sectorIdx = renderable["sector"]#
	var oSectorIdx = renderable["oSector"]
	var textureName = renderable["texture"]

	
	var sTypes = []
	if mapDict["sectorToInteraction"].has(sectorIdx): 
		sTypes += mapDict["sectorToInteraction"][sectorIdx]
	
	
	var start = verts[renderable["startVertIdx"]]
	var end =  verts[renderable["endVertIdx"]]
	var sector = sectors[sectorIdx]

	var type = renderable["type"]
	var fFloor = sectors[sectorIdx]["floorHeight"]
	var fCeil = sectors[sectorIdx]["ceilingHeight"]

	var flags = renderable["flags"]
	var textureOffset = renderable["textureOffset"]
	
	
	var hasCollision = flags & LINDEF_FLAG.BLOCK_CHARACTERS == 1
	var lowerUnpegged = (flags &  LINDEF_FLAG.LOWER_UNPEGGED) != 0
	var upperUnpegged = (flags &  LINDEF_FLAG.UPPER_UNPEGGED) != 0
	var doubleSided = (flags & LINDEF_FLAG.TWO_SIDED) != 0
	var floorDraw = TEXTUREDRAW.TOPBOTTOM
	var midDraw = TEXTUREDRAW.TOPBOTTOM
	var ceilDraw = TEXTUREDRAW.BOTTOMTOP
	var lineIndex = renderable["lineIndex"]
	var oSide = renderable["oSide"]
	var oSideHasTexture = false

	if lowerUnpegged: 
		floorDraw = TEXTUREDRAW.GRID
		midDraw = TEXTUREDRAW.BOTTOMTOP
	
	if upperUnpegged:
		ceilDraw = TEXTUREDRAW.GRID
	
	
	if type != "middle": hasCollision = true#only floating mids can be fake walls
	#hasCollision = hasCollision or doubleSided
	
	

	
	if oSectorIdx == null:
		hasCollision = true
	
	if type == "trigger":
		return
	 
	var texture =  resourceManager.fetchPatchedTexture(textureName)
	
	#if texture == null:
	#	print("failed to fetch patched texture:",textureName)

	var oSectorSky = false
	if oSectorIdx != null:
		if sectors[oSectorIdx]["ceilingTexture"] == "F_SKY1":
			oSectorSky = true
	


	
	var dest = fFloor
	var minDest = INF
	var maxDest = -INF
	var destH = fFloor
	var isCumulative = false
	var tDict = typeSheet.data
	var hasLoop = false
	var alpha = 1.0
	if mapDict["isHexen"]: 
		tDict = typeDictHexen.data
	
	if renderable.has("alpha"):
		alpha = renderable["alpha"]
	
	for t in sTypes:
		
		var ty = t["type"]
		
		if ty == -2 and renderable.has("stairInfo"):
			destH = sector["floorHeight"]+16.0*scaleFactor.y*renderable["stairInfo"]["stairNum"]
		
		if !tDict.has(str(ty)):
			continue
		
		var row = tDict[str(ty)]
		
		if row.has("cumulative"):
			if typeof( row["cumulative"]) == TYPE_BOOL:
				if row["cumulative"] == true:
					isCumulative = true
		
		if isCumulative:
			if dir == DIR.UP:
				breakpoint
			else:
				destH = sector["nextHighestCeil"]
		
		if row.has("dest"):
			var destType = row["dest"]
			if destType != 16:
				destH = WADG.getDest(destType,sector,scaleFactor.y)
		
		if row.has("loop"):
			if typeof(row["loop"]) == TYPE_BOOL:
				if row["loop"] == true:
					hasLoop = true
		
		#the folowing used to be elif but changed after spreadsheet made dest manditor
		if row["type"] == WADG.LTYPE.LIFT: destH = sector["lowestNeighFloorExc"]
		if row["type"] == WADG.LTYPE.DOOR: destH = sector["lowestNeighCeilExc"]
		if row["type"] == WADG.LTYPE.CRUSHER: destH = sector["floorHeight"]+8.0*scaleFactor.y

		
		minDest = min(minDest,destH)
		maxDest = max(maxDest,destH)
		
	

	if hasLoop:
		minDest = sector["lowestNeighFloorInc"]
		maxDest = sector["highestNeighFloorInc"]
		
		
	

	if oSectorIdx == null:
		if type == "middle":
			createMeshAndCol(start,end,min(fFloor,minDest),max(fCeil,maxDest),fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,true,renderable["sType"],dir,false,alpha,{},renderable["scroll"])
			return
		return
		
	

	var oSector = sectors[oSectorIdx]
	var oFloor = oSector["floorHeight"]
	var oCeil = oSector["ceilingHeight"]
	
	var minOdest = INF
	var maxOdest = -INF
	var odestH = oFloor

	
	if mapDict["sectorToInteraction"].has(oSectorIdx):
		var allTypes = mapDict["sectorToInteraction"][oSectorIdx]
		for t in allTypes:
			
			var ty = str(t["type"])
			
			if !tDict.has(ty):
				print("missing type:",ty)
				continue
			
			var row = tDict[ty]
			
			
			#if renderable["sideIndex"] == 355:
			#	breakpoint
			
			if ty == "-2" and renderable.has("stairInfo"):
				destH = sector["floorHeight"]+16*scaleFactor.y*renderable["stairInfo"]["stairNum"]
			
			if tDict[ty].has("dest"):
				var destType = tDict[ty]["dest"]
				if destType != 16:
					odestH = WADG.getDest(destType,oSector,get_parent().scaleFactor.y)
				
			elif row["type"] == WADG.LTYPE.LIFT: destH = sector["lowestNeighFloorExc"]
			elif row["type"] == WADG.LTYPE.DOOR: destH = sector["lowestNeighCeilExc"]
			elif row["type"] == WADG.LTYPE.CRUSHER: destH = sector["floorHeight"]

			minOdest = min(minOdest,odestH)
			maxOdest = max(maxOdest,odestH)
			
			
			

	
	var lowestLocalFloor = min(fFloor,minDest)
	var lowestLocalCeil = min(fCeil,minDest)
	var highestLocalCeil = max(fCeil,maxDest)
	var highestOFloor = max(oFloor,maxOdest)
	var lowestOCeil = min(oCeil,minOdest)
	
	
	var lowestCeil = min(fCeil,min(oCeil,minDest))
	var highestCeil = max(fCeil,max(oCeil,maxDest))
	
	var highFloor = max(fFloor,oFloor)
	var lowCeil = min(fCeil,oCeil)

	var shootThrough = false
	if oSector != null and doubleSided != false: shootThrough = true
	
	if type == "upper" or type == "lower":
		shootThrough = false#is there a case where you can shoot through an upper
	
	if type == "middle" and !doubleSided:
		createMeshAndCol(start,end,lowestLocalFloor,highestOFloor,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,true,renderable["sType"],false,shootThrough,alpha)
		return 
	
	
	
	if type == "middle" and doubleSided and texture != null:#floating mid
		var h = texture.get_height() * scaleFactor.y
		
		
		
		
		
		
		
		
		
		
		if lowerUnpegged:
			createMeshAndCol(start,end,highFloor+textureOffset.y,highFloor+textureOffset.y+h,fCeil,texture,midDraw,Vector2(textureOffset.x,0),renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir,shootThrough,alpha)
			return
		
		else:#lower unpegged and no pegged seems to be the same

			var a = lowCeil+textureOffset.y-h
			var b = highFloor
			
			
			createMeshAndCol(start,end,max(a,b),lowCeil+textureOffset.y,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir,shootThrough,alpha)
			return
		return
	

		
	if type == "lower":
		
		if renderable.has("stairIdx"):
			highestOFloor = highestOFloor + renderable["stairIdx"]*renderable["stairInc"]*scaleFactor.y
		
		
		
		var wallBot = oFloor-(highestOFloor-lowestLocalFloor)
		var wallTop = oFloor
		
		if renderable.has("stairIdx"):
			wallBot =  lowestLocalFloor-(renderable["stairIdx"]*renderable["stairInc"]*scaleFactor.y)


		if lowestLocalFloor < highestOFloor:

			createMeshAndCol(start,end,wallBot,wallTop,fCeil,texture,floorDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,true,renderable["sType"],dir,shootThrough,alpha)


	if type == "upper":
		var bottom = min(minDest,minOdest)
		
		var wallBottom = oCeil
		var wallTop = oCeil + (highestLocalCeil-lowestOCeil)
		
	
		if wallBottom < wallTop: 
			createMeshAndCol(start,end,wallBottom,wallTop,fCeil,texture,ceilDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,true,renderable["sType"],dir,shootThrough,alpha)
	return
	

var meshCash : Dictionary = {}

func makeSideMesh(start:Vector2,end:Vector2,floorZ:float,ceilZ:float,fCeil:float,texture:Texture2D,uvType:TEXTUREDRAW,textureOffset:Vector2,sideIndex:int,lightLevel:int,textureName:String,sType:int,createCol : bool,alpha : float) -> Array:
	var origin : Vector3 = Vector3(start.x,ceilZ,start.y)
	var height : float = ceilZ-floorZ 
	var startUVy : float = 0
	var startUVx : float = 0
	var endUVy : float= 0
	var endUVx : float = 0
	var scaleFactor : Vector3 = get_parent().scaleFactor
	#var origin = Vector3(start.x,floorZ,start.y) -  Vector3(end.x,ceilZ,end.y)/2.0
	var useInstanceShaderParam = get_parent().useInstanceShaderParam
	var w = (end - start).length()
	var h = ceilZ-floorZ
	var textureDim = null
	
	
	#if sideIndex == 2253:
	#	breakpoint
	#var key = [w,h,textureDim,textureOffset]
	
	if texture != null:
		textureDim = texture.get_size() * Vector2(scaleFactor.x,scaleFactor.y)
		endUVx = ((start-end).length()/textureDim.x)
		
		
		if uvType == TEXTUREDRAW.TOPBOTTOM:
			endUVy = height#*scaleFactor
			startUVy/=textureDim.y
			endUVy/=textureDim.y
		
		elif uvType == TEXTUREDRAW.BOTTOMTOP:
			startUVy = (floorZ-ceilZ)#*scaleFactor
			endUVy = 0
			startUVy/=textureDim.y
			endUVy/=textureDim.y
			
		elif uvType == TEXTUREDRAW.GRID:
			startUVy = (fCeil - ceilZ)/textureDim.y
			endUVy = startUVy+(ceilZ-floorZ)/textureDim.y
	
	 
		startUVy += textureOffset.y / textureDim.y
		endUVy += textureOffset.y / textureDim.y
	
		startUVx += textureOffset.x / textureDim.x
		endUVx += textureOffset.x / textureDim.x
	
	var TL : Vector3 = Vector3(start.x,ceilZ,start.y) - origin
	var BL : Vector3 = Vector3(start.x,floorZ,start.y) -origin
	var TR  : Vector3= Vector3(end.x,ceilZ,end.y) - origin
	var BR : Vector3= Vector3(end.x,floorZ,end.y) - origin
	
	var line1 : Vector3 = TL - TR
	var line2 : Vector3 = TL - BL
	var normal : Vector3 = -line1.cross(line2).normalized()

	
	var mesh : Mesh = Mesh.new()
	var mat : Material
	
	

	var scroll : Vector2 = Vector2(0,0)

	if texture!=null and textureName != "F_SKY1":
		var inc : int = 0
		if start.y == end.y: inc = -1
		elif start.x == end.x: inc = 1
		
		
		#var alpha : float = 1.0
		
		var typeStr : String = var_to_str(sType)
		var row =  typeSheet.getRow(typeStr)
		
		
		if row["type"] == LTYPE.SCROLL:
			if row["direction"] != DIR.UP and row["direction"] != DIR.DOWN:
				if row.has("vector"):
					scroll = row["vector"]
				
				if row.has("specialType"):
					scroll = textureOffset/Vector2(get_parent().scaleFactor.x,get_parent().scaleFactor.y)
		
	#	if row.has("alpha"):
	#		alpha = row["alpha"]
		var lightAdjusted = WADG.getLightLevel(lightLevel)
		var sectorColor : Color = Color(lightAdjusted,lightAdjusted,lightAdjusted)
		

		
		mat =   materialManager.fetchGeometryMaterial(textureName,texture,sectorColor,scroll,alpha,false)
		
	
	if textureName == "F_SKY1":
		var texName : String = $"../ImageBuilder".getSkyboxTextureForMap(mapName) 
		mat =  materialManager.fetchSkyMat(texName,true)
	
	
	var meshKey = [TL-TL,TR-TL,BR-TL,BL-TL,textureOffset,textureDim]
	
	#if !meshCash.has(meshKey):
	var surf : SurfaceTool = SurfaceTool.new()
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	surf.set_normal(normal)
	surf.set_uv(Vector2(startUVx,startUVy))
	surf.set_uv2(Vector2(startUVx,startUVy))
	surf.add_vertex(TL)
			
	surf.set_normal(normal)
	surf.set_uv((Vector2(endUVx,startUVy)))
	surf.set_uv2(Vector2(startUVx,startUVy))
	surf.add_vertex(TR)
			
	surf.set_normal(normal)
	surf.set_uv(Vector2(endUVx,endUVy))
	surf.add_vertex(BR)
			
			
	surf.set_normal(normal)
	surf.set_uv(Vector2(startUVx,startUVy))
	surf.set_uv2(Vector2(startUVx,startUVy))
	surf.add_vertex(TL)
			
	surf.set_normal(normal)
	surf.set_uv(Vector2(endUVx,endUVy))
	surf.set_uv2(Vector2(startUVx,startUVy))
	surf.add_vertex(BR)
			
	surf.set_normal(normal)
	surf.set_uv(Vector2(startUVx,endUVy))
	surf.set_uv2(Vector2(startUVx,startUVy))
	surf.add_vertex(BL)
			
	surf.set_material(mat)
	#surf.index()

	mesh = surf.commit()
	#mesh.surface_set_name(mesh.get_surface_count()-1,textureName)

	if get_parent().unwrapLightmap:
		mesh.lightmap_unwrap(Transform3D.IDENTITY,1)
			
		#meshCash[meshKey] = mesh
	#else:
	#	mesh = meshCash[meshKey].duplicate()
		
	var meshNode : MeshInstance3D = MeshInstance3D.new()
	meshNode.position = origin
	meshNode.mesh = mesh
	
	var tintParam = WADG.getLightLevel(lightLevel)
	if useInstanceShaderParam:
		
		meshNode.set("instance_shader_parameters/sectorLight",Color(tintParam,tintParam,tintParam))
		meshNode.set("instance_shader_parameters/scrolling",scroll)
	
	if texture == null and textureName !="F_SKY1" and !get_parent().renderNullTextures:
		meshNode.visible = false

	meshNode.name = "sidedef " + str(sideIndex)
	
	
	if createCol:
		var colInstance = CollisionShape3D.new()
		var colShape = ConvexPolygonShape3D.new()
		var body = StaticBody3D.new()
		colShape.points = [TL,TR,BR,BL]
		
		colInstance.shape = colShape
		body.add_child(colInstance)
		meshNode.add_child(body)
	
	return [meshNode,null]

	
	
func addOccluerToMesh2(mesh : Node3D,startVert:Vector2,endVert:Vector2,height:float,origin:Vector3):
	occluderCount+=1
	var length :Vector2=  endVert-startVert
	var dim :Vector3 = Vector3(length.length(),height,1)
	var angle : float= length.angle_to(Vector2.UP) + deg_to_rad(90)
	
	height*2
	
	dim = Vector3(abs(dim.x),abs(dim.y),abs(dim.z))
	
	var area = dim.x * dim.y * dim.z
	var TL : Vector2 = Vector2(0,0)
	var TR : Vector2= Vector2(dim.x,0)
	var BR : Vector2= Vector2(dim.x,-height)
	var BL  : Vector2= Vector2(0,-height)
	
	
	var occShape :  PolygonOccluder3D= PolygonOccluder3D.new()
	var occ : OccluderInstance3D = OccluderInstance3D.new()
	var xy : PackedVector2Array= [TL,TR,BR,BL]
	
	
	occShape.polygon = PackedVector2Array(xy)
	
	if occludersByArea.size() == 0:
		occludersByArea.append([area,occ])
		occludersByArea.append([area,occ])
	else:
		for i in occludersByArea.size():
			if area > occludersByArea[i][0]:
				occludersByArea.insert(i,[area,occ])
				break
				
			if i == occludersByArea.size()-1:#if we at end we are the largest
				occludersByArea.append([area,occ])
	#		if i.
	
	#occ.shape = occShape
	occ.name = "occluder"
	occ.occluder = occShape
	occ.position = origin
	occ.rotation.y = angle
	
	mesh.add_child(occ)
	#occShape.polygon_points = PoolVector2Array(xy)
	
func createMeshAndCol(start:Vector2,end:Vector2,floorZ:float,ceilZ:float,fCeil:float,texture:Texture2D,uvType:TEXTUREDRAW,textureOffset:Vector2,sideIndex:int,lineIndex:int,sectorIdx:int,nameStr:String,hasCollision:bool,textureName:String,isDynamic:bool,sType:int,dir:int,shootThrough:bool,alpha : float,udmfData = {},scroll : Vector2 = Vector2.ZERO) -> void:

	var side : Dictionary = sideDefs[int(sideIndex)]
	var oSectorIdx = side["backSector"]
	var sector : Dictionary = sectors[sectorIdx]
	var sectorIdxPre :int  = sectorIdx
	var sectorIdxStr : String = "sector " + str(sectorIdx)
	var sectorNode : Node= geomNode.get_node_or_null(sectorIdxStr)
	
	
	
	
	if textureName == "F_SKY1":
		shootThrough = true
	
	
	
	#if texture == null:
		#print("creating mesh and col but texture %s is null" % textureName)
		
	if sectorNode == null:
		print("couldn't find sector node for line:",str(lineIndex))
		sectorNode = Node3D.new()
		sectorNode.name = "sector node"
		par.add_child(sectorNode)
		
		
	if sectorNode.get_node_or_null(str(lineIndex)) == null: #and isDynamic:#if it isn't dynamic it will be merged and a mesh won't exist for this node to parent
		var lineNode = Node3D.new()
		lineNode.name =  "linenode " + str(lineIndex)
		sectorNode.add_child(lineNode)
	
	
	
	
	
	var diff = (end-start).normalized()

	
	if par.addOccluder and alpha == 1.0:
		var length : float=  (end-start).length()
		var height : float = ceilZ-floorZ 
		var origin : Vector3= Vector3(start.x,ceilZ,start.y)
		var flags : int= lines[lineIndex]["flags"]
		var doubleSided : bool= (flags & LINDEF_FLAG.TWO_SIDED) != 0
		
		if udmfData.has("twoSided"):
			doubleSided = udmfData["twoSided"]
		
		var c = par.occluderBBclip
		
		
		
		end += diff*0.0001#anti pixel gap measures
		start -= diff*0.0001
		if length >= par.occMin and height >= par.occMin:
			if texture != null and texture.get_image() != null:
				if !texture.get_image().detect_alpha() and !isDynamic:
					var bb = mapDict["BB"]  + (mapDict["minDim"] + (mapDict["BB"]/2))
					
	
					var b0 : bool = true
					
					if oSectorIdx != null:
						if nameStr == "lower" and  sectors[oSectorIdx]["floorHeight"] - (sector["floorHeight"]) < 10 * scaleFactor.y:
							b0 = false
					
					if b0:
						
						var b1 : bool = (origin.x -mapDict["minDim"].x) < c
						var b2 : bool= (mapDict["maxDim"].x - origin.x) < c
						
						var b3 : bool= (origin.z -mapDict["minDim"].z) < c
						var b4 : bool= (mapDict["maxDim"].z - origin.z) < c
						
						if abs(origin.x - bb.x) > 9*scaleFactor.x:
							if oSectorIdx == null:
								height = bb.y
								origin.y = bb.y / 2
							
							if !b1 and !b2 and !b3 and !b4:
								addOccluerToMesh2(sectorNode,start,end,height,origin)

	floorZ-=0.0001
	ceilZ+=0.0001
	if par.mergeMesh != par.MERGE.DISABLED and !isDynamic and textureName != "-":
		if !preInstancedMeshes.has(sectorIdxPre):
			preInstancedMeshes[sectorIdxPre] = []
			
		var lineNode = sectorNode.get_node("linenode " + str(lineIndex))
		
		var colMask = 1
		
		if shootThrough: colMask = 0
		if textureName == "F_SKY1": colMask = 0
		
		
		preInstancedMeshes[sectorIdxPre].append({"start":start,"end":end,"floorZ":floorZ,"ceilZ":ceilZ,"fCeil":fCeil,"uvType":uvType,"textureOffset":textureOffset,"sideIndex":sideIndex,"textureName":textureName,"texture":texture,"sectorNode":sectorNode,"colMask":colMask,"hasCol":hasCollision,"alpha":alpha,"scroll":scroll})
		#var t = get_parent()
		
		#if side["index"] == 127:
		#	breakpoint
		
		if get_parent().KEEP_WALLS_CONVEX and hasCollision:
			var staticBody : StaticBody3D = makeConvexCollision(start,end,floorZ,ceilZ,sectorNode)
			
		#	if side["index"] == 127:
		#		WADG.saveNodeAsScene(staticBody,"res://dbg/test.tscn")

			setCollisionFlags(staticBody,shootThrough,textureName)

		#preInstancedMeshes[sectorIdxPre].append({"start":start,"end":end,"floorZ":floorZ,"ceilZ":ceilZ,"fCeil":fCeil,"uvType":uvType,"textureOffset":textureOffset,"sideIndex":sideIndex,"textureName":textureName,"texture":texture,"lineNode":lineNode,"sector":sector,"sectorNode":sectorNode,"colMask":colMask,"dir":dir,"hasCol":hasCollision})
		return
	

	#checkMeshCache(start,end,ceilZ,fCeil,texture,uvType,textureOffset)
		
	
	var ret : Array = makeSideMesh(start,end,floorZ,ceilZ,fCeil,texture,uvType,textureOffset,sideIndex,sector["lightLevel"],textureName,sType,hasCollision,alpha)
	
	var mesh : MeshInstance3D = ret[0]

	
	
	if !hasCollision:
		
		if side["index"] == 127:
			breakpoint
		
		mesh.create_trimesh_collision()
	#mesh.create_convex_collision()
	
	
	
	
	var lastChlildIdx = mesh.get_child_count()-1#if messh has occluder index will be 1 otherwise 0
	var staticBody : StaticBody3D = null
	
	if lastChlildIdx>-1:
		staticBody = mesh.get_child(lastChlildIdx)
		setCollisionFlags(staticBody ,shootThrough ,textureName)

	
	if isDynamic:

		mesh.name = "sidedef " + str(sideIndex)
		mesh.set_meta("type",nameStr)
		
		
		var lineNode = sectorNode.get_node("linenode " + str(lineIndex))
		lineNode.add_child(mesh)
		sideNodePath[sideIndex] = mesh
		
	else:
	
		mesh.name = "sidedef " + str(sideIndex)
		mesh.set_meta("type",nameStr)
		#if get_parent().mergeMesh == get_parent().MERGE.DISABLED:
		var lineNode = sectorNode.get_node("linenode " + str(lineIndex))
		lineNode.add_child(mesh)
	
	
	if isDynamic:
		sideNodePath[sideIndex] = mesh
		var length : float =  (end-start).length()
		var height : float = ceilZ-floorZ 
		var origin : Vector3 = Vector3(start.x,ceilZ,start.y)
		var flags: int = lines[lineIndex]["flags"]
		
		
		if get_parent().addOccluder:
			if length >= get_parent().occMin and height >= get_parent().occMin:
				if texture != null:
					if !texture.get_image().detect_alpha():
						var c = get_parent().occluderBBclip
						
						var b1 : bool= (origin.x -mapDict["minDim"].x) < c
						var b2 : bool= (mapDict["maxDim"].x - origin.x) < c
							
						var b3 : bool= (origin.z -mapDict["minDim"].z) < c
						var b4 : bool= (mapDict["maxDim"].z - origin.z) < c
						
						if !b1 and !b2 and !b3 and !b4:
							addOccluerToMesh2(mesh,start,end,height,Vector3.ZERO)
		
	
	if textureName != "F_SKY":
		mesh.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		mesh.use_in_baked_light = true
	
	

func createInteractables(sectorToInteraction : Dictionary,mapDict : Dictionary) -> void:
	var a = Time.get_ticks_msec()
	var tDict : gsheet = typeSheet
	if mapDict["isHexen"]: tDict = typeDictHexen
	
	
	
	for secIndex : int in sectorToInteraction.keys():#for every sector
		var sectorInteraction : Dictionary = {}

		for i in sectorToInteraction[secIndex]:
			if !sectorInteraction.has(i["type"]):
				sectorInteraction[i["type"]] = []
			
			sectorInteraction[i["type"]].append(i)
		
		sectorToInteraction[secIndex].sort_custom(Callable(interactionSectorSort, "sort_asc"))

		var animMeshPath : PackedStringArray = []
		
		

		for type : int in sectorInteraction.keys():#for every line type that the sector is targeted by
			#var lineType
			var triggerNodes : Array[Node3D]= []
			var teleportTargets : PackedInt32Array= []
			var teleportPointTarget = null
			for i in sectorInteraction[type]:#we have the type so we iterate each instance of that type (i lists the type and the line that targeted the sector)
				

				var triggerNode = createTriggerNodeForType(i,secIndex)
				
				if triggerNode != null:
					triggerNodes.append(triggerNode)
					if triggerNode is Area3D:
						if triggerNode.get_script() == null:
							triggerNode.set_script(load("res://addons/godotWad/src/interactables/rangeTrigger.gd"))
				
				if i.has("line"):
					var line : Dictionary = lines[i["line"]]
					
					if !triggerNodes.is_empty():
						triggerNodes.back().set_meta("targeterLineBackSector",line["backSector"])
					var lineThatTargets = line
					var sectorOfLineThatTargets = lineThatTargets["frontSector"]
					var pathPost = "Geometry/sector %s/linenode %s"%[sectorOfLineThatTargets,lineThatTargets["index"]]
					var path = "../../../" + pathPost
				
					if isSideAnimatedSwitch(sideDefs[lineThatTargets["frontSideDef"]]):
						if mapNode.get_node_or_null(pathPost)!= null:
							for c in mapNode.get_node(pathPost).get_children():
								animMeshPath.append(path + "/" + c.name)
						else:
							breakpoint
							
				if i.has("teleportTargets"):
					for tTarg in i["teleportTargets"]:
						if !teleportTargets.has(tTarg):
							teleportTargets.append(tTarg)
							
				if i.has("teleportPointTarget"):
					teleportPointTarget = i["teleportPointTarget"]
			

			
			var typeInfoS : Dictionary = tDict.getRow(str(type))
			
			if typeInfoS.is_empty():
				return
			var category = typeInfoS["type"]

			if geomNode.get_node_or_null("sector " + str(secIndex)) == null:
				continue
			
			var sector = sectors[secIndex]
			var sectorNode = geomNode.get_node("sector " + str(secIndex))
			
			
			var ceilings = []
			var floorings = []
			
			var sectorFrontSides : PackedInt32Array= mapDict["sectorToFrontSides"][secIndex]
			var sectorBackSides  : PackedInt32Array= mapDict["sectorToBackSides"][secIndex]
			var frontSidesNodes   : Array= getSideNodePaths(sectorFrontSides)
			var backSideLinedefNodes :  Array = getSideNodePaths(sectorBackSides)
			
			var backSideSideDefNodes = []
			
			for c in backSideLinedefNodes:
				backSideSideDefNodes.append(c)
			
			for c : Node in sectorNode.get_children():
				var path = "Geometry/" + c.get_parent().name + "/" + c.name
				
				if c.has_meta("floor"): 
					floorings.append(path)
					
				elif c.has_meta("ceil"):
					ceilings.append(path) 
					makeAreaForCeilFloor(c)
					
			
			
			var script : Script
			var sectorGroup = {}
			var lightValue : float
			
			var node := Node3D.new()
			node.name = "nodeName"
			
			
			
			if typeInfoS.has("triggerType"):
				if typeInfoS["triggerType"] == WADG.TTYPE.SWITCH1 or typeInfoS["triggerType"] == WADG.TTYPE.SWITCHR:#button press sound
					var buttonSound = createAudioPlayback("DSSWTCHN")
					buttonSound.name="buttonSound"
					
					if node.has_node("triggerType"):
						node.get_node("triggerType").add_child(buttonSound)
					else:
						node.add_child(buttonSound)
						
					
			#if typeInfoS.has("specialType"):
			#	breakpoint
			
			if category == LTYPE.CEILING or category == LTYPE.CRUSHER or category == LTYPE.DOOR:
				sectorGroup = {"targets":backSideSideDefNodes+ceilings+floorings,"sectorInfo":sector}

			
			if category == LTYPE.FLOOR or category == LTYPE.LIFT:
				sectorGroup = ({"targets":backSideSideDefNodes+floorings,"sectorInfo":sector})
		
		
			var fastDoor := false
			
			if typeInfoS.has("doorSpeed"):
				if typeInfoS["doorSpeed"] == DOORSPEED.FAST:
					fastDoor = true
		
			if category != LTYPE.FLOOR:
				if typeSounds.has(category):
					if !fastDoor:
						addSoundsToNode(node,typeSounds[category])
				
				if fastDoor and category != LTYPE.CRUSHER:
					addSoundsToNode(node,["openSound","closeSound","DSBDOPN","DSBDCLS"])

			
			if category == LTYPE.TELEPORT:
				var teleportSound = createAudioPlayback("DSTELEPT")
				teleportSound.name="sound"
				node.add_child(teleportSound)
				
				var teleportSectors := {}
				
				for i : int in teleportTargets:
					
					teleportSectors[i] = {"floor":null,"ceiling":null}
					
					var tSecPath = "Geometry/sector %s/" %i
					var secNode = mapNode.get_node_or_null(tSecPath)
					if secNode == null:
						continue

					for k in secNode.get_children():
						if k.has_meta("floor"):
							teleportSectors[i]["floor"] = mapNode.get_path_to(k)
						
						
						
						if k.has_meta("ceil"):
							teleportSectors[i]["ceiling"] = mapNode.get_path_to(k)
				
				sectorGroup = {"targets":teleportSectors,"sectorInfo":sector,"pointTarget":teleportPointTarget}
			
			
			
			if category == LTYPE.LIGHT:
				sectorGroup = {"targets":frontSidesNodes+floorings+ceilings,"sectorInfo":sector}
				if typeInfoS.has("value"):
					var value = typeInfoS["value"]
					
					if value < 0:
						if value == LIGHTCAT.HIGHEST_ADJ: 
							lightValue = sector["brightestNeighValue"]
						if value == LIGHTCAT.LOWEST_ADJ:
							lightValue = sector["darkestNeighValue"]
						if  value == LIGHTCAT.BLINK:
							lightValue = sector["darkestNeighValue"]
						
					else:
						lightValue = value
						

			
			if category == LTYPE.STAIR and mapDict["stairLookup"].has(secIndex):
				var targetStairs = []
				var x =  mapDict["stairLookup"]
				var stairSectorDict = mapDict["stairLookup"][secIndex]

				for stairSectorIdx in stairSectorDict.keys():

					sectorBackSides  = mapDict["sectorToBackSides"][stairSectorIdx]
					backSideLinedefNodes  = getSideNodePaths(sectorBackSides)
					sectorNode = geomNode.get_node("sector " + str(stairSectorIdx))
					var sectorFloor
					var sectorCeiling
					sector = sectors[stairSectorIdx]
					
					
					for c in sectorNode.get_children():
						if c.has_meta("floor"): 
							sectorFloor = [("Geometry/" + c.get_parent().name + "/" + c.name)]
						elif c.has_meta("ceil"): 
							sectorCeiling = [("Geometry/" + c.get_parent().name + "/" + c.name)]
					

					if sectorFloor ==  null: continue
						
					targetStairs.append({"targets":sectorFloor+backSideLinedefNodes,"sectorInfo":sector})
				sectorGroup = targetStairs
			
			
			if category != LTYPE.SCROLL:
				if typeToScript.has(category):
					script = load(typeToScript[category])
					node.set_script(script)
			
			if category == LTYPE.LIGHT:
				var value : int = typeInfoS["value"]
				if value == LIGHTCAT.BLINK: 
					node.doesBlink = true
				
				if typeInfoS.has("vector"):
					lightValue = typeInfoS["vector"]
				
			
			for i in scriptAttributes:
				if typeInfoS.has(i):
					node.set(i,typeInfoS[i])
			
			if sectorGroup.has("targets"):
				if typeSounds.has(category):
					for i in sectorGroup["targets"]:
						var t = mapNode.get_node(i)
						
						if t.has_meta("floor"):
							addSoundsToNode(t,typeSounds[category])
			
			if typeInfoS.has("cumulative"):
				if "allSectorTuples" in node:
					node.allSectorTuples = getSectorTuples(secIndex)
			
			if "globalScale" in node: node.globalScale = get_parent().scaleFactor
			if "info" in node :node.info = sectorGroup
			if "targets" in node :node.targets = sectorGroup["targets"]
			if "type" in node: node.type = type
			if sectorGroup.has("pointTarget"):
				if sectorGroup["pointTarget"] != null:
					if "pointTarget" in node: node.pointTarget = sectorGroup["pointTarget"]
				
			if !typeInfoS.has("speed") and fastDoor:
				node.speed = 4
				if category == LTYPE.CRUSHER:
					node.speed = 1.3
		
			if typeInfoS.has("crushes"):
				if "crushes" in node: node.crushes = typeInfoS["crushes"]
		
			if typeInfoS.has("damage"):
				if "damage" in node: node.damage = typeInfoS["damage"]
			if "animMeshPath" in node: 
				node.animMeshPath = animMeshPath
			if "category" in node: node.category = typeInfoS["type"]
			if "lightValue" in node: node.lightValue = lightValue
			if "sectorInfo" in node: node.sectorInfo = sectorGroup["sectorInfo"]
			
				#node.sectorIdx = sect
			if floorings.size()!= 0:
				if "floorPath" in node:node.floorPath = floorings[0]
			
			if typeInfoS.has("wait") and "waitClose" in node: node.waitClose = typeInfoS["wait"]
			
			
			
			if typeInfoS.has("changeTexture"):
				if "textureChange" in node:
					node.textureChange = true
			
			if typeInfoS.has("cumulative"):
				if "cumulative" in node:
					node.cumulative = true 
			
			if typeInfoS.has("str"):
				node.name = typeInfoS["str"]
			
			var mid = Vector3.ZERO
			
			
			
			var sectorNodeName : String= "Sector "+str(secIndex)
			var sectorInteractionParent  = fetchInteractableParentNode(mapNode,sectorNodeName,mid)
			
			
			for triggerNode : Node3D in triggerNodes:
				
				if triggerNode.get_class() == "Timer":
					triggerNode.timeout.connect(node.activate)
					continue
				var passer := Node.new()
				node.add_child(passer)
				var triggerType = null
				if triggerNode.has_meta("triggerType"):
					triggerType = triggerNode.get_meta("triggerType")
				
				#node.add_child(i)
				#i.owner = node
				if triggerNode.has_meta("gunTrigger"):
					var sideDefIdx = triggerNode.get_meta("sideDef")
					var activator = getSideNodePaths([sideDefIdx])
					if activator.is_empty():
						continue
						
					var targetMesh = mapNode.get_node(activator[0])
					if targetMesh.get_child_count() == 0:
						continue
						
					var targetCol = targetMesh.get_child(0)
					targetCol.set_script(load("res://addons/godotWad/src/interactables/gunTrigger.gd"))
					targetCol.connect("takeDamageSignal", Callable(node, "activate").bind(), 2)

							
				elif triggerNode.has_meta("npcTrigger"):
					passer.set_script(load("res://addons/godotWad/src/interactables/npcTrigger.gd"))
					passer.add_to_group("counter_"+triggerNode.get_meta("npcTrigger"),true)
				elif category == LTYPE.TELEPORT: 
					passer.set_script(load("res://addons/godotWad/src/interactables/teleportTrigger.gd"))
					triggerNode.connect("body_entered", Callable(passer, "bin").bind(), 2)
					triggerNode.connect("body_exited", Callable(passer, "bout").bind(), 2)
					passer.triggerType =  triggerType

					
				elif category == LTYPE.FLOOR: 
					passer.set_script(load("res://addons/godotWad/src/interactables/floorTrigger.gd"))
					if triggerType != TTYPE.WALK1 and triggerType != TTYPE.WALKR:
						if passer.has_method("bin") :
							triggerNode.connect("body_entered", Callable(passer, "bin").bind(), 2)
							triggerNode.connect("body_exited", Callable(passer, "bout").bind(), 2)
				
				
				if passer.has_method("takeDamage"):
					triggerNode.connect("takeDamageSignal", Callable(node, "activate").bind(), 2)
				
				
				var arr = ["npcTrigger","sectorTag","sectorIdx","fType","fTextureName","lineStart","lineEnd","triggerType","sectorIdx"]
				
				
				for atr in arr:
					if triggerNode.has_meta(atr):
						passer.set_meta(atr,triggerNode.get_meta(atr))
						
				
				if triggerType == TTYPE.WALK1 or triggerType == TTYPE.WALKR:
					if node.has_method("bin"):
							if triggerNode.get_signal_connection_list("body_entered").is_empty():
								triggerNode.connect("body_entered", Callable(node, "bin").bind(), 2)
								triggerNode.connect("body_exited", Callable(node, "bout").bind(), 2)
							
							if "textureChange" in node:
								if node.textureChange == true:
									#triggerNode.connect("walkOverSignalTextureChange")
									triggerNode.walkOverSignalTextureChange.connect(node.bodyIn)
								elif triggerNode.has_signal("walkOverSignal"):
									triggerNode.walkOverSignal.connect(node.walkOverTrigger)
							
							elif triggerNode.has_signal("walkOverSignal"):
								#if node.script.get_path() != "res://addons/godotWad/src/interactables/stopper.gd":
								triggerNode.walkOverSignal.connect(node.walkOverTrigger)
							
							
						
					elif node.has_method("bodyIn"):
						if triggerNode.get_signal_connection_list("body_entered").is_empty():
							triggerNode.connect("body_entered", Callable(node, "bodyIn").bind(), 2)
							triggerNode.connect("body_exited", Callable(node, "bodyIn").bind(), 2)
						
						if "textureChange" in node:
							if node.textureChange == true:
								triggerNode.walkOverSignalTextureChange.connect(node.bodyIn)
							elif triggerNode.has_signal("walkOverSignal"):
								triggerNode.walkOverSignal.connect(node.bodyIn)
								
						
						elif triggerNode.has_signal("walkOverSignal"):
							triggerNode.walkOverSignal.connect(node.bodyIn)
					
					
				else:
					if node.has_method("bin") :
						if triggerNode.has_signal("body_entered"):
							triggerNode.connect("body_entered", Callable(node, "bin").bind(), 2)
					if node.has_method("bout"):
						if triggerNode.has_signal("body_exited"):
							triggerNode.connect("body_exited", Callable(node, "bout").bind(), 2)
				
				if triggerNode.has_method("bout"):
					if !triggerNode.body_exited.is_connected(triggerNode.bout):
						triggerNode.body_exited.connect(triggerNode.bout)
					
					
			
		
			sectorInteractionParent.add_child(node)
	#print("create interactables time:",Time.get_ticks_msec()-a)



var triggerDict = {}

func createTriggerNodeForType(i,secIndex):
	

	if !i.has("line"):
		if i.has("timerTrigger"):
			var timer : Timer = Timer.new()
			timer.one_shot = true
			timer.autostart = true
			timer.wait_time = i["timerTrigger"]
			timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
			var sectorIdxStr : String = "sector " + str(secIndex)
			geomNode.get_node(sectorIdxStr).add_child(timer)
			
			return timer

	var triggerNode : Node = null
	var tDict = typeSheet.data
	if mapDict["isHexen"]: tDict = typeDictHexen.data
	
	var lineType : StringName = var_to_str(i["type"])#we assumne every linetype is the same
	var lineIdx : int = i["line"]
	var line : Dictionary = lines[lineIdx]
	
	if !tDict.has(lineType):
		return
	
	var typeInfo : Dictionary = tDict[lineType]
	
	if lineType == "-2" or typeInfo["type"] == LTYPE.SCROLL:
		return null

	var triggerType = null
	
	
	var interactionAreaNode : Area3D
	var depth : float = 40*scaleFactor.z
	

	if typeInfo.has("triggerType"):
		triggerType = typeInfo["triggerType"]
		
	if i.has("triggerType"):
		triggerType = i["triggerType"]
	
	
	if !triggerDict.has(lineIdx):
		triggerDict[lineIdx] = {}
	
	if triggerDict[lineIdx].has([triggerType,i.has("npcTrigger")]):
		return triggerDict[lineIdx][[triggerType,i.has("npcTrigger")]]
	
	if triggerType != TTYPE.GUN1 and triggerType != TTYPE.GUNR:
		
		if triggerType == TTYPE.WALK1 or triggerType == TTYPE.WALKR:
			depth = 20*scaleFactor.z
			
		
		if typeInfo["type"] == LTYPE.TELEPORT:
			depth = 20*scaleFactor.z
	
		
		interactionAreaNode = createInteractionAreaNode(line,depth,triggerType,"sector %s %s trigger" % [str(secIndex),typeInfo["str"]] )
		

		interactionAreaNode.set_meta("triggerType",triggerType)
		interactionAreaNode.set_meta("sectorIdx",sectors[secIndex])
		interactionAreaNode.set_meta("lineStart",verts[line["startVert"]])
		interactionAreaNode.set_meta("lineEnd",verts[line["endVert"]])
		
		if i.has("npcTrigger"):
			interactionAreaNode.set_meta("npcTrigger",i["npcTrigger"])
		
		if line.has("sectorTag"):
			interactionAreaNode.set_meta("sectorTag",line["sectorTag"])#for teleports the destination sector is set as a sector tag
		
		
		var mid = Vector2.ZERO
		
		
		if line["frontSector"] != null:
			setFtypeAndTexture(interactionAreaNode,secIndex,typeInfo,line)

				
		triggerNode = interactionAreaNode
	else:
		
		var gt := Node3D.new()
		gt.set_meta("gunTrigger",true)
		gt.set_meta("sideDef",line["frontSideDef"])
		triggerNode  = gt 
		setFtypeAndTexture(triggerNode,secIndex,typeInfo,line)
		
	
	
	var sectorIdxStr : String = "sector " + str(secIndex)
	geomNode.get_node(sectorIdxStr).add_child(triggerNode)
	#geomNode.add_child(triggerNode)
	triggerNode.owner = geomNode.get_node(sectorIdxStr)

	
	
	triggerDict[lineIdx][[triggerType,i.has("npcTrigger")]] = triggerNode
	return triggerDict[lineIdx][[triggerType,i.has("npcTrigger")]]
	#return triggerNode

func getSectorTuples(sectorIdx : int):
	var ret : Array[Array]
	for neighIdx : int in sectors[sectorIdx]["nieghbourSectors"]:
		ret.append([sectors[neighIdx]["floorHeight"],sectors[neighIdx]["ceilingHeight"]])

	return ret

func setCollisionFlags(staticBody : StaticBody3D,shootThrough : bool,textureName : String):
	
	staticBody.set_collision_layer_value(1,true)#stops actors
	staticBody.set_collision_layer_value(2,true)#stops bullets
	
	
	if hasCollision == false:
		staticBody.set_collision_layer_value(1,false)#stops nothing
		staticBody.set_collision_layer_value(2,false)

	
	if shootThrough or textureName == "F_SKY1":
		staticBody.set_collision_layer_value(2,false)#doesn't stop bullets

func getSideNodePaths(sideIdxArr : PackedInt32Array) -> Array:
	var sideNodes :  Array = []
	for idx : int in sideIdxArr:
		if sideNodePath.has(idx):
			var node = sideNodePath[idx]#get mesh node for sideIdx
			var p = node.get_parent()
			var path
			
			
			if p.get_class() == "CharacterBody3D":#a kinemtatic body with mesh as child
				path = "Geometry/" + p.get_parent().get_parent().name + "/" + p.get_parent().name + "/" + p.name
			else:#a mesh with a static body as child
				path = ("Geometry/" + node.get_parent().get_parent().name + "/" + node.get_parent().name)
			#path = Gerometry/sector/linenode
			
			var lineNode = mapNode.get_node(path)
			if lineNode == null:
				continue
			for c in lineNode.get_children():
				var sidePath = path + "/" + c.name
				sideNodes.append(sidePath)

	return sideNodes
	
func createAudioPlayback(soundName,loop=false):
	

	
	var audioStream =   resourceManager.fetchSound(soundName)
	var audioPlay = AudioStreamPlayer3D.new()
	audioPlay.stream = audioStream
	
	return audioPlay
	


func createInteractionAreaNode(line : Dictionary,depth : float,tType : int,nameStr : String ="interactionBox") -> Area3D:
	var scaleFactor : Vector3 = get_parent().scaleFactor
	var areaNode : Area3D = Area3D.new()
	var collisionNode := CollisionShape3D.new()
	var shapeNode := BoxShape3D.new()
	
	var startVert : Vector2 = verts[line["startVert"]]
	var endVert : Vector2= verts[line["endVert"]]
	var length : Vector2=  endVert-startVert
	var sector : Dictionary= sectors[line["frontSector"]]
	
	if tType == TTYPE.WALK1 or tType == TTYPE.WALKR:
		areaNode.set_script(load("res://addons/godotWad/src/interactables/walkTrigger.gd"))
		if tType == TTYPE.WALK1:
			areaNode.W1 = true
		areaNode.body_entered.connect(areaNode.bin)
		areaNode.lineStart = startVert
		areaNode.lineEnd = endVert
	
	var maxHeight : float = sector["ceilingHeight"]
	var types = []
	
	if mapDict["sectorToInteraction"].has(line["frontSector"]):
		types +=mapDict["sectorToInteraction"][line["frontSector"]]
	
	if line["backSector"] != -1:
		if mapDict["sectorToInteraction"].has(line["backSector"]):
			types +=mapDict["sectorToInteraction"][line["backSector"]]
	
	
	var hasTeleport = false
	
	for i in types:
		var typeInt = var_to_str(i["type"])
		var typeInfo = typeSheet.data[typeInt]
		if mapDict["isHexen"] == true:
			typeInfo = typeDictHexen.data[typeInt]
		
		var destType = 0
		var dest = null
		
		if typeInfo.has("dest"):
			dest = WADG.getDest(typeInfo["dest"],sector,scaleFactor.y)
		
		if typeInfo.has("lowerBy"):
			dest = sector["floorHeight"] - typeInfo["lowerBy"]

		
		if dest == null:
			if   typeInfo["type"] == WADG.LTYPE.LIFT:    dest = sector["lowestNeighFloorExc"]
			elif typeInfo["type"] == WADG.LTYPE.DOOR:    dest = sector["lowestNeighCeilExc"]
			elif typeInfo["type"] == WADG.LTYPE.CRUSHER: dest = sector["floorHeight"]
			elif typeInfo["type"] == WADG.LTYPE.TELEPORT: hasTeleport = true

		if dest != null:
			if dest > maxHeight:
				maxHeight = dest


	var height = maxHeight - sector["floorHeight"]
	
	
	var dim = Vector3(length.length()/2.0,height/2,1)
	var angle = length.angle_to(Vector2.UP) + 1.5707963267949
	var h = sector["floorHeight"]+height/2
	
	var startVec = Vector3(startVert.x,h,startVert.y)
	var endVec = Vector3(endVert.x,h,endVert.y)
	var mid = (startVec + endVec)/2
	
	var diff = startVec - endVec
	
	var normal = Vector3(diff.z,diff.y,-diff.x).normalized()
	areaNode.set_meta("normal",normal)
	var areaCenter = mid + normal*depth
	
	if hasTeleport or tType == TTYPE.WALK1 or TTYPE.WALKR:
		areaCenter = mid - normal*(depth/2.0)
	
	#WADG.drawLine(self,startVec,endVec)
	#WADG.drawSphere($"/root",mid,Color.red)
	#WADG.drawSphere($"/root",mid,Color.red)
	#WADG.drawLine($"/root",mid,mid+normal)
	
	dim = Vector3(abs(dim.x),abs(dim.y),abs(dim.z))
	dim.z = depth

	areaNode.rotation.y = angle
	areaNode.position = areaCenter
	
	shapeNode.extents = dim
	collisionNode.shape = shapeNode
	areaNode.add_child(collisionNode)
	areaNode.name = nameStr 
	
	
	
	return areaNode


func createSurroundingSkybox(dim,minDim):
	var meshInstance = MeshInstance3D.new()
	var cubeMesh = BoxMesh.new()
	cubeMesh.size = dim+Vector3(20,100,20)*scaleFactor#add a small buffer to prevent z-fighing
	cubeMesh.flip_faces = true
	meshInstance.mesh = cubeMesh 
	meshInstance.position = minDim + (dim/2)

	cubeMesh.size.y += 100
	meshInstance.position.y += 100/2.0
	var texName : String = $"../ImageBuilder".getSkyboxTextureForMap(mapName) 
	cubeMesh.material =  materialManager.fetchSkyMat(texName)
	meshInstance.name = "Surrounding Skybox"
	mapNode.add_child(meshInstance)
	meshInstance.create_trimesh_collision()
	meshInstance.set_owner(mapNode)

		
	

func getStairSectors(mapDict,frontSides,sectorIdx):
	var stairSectors = [sectorIdx]
	var nextSector = getNextStairSector(frontSides,stairSectors)
	
	while nextSector != null:
		stairSectors.append(nextSector)
		frontSides = mapDict["sectorToFrontSides"][nextSector]
		nextSector = getNextStairSector(frontSides,stairSectors)
		
	return stairSectors
	

func getNextStairSector(frontSides,curStairs):
	for sideIdx in frontSides:
		var side = sideDefs[sideIdx]
		if side["backSector"] != null: 
			if !curStairs.has(side["backSector"]):
				return side["backSector"]
			
	return null



func makeFloorKinematic(flr):
	
	var flrParent = flr.get_parent()
	var colNode = flr.get_child(0)
	flr.get_parent().remove_child(flr)
	#flr.remove_child(colNode)
	var floorKine = CharacterBody3D.new()
	
	flrParent.add_child(floorKine)
	floorKine.add_child(flr)
	
	
func makeAreaForCeilFloor(cf):
	return
	var colNode = cf.get_child(0).duplicate()
	var shapeNode = colNode.get_child(0)
	
	var area = Area3D.new()
	area.position.y -= 1
	colNode.remove_child(shapeNode)
	area.add_child(shapeNode)
	colNode.queue_free()
	area.name = "area"
	cf.add_child(area)
	
	

func isSideAnimatedSwitch(side):
	
	if WADG.isASwitchTexture(side["lowerName"], $"../ImageBuilder".switchTextures): return true
	if WADG.isASwitchTexture(side["middleName"], $"../ImageBuilder".switchTextures): return true
	if WADG.isASwitchTexture(side["upperName"], $"../ImageBuilder".switchTextures): return true
	
	return false

func addSoundsToNode(node,arr):
	var start = createAudioPlayback(arr[2])
	start.name=arr[0]
	var stop = createAudioPlayback(arr[3])
	stop.name=arr[1]
	node.add_child(start)
	node.add_child(stop)


func fetchInteractableParentNode(mapNode : Node3D,sectorNodeName : String,pos : Vector3):
	
	var sectorInteractionParent
	if !mapNode.get_node("Interactables").has_node(sectorNodeName):
		sectorInteractionParent = Node3D.new()
		sectorInteractionParent.position = pos
		sectorInteractionParent.name = sectorNodeName
		sectorInteractionParent.set_meta("owner",false)
		mapNode.get_node("Interactables").add_child(sectorInteractionParent)
		return sectorInteractionParent
		
	sectorInteractionParent = mapNode.get_node("Interactables").get_node(sectorNodeName)
	return sectorInteractionParent
	
func getTextureTriggerModel(sector,destH):
	return [sector["floorTexture"],sector["type"]]

func getTextureNumericModel(sector,destH):
	
	var oSides = mapDict["sectorToBackSides"][sector["index"]]
	oSides.sort()
	
	
	for i in oSides:
		var side = sideDefs[i]
		var sideSector = sectors[side["sector"]]
		if sideSector["floorHeight"] == destH:
			return [sideSector["floorTexture"],sideSector["type"]]
#	for i in sector["nieghbourSectors"]:
	#	var oSec = sectors[i]
	#	sectorToBackSides
		#for lineIdx in mapDict["sectorToSides"][i]:
		#	var line= lines[line]
		#	breakpoint
		#if oSec["floorHeight"] == destH:
				
		
	return null

func initLowerTextureHeights(mapDict : Dictionary) -> void:
	
	for sector : Dictionary in mapDict["sectorsParsed"]:

		var lowest : float = INF
		
		if sector.has("lowerTextures"):
			for i in sector["lowerTextures"]:
				var texture : Texture2D =  resourceManager.fetchPatchedTexture(i)
				
				if texture == null:
					continue
				
				if texture.get_class() == "ImageTexture":
					if texture.get_image().get_height() < lowest:
						lowest =  texture.get_image().get_height()
				else:
					var t = texture.get("frame_0/texture")
					if t != null:
						if t.get_image().get_height() < lowest:
							lowest = t.get_image().get_height()
				
		sector["lowestTextureHeight"] = lowest


func initLowerTextureHeights2(mapDict : Dictionary) -> void:
	var sectors : Array = mapDict["sectorsParsed"]
	for sector : Dictionary in mapDict["sectorsParsed"]:
		
		var lowest : float = sector["lowestTextureHeight"]
		
		for i in sector["nieghbourSectors"]:
			if sectors[i]["lowestTextureHeight"] < lowest:
				lowest = sectors[i]["lowestTextureHeight"]
				
		
		if lowest == INF:
			lowest = INF
			
	
		sector["lowestTextureHeight"] = lowest
	
func makeConvexCollision(start:Vector2,end:Vector2,floorZ:float,ceilZ:float,node):
	var origin : Vector3 = Vector3(start.x,ceilZ,start.y)
	var height : float = ceilZ-floorZ 


	var TL : Vector3 = Vector3(start.x,ceilZ,start.y) - origin
	var BL : Vector3 = Vector3(start.x,floorZ,start.y) -origin
	var TR  : Vector3= Vector3(end.x,ceilZ,end.y) - origin
	var BR : Vector3= Vector3(end.x,floorZ,end.y) - origin
	
	
	
	return createColSimple([TL,BL,TR,BR],node,origin)
	#return createColSimple2([TL,BL,TR,BR],node,origin,start,end,height)

func createColSimple(verts : Array,meshNode : Node,center : Vector3):
	var colInstance = CollisionShape3D.new()
	var colShape = ConvexPolygonShape3D.new()
	var body = StaticBody3D.new()
	var points = PackedVector3Array()
	#colShape.points = []

	for i in verts:
		points.append(Vector3(i.x,i.y,i.z)+center)

	
	colShape.points = points
	colInstance.shape = colShape
	body.add_child(colInstance)
	meshNode.add_child(body)
	return body

func createColSimple2(verts : Array,meshNode : Node,center : Vector3,start,end,height):
	var colInstance = CollisionShape3D.new()
	var colShape = BoxShape3D.new()
	var body = StaticBody3D.new()
	var points = PackedVector3Array()
	
	
	var length :Vector2=  start-end
	var dim :Vector3 = Vector3(length.length(),height,0.001)
	var angle : float= length.angle_to(Vector2.UP) + deg_to_rad(90)
	
	dim = Vector3(abs(dim.x),abs(dim.y),abs(dim.z))

	colShape.size = dim
	colInstance.shape = colShape
	body.add_child(colInstance)
	body.rotation.y = angle
	body.position = center-(dim/2.0).rotated(Vector3.UP,angle)
	
	
	meshNode.add_child(body)
	return body
	

func checkMeshCache(start:Vector2,end:Vector2,floorZ:float,ceilZ:float,fCeil:float,texture:Texture2D,uvType:TEXTUREDRAW,textureOffset:Vector2):	
	return

func setFtypeAndTexture(interactionAreaNode : Node ,sectorIdx : int,typeInfo : Dictionary,line : Dictionary):


	var sector = sectors[sectorIdx]
	var fTexture = sector["floorTexture"]
	var fType = 0  

	if get_parent().sectorSpecials.has(sector["type"]):
		fType = get_parent().sectorSpecials[sector["type"]]

	
	if typeInfo.has("changeTexture"):
		if typeof(typeInfo["changeTexture"]) == TYPE_BOOL:
			if typeInfo["changeTexture"] == true:
				var model : String = typeInfo["model"]
				var res
							
				if model == "trigger":
					res = getTextureTriggerModel(sectors[line["frontSector"]],WADG.getDest(typeInfo["dest"],sector,scaleFactor.y))
							
				elif model == "numeric":
					res = getTextureNumericModel(sector,WADG.getDest(typeInfo["dest"],sector,scaleFactor.y))#[sideSector["floorTexture"],sideSector["type"]]
				else:
					breakpoint
				if res != null :
					fTexture = res[0]
					fType = get_parent().sectorSpecials[res[1]]
	
	
	
		interactionAreaNode.set_meta("fType",fType)
		interactionAreaNode.set_meta("fTextureName",fTexture)#some types need to know the floor texture the line is facing
		if fTexture in interactionAreaNode:
			interactionAreaNode.fTexture = resourceManager.fetchFlat(fTexture)
		interactionAreaNode.set_meta("fTextureName",resourceManager.fetchFlat(fTexture))#some types need to know the floor texture the line is facing
	
