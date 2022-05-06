tool
extends Node
var lineDefs = []
var format = "DOOM"


var staticRenderables = []
var dynamicRenderables = []
var textureEntries = {}
var flatMatEntries = {}
var wallMatEntries = {}
var patchTextureEntries = {}
var palletes = []
var colorMaps = []
var patchNames = {}
var curMapDict
var sectorToSides = {}
var sectorToRenderables = {}

var minDim = Vector3(INF,INF,INF)
var maxDim =  Vector3(-INF,-INF,-INF)
var BB
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
	PASS_THRU = 0x200
}


func _ready():
	set_meta("hidden",true)

var inPatch = false
var inFlat = false

func parseLumps(lumps):
	for lump in lumps:
		
		var lumpName = lump["name"]
		
		if lumpName == "P_START": inPatch = true
		if lumpName == "P_END": inPatch = false
		if lumpName == "F_START" or lumpName == "F1_START" or lumpName == "F2_START": inFlat = true
		if lumpName == "F_END" or lumpName == "F1_END" or lumpName == "F2_END": inFlat = false
		
		
		if lumpName.substr(0,7) == "TEXTURE": parseTextureLump(lump)
		elif lumpName == "PLAYPAL": parsePallete(lump)
		elif lumpName == "COLORMAP": parseColorMap(lump)
		elif lumpName == "PNAMES": parsePatchNames(lump)
		elif lumpName == "GENMIDI" : continue
		elif lumpName == "DMXGUS": continue
		elif lumpName.substr(0,2) == "DS": parseDs(lump,lumpName)
		elif lumpName.substr(0,2) == "D_": parseD_(lump,lumpName)
		elif lumpName.substr(0,2) == "DP": continue
		elif lumpName.substr(0,4) == "DEMO": continue
		else: patchTextureEntries[lumpName] = lump
		
	get_parent().colorMaps = colorMaps
	get_parent().palletes = palletes
	get_parent().textureEntries = textureEntries
	get_parent().patchTextureEntries = patchTextureEntries
	get_parent().patchNames = patchNames
	
	


func parseMap(mapDict,isHexen = false):
	var linedefs = []
	curMapDict = mapDict
	mapDict["isHexen"] = isHexen
	mapDict["tagToSectors"] = {}
	mapDict["actionSectorTags"] = {}
	mapDict["taggedSidedefs"] = {}
	mapDict["sectorToSides"] = {}
	mapDict["sectorToFrontSides"] = {}
	mapDict["sectorToBackSides"] = {}
	mapDict["interactables"] = []
	mapDict["sectorToInteraction"] = {}
	mapDict["staticRenderables"] = []
	mapDict["dynamicRenderables"] = []
	mapDict["stairLookup"] = {}
	mapDict["sideToLine"] = {}
	staticRenderables = []
	dynamicRenderables = []
	

	
	if mapDict.has("BEHAVIOR"): mapDict["isHexen"] = true
	for lumpName in mapDict.keys():
		if lumpName == "LINEDEFS" and mapDict["isHexen"] == false: mapDict[lumpName] = parseLinedef(mapDict[lumpName])
		if lumpName == "LINEDEFS" and mapDict["isHexen"] == true: mapDict[lumpName] = parseLinedefHexen(mapDict[lumpName])
		elif lumpName == "SIDEDEFS" : mapDict[lumpName] = parseSidedef(mapDict[lumpName])
		elif lumpName == "SECTORS"  : mapDict[lumpName] = parseSector(mapDict[lumpName],mapDict)
		elif lumpName == "VERTEXES" : mapDict[lumpName] = parseVertices(mapDict[lumpName])
		elif lumpName == "THINGS" and mapDict["isHexen"] == false: mapDict[lumpName] = parseThings(mapDict[lumpName])
		elif lumpName == "THINGS" and mapDict["isHexen"] == true: mapDict[lumpName] = parseThingsHexen(mapDict[lumpName])
		elif lumpName == "BEHAVIOR": continue
	mapDict["minDim"] = Vector3(minDim.x,minDim.z,minDim.y)
	mapDict["maxDim"] = Vector3(maxDim.x,maxDim.z,maxDim.y)  
	mapDict["BB"] = mapDict["maxDim"] - mapDict["minDim"]
	
	


func parseSector(lump,mapDict):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	var sectors = []

	for i in size/(2*5 + 8*2):
		var floorHeight = file.get_16s()
		var ceilingHeight = file.get_16s()
		var floorTexture = file.get_String(8)
		var ceilingTexture = file.get_String(8)
		var lightLevel = file.get_16()
		var type = file.get_16()
		var tagNum = file.get_16()
		
		sectors.append({"floorHeight":floorHeight,"ceilingHeight":ceilingHeight,"floorTexture":floorTexture,"ceilingTexture":ceilingTexture,"lightLevel":lightLevel,"type":type,"tagNum":tagNum,"index":i})
		
		
		#var light = WADG.getLightLevel(lightLevel)
		
		if !flatMatEntries.has(floorTexture): flatMatEntries[floorTexture] = []
		if !flatMatEntries.has(ceilingTexture): flatMatEntries[ceilingTexture] = []
		
		if !flatMatEntries[floorTexture].has(lightLevel): 
			if !flatMatEntries[floorTexture].has([lightLevel,Vector2.ZERO]):
				flatMatEntries[floorTexture].append([lightLevel,Vector2.ZERO])
				
		if !flatMatEntries[ceilingTexture].has(lightLevel):
			if !flatMatEntries[ceilingTexture].has([lightLevel,Vector2.ZERO]):
				flatMatEntries[ceilingTexture].append([lightLevel,Vector2.ZERO])
		
		if !curMapDict["tagToSectors"].has(tagNum):
			curMapDict["tagToSectors"][tagNum] = []

		curMapDict["tagToSectors"][tagNum].append(i)
		mapDict["sectorToSides"][i] = []
		mapDict["sectorToFrontSides"][i] = []
		mapDict["sectorToBackSides"][i] = []

		minDim.z = min(minDim.z,floorHeight)
		maxDim.z = max(maxDim.z,ceilingHeight)


	return sectors


func parseLinedef(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	var lineDefs = []
	var actionSectorTags = curMapDict["actionSectorTags"]
	for i in size/(2*7):
		var startVert = file.get_16()
		var endVert = file.get_16()
		var flags = file.get_16()
		var type = file.get_16()
		var sectorTag = file.get_16()
		var frontSidedef = file.get_16s()
		var backSidedef = file.get_16s()

		if !$"../LevelBuilder".typeDict.has(type):
			type = 0
		
		if type == 65535: type = 0
		if frontSidedef != -1: curMapDict["sideToLine"][frontSidedef] = i
		if backSidedef != -1: curMapDict["sideToLine"][backSidedef] = i
		
		lineDefs.append({"startVert":startVert,"endVert":endVert,"flags":flags,"type":type,"sectorTag":sectorTag,"frontSideDef":frontSidedef,"backSideDef":backSidedef,"index":i})


	return lineDefs


func parseLinedefHexen(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	var lineDefs = []
	var actionSectorTags = curMapDict["actionSectorTags"]
	var numLindef = size/((5*2)+6)
	
	for i in numLindef:
		var startVert = file.get_16()
		var endVert = file.get_16()
		var flags = file.get_16()
		var type = file.get_8()
		
		var arg1 = file.get_8()
		var arg2 = file.get_8()
		var arg3 = file.get_8()
		var arg4 = file.get_8()
		var arg5 = file.get_8()
		
		var frontSidedef = file.get_16s()
		var backSidedef = file.get_16s()
		
		if type == 65535: type = 0
		if frontSidedef != -1: curMapDict["sideToLine"][frontSidedef] = i
		if backSidedef != -1: curMapDict["sideToLine"][backSidedef] = i
		
		
		lineDefs.append({"startVert":startVert,"endVert":endVert,"flags":flags,"type":type,"frontSideDef":frontSidedef,"backSideDef":backSidedef,"index":i})


	return lineDefs


func parseSidedef(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	var sidedef = []

	for i in size/(2*3 + 3*8) :
		var xOffset = file.get_16s()
		var yOffset = file.get_16s()
		var upperName = file.get_String(8)
		var lowerName = file.get_String(8)
		var middleName = file.get_String(8)
		var sector = file.get_16()
		
		
		sidedef.append({"xOffset":xOffset,"yOffset":yOffset,"upperName":upperName,"lowerName":lowerName,"middleName":middleName,"sector":sector,"index":String(i)})

	return sidedef

func parseVertices(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	var vertices = []
	file.seek(offset)

	for i in size/(2*2):
		var posX = file.get_16s()
		var posY = -file.get_16s()
		
		minDim.x = min(minDim.x,posX)
		minDim.y = min(minDim.y,posY)
		maxDim.x = max(maxDim.x,posX)
		maxDim.y = max(maxDim.y,posY)
		
		vertices.append(Vector2(posX,posY))

	return vertices

func parseThings(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	var things = {}

	for i in size/(2*5):
		var pos = Vector3(file.get_16s(),0,-file.get_16s())
		var rot = file.get_16s()
		var type = file.get_16()
		var flags = file.get_16()
		if !things.has(type): things[type] = []

		things[type].append({"pos":pos,"rot":rot,"flags":flags})
		#things.append({"pos":pos,"rot":rot,"type":type,"flags":flags})

	return things
	

func parseThingsHexen(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	var things = {}

	var numThingEntry = size/((2*7)+(6))
	for i in size/((2*7)+(6)):
		var id = file.get_16()
		var pos = Vector3(file.get_16s(),0,-file.get_16s())
		var height = file.get_16()
		var rot = file.get_16s()
		var DoomEd = file.get_16s()
		var flags = file.get_16()
		var hexenSpecial = file.get_8()
		
		var arg1 = file.get_8()
		var arg2 = file.get_8()
		var arg3 = file.get_8()
		var arg4 = file.get_8()
		var arg5 = file.get_8()
		
		if !things.has(id): things[id] = []

		things[id].append({"pos":pos,"rot":rot,"flags":flags})
		#things.append({"pos":pos,"rot":rot,"type":type,"flags":flags})

	return things


func typeOveride(type,line,sector,mapName,mapTo666,mapDict):
	var npcTrigger = null
	
	if sector["tagNum"] == 666:
		if mapTo666.has(mapName):
			type = mapTo666[mapName]["type"]
			npcTrigger = mapTo666[mapName]["npcName"]
			
		
	if line["backSector"]!= null:
		var oSector = mapDict["SECTORS"][line["backSector"]]
		if oSector["tagNum"] == 666:
			if mapTo666.has(mapName):
				type = mapTo666[mapName]["type"]
				npcTrigger = mapTo666[mapName]["npcName"]
	
	line["npcTrigger"] = npcTrigger
	return type
	
func postProc(mapDict):
	
	
	var sideDefs = mapDict["SIDEDEFS"]

	initSectorToSides(mapDict)
	initSectorNeighbours(mapDict)
	createSectorToInteraction(mapDict)




	for line in mapDict["LINEDEFS"]:

		var frontSidedefIdx = line["frontSideDef"]
		var backSidedefIdx = line["backSideDef"]
		var frontSide = sideDefs[frontSidedefIdx]
		
		var backSide = null
		if backSidedefIdx != -1:
			backSide = sideDefs[backSidedefIdx]


		
		procSide(line,frontSide,backSide)
		if backSidedefIdx!=-1:
			procSide(line,backSide,frontSide,-1)

	
	mapDict["staticRenderables"] = staticRenderables
	mapDict["dynamicRenderables"] = dynamicRenderables
	mapDict["sectorToRenderables"] = sectorToRenderables



func createSectorToInteraction(mapDict):
	
	var tagToSectors = mapDict["tagToSectors"]
	var typeDict =  $"../LevelBuilder".typeDict
	var interactables = mapDict["interactables"]
	var sectorToInteraction = mapDict["sectorToInteraction"]
	var sideDefs = mapDict["SIDEDEFS"]
	
	
	
	sectorToSides = mapDict["sectorToSides"]
	
	for line in mapDict["LINEDEFS"]:#action sectors and interactables

		var frontSidedefIdx = line["frontSideDef"]
		var backSidedefIdx = line["backSideDef"]
		var backSide = null#sideDefs[backSidedefIdx]
		var backSideSector = null
		var sector = mapDict["SECTORS"][line["frontSector"]]
		
		var type = line["type"]
		var mapTo666 = $"../LevelBuilder".mapTo666
		var mapName = mapDict["name"]
		
		
		type = typeOveride(type,line,sector,mapName,mapTo666,mapDict)
		
		
		var targetTag = 0
		
		
		if !typeDict.has(type): continue#new
		
		if line.has("sectorTag"):#hexen line wont have have target tag entry
			 targetTag = line["sectorTag"]
		
		var typeInfo = typeDict[type]
		 

		
		if backSidedefIdx != -1:
			backSide = sideDefs[backSidedefIdx]
			backSideSector = backSide["sector"]

		var targetSectors
		
		if type != 0:#if line has a type
			
			targetSectors = getTargetSectors(tagToSectors,targetTag,typeInfo,line,backSideSector)
			
			if targetSectors == null:
				continue
			
			if typeInfo["type"] == WADG.LTYPE.STAIR:#if the type of the line is a stair
				for sec in targetSectors:#we get every target sector
					var stairSectors = getStairSectors(mapDict,mapDict["sectorToFrontSides"][sec],sec,type)#we get every sector in stair chain
					
					
					mapDict["stairLookup"][sec] = stairSectors
					
					for sectorIdx in stairSectors.keys():
						for sideIdx in mapDict["sectorToBackSides"][sectorIdx]:
							
							var stairLineIdx = mapDict["sideToLine"][sideIdx]
							var stairLine = mapDict["LINEDEFS"][stairLineIdx]
							
							stairLine["stairIdx"] = stairSectors[sectorIdx]["stairNum"]
							stairLine["stairInc"] = typeDict[type]["inc"]


			interactables.append({"type":type,"sector":targetSectors,"line":line})
			 
			
			var npcTrigger = line["npcTrigger"]
			
			for s in targetSectors:#for every target sector
				if !sectorToInteraction.has(s):
					sectorToInteraction[s] = []#create an interaction entry for sector

				sectorToInteraction[s].append({"type":type,"line":line,"npcTrigger":npcTrigger})#set the interaction type for sector


func getTargetSectors(tagToSectors,targetTag,typeInfo,line,backSideSector):
	
	var targetSectors = []
	
	#if line["index"] == 846:
	#	breakpoint
	
	
	if !tagToSectors.has(targetTag):#if sectorTag of line invalid skip
		return null
	
	if targetTag != 0:
		targetSectors = tagToSectors[targetTag]#we use tag to lookup target sector index

	
	if typeInfo["type"] == WADG.LTYPE.SCROLL or typeInfo["type"] == WADG.LTYPE.EXIT:#scroll is a special case that dosen't target oside(this is just a quick fix as all walls in the sector will be targeted which is incorrect)
		 targetSectors = [line["frontSector"]]
		
	if targetTag == 0 and backSideSector != null:#0 tagged so the back sector is targeted
		 targetSectors = [backSideSector]
	
	return targetSectors


func initSectorToSides(mapDict):
	var sideDefs = mapDict["SIDEDEFS"]
	var tagToSectors = mapDict["tagToSectors"]

	var lineIdx = 0
	for line in mapDict["LINEDEFS"]:
		var frontSidedefIdx = line["frontSideDef"]
		var backSidedefIdx = line["backSideDef"]
		var frontSide = sideDefs[frontSidedefIdx]
		var frontSector = frontSide["sector"]
		var backSide = null
		var backSideSector = null
		var type = line["type"]



		line["frontSector"] = frontSector
		line["backSector"] = null

		frontSide["frontSector"] = frontSector
		frontSide["backSector"] = null


		if backSidedefIdx != -1:
			backSide = sideDefs[backSidedefIdx]

			backSideSector = backSide["sector"]

			frontSide["backSector"] = backSideSector
			backSide["frontSector"] = backSideSector
			backSide["backSector"] = frontSector


		line["frontSector"] = frontSector
		line["backSector"] = backSideSector


		if backSideSector == -1:
			breakpoint

		mapDict["sectorToSides"][frontSector].append(frontSidedefIdx)#we add our frontSide LineIdx to the front sector
		mapDict["sectorToFrontSides"][frontSector].append(frontSidedefIdx)


		if backSideSector != null:#if we have a back sector
			mapDict["sectorToSides"][frontSector].append(backSidedefIdx)#if we have a back side index we add that to front sector too
			mapDict["sectorToSides"][backSideSector].append(backSidedefIdx)#add frontSide LineIdx to sector
			mapDict["sectorToSides"][backSideSector].append(frontSidedefIdx)#add backSide LineIdx to sector

			mapDict["sectorToBackSides"][frontSector].append(backSidedefIdx)#add frontSide LineIdx to sector
			mapDict["sectorToBackSides"][backSideSector].append(frontSidedefIdx)

			mapDict["sectorToFrontSides"][backSideSector].append(backSidedefIdx)


		lineIdx += 1



func initSectorNeighbours(mapDict):
	var sectors = mapDict["SECTORS"]
	var sectorToSides = mapDict["sectorToSides"]
	var sectorToFrontSides = mapDict["sectorToFrontSides"]
	var sectorToBackSides = mapDict["sectorToBackSides"]
	var sides = mapDict["SIDEDEFS"]
	var sectorIdx = 0



	for sector in sectors:#for each sector
		var neighbourSectors = []
		var secSides = sectorToSides[sectorIdx]


		for lineIdx in secSides:#go through each line in sector
			var line = sides[lineIdx]
			var frontSectorIdx = line["frontSector"]
			var backSectorIdx = line["backSector"]

			if !neighbourSectors.has(frontSectorIdx) and frontSectorIdx != sectorIdx:
				neighbourSectors.append(frontSectorIdx)

			if !neighbourSectors.has(backSectorIdx) and backSectorIdx != null and backSectorIdx != sectorIdx:
				neighbourSectors.append(backSectorIdx)

		sector["nieghbourSectors"] = neighbourSectors
		sectorIdx += 1
		
	sectorIdx= 0
	
	for sector in sectors:
		var idx = sector["index"]
		var lowestNeighFloorInc = sector["floorHeight"]
		var lowestNeighCeilInc = sector["ceilingHeight"]
		var highestNeighFloorInc = sector["floorHeight"]
		var highestNeighCeilInc = sector["ceilingHeight"]
		
		var lowestNeighFloorExc = INF#sector["floorHeight"]#inc = including self , exc = excluding self
		var lowestNeighCeilExc = INF#sector["ceilingHeight"]
		var highestNeighFloorExc = -INF#sector["floorHeight"]
		var highestNeighCeilExc =  -INF#sector["ceilingHeight"]
		
		var closetNeighCeil = INF
		var closetNeighFloor = INF
		
		var nextHighestFloor = INF
		var nextLowestFloor = -INF
		
		
		var nextHighestCeil = INF
		var nextLowestCeil = -INF
		
		var brightestNeighValue = -INF
		var darkestNeighValue = INF

		for neighSectorIdx in sector["nieghbourSectors"]:
			var neighSector = sectors[neighSectorIdx]
			
			var nfloorHeight = neighSector["floorHeight"]
			var nCeilHeight = neighSector["ceilingHeight"]
			
			lowestNeighFloorInc  = min(nfloorHeight,lowestNeighFloorInc)
			highestNeighFloorInc = max(nfloorHeight,highestNeighFloorInc)
			
			lowestNeighFloorExc  = min(nfloorHeight,lowestNeighFloorExc)
			highestNeighFloorExc = max(nfloorHeight,highestNeighFloorExc)
			
			if nfloorHeight > sector["floorHeight"]: nextHighestFloor = min(nextHighestFloor,nfloorHeight)
			if nfloorHeight < sector["floorHeight"]: nextLowestFloor  = max(nextLowestFloor,nfloorHeight)

			lowestNeighCeilInc   = min(nCeilHeight,lowestNeighCeilInc)
			highestNeighCeilInc  = max(nCeilHeight,highestNeighCeilInc)
			lowestNeighCeilExc   = min(nCeilHeight,lowestNeighCeilExc)
			highestNeighCeilExc  = max(nCeilHeight,highestNeighCeilExc)
			
			if nCeilHeight > sector["ceilingHeight"]: nextHighestCeil = min(nextHighestCeil,nCeilHeight)
			if nCeilHeight < sector["ceilingHeight"]: nextLowestCeil  = max(nextLowestCeil,nCeilHeight)
			
			brightestNeighValue = max(brightestNeighValue,neighSector["lightLevel"])
			darkestNeighValue = min(darkestNeighValue,neighSector["lightLevel"])
		
		if nextHighestFloor == INF: nextHighestFloor = sector["floorHeight"]
		if nextLowestFloor == -INF: nextLowestFloor = sector["floorHeight"]
		
		if nextHighestCeil == INF: nextHighestCeil = sector["ceilingHeight"]
		if nextLowestCeil == -INF: nextLowestCeil = sector["ceilingHeight"]
		
		if brightestNeighValue == -INF: brightestNeighValue = sector["lightLevel"]
		if darkestNeighValue == INF: darkestNeighValue = sector["lightLevel"]

		sector["lowestNeighFloorInc"] = lowestNeighFloorInc
		sector["highestNeighFloorInc"] = highestNeighFloorInc
		sector["lowestNeighFloorExc"] = lowestNeighFloorExc
		sector["highestNeighFloorExc"] = highestNeighFloorExc
		
		sector["lowestNeighCeilInc"] = lowestNeighCeilInc
		sector["highestNeighCeilInc"] = highestNeighCeilInc
		sector["lowestNeighCeilExc"] = lowestNeighCeilExc
		sector["highestNeighCeilExc"] = highestNeighCeilExc
		
		sector["nextHighestFloor"] = nextHighestFloor
		sector["nextLowestFloor"] = nextLowestFloor
		sector["nextHighestCeil"] = nextHighestCeil
		sector["nextLowestCeil"] = nextLowestFloor
		
		sector["brightestNeighValue"] = brightestNeighValue
		sector["darkestNeighValue"] = darkestNeighValue

		sectorIdx += 1


func procSide(line,side,oSide,dir = 1):
	var type = line["type"]
	var upperTexture = side["upperName"]
	var middleTexture = side["middleName"]
	var lowerTexture = side["lowerName"]
	

	#matEntries
	
	
	if upperTexture  != "-": addRenderable(line,side,oSide,dir,upperTexture,"upper")
	if middleTexture != "-": addRenderable(line,side,oSide,dir,middleTexture,"middle")
	if lowerTexture  != "-": addRenderable(line,side,oSide,dir,lowerTexture,"lower")

	

	var oSideNull = false
	var sector = side["sector"]
	
	
	if oSide != null:#if side has an oSide but that oSide has no texture
		if oSide["upperName"] == "-" and oSide["middleName"] == "-" and oSide["lowerName"] == "-" :
			oSideNull = true
	else:
		oSideNull = true

	if middleTexture == "-" and upperTexture == "-" and lowerTexture == "-" and oSideNull and type != 0:
		addRenderable(line,side,oSide,dir,middleTexture,"trigger")#trigger
	
	

func addRenderable(line,side,oSide,dir,textureName,type):
	var dict = {}
	var alpha = 1.0
	

	

	var sector =curMapDict["SECTORS"][side["sector"]]

	if !wallMatEntries.has(textureName):
		if wallMatEntries.has([sector["lightLevel"]/16.0,Vector2(0,0),alpha]):
			wallMatEntries[textureName] = [sector["lightLevel"]/16.0,Vector2(0,0),alpha]
		
	if dir == 1:
		dict["startVertIdx"]  = line["startVert"]
		dict["endVertIdx"]  = line["endVert"]

	else:
		dict["endVertIdx"]  = line["startVert"]
		dict["startVertIdx"]  = line["endVert"]

	dict["dir"] = dir
	dict["type"] = type 
	dict["texture"] = textureName
	dict["sector"] = side["frontSector"]
	dict["oSector"] = null
	dict["flags"] = line["flags"]
	dict["textureOffset"] = Vector2(side["xOffset"],side["yOffset"])
	dict["sType"] = line["type"]
	dict["sTypeDir"] = 1
	dict["sideIndex"] = side["index"]
	dict["lineIndex"] = line["index"]
	dict["oSide"] = oSide
	
	var sType = line["type"]
	var scrollVector = Vector2.ZERO
	var typeDict = $"../LevelBuilder".typeDict
	

	if typeDict[sType]["type"] == WADG.LTYPE.SCROLL: 
		scrollVector =  typeDict[sType]["vector"]
	
	if typeDict[sType].has("alpha"):
		alpha =  typeDict[sType]["alpha"]
	
	
	if !wallMatEntries.has(textureName): wallMatEntries[textureName] = []
	
	if !wallMatEntries[textureName].has([sector["lightLevel"],scrollVector,alpha]):
		wallMatEntries[textureName].append([sector["lightLevel"],scrollVector,alpha])
	
	var sectorToInteraction = curMapDict["sectorToInteraction"]
	
	if line.has("stairIdx"):
		dict["stairIdx"] = line["stairIdx"]
		dict["stairInc"] = line["stairInc"]
		
	
	
	if oSide != null:
		dict["oSector"] = oSide["frontSector"]

	var lineType
	

	
	lineType = $"../LevelBuilder".typeDict[dict["sType"]]["type"]
	
	var sectorIdx = dict["sector"]
	#var t= sectorToInteraction[sectorIdx]
	var b1 = !sectorToInteraction.has(dict["sector"])
	var b2 = !sectorToInteraction.has(dict["oSector"])
	var b3 = !line.has("stairIdx")
	var b4 = !$"../ImageBuilder".switchTextures.has(textureName)
	
	

	
#	if side["index"] == "295":
	#	breakpoint
	
	if sector["ceilingTexture"] == "F_SKY1" and get_parent().skyWall== get_parent().SKYVIS.ENABLED:#walls to cover sky gap
		#var b1 = oSide == null:
		var sky = false
		if oSide == null: sky = true
		
		if oSide != null:
			if oSide["upperName"] == "-" and oSide["middleName"] == "-" and oSide["lowerName"] == "-":
				sky = true
		
		#if oSide["upperName"] == "-" and oSide["middleName"] == "-" and oSide["lowerName"] == "-":
		if sky:
			#if oSide["upperName"] == "-" and oSide["middleName"] == "-" and oSide["lowerName"] == "-":
			var dict2 = dict.duplicate(true) 
			dict2.type = "skyUpper"
			
			dict2["textureName"] = "F_SKY1"
			dict2["texture"] = "F_SKY1"
			staticRenderables.append(dict2)
			
	
	#if !sectorToInteraction.has(dict["sector"]) and !sectorToInteraction.has(dict["oSector"]) and !line.has("stairIdx") and  !$"../ImageBuilder".switchTextures.has(textureName):
	if b1 && b2 && b3 && b4:

		staticRenderables.append(dict)
		
		if !sectorToRenderables.has(dict["sector"]):
			sectorToRenderables[dict["sector"]] = []
		
	
	else:
		dynamicRenderables.append(dict)
		

func checkSidesDynamic(sectorToInteraction,dict,typeDict,textureName):
	
	var sec = dict["sector"]
	var oSec = dict["oSector"]
	
	
	if dict.has("stairIdx"):
		return false
	
	if sec != null:
		if sectorToInteraction.has(sec):
			var interactions = sectorToInteraction[sec]
			for i in interactions:
				var t = typeDict[i["type"]]["type"]
				if t != WADG.LTYPE.EXIT:# and t != WADG.LTYPE.TELEPORT:
					return false
	
	if oSec!= null:
		if sectorToInteraction.has(oSec):
			var interactions = sectorToInteraction[oSec]
			for i in interactions:
				var t = typeDict[i["type"]]["type"]
				if t != WADG.LTYPE.EXIT:# and t != WADG.LTYPE.TELEPORT:
					return false
			
			
	return true
	

func parsePallete(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)

	for i in range(0,size/768):
		var pallete = []
		for j in 256:
			pallete.append(Color8(file.get_8(),file.get_8(),file.get_8()))
		palletes.append(pallete)

func parseColorMap(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	var pallete = palletes[0]

	for i in 34:
		var image = Image.new()
		image.create(256,1,false,Image.FORMAT_RGBA8)
		image.lock()


		for j in 256:
			var index =file.get_8()
			image.set_pixel(j,0,pallete[index])

		image.unlock()

		var texture = ImageTexture.new()
		texture.create_from_image(image)
		
		texture.flags = 0
		colorMaps.append(texture)

func parseColorMapDummy():

	if palletes.size() == 0:
		for i in 32:
			palletes.append([])
			for j in 256:
				palletes[i].append(Color8(255,0,255))

	for i in 34:
		var image = Image.new()
		image.create(256,1,false,Image.FORMAT_RGBA8)
		

		var texture = ImageTexture.new()
		texture.create_from_image(image)
		
		texture.flags = 0
		colorMaps.append(texture)

func parseTextureLump(lump):#all textures parsed here
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	var textureOffsets = []
	file.seek(offset)
	var numTextures = file.get_32()

	for i in numTextures:
		textureOffsets.append(file.get_32())

	for tOffset in textureOffsets:
		file.seek(offset + tOffset)

		var texName = file.get_String(8)
		var masked = file.get_32()
		var width = file.get_16()
		var height = file.get_16()
		var obsoleteData = file.get_32()
		var patchCount = file.get_16()
		var patches = []

		for i in patchCount:
			var originX = file.get_16s()
			var originY = file.get_16s()
			var pnameIndex = file.get_16()
			var stepDir = file.get_16()
			var colorMap = file.get_16()
			patches.append({"originX":originX,"originY":originY,"pnamIndex":pnameIndex,"stepDir":stepDir,"colorMap":colorMap})

		textureEntries[texName] = {"masked":masked,"file":file,"width":width,"height":height,"obsoleteData":obsoleteData,"patchCount":patchCount,"patches":patches}

func parsePatchNames(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	var index = 0
	file.seek(offset)

	var numberOfPname = file.get_32()
	if name == "SW1BRCOM":
		breakpoint
	for i in numberOfPname:
		var name = file.get_String(8)
		patchNames[index] = name
		index += 1

func parsePatch(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	
	var width = file.get_16()
	var height = file.get_16()

	var left_offset = file.get_16s()
	var top_offset = file.get_16s()
	var columnOffsets = []
	if (file.get_position() + width) > file.get_len():
		return null
	for i in width:
		columnOffsets.append(file.get_32())

	return {"width":width,"height":height,"left_offset":left_offset,"top_offset":top_offset,"columnOffsets":columnOffsets}

func parseDs(lump,lumpName):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	var sampleArr = []
	
	var magic = file.get_16()
	var sampleRate = file.get_16()
	var numberOfSamples = file.get_16()
	var unk = file.get_16()
	
	#var audioPlayer = AudioStreamPlayer.new()
	#audioPlayer.volume_db = -21
	
	var audio = AudioStreamSample.new()
	audio.format = AudioStreamSample.FORMAT_8_BITS
	audio.mix_rate = sampleRate

	var data = []
	
	for i in range(0,numberOfSamples - 4):#4 bytes of padding at end of sample:
		data.append(file.get_8()-128)
	
	audio.data = data
	$"../ResourceManager".saveSound(lumpName,audio)
	

	

func parseD_(lump,lumpName):
	return
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	var instrumentPatchs = []
	
	file.seek(offset)
	var magic = file.get_String(4)
	var totalSize = file.get_16s()
	var startOffset = file.get_16s()
	var numPrimanyChannels = file.get_16s()
	var numSecondaryChannels = file.get_16s()
	var numInstrumentPatches = file.get_16s()
	var zero = file.get_16s()
	#var instrumentPatchNumbers  =file.get_16()
	
	for i in numInstrumentPatches:
		instrumentPatchs.append(file.get_16())
			
	
	file.seek(startOffset)
	var infoByte #= file.get_8()
	var channelNumber = 0
	var event         = 7
	var last          = 0
	var data
	
	#print("%s %s" % [data >> 4,type])
	#print(numPrimanyChannels)

	while event != 6:
		
		infoByte = file.get_8()
		#infoByte = 32
		channelNumber = (infoByte & 0b00001111)
		event         = (infoByte & (0b01110000)) >> 4
		last          = (infoByte & (0b10000000)) >> 7
		if last:
			breakpoint
		if event == 5:
			continue
		
		if event == 6:
			breakpoint
			return
			
		
		data = file.get_8()
		
		if event == 0:
			var noteNumber = data & 0b01111111
			print("release note:",noteNumber)
			
		if event == 1:
			var noteNumber = data & 0b01111111
			var data2 = file.get_8()#play note reads an extra byte
			var volume = data & 0b01111111
			print("play note:",noteNumber)
			
		if event == 2:
			var bendAmount = data & 0b01111111
			print("pitch bend")
			
		if event == 3:
			var eventNum = data & 0b01111111
			print("system event:",eventNum)
			
		if event == 4:
			var controller = data & 0b01111111
			var data2 = file.get_8()
			print("controller")
			
		if event == 5:
			print("end of measure")
		
		
		while last:
			var delay = file.get_8()
			last = delay & 0x7f
			
		
		#if event == 7:
		#	print("empty")
		
	breakpoint
	return

func getStairSectors(mapDict,frontSides,sectorIdx,type):
	var stairDict = {}
	stairDict[sectorIdx] = null
	var ret = getNextStairSector(mapDict,stairDict,type)
	
	while ret != false:
		ret = getNextStairSector(mapDict,stairDict,type)
		
	return stairDict
	

func getNextStairSector(mapDict,stairDict,type):
	var curSecIdx = stairDict.keys().back()
	var frontSides = mapDict["sectorToFrontSides"][curSecIdx]
	var curFloorTexture = mapDict["SECTORS"][curSecIdx]["floorTexture"]
	var allNull
	
	
	for sideIdx in frontSides:#for every node facing inwards towards sector
		
		var side = mapDict["SIDEDEFS"][sideIdx]#get entry for side
		
		if side["backSector"] != null:#if side has back sector

			var oFloorTexture = mapDict["SECTORS"][side["backSector"]]["floorTexture"]
			if oFloorTexture == curFloorTexture:#if opposing floor is same texture as current floor 
				if !stairDict.has(side["backSector"]):#if a previous sector of the stairs isn't the oSide of the side
					
					stairDict[curSecIdx] = {"sideIdx":sideIdx,"stairNum":stairDict.keys().size(),"stairType":type}
					stairDict[side["backSector"]] = null
					return true
		
				
	
	stairDict[curSecIdx] = {"sideIdx":null,"stairNum":stairDict.keys().size()}
	return false

