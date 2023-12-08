tool
extends Node

enum LINDEF_FLAG{
	BLOCK_CHARACTERS = 0x01,
	BLOCK_MONSTERS = 0x02,
	TWO_SIDED = 0x4
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
}



var typeToScript ={}



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


var damageSectorTypes = [4,5,7,11,16]

export(Resource) var typeSheet = preload("res://addons/godotWad/resources/lineTypes.tres")
	

var typeDictHexen =  {
	-2:{"type":LTYPE.FLOOR,"str":"stair"},
	0:{"type":LTYPE.DUMMY,"str":"dummy"},
	10:{"type":LTYPE.DOOR,"str":"Door Close","arg1":"sectorTag","direction":DIR.DOWN},
	11:{"type":LTYPE.DOOR,"str":"Door Open","arg1":"sectorTag"},
	13:{"type":LTYPE.DOOR,"str":"Door Open"},
}

var mapTo666 = {
	"E1M8":{"type":23,"npcName":"baronOfHell"},
	"E2M8":{"type":11,"npcName":"baronOfHell"},
	"E3M8":{"type":11,"npcName":"baronOfHell"},
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
	"stayOpen",
	"triggerType",
	"speed",
	"secret"
]


var typeSounds ={
	LTYPE.FLOOR:["openSound","closeSound","DSSTNMOV","DSSTNMOV"],
	LTYPE.LIFT:["openSound","closeSound","DSPSTART","DSPSTOP"],
	LTYPE.DOOR:["openSound","closeSound","DSDOROPN","DSDORCLS"],
	LTYPE.CRUSHER:["openSound","closeSound","DSSTNMOV","DSSTNMOV"]
}

var sideDefs
var sectors
var verts 
var lineToSide
var lines
var sides 
var geomNode = null
var sideNodePath = {}
var preInstancedMeshes = {}
var scaleFactor = 1
var mapName 
var mapNode 
var mapDict
var occluderCount = 0
var occludersByArea = []

func _ready():

	set_meta("hidden",true)
	

func createLevel(mapDict,mapname,mapNodei):
	var startTime = OS.get_system_time_msecs()
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
	
	
	self.mapDict =mapDict
	
	initLowerTextureHeights(mapDict)
	initLowerTextureHeights2(mapDict)
	mapNode = mapNodei
	
	mapName = mapname
	
	occludersByArea = []

	mapNode.name = mapname
	mapNode.set_meta("map",true)
	
	
	get_parent().mapNode = mapNode
	mapNode.set_script(load("res://addons/godotWad/src/mapNode.gd"))
	
	mapNode.transform = get_parent().transform
	
	
	geomNode = NavigationMeshInstance.new()
	
	var navMesh = NavigationMesh.new()
	
	geomNode.navmesh = navMesh
	
	navMesh.set_parsed_geometry_type( NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS)
	navMesh.set_sample_partition_type(NavigationMesh.SAMPLE_PARTITION_MONOTONE)
	navMesh.agent_radius = 0.5
	navMesh.agent_max_climb = 0.8
	
	geomNode.name = "Geometry"
	mapNode.add_child(geomNode)
	
	var specialNode = Node.new()
	specialNode.name = "SectorSpecials"
	mapNode.add_child(specialNode)
	
		
	var ineteractablesNode = Spatial.new()
	ineteractablesNode.name = "Interactables"
	mapNode.add_child(ineteractablesNode)
	
	
	
	preInstancedMeshes = {}
	sideNodePath = {}

	sideDefs = mapDict["SIDEDEFS"]
	sectors = mapDict["SECTORS"]
	verts = mapDict["VERTEXES"]
	lines = mapDict["LINEDEFS"]
	sides = mapDict["SIDEDEFS"]
	
	var a = OS.get_system_time_msecs()
	if get_parent().floorMethod == get_parent().FLOORMETHOD.old:
		$"../FloorBuilder".instance(mapDict,geomNode,specialNode)
	elif get_parent().floorMethod == get_parent().FLOORMETHOD.new:
		
		$"../FloorBuilderNew".instance(mapDict,geomNode,specialNode)
	else:
		
		$"../FloorBuilder3".instance(mapDict,geomNode,specialNode)
	
	

	for r in mapDict["staticRenderables"]:
		createStaticSide(r)
	
	var count = 0
	for r in mapDict["dynamicRenderables"]:
		createDynamicSide(r)
		count +=1
		
	
	if get_parent().mergeMesh != get_parent().MERGE.DISABLED:
		$"../MeshCombiner".merge(preInstancedMeshes,geomNode,mapName)
		

	
	createInteractables(mapDict["sectorToInteraction"],mapDict)
	
	if mapDict["createSurroundingSkybox"]:
		createSurroundingSkybox(mapDict["BB"],mapDict["minDim"])
	
	
	

	
	if occludersByArea.size() > get_parent().maxOccluderCount:
		var overflow = occludersByArea.slice(get_parent().maxOccluderCount,occludersByArea.size())
		for i in overflow:
			i[1].queue_free()
			
	
	WADG.setTimeLog(get_tree(),"levelBuild",startTime)
	print("return map")
	return mapNode
	
	



func createStaticSide(renderable):
	var start = verts[renderable["startVertIdx"]]
	var end =  verts[renderable["endVertIdx"]]
	var sector = sectors[renderable["sector"]]
	var oSectorIdx = renderable["oSector"]
	var type = renderable["type"]
	var dir = renderable["dir"]
	var fFloor = sector["floorHeight"]
	var fCeil = sector["ceilingHeight"]
	var textureName = renderable["texture"]
	var flags = renderable["flags"]
	var textureOffset = renderable["textureOffset"]
	var lowerUnpegged = (flags &  LINDEF_FLAG.LOWER_UNPEGGED) != 0
	var upperUnpegged = (flags &  LINDEF_FLAG.UPPER_UNPEGGED) != 0
	var doubleSided = (flags & LINDEF_FLAG.TWO_SIDED) != 0
	
	
	

	
	var hasCollision = flags & LINDEF_FLAG.BLOCK_CHARACTERS == 1
	
	#if oSectorIdx == null:
	#	hasCollision = true
		
		
	if type != "middle": hasCollision = true#only floating mids can be fake walls
	
	
	var floorDraw = TEXTUREDRAW.TOPBOTTOM
	var midDraw = TEXTUREDRAW.TOPBOTTOM
	var ceilDraw = TEXTUREDRAW.BOTTOMTOP
	var lineIndex = renderable["lineIndex"]

	
	if lowerUnpegged: 
		floorDraw = TEXTUREDRAW.GRID
		midDraw = TEXTUREDRAW.BOTTOMTOP
	
	if upperUnpegged:
		ceilDraw = TEXTUREDRAW.GRID
	

	
	if type == "trigger":return
	

	var texture

	if textureName == "F_SKY1":
		var textureSky = $"../ImageBuilder".getSkyboxTextureForMap(mapName)
		texture = $"../ResourceManager".fetchPatchedTexture(textureSky,!get_parent().dontUseShader)
	else:
		texture = $"../ResourceManager".fetchPatchedTexture(textureName,!get_parent().dontUseShader)

	
		
	
	if texture == null:
		texture = $"../ResourceManager".fetchFlat(textureName)

	var oSectorSky = false
	if oSectorIdx != null:
		if sectors[oSectorIdx]["ceilingTexture"] == "F_SKY1":
			oSectorSky = true
	
	
	
	if type == "skyUpper":
		if oSectorIdx != null:
			if sectors[oSectorIdx]["ceilingTexture"] == "F_SKY1":
				return
		
	
		if fCeil < sector["highestNeighCeilInc"]:
			createMeshAndCol(start,end,fCeil,sector["highestNeighCeilInc"],sector["highestNeighCeilInc"],texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir,false)
			return
		else:
			return

	
	
	
	if sector["ceilingTexture"] == "F_SKY1" and type!="lower" and oSectorSky and renderable["oSide"]["upperName"] == "-" and oSectorIdx and type == "upper" :#if my ceiling is sky and I'm not lower and oSector is also sky then I'm sky 
		return # this stops the floating walls e.g. E1M1

	
	if oSectorIdx == null:#if oSector is null we only every render the mid
		if type == "middle":
			createMeshAndCol(start,end,fFloor,fCeil,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir,false)
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
	

	if type == "middle" and !doubleSided:
		
		
		
		createMeshAndCol(start,end,fFloor,fCeil,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir,false)
		return 
		
	if type == "middle" and doubleSided and texture != null:#floating mid
		
		var h = texture.get_height() * scaleFactor.y
		var shootThrough = false
		
		if oSector != null and doubleSided != false: shootThrough = true
		
		if lowerUnpegged:
			createMeshAndCol(start,end,highFloor+textureOffset.y,highFloor+textureOffset.y+h,fCeil,texture,midDraw,Vector2(textureOffset.x,0),renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir,shootThrough)
			return
		
		else:#lower unpegged and no pegged seems to be the same
			var a = lowCeil+textureOffset.y-h
			var b = highFloor
			createMeshAndCol(start,end,max(a,b),lowCeil+textureOffset.y,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir,shootThrough)
			return
		return
	
	if type == "upper" and fCeil > oCeil:#upper section
		if sector["ceilingTexture"] == "F_SKY1" and  oSector["ceilingTexture"] == "F_SKY1":
			return
			
		createMeshAndCol(start,end,lowCeil,highCeil,fCeil,texture,ceilDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir)
	
	if type == "lower" and fFloor < oFloor:#lower section
		createMeshAndCol(start,end,lowFloor,highFloor,fCeil,texture,floorDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],dir)
	



func createDynamicSide(renderable):
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
	 
	
	
	
	var texture = $"../ResourceManager".fetchPatchedTexture(textureName,!get_parent().dontUseShader)
	
	if texture == null:
		print("failed to fetch patched texture:",textureName)

	var oSectorSky = false
	if oSectorIdx != null:
		if sectors[oSectorIdx]["ceilingTexture"] == "F_SKY1":
			oSectorSky = true
	


	
	var dest = fFloor
	var minDest = INF
	var maxDest = -INF
	var destH = fFloor
	
	var tDict = typeSheet.data
	var hasLoop = false
	if mapDict["isHexen"]: tDict = typeDictHexen
	
	
	for t in sTypes:
		
		var ty = t["type"]
		
		
		
		if ty == -2 and renderable.has("stairInfo"):
			destH = sector["floorHeight"]+16.0*scaleFactor.y*renderable["stairInfo"]["stairNum"]
		
		var row = tDict[var2str(ty)]
		
		
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
			createMeshAndCol(start,end,min(fFloor,minDest),max(fCeil,maxDest),fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,true,renderable["sType"],dir)
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
			var ty = var2str(t["type"])
			var row = tDict[ty]
			
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


	if type == "middle" and !doubleSided:
		createMeshAndCol(start,end,lowestLocalFloor,highestOFloor,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,true,renderable["sType"],false)
		return 
	
	
	
	if type == "middle" and doubleSided and texture != null:#floating mid
		var h = texture.get_height() * scaleFactor.y
		var shootThrough = false
		
		
		
		
		
		if oSector != null and doubleSided != false: shootThrough = true
		
		
		
		if lowerUnpegged:
			
			createMeshAndCol(start,end,highFloor+textureOffset.y,highFloor+textureOffset.y+h,fCeil,texture,midDraw,Vector2(textureOffset.x,0),renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],shootThrough)
			return
			#var wallNode = createWall(startVert,endVert,start,end,midDraw,Vector2(offset.x,0),hasCollision,texture,fCeil,String(lineIndex)+" mid",type,sectorLight)
		
		else:#lower unpegged and no pegged seems to be the same
			
			#createMeshAndCol(start,end,fCeil+textureOffset.y-h,fCeil+textureOffset.y,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,true,renderable["sType"])

			
			var a = lowCeil+textureOffset.y-h
			var b = highFloor
			
			
			createMeshAndCol(start,end,max(a,b),lowCeil+textureOffset.y,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],shootThrough)
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

			createMeshAndCol(start,end,wallBot,wallTop,fCeil,texture,floorDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,true,renderable["sType"],dir)


	if type == "upper":
		var bottom = min(minDest,minOdest)
		
		var wallBottom = oCeil
		var wallTop = oCeil + (highestLocalCeil-lowestOCeil)
		
	
		if wallBottom < wallTop: 
			createMeshAndCol(start,end,wallBottom,wallTop,fCeil,texture,ceilDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,true,renderable["sType"],dir)
	return
	
	
func makeSideMesh(start,end,floorZ,ceilZ,fCeil,texture,uvType,textureOffset,sideIndex,sector,textureName,sType):
	var origin = Vector3(start.x,ceilZ,start.y)
	var height = ceilZ-floorZ 
	var startUVy = 0
	var startUVx = 0
	var endUVy= 0
	var endUVx = 0
	var scaleFactor = get_parent().scaleFactor
	#var origin = Vector3(start.x,floorZ,start.y) -  Vector3(end.x,ceilZ,end.y)/2.0


	if texture != null:
		var textureDim = texture.get_size() * Vector2(scaleFactor.x,scaleFactor.y)
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
	
	var TL = Vector3(start.x,ceilZ,start.y) - origin
	var BL = Vector3(start.x,floorZ,start.y) -origin
	var TR = Vector3(end.x,ceilZ,end.y) - origin
	var BR = Vector3(end.x,floorZ,end.y) - origin
	
	var line1 = TL - TR
	var line2 = TL - BL
	var normal = -line1.cross(line2).normalized()

	var surf = SurfaceTool.new()
	var mesh = Mesh.new()
	var mat
	
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)



	if texture!=null and textureName != "F_SKY1":
		var inc = 0
		if start.y == end.y: inc = -1
		elif start.x == end.x: inc = 1
		
		var scroll = Vector2(0,0)
		var alpha = 1.0
		
		var typeStr = var2str(sType)
		
		if typeSheet.getRow(typeStr)["type"] == LTYPE.SCROLL:
			if typeSheet.getRow(typeStr).has("vector"):
				scroll = typeSheet.getRow(typeStr)["vector"]
				
			if typeSheet.getRow(typeStr).has("specialType"):
				scroll = textureOffset/Vector2(get_parent().scaleFactor.x,get_parent().scaleFactor.y)
		
		if typeSheet.getRow(typeStr).has("alpha"):
			alpha = typeSheet.getRow(typeStr)["alpha"]
		
		mat =  $"../ResourceManager".fetchMaterial(textureName,texture,sector["lightLevel"],scroll,alpha,inc,true)
		
	
	if textureName == "F_SKY1":
		var texName : String = $"../ImageBuilder".getSkyboxTextureForMap(mapName) 
		mat = $"../ResourceManager".fetchSkyMat(texName,true)
	
	surf.set_material(mat)
		

	surf.add_normal(normal)
	surf.add_uv(Vector2(startUVx,startUVy))
	surf.add_vertex(TL)
	
	surf.add_normal(normal)
	surf.add_uv((Vector2(endUVx,startUVy)))
	surf.add_vertex(TR)
	
	surf.add_normal(normal)
	surf.add_uv(Vector2(endUVx,endUVy))
	surf.add_vertex(BR)
	
	
	surf.add_normal(normal)
	surf.add_uv(Vector2(startUVx,startUVy))
	surf.add_vertex(TL)
	
	surf.add_normal(normal)
	surf.add_uv(Vector2(endUVx,endUVy))
	surf.add_vertex(BR)
	
	surf.add_normal(normal)
	surf.add_uv(Vector2(startUVx,endUVy))
	surf.add_vertex(BL)
	
	#surf.index()
	
	surf.commit(mesh)
	mesh.surface_set_name(mesh.get_surface_count()-1,textureName)
	
	if get_parent().unwrapLightmap:
		mesh.lightmap_unwrap(Transform.IDENTITY,1)
	var meshNode = MeshInstance.new()
	meshNode.translation = origin
	meshNode.mesh = mesh
	
	
	
#	if get_parent().addOccluder:
#		var length =  (end-start).length()
#		addOccluerToMesh2(meshNode,start,end,height)

	
	
	if texture == null and textureName !="F_SKY1" and !get_parent().renderNullTextures:
		meshNode.visible = false
	

	meshNode.name = "sidedef " + sideIndex
	return meshNode

func addOccluerToMesh(mesh,verts,normal,width,height,start,end):
	var length =  end-start
	var occShape = OccluderShapePolygon.new()
	var occ = Occluder.new()
	var xy : PoolVector2Array= []
	var rotRad = (atan2(normal.x,normal.y))
	rotRad = length.angle_to(Vector2.UP) + deg2rad(90)
	
	for i in verts:
		
		var u= i.dot(Vector3(1,0,0))
		var v= i.dot(Vector3(0,1,0))
		#xy.append(Vector2(i.x,i.y))
		xy.append(Vector2(u,v))
	

	var center = Vector2(width,height)/2.0
	var TL = Vector2(-width,height)/2.0 - center
	var TR = Vector2(width,-height)/2.0- center
	var BL = Vector2(-width,-height)/2.0- center
	var BR = Vector2(width,height)/2.0- center
	
	xy = [TL,TR,BR,BL]
	
	occ.rotate_y(rotRad + deg2rad(90))
	occ.shape = occShape
	#occ.rotation.y = rotRad
	mesh.add_child(occ)
	occShape.polygon_points = PoolVector2Array(xy)
	
	
func addOccluerToMesh2(mesh,startVert,endVert,height,origin):
	occluderCount+=1
	var length =  endVert-startVert
	var dim = Vector3(length.length(),height,1)
	var angle = length.angle_to(Vector2.UP) + deg2rad(90)
	
	dim = Vector3(abs(dim.x),abs(dim.y),abs(dim.z))
	
	var area = dim.x * dim.y * dim.z
	var TL = Vector2(0,0)
	var TR = Vector2(dim.x,0)
	var BR = Vector2(dim.x,-height)
	var BL  = Vector2(0,-height)
	
	
	var occShape = OccluderShapePolygon.new()
	var occ = Occluder.new()
	var xy : PoolVector2Array= [TL,TR,BR,BL]
	occShape.polygon_points = PoolVector2Array(xy)
	
	
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
	
	occ.shape = occShape
	occ.translation = origin
	occ.rotation.y = angle
	
	mesh.add_child(occ)
	#occShape.polygon_points = PoolVector2Array(xy)
	
func createMeshAndCol(start,end,floorZ,ceilZ,fCeil,texture,uvType,textureOffset,sideIndex,lineIndex,sectorIdx,nameStr,hasCollision,textureName,isDynamic,sType,dir,shootThrough = false):
	var side = sides[int(sideIndex)]
	var oSectorIdx = side["backSector"]
	var sector = sectors[sectorIdx]
	var sectorIdxPre = sectorIdx
	sectorIdx = "sector " + String(sectorIdx)
	var sectorNode = geomNode.get_node(sectorIdx)
	
	
	if textureName == "F_SKY1":
	#	textureName = $"../ImageBuilder".getSkyboxTextureForMap(mapName) 
		shootThrough = true
	
	if texture == null:
		print("we createing mesh and col but texture %s is null" % textureName)
		
	if sectorNode == null:
		print("couldn't find sector node for line:",String(lineIndex))
		sectorNode = Spatial.new()
		sectorNode.name = "sector node"
		get_parent().add_child(sectorNode)
		
		
	
	#if dir == 1:
	#	isDynamic = false
	
	
	if sectorNode.get_node_or_null(String(lineIndex)) == null: #and isDynamic:#if it isn't dynamic it will be merged and a mesh won't exist for this node to parent
		var lineNode = Spatial.new()
		lineNode.name =  "linenode " + String(lineIndex)
		sectorNode.add_child(lineNode)
	
	
	
	
	
	var diff = (end-start).normalized()
	#start -= diff*0.00001
	#end += diff*0.00001
	
	
	if get_parent().addOccluder:
		var length =  (end-start).length()
		var height = ceilZ-floorZ 
		var origin = Vector3(start.x,ceilZ,start.y)
		var flags = lines[lineIndex]["flags"]
		var doubleSided = (flags & LINDEF_FLAG.TWO_SIDED) != 0
		
		#if !doubleSided:
		if texture != null and texture.get_data() != null:
			if length >= get_parent().occMin and height >= get_parent().occMin:
				if !texture.get_data().detect_alpha() and !isDynamic:
					var bb = mapDict["BB"]  + (mapDict["minDim"] + (mapDict["BB"]/2))
					
					
					var b0 = true
					
					if oSectorIdx != null:
						if nameStr == "lower" and  sectors[oSectorIdx]["floorHeight"] - (sector["floorHeight"]) < 10 * scaleFactor.y:
							b0 = false
					
					if b0:
						var c = get_parent().occluderBBclip
						
						var b1 = (origin.x -mapDict["minDim"].x) < c
						var b2 = (mapDict["maxDim"].x - origin.x) < c
						
						var b3 = (origin.z -mapDict["minDim"].z) < c
						var b4 = (mapDict["maxDim"].z - origin.z) < c
						
						if abs(origin.x - bb.x) > 9*scaleFactor.x:
							if oSectorIdx == null:
								 height = bb.y
								 origin.y = bb.y / 2
							
							if !b1 and !b2 and !b3 and !b4:
								addOccluerToMesh2(sectorNode,start,end,height,origin)
					#else:
					#	breakpoint
	
	#if !isDynamic or oSectorIdx == null:
	#	breakpoint
	#if get_parent().mergeMesh != get_parent().MERGE.DISABLED and (!isDynamic or oSectorIdx == null):# and textureName != "F_SKY1" :
	if get_parent().mergeMesh != get_parent().MERGE.DISABLED and !isDynamic:
		if !preInstancedMeshes.has(sectorIdxPre):
			preInstancedMeshes[sectorIdxPre] = []
			
		var lineNode = sectorNode.get_node("linenode " + String(lineIndex))
		
		var colMask = 1
		
		if shootThrough: colMask = 0
		if textureName == "F_SKY1": colMask = 0
		preInstancedMeshes[sectorIdxPre].append({"start":start,"end":end,"floorZ":floorZ,"ceilZ":ceilZ,"fCeil":fCeil,"uvType":uvType,"textureOffset":textureOffset,"sideIndex":sideIndex,"textureName":textureName,"texture":texture,"lineNode":lineNode,"sector":sector,"sectorNode":sectorNode,"colMask":colMask,"dir":dir,"hasCol":hasCollision})
		preInstancedMeshes[sectorIdxPre].append({"start":start,"end":end,"floorZ":floorZ,"ceilZ":ceilZ,"fCeil":fCeil,"uvType":uvType,"textureOffset":textureOffset,"sideIndex":sideIndex,"textureName":textureName,"texture":texture,"lineNode":lineNode,"sector":sector,"sectorNode":sectorNode,"colMask":colMask,"dir":dir,"hasCol":hasCollision})
		return
	
	
	
	
	
	
	var mesh = makeSideMesh(start,end,floorZ,ceilZ,fCeil,texture,uvType,textureOffset,sideIndex,sector,textureName,sType)
	mesh.create_trimesh_collision()
	#mesh.create_convex_collision()
	
	var lastChlildIdx = mesh.get_child_count()-1#if messh has occluder index will be 1 otherwise 0
	if hasCollision == false:
		mesh.get_child(lastChlildIdx).collision_mask = 0
		mesh.get_child(lastChlildIdx).collision_layer = 0
	
	if shootThrough or textureName == "F_SKY1":
		mesh.get_child(lastChlildIdx).collision_layer = 0
	
	
	if isDynamic:# and false:
		var colShape = mesh.get_child(lastChlildIdx).get_child(0)
		var staticCol = mesh.get_child(lastChlildIdx)

		mesh.name = "sidedef " + sideIndex
		mesh.set_meta("type",nameStr)

		var lineNode = sectorNode.get_node("linenode " + String(lineIndex))
		lineNode.add_child(mesh)
		sideNodePath[sideIndex] = mesh
		
	else:
		mesh.name = "sidedef " + sideIndex
		mesh.set_meta("type",nameStr)
		if get_parent().mergeMesh == get_parent().MERGE.DISABLED:
			var lineNode = sectorNode.get_node("linenode " + String(lineIndex))
			lineNode.add_child(mesh)
	
	
	if isDynamic:
		sideNodePath[sideIndex] = mesh
		var length =  (end-start).length()
		var height = ceilZ-floorZ 
		var origin = Vector3(start.x,ceilZ,start.y)
		var flags = lines[lineIndex]["flags"]
		if get_parent().addOccluder:
			if length >= get_parent().occMin and height >= get_parent().occMin:
				if texture != null:
					if !texture.get_data().detect_alpha():
						var c = get_parent().occluderBBclip
						
						var b1 = (origin.x -mapDict["minDim"].x) < c
						var b2 = (mapDict["maxDim"].x - origin.x) < c
							
						var b3 = (origin.z -mapDict["minDim"].z) < c
						var b4 = (mapDict["maxDim"].z - origin.z) < c
						
						if !b1 and !b2 and !b3 and !b4:
							addOccluerToMesh2(mesh,start,end,height,Vector3.ZERO)
		
	
	if textureName != "F_SKY":
		mesh.cast_shadow = MeshInstance.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		mesh.use_in_baked_light = true
	
	

func createInteractables(sectorToInteraction,mapDict):
	
	var tDict = typeSheet
	if mapDict["isHexen"]: tDict = typeDictHexen
	
	
	
	for secIndex in sectorToInteraction.keys():#for every sector
		var sectorInteraction = {}

		for i in sectorToInteraction[secIndex]:
			if !sectorInteraction.has(i["type"]):
				sectorInteraction[i["type"]] = []
			
			sectorInteraction[i["type"]].append(i)
		
		sectorToInteraction[secIndex].sort_custom(interactionSectorSort,"sort_asc")

		var originSectorIdx
		var animMeshPath = []
		
		

		for type in sectorInteraction.keys():#for every line type that the sector is targeted by
			#var lineType
			var triggerNodes = []
			
			for i in sectorInteraction[type]:#we have the type so we iterate each instance of that type (i lists the type and the line that targeted the sector)
				
				
				
			
				triggerNodes+= createTriggerNodeForType(i,secIndex)
				
				#if i["type"] == WADG.LTYPE.TELEPORT:
				if !triggerNodes.empty():
					triggerNodes.back().set_meta("targeterLineBackSector",i["line"]["backSector"])
				var lineThatTargets = i["line"]
				var sectorOfLineThatTargets = lineThatTargets["frontSector"]
				var pathPost = "Geometry/sector %s/linenode %s"%[sectorOfLineThatTargets,lineThatTargets["index"]]
				var path = "../../../" + pathPost
				
				if isSideAnimatedSwitch(sides[lineThatTargets["frontSideDef"]]):
					if mapNode.get_node_or_null(pathPost)!= null:
						for c in mapNode.get_node(pathPost).get_children():
							animMeshPath.append(path + "/" + c.name)
			

			
			#var typeInfo = tDict[type]
			var typeInfoS = typeSheet.getRow(var2str(type))
			
			#typeInfo = typeInfoS
			#var category = tDict[type]["type"]
			var category = typeInfoS["type"]

			if geomNode.get_node_or_null("sector " + String(secIndex)) == null:
				continue
			
			var sector = sectors[secIndex]
			var sectorNode = geomNode.get_node("sector " + String(secIndex))
			
			
			var ceilings = []
			var floorings = []
			
			var sectorFrontSides = mapDict["sectorToFrontSides"][secIndex]
			var sectorBackSides  = mapDict["sectorToBackSides"][secIndex]
			
			
			
			
			var frontSidesNodes  = getSideNodePaths(secIndex,sectorFrontSides)
			var backSideLinedefNodes  = getSideNodePaths(secIndex,sectorBackSides)
			
			var backSideSideDefNodes = []
			
			for c in backSideLinedefNodes:
				backSideSideDefNodes.append(c)
			
			for c in sectorNode.get_children():
				var path = "Geometry/" + c.get_parent().name + "/" + c.name
				
				if c.has_meta("floor"): 
					floorings.append(path)
					
				elif c.has_meta("ceil"):
					ceilings.append(path) 
					makeAreaForCeilFloor(c)
					
			
			
			var script
			var sectorGroup = {}
			var lightValue
			
			var node = Spatial.new()
			node.name = "nodeName"
			
			
			
			if typeInfoS.has("triggerType"):
				if typeInfoS["triggerType"] == WADG.TTYPE.SWITCH1 or typeInfoS["triggerType"] == WADG.TTYPE.SWITCHR:#button press sound
					var buttonSound = createAudioPlayback("DSSWTCHN")
					buttonSound.name="buttonSound"
					
					if node.has_node("triggerType"):
						node.get_node("triggerType").add_child(buttonSound)
					else:
						node.add_child(buttonSound)
						
					
			
			
			if category == LTYPE.CEILING or category == LTYPE.CRUSHER or category == LTYPE.DOOR:
				sectorGroup = {"targets":backSideSideDefNodes+ceilings,"sectorInfo":sector}

			
			if category == LTYPE.FLOOR or category == LTYPE.LIFT:
				sectorGroup = ({"targets":backSideSideDefNodes+floorings,"sectorInfo":sector})
		
		
			var fastDoor = false
			
			if typeInfoS.has("doorSpeed"):
				if typeInfoS["doorSpeed"] == DOORSPEED.FAST:
					fastDoor = true
		
			if category != LTYPE.FLOOR:
				if typeSounds.has(category):
					if !fastDoor:
						addSoundsToNode(node,typeSounds[category])
				
				if fastDoor:
					addSoundsToNode(node,["openSound","closeSound","DSBDOPN","DSBDCLS"])

			
			if category == LTYPE.TELEPORT:
				var teleportSound = createAudioPlayback("DSTELEPT")
				teleportSound.name="sound"
				node.add_child(teleportSound)
				
			
			
			
			if category == LTYPE.LIGHT:
				sectorGroup = {"targets":frontSidesNodes+floorings+ceilings,"sectorInfo":sector}
				if typeInfoS.has("value"):
					var value = typeInfoS["value"]
					
					if value < 0:
						if value == LIGHTCAT.HIGHEST_ADJ: lightValue = sector["brightestNeighValue"]
						if value == LIGHTCAT.LOWEST_ADJ: lightValue = sector["darkestNeighValue"]
					else:
						lightValue = value
					
			
			if category == LTYPE.STAIR and mapDict["stairLookup"].has(secIndex):
				var targetStairs = []
				var x =  mapDict["stairLookup"]
				var stairSectorDict = mapDict["stairLookup"][secIndex]

				for stairSectorIdx in stairSectorDict.keys():

					sectorBackSides  = mapDict["sectorToBackSides"][stairSectorIdx]
					backSideLinedefNodes  = getSideNodePaths(stairSectorIdx,sectorBackSides)
					sectorNode = geomNode.get_node("sector " + String(stairSectorIdx))
					var sectorFloor
					var sectorCeiling
					sector = sectors[stairSectorIdx]
					
					
					for c in sectorNode.get_children():
						if c.has_meta("floor"): 
							sectorFloor = [("Geometry/" + c.get_parent().name + "/" + c.name)]
						elif c.has_meta("ceil"): 
							sectorCeiling = [("Geometry/" + c.get_parent().name + "/" + c.name)]
					

					if sectorFloor == null: continue
						
					targetStairs.append({"targets":sectorFloor+backSideLinedefNodes,"sectorInfo":sector})
				sectorGroup = targetStairs
			
			if category != LTYPE.SCROLL:
				if typeToScript.has(category):
					script = load(typeToScript[category])
					node.set_script(script)
			
			
			
			for i in scriptAttributes:
				if typeInfoS.has(i):
					node.set(i,typeInfoS[i])
			
			if sectorGroup.has("targets"):
				if typeSounds.has(category):
					for i in sectorGroup["targets"]:
						var t = mapNode.get_node(i)
						
						if t.has_meta("floor"):
							addSoundsToNode(t,typeSounds[category])
			
			if "globalScale" in node: node.globalScale = get_parent().scaleFactor
			if "info" in node :node.info = sectorGroup
			if "targets" in node :node.targets = sectorGroup["targets"]
			if "type" in node: node.type = type
			
				
			if !typeInfoS.has("speed") and fastDoor:
				node.speed = 4
		
			if "animMeshPath" in node: node.animMeshPath = animMeshPath
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
			
			

			node.name = typeInfoS["str"]
			
			var mid = Vector3.ZERO
			
			
			
			var sectorNodeName = "Sector "+String(secIndex)
			var sectorInteractionParent  = fetchInteractableParentNode(mapNode,sectorNodeName,mid)
			
			
			for i in triggerNodes:
				node.add_child(i)
				i.owner = node


				if i.has_meta("gunTrigger"):
					var sideDefIdx = i.get_meta("sideDef")
					var activator = getSideNodePaths(null,[sideDefIdx])
					if activator.empty():
						continue
						
					var targetMesh = mapNode.get_node(activator[0])
					if targetMesh.get_child_count() == 0:
						continue
						
					var targetCol = targetMesh.get_child(0)
					targetCol.set_script(load("res://addons/godotWad/src/interactables/gunTrigger.gd"))
					targetCol.connect("takeDamage",node,"activate",[],2)
#					for tt in sectorGroup["targets"]:
#						
#						if targetMesh.get_child_count() > 0:
#							var targetCol = targetMesh.get_child(0)
#							targetCol.set_script(load("res://addons/godotWad/src/interactables/gunTrigger.gd"))
#							targetCol.connect("takeDamage",node,"activate",[],2)
							
				elif i.has_meta("npcTrigger"):
					i.set_script(load("res://addons/godotWad/src/interactables/npcTrigger.gd"))
					i.add_to_group("counter_"+i.get_meta("npcTrigger"),true)
				elif category == LTYPE.TELEPORT: 
					i.set_script(load("res://addons/godotWad/src/interactables/teleportTrigger.gd"))
				elif category == LTYPE.FLOOR: 
					i.set_script(load("res://addons/godotWad/src/interactables/floorTrigger.gd"))
					if i.has_method("bin") :
						#if i.get_signal_list().has("body_entered"):
						i.connect("body_entered",i,"bin",[],2)
						#else:
						#	breakpoint

						#if i.has_method("bout"):
						i.connect("body_exited",i,"bout",[],2)
						#else:
						#	breakpoint
				
				if i.has_method("takeDamage"):
					i.connect("takeDamage",node,"activate",[],2)
				
				
				if "sectorIdx" in i:
					i.sectorIdx = secIndex
				
				if node.has_method("bin") :i.connect("body_entered",node,"bin",[],2)
				if node.has_method("bout"):i.connect("body_exited",node,"bout",[],2)
			
		
							
			
			sectorInteractionParent.add_child(node)



func createTriggerNodeForType(i,secIndex):
	
	var originSectorIdx
	var triggerNodes = []
	var tDict = typeSheet.data
	if mapDict["isHexen"]: tDict = typeDictHexen
	
	var lineType = var2str(i["type"])#we assumne every linetype is the same
	var line = i["line"]
	var typeInfo = tDict[lineType]
	
	
	#if line["index"] == 34:
	#	breakpoint
	
	var triggerType = null
	if typeInfo.has("trigger"): 
		triggerType = typeInfo["trigger"]
	elif line.has("trigger"):
		triggerType = line["trigger"]
		
	if triggerType != null:
		if triggerType == TTYPE.SWITCH1 or triggerType == TTYPE.SWITCHR:
			originSectorIdx = line["frontSector"]#get sector that switch belongs to
			var pathPost = "Geometry/sector " +String(originSectorIdx) + "/linenode " + String(line["index"])
			var path = "../../../" + pathPost
	
		
			var frontSideDefIndex = mapDict["SIDEDEFS"][line["frontSideDef"]]

				
	if lineType == "-2" or typeInfo["type"] == LTYPE.SCROLL:
		return []
				

	var interactionAreaNode
				
				
	var depth = 9*scaleFactor.z
				
	
	
	if triggerType != null:
		if tDict[lineType]["type"] == LTYPE.TELEPORT:
			depth = 2*scaleFactor.z
			
		elif triggerType == TTYPE.SWITCH1 or triggerType == TTYPE.SWITCHR:
			depth = 10*scaleFactor.z
	
	if typeInfo["type"] == LTYPE.TELEPORT:
		depth = scaleFactor.z * 10
	
	
	
	
	var t = typeInfo["triggerType"]
	
	if t != TTYPE.GUN1 and t != TTYPE.GUNR:
		interactionAreaNode = createInteractionAreaNode(line,depth)
		interactionAreaNode.set_meta("lineStart",verts[line["startVert"]])
		interactionAreaNode.set_meta("lineEnd",verts[line["endVert"]])
		interactionAreaNode.set_meta("triggerType",triggerType)
		interactionAreaNode.set_meta("sectorIdx",sectors[secIndex])
	
		
		
		
		
		if i.has("npcTrigger"):
			interactionAreaNode.set_meta("npcTrigger",i["npcTrigger"])
		
		if i["line"].has("sectorTag"):
			interactionAreaNode.set_meta("sectorTag",i["line"]["sectorTag"])#for teleports the destination sector is set as a sector tag
		
		
		var mid = Vector2.ZERO
		
		#if sectors[secIndex].has("center"):
		#	mid =  sectors[secIndex]["center"]
		#	mid.y = sectors[secIndex]["ceilingHeight"] - sectors[secIndex]["floorHeight"]
		#	interactionAreaNode.translation -= mid
		
		if line["frontSector"] != null:
			var sector = sectors[line["frontSector"]]
			
			
			
			var fTexture = sector["floorTexture"]
			var fType = sector["type"]
			
			if typeInfo["direction"] == DIR.DOWN:
				if typeof(typeInfo["changeTexture"]) == TYPE_BOOL:
					if typeInfo["changeTexture"] == true:
						var num = getTextureNumericModel(sector,WADG.getDest(typeInfo["dest"],sector,scaleFactor.y))
						if num != null : 
							fTexture = num[0]
							fType = num[1]
							
			interactionAreaNode.set_meta("fType",fType)
			interactionAreaNode.set_meta("fTextureName",fTexture)#some types need to know the floor texture the line is facing
			
				
				
		triggerNodes.append(interactionAreaNode)
	else:
		var gt = Spatial.new()
		gt.set_meta("gunTrigger",true)
		gt.set_meta("sideDef",line["frontSideDef"])
		triggerNodes.append(gt)
		
					

		
	return triggerNodes


func getSideNodePaths(sector,sideIdxArr):
	var sideNodes = []
	
	for idx in sideIdxArr:
		if sideNodePath.has(String(idx)):
			var node = sideNodePath[String(idx)]#get mesh node for sideIdx
			var p = node.get_parent()
			var path
			
			
			if p.get_class() == "KinematicBody":#a kinemtatic body with mesh as child
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
	

	
	var audioStream =  $"../ResourceManager".fetchSound(soundName)
	var audioPlay = AudioStreamPlayer3D.new()
	audioPlay.stream = audioStream
	
	return audioPlay
	


func createInteractionAreaNode(line,depth,nameStr ="interactionBox"):
	var scaleFactor = get_parent().scaleFactor
	var areaNode = Area.new()
	var collisionNode = CollisionShape.new()
	var shapeNode = BoxShape.new()
	
	var startVert  = verts[line["startVert"]]
	var endVert = verts[line["endVert"]]
	var length =  endVert-startVert
	var sector = sectors[line["frontSector"]]
	
	
	
	var maxHeight = sector["ceilingHeight"]
	var types = []
	
	if mapDict["sectorToInteraction"].has(line["frontSector"]):
		types +=mapDict["sectorToInteraction"][line["frontSector"]]
	
	if line["backSector"] != -1:
		if mapDict["sectorToInteraction"].has(line["backSector"]):
			types +=mapDict["sectorToInteraction"][line["backSector"]]
	
	
	var hasTeleport = false
	
	for i in types:
		var typeInt = var2str(i["type"])
		var typeInfo = typeSheet.data[typeInt]
		
		var dest = WADG.getDest(typeInfo["dest"],sector,scaleFactor.y)
		
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
	var angle = length.angle_to(Vector2.UP) + deg2rad(90)
	var h = sector["floorHeight"]+height/2
	
	
	var startVec = Vector3(startVert.x,h,startVert.y)
	var endVec = Vector3(endVert.x,h,endVert.y)
	var mid = (startVec + endVec)/2
	
	var diff = startVec - endVec
	
	var normal = Vector3(diff.z,diff.y,-diff.x).normalized()
	areaNode.set_meta("normal",normal)
	var areaCenter = mid + normal*depth
	
	if hasTeleport:
		areaCenter = mid - normal*(depth/2.0)
	
	#WADG.drawLine(self,startVec,endVec)
	#WADG.drawSphere($"/root",mid,Color.red)
	#WADG.drawSphere($"/root",mid,Color.red)
	#WADG.drawLine($"/root",mid,mid+normal)
	
	dim = Vector3(abs(dim.x),abs(dim.y),abs(dim.z))
	dim.z = depth

	var x = areaCenter
	areaNode.rotation.y = angle
	areaNode.translation = areaCenter
	
	shapeNode.extents = dim
	collisionNode.shape = shapeNode
	areaNode.add_child(collisionNode)
	areaNode.name = nameStr 
	areaNode.name = "trigger"
	return areaNode


func createSurroundingSkybox(dim,minDim):
	var meshInstance = MeshInstance.new()
	var cubeMesh = CubeMesh.new()
	cubeMesh.size = dim+Vector3(20,20,20)*scaleFactor#add a small buffer to prevent z-fighing
	cubeMesh.flip_faces = true
	meshInstance.mesh = cubeMesh 
	meshInstance.translation = minDim + (dim/2)
	##
	cubeMesh.size.y += 100
	meshInstance.translation.y += 100/2.0
	var texName : String = $"../ImageBuilder".getSkyboxTextureForMap(mapName) 
	cubeMesh.material = $"../ResourceManager".fetchSkyMat(texName)
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
		var side = sides[sideIdx]
		if side["backSector"] != null: 
			if !curStairs.has(side["backSector"]):
				return side["backSector"]
			
	return null



func makeFloorKinematic(flr):
	
	var flrParent = flr.get_parent()
	var colNode = flr.get_child(0)
	flr.get_parent().remove_child(flr)
	#flr.remove_child(colNode)
	var floorKine = KinematicBody.new()
	
	flrParent.add_child(floorKine)
	floorKine.add_child(flr)
	
	
func makeAreaForCeilFloor(cf):
	return
	var colNode = cf.get_child(0).duplicate()
	var shapeNode = colNode.get_child(0)
	
	var area = Area.new()
	area.translation.y -= 1
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


func fetchInteractableParentNode(mapNode,sectorNodeName,pos):
	
	var sectorInteractionParent
	if !mapNode.get_node("Interactables").has_node(sectorNodeName):
		sectorInteractionParent = Spatial.new()
		sectorInteractionParent.translation = pos
		sectorInteractionParent.name = sectorNodeName
		sectorInteractionParent.set_meta("owner",false)
		mapNode.get_node("Interactables").add_child(sectorInteractionParent)
		return sectorInteractionParent
		
	sectorInteractionParent = mapNode.get_node("Interactables").get_node(sectorNodeName)
	return sectorInteractionParent
	

func getTextureNumericModel(sector,destH):
	
	var oSides = mapDict["sectorToBackSides"][sector["index"]]
	oSides.sort()
	
	
	for i in oSides:
		var side = sides[i]
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

func initLowerTextureHeights(mapDict : Dictionary):
	for sector in mapDict["SECTORS"]:

		var lowest = INF
		
		
		if sector.has("lowerTextures"):
			for i in sector["lowerTextures"]:
				var texture : Texture = $"../ResourceManager".fetchPatchedTexture(i,!get_parent().dontUseShader)
				
				if texture == null:
					continue
				
				if texture.get_class() == "ImageTexture":
					if texture.size.y < lowest:
						lowest = texture.size.y
				else:
					var t = texture.get("frame_0/texture")
					if t != null:
						if t.size.y < lowest:
							lowest = t.size.y
				
		sector["lowestTextureHeight"] = lowest


func initLowerTextureHeights2(mapDict : Dictionary):
	var sectors = mapDict["SECTORS"]
	for sector in mapDict["SECTORS"]:
		
		var lowest = sector["lowestTextureHeight"]
		
		for i in sector["nieghbourSectors"]:
			if sectors[i]["lowestTextureHeight"] < lowest:
				lowest = sectors[i]["lowestTextureHeight"]
				
		
		if lowest == INF:
			lowest = INF
			
	
		sector["lowestTextureHeight"] = lowest
	
