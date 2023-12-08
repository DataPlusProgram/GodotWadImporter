tool
extends Node
var lineDefs = []
var format = "DOOM"


var staticRenderables = []
var dynamicRenderables = []
var patchTextureEntries = {}
var flatMatEntries = {}
var wallMatEntries = {}
var flatTextureEntries = {}
var textMap = []
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
	TWO_SIDED = 0x4,
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
	
	colorMaps = []
	
	for lump in lumps:
		var lumpName = lump["name"]
		if lumpName == "PLAYPAL": 
			parsePallete(lump)
			break
			
	
	for lump in lumps:
		
		
		
		var lumpName = lump["name"]
		
		#if lumpName == "P1_START" or lumpName == "P2_START" or lumpName == "P2_END":
		#	continue
		
		#if lumpName == "P_START" or lumpName == "PP_START": 
		#	inPatch = true
		#	continue

	#	if lumpName == "PP_END" or lumpName == "P_END" or lumpName == "P1_END": 
	#		inPatch = false
	#		continue
	#	
		#if lumpName == "F_START" or lumpName == "F1_START" or lumpName == "F2_START": inFlat = true
		#if lumpName == "F_END" or lumpName == "F1_END" or lumpName == "F2_END": inFlat = false
		
		
		if lumpName == "S_START" and get_parent().is64:
			breakpoint
		
		#if lumpName.substr(0,7) == "TEXTURE":
		if lumpName == "TEXTURE1" or lumpName == "TEXTURE2":
			#print("tl") 
			parseTextureLump(lump)
			
		elif lumpName == "PLAYPAL": 
			continue
			#print("pall")
		#	parsePallete(lump)
			
		elif lumpName == "COLORMAP": 
			#print("colorMap")
			parseColorMap(lump)
			
		elif lumpName == "PNAMES": 
			#print("pacthNames")
			parsePatchNames(lump)
			
		elif lumpName == "GENMIDI" : continue
		elif lumpName == "DMXGUS": continue
		elif lumpName.substr(0,2) == "DS": 
			#print("ds")
			parseDs(lump,lumpName)
		elif lumpName.substr(0,2) == "D_": 
			#print("d")
			parseD_(lump,lumpName)
		elif lumpName.substr(0,2) == "DP": continue
		elif lumpName.substr(0,4) == "DEMO": 
			#print("demo")
			parseDemo(lump,lumpName)
		elif lumpName == "TEXTMAP": 
			#print("textMap")
			parseTextmap(lump,lumpName)
			parseTextMap(lump,lumpName)
		else: 
			#if flatMatEntries.has(lumpName):
			#	breakpoint
			flatTextureEntries[lumpName] = lump
	
	get_parent().colorMaps = colorMaps
	get_parent().palletes = palletes
	get_parent().patchTextureEntries = patchTextureEntries
	get_parent().flatTextureEntries = flatTextureEntries
	get_parent().patchNames = patchNames
	
	

func parseMap(mapDict,isHexen = false,is64 = false):
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
	mapDict["lineToStairSectors"] = {}
	mapDict["sideToLine"] = {}
	mapDict["entities"] = {}
	staticRenderables = []
	dynamicRenderables = []
	
	mapDict["BB"] = Vector3.ZERO
	minDim.x = INF
	minDim.z = INF
	minDim.y = INF
	maxDim.x =-INF
	maxDim.z = -INF
	maxDim.y = -INF

	
	if mapDict.has("BEHAVIOR"): mapDict["isHexen"] = true
	for lumpName in mapDict.keys():
		if lumpName == "LINEDEFS" and mapDict["isHexen"] == false: mapDict[lumpName] = parseLinedef(mapDict[lumpName])
		if lumpName == "LINEDEFS" and mapDict["isHexen"] == true: mapDict[lumpName] = parseLinedefHexen(mapDict[lumpName])
		elif lumpName == "SIDEDEFS" : mapDict[lumpName] = parseSidedef(mapDict[lumpName])
		elif lumpName == "SECTORS"  : mapDict[lumpName] = parseSector(mapDict[lumpName],mapDict)
		elif lumpName == "VERTEXES" : mapDict[lumpName] = parseVertices(mapDict[lumpName])
		elif lumpName == "THINGS" and get_parent().is64: mapDict[lumpName] = parseThings64(mapDict[lumpName])
		elif lumpName == "THINGS" and mapDict["isHexen"] == false: mapDict[lumpName] = parseThings(mapDict[lumpName])
		elif lumpName == "THINGS" and mapDict["isHexen"] == true: mapDict[lumpName] = parseThingsHexen(mapDict[lumpName])
		elif lumpName == "BEHAVIOR": continue
	mapDict["minDim"] = Vector3(minDim.x,minDim.z,minDim.y)
	mapDict["maxDim"] = Vector3(maxDim.x,maxDim.z,maxDim.y)  
	mapDict["BB"] = mapDict["maxDim"] - mapDict["minDim"]
	

func parseTextMap(mapDict,isHexen = false):
	curMapDict = mapDict
	mapDict["VERTEXES"] = []
	mapDict["LINEDEFS"] = []
	mapDict["SIDEDEFS"] = []
	mapDict["SECTORS"] = []
	mapDict["THINGS"] = []
	
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
	mapDict["BB"] = Vector3.ZERO
	minDim.x = INF
	minDim.z = INF
	minDim.y = INF
	maxDim.x =-INF
	maxDim.z = -INF
	maxDim.y = -INF
	mapDict["isHexen"] = true
	
	for i in textMap:
		if i.substr(0,5) == "THING": parseThingsUDMF(i,mapDict)
		elif i.substr(0,9) == "NAMESPACE": pass
		elif i.substr(0,6) == "VERTEX": parseVertexUDMF(i,mapDict)
		elif i.substr(0,7) == "LINEDEF": parseLinedefUMDF(i,mapDict)
		elif i.substr(0,7) == "SIDEDEF": parseSidedefUDMF(i,mapDict)
		elif i.substr(0,6) == "SECTOR": parseSectorUDMF(i,mapDict)
#		else:
#			breakpoint
		
		
		
		
		
	mapDict["minDim"] = Vector3(minDim.x,minDim.z,minDim.y)
	mapDict["maxDim"] = Vector3(maxDim.x,maxDim.z,maxDim.y)  
	mapDict["BB"] = mapDict["maxDim"] - mapDict["minDim"]
	

func parseSector(lump,mapDict):
	var scaleFactor = get_parent().scaleFactor
	
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	var sectors = []

	for i in size/(2*5 + 8*2):
		var floorHeight = file.get_16s()*  scaleFactor.y
		var ceilingHeight = file.get_16s() *  scaleFactor.y
		var floorTexture = file.get_String(8) 
		var ceilingTexture = file.get_String(8) 
		var lightLevel = file.get_16()
		var type = file.get_16()
		var tagNum = file.get_16()
		
		sectors.append({"floorHeight":floorHeight,"ceilingHeight":ceilingHeight,"floorTexture":floorTexture,"ceilingTexture":ceilingTexture,"lightLevel":lightLevel,"type":type,"tagNum":tagNum,"index":i})
		
		
		#var light = WADG.getLightLevel(lightLevel)
		if floorTexture != "F_SKY1":
			if !flatMatEntries.has(floorTexture): flatMatEntries[floorTexture] = []
		
		
			if !flatMatEntries[floorTexture].has(lightLevel): 
				if !flatMatEntries[floorTexture].has([lightLevel,Vector2.ZERO,0]):
					flatMatEntries[floorTexture].append([lightLevel,Vector2.ZERO,0])
		
		if ceilingTexture != "F_SKY1":
			if !flatMatEntries.has(ceilingTexture): flatMatEntries[ceilingTexture] = []
				
			if !flatMatEntries[ceilingTexture].has(lightLevel):
				if !flatMatEntries[ceilingTexture].has([lightLevel,Vector2.ZERO,0]):
					flatMatEntries[ceilingTexture].append([lightLevel,Vector2.ZERO,0])
		
		if !curMapDict["tagToSectors"].has(tagNum):
			curMapDict["tagToSectors"][tagNum] = []

		curMapDict["tagToSectors"][tagNum].append(i)
		mapDict["sectorToSides"][i] = []
		mapDict["sectorToFrontSides"][i] = []
		mapDict["sectorToBackSides"][i] = []

		minDim.z = min(minDim.z,floorHeight)
		maxDim.z = max(maxDim.z,ceilingHeight)


	return sectors

func parseSectorUDMF(data,mapDict):
	var scaleFactor = get_parent().scaleFactor
	var floorHeight = 0
	var ceilingHeight = 0
	var floorTexture = "-"
	var ceilingTexture = "-"
	var lightLevel = 0
	var type = 0
	var tagNum = 0
	var index = mapDict["SECTORS"].size()
	
	data = data.replace(" ","")
	data = data.split("{")
	data = data[1].split(";",false)
	
	
	for i in data:
		i = i.split("=")
		var valName = i[0]
		var value = i[1]
		
		value = value.replace('"',"")
		
		if valName == "HEIGHTFLOOR": floorHeight = int(value)*scaleFactor.y
		if valName == "HEIGHTCEILING": ceilingHeight = int(value)*scaleFactor.y
		if valName == "TEXTUREFLOOR": floorTexture = value
		if valName == "TEXTURECEILING": ceilingTexture = value
		if valName == "LIGHTLEVEL": lightLevel = int(value)
		


	if !flatMatEntries.has(floorTexture): flatMatEntries[floorTexture] = []
	if !flatMatEntries.has(ceilingTexture): flatMatEntries[ceilingTexture] = []
		
	if !flatMatEntries[floorTexture].has(lightLevel): 
		if !flatMatEntries[floorTexture].has([lightLevel,Vector2.ZERO]):
			flatMatEntries[floorTexture].append([lightLevel,Vector2.ZERO,0])
				
	if !flatMatEntries[ceilingTexture].has(lightLevel):
		if !flatMatEntries[ceilingTexture].has([lightLevel,Vector2.ZERO]):
			flatMatEntries[ceilingTexture].append([lightLevel,Vector2.ZERO,0])
		
	if !curMapDict["tagToSectors"].has(tagNum):
		curMapDict["tagToSectors"][tagNum] = []

	curMapDict["tagToSectors"][tagNum].append(index)
	mapDict["sectorToSides"][index] = []
	mapDict["sectorToFrontSides"][index] = []
	mapDict["sectorToBackSides"][index] = []

	minDim.z = min(minDim.z,floorHeight)
	maxDim.z = max(maxDim.z,ceilingHeight)
	
	
	var dict = {"floorHeight":floorHeight,"ceilingHeight":ceilingHeight,"floorTexture":floorTexture,"ceilingTexture":ceilingTexture,"lightLevel":lightLevel,"type":type,"tagNum":tagNum,"index":index}
	mapDict["SECTORS"].append(dict)
	
	
func parseLinedef(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	
	var lineDefs = []
	var actionSectorTags = curMapDict["actionSectorTags"]
	
	file.seek(offset)
	
	for i in size/(2*7):
		var startVert = file.get_16()
		var endVert = file.get_16()
		var flags = file.get_16()
		var type = file.get_16()
		var sectorTag = file.get_16()
		var frontSidedef = file.get_16s()
		var backSidedef = file.get_16s()
		
		
		#if i == 36:
		#	breakpoint
		
		var typeDict = $"../LevelBuilder".typeSheet.data
		
		if curMapDict["isHexen"]:
			typeDict = $"../LevelBuilder".typeDictHexen
		
		if !typeDict.has(var2str(type)):
			type = 0
		
		if type == 65535: type = 0
		if frontSidedef != -1: curMapDict["sideToLine"][frontSidedef] = i
		if backSidedef != -1: curMapDict["sideToLine"][backSidedef] = i
		
		lineDefs.append({"startVert":startVert,"endVert":endVert,"flags":flags,"type":type,"sectorTag":sectorTag,"frontSideDef":frontSidedef,"backSideDef":backSidedef,"index":i})


	return lineDefs

func parseLinedefUMDF(data,mapDict):
	data = data.replace(" ","")
	data = data.split("{")
	data = data[1].split(";",false)
	
	var scaleFactor = get_parent().scaleFactor
	var v1 = 0
	var v2 = 0
	var frontSide = -1
	var backSide =  -1
	var blocking = false
	var flags = 0
	var type = 0
	var sectorTag = 0
	
	var typeDict =  $"../LevelBuilder".typeDictHexen
	
	
	
	
	for i in data:
		i = i.split("=")
		var valName = i[0]
		var value = i[1]
		
		if valName == "V1": v1 = int(value)
		if valName == "V2": v2 = int(value)
		if valName == "SIDEFRONT": frontSide = int(value)
		if valName == "SIDEBACK": backSide = int(value)
		if valName == "BLOCKING": blocking = bool(value)
	
	if !typeDict.has(type):
		type = 0
	
	var dict = {"startVert":v2,"endVert":v1,"flags":flags,"type":type,"sectorTag":sectorTag,"frontSideDef":frontSide,"backSideDef":backSide,"index":mapDict["VERTEXES"].size()}
	mapDict["LINEDEFS"].append(dict)
	

func parseLinedefHexen(lump):
	var scaleFactor = get_parent().scaleFactor
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	var lineDefs = []
	var actionSectorTags = curMapDict["actionSectorTags"]
	var numLindef = size/((5*2)+6)
	var typeDict =  $"../LevelBuilder".typeDictHexen
	
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
		
		
		var blocksPlayer = (flags & 0x1) != 0
		var blocksMonster = (flags & 0x2) != 0
		var twoSided =  (flags & 0x4) != 0
		var upperUnpegged =  (flags & 0x8) != 0
		var lowerUnpegged = (flags & 0x10) != 0
		var secret = (flags & 20) != 0
		var blocksSound = (flags & 0x40) != 0
		var notOnAutoMap = (flags & 0x80) != 0
		var onAutoMap = (flags & 0x100) != 0
		var reapeatable = (flags & 0x200) != 0
		
		var triggerFlag = flags & 0b1110000000000
		var trigger
		
		if type != 0:
			if triggerFlag == 0:
				if reapeatable: trigger = WADG.TTYPE.WALKR
				else: trigger = WADG.TTYPE.WALK1
			
			elif triggerFlag == 1024:
				if reapeatable: trigger = WADG.TTYPE.SWITCHR
				else: trigger = WADG.TTYPE.SWITCH1
				
			elif triggerFlag == 2048:
				trigger = "monster walks over"
				
			elif triggerFlag == 3072:
				if reapeatable: trigger = WADG.TTYPE.GUNR
				else: trigger = WADG.TTYPE.GUN1
				
			elif triggerFlag == 4096:
				trigger = "player bumps"
			elif triggerFlag == 5120:
				trigger = "projectile flies over"
			elif triggerFlag == 6144:
				if reapeatable: trigger = WADG.TTYPE.SWITCHR
				else: trigger = WADG.TTYPE.SWITCH1
				
			elif triggerFlag == 7168:
				trigger = "projectile hits or crosses"
				

				
		
		if type == 65535: type = 0
		
		if !typeDict.has(type):
			type = 0
		
		
		if frontSidedef != -1: curMapDict["sideToLine"][frontSidedef] = i
		if backSidedef != -1: curMapDict["sideToLine"][backSidedef] = i
		
		var dict = {"startVert":startVert,"endVert":endVert,"flags":flags,"type":type,"frontSideDef":frontSidedef,"backSideDef":backSidedef,"index":i}
		
		dict["trigger"] = trigger
		#if buttonActivate and reapeatable: dict["trigger"] = WADG.TTYPE.SWITCHR
		#if buttonActivate and !reapeatable: dict["trigger"] = WADG.TTYPE.SWITCH1
		
		if typeDict[type].has("arg1"):
			var argName = typeDict[type]["arg1"]
			dict[argName] = arg1
		
		lineDefs.append(dict)


	return lineDefs


func parseSidedef(lump):
	var scaleFactor = get_parent().scaleFactor
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	var sidedef = []

	for i in size/(2*3 + 3*8) :
		var xOffset = file.get_16s() * scaleFactor.x
		var yOffset = file.get_16s() * scaleFactor.y
		var upperName = file.get_String(8)
		var lowerName = file.get_String(8)
		var middleName = file.get_String(8)
		var sector = file.get_16()
		
		
		sidedef.append({"xOffset":xOffset,"yOffset":yOffset,"upperName":upperName,"lowerName":lowerName,"middleName":middleName,"sector":sector,"index":String(i)})

	return sidedef

func parseSidedefUDMF(data,mapDict):
	data = data.replace(" ","")
	data = data.split("{")
	data = data[1].split(";",false)
	
	var xOffset = 0
	var yOffset = 0
	var upperName = "-"
	var middleName = "-"
	var lowerName =  "-"
	var sector = 0
	
	for i in data:
		i = i.split("=")
		var valName = i[0]
		var value = i[1]
		
		value = value.replace('"',"")
		
		if valName == "SECTOR": sector = int(value)
		if valName == "TEXTURETOP": upperName = value
		if valName == "TEXTUREMIDDLE": middleName = value
		if valName == "TEXTUREBOTTOM": lowerName = value
		
	
	
	
	var index = mapDict["SIDEDEFS"].size()
	var dict = {"xOffset":xOffset,"yOffset":yOffset,"upperName":upperName,"lowerName":lowerName,"middleName":middleName,"sector":sector,"index":String(index)}
	
	mapDict["SIDEDEFS"].append(dict)
	

func parseVertices(lump):
	var scaleFactor = get_parent().scaleFactor
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	var vertices = []
	file.seek(offset)

	for i in size/(2*2):
		var posX = file.get_16s() * scaleFactor.x
		var posY = -file.get_16s() * scaleFactor.z
		
		minDim.x = min(minDim.x,posX)
		minDim.y = min(minDim.y,posY)
		maxDim.x = max(maxDim.x,posX)
		maxDim.y = max(maxDim.y,posY)
		
		vertices.append(Vector2(posX,posY))

	return vertices



func parseVertexUDMF(data,mapDict):

	data = data.replace(" ","")
	data = data.split("{")
	data = data[1].split(";",false)
	
	var scaleFactor = get_parent().scaleFactor
	var values = []
	
	for comp in data:
		comp = comp.split("=")[1]
		values.append(float(comp))
		
	var vert = Vector2(values[0],values[1])* Vector2(scaleFactor.x,scaleFactor.z)
	mapDict["VERTEXES"].append(vert)
	

func parseThings(lump):
	
	var scaleFactor = get_parent().scaleFactor
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	var things = []

	for i in size/(2*5):
		var pos = Vector3(file.get_16s(),-INF,-file.get_16s())* Vector3(scaleFactor.x,scaleFactor.y,scaleFactor.z)
		var rot = file.get_16s()
		var type = file.get_16()
		var flags = file.get_16()
		#if !things.has(type): things[type] = []

		things.append({"type":type,"pos":pos,"rot":rot-90,"flags":flags})

	return things
	

func parseThingsUDMF(data,mapDict):
	
	var x = 0
	var y = 0
	var angle = 0
	var type = 0
	var skill1 = 0
	var skill2 = 0
	var flags = 0
	
	data = data.replace(" ","")
	data = data.split("{")
	data = data[1].split(";",false)
	
	var values = []
	
	for i in data:
		i = i.split("=")
		var valName = i[0]
		var value = i[1]
		
		if valName == "X": x = float(value)
		if valName == "Y": y = float(value)
		if valName == "angle": angle = float(value)
		if valName == "type": type = int(value)
	
	
	var pos = Vector2(x,y)

	mapDict["THINGS"].append({"type":type,"pos":pos,"rot":type,"flags":flags})

		
func parseThingsHexen(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	var things = []

	var numThingEntry = size/((2*7)+(6))
	for i in size/((2*7)+(6)):
		var id = file.get_16()
		var pos = Vector3(file.get_16s(),-INF,-file.get_16s())*get_parent().scaleFactor
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
		
		things.append({"type":DoomEd,"pos":pos,"rot":rot,"flags":flags})
		#things.append({"pos":pos,"rot":rot,"type":type,"flags":flags})

	return things


func parseThings64(lump):
	

	
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	var things = []
	var numThingEntry = size/((2*7)+(6))
	
	var x = file.get_16s() 
	var y = file.get_16s() 
	var z = file.get_16s() 
	var angle = file.get_16s() 
	var type = file.get_16s() 
	var flags = file.get_16s() 
	var id = file.get_16s() 
	return

func typeOveride(type,line,sector,mapName,mapTo666,mapTo667,mapDict):
	
	var npcTrigger = null
	var map666entry = null
	var map667entry = null
	var sIndex = sector["index"]
	
	if mapTo666.has(mapName):
		map666entry = mapTo666[mapName]
	
	if mapTo667.has(mapName):
		map667entry = mapTo667[mapName]
	
#	if sector["tagNum"] == 666:
#		if mapTo666.has(mapName):
#			type = map666entry["type"]
#			npcTrigger = map666entry["npcName"]
#
#
#	if sector["tagNum"] == 667:
#		if mapTo667.has(mapName):
#			type = map667entry["type"]
#			npcTrigger = map667entry["npcName"]
#
	if line["backSector"]!= null:
		var oSector = mapDict["SECTORS"][line["backSector"]]
		if oSector["tagNum"] == 666:
			if mapTo666.has(mapName):
				type = map666entry["type"]
				npcTrigger = map666entry["npcName"]
				
		if oSector["tagNum"] == 667:
			if mapTo667.has(mapName):
				type = map667entry["type"]
				npcTrigger = map667entry["npcName"]

				
	
	line["npcTrigger"] = npcTrigger
	return type
	
func postProc(mapDict):
	
	
	var sideDefs = mapDict["SIDEDEFS"]

	initSectorToSides(mapDict)
	initSectorNeighbours(mapDict)
	createSectorToInteraction(mapDict)
	initSectorToLowestLowTexture(mapDict)
	
	createStairs(mapDict)
	
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
	var typeDict =  $"../LevelBuilder".typeSheet.data
	var interactables = mapDict["interactables"]
	var sectorToInteraction = mapDict["sectorToInteraction"]
	var sideDefs = mapDict["SIDEDEFS"]
	var isHexen = false
	
	if mapDict["isHexen"]:
		typeDict = $"../LevelBuilder".typeDictHexen
		isHexen= true
	
	sectorToSides = mapDict["sectorToSides"]
	
	for line in mapDict["LINEDEFS"]:#action sectors and interactables

		var frontSidedefIdx = line["frontSideDef"]
		var backSidedefIdx = line["backSideDef"]
		var backSide = null#sideDefs[backSidedefIdx]
		var backSideSector = null
		var sector = mapDict["SECTORS"][line["frontSector"]]
		
		var type = line["type"]
		var mapTo666 = $"../LevelBuilder".mapTo666
		var mapTo667 = $"../LevelBuilder".mapTo667
		var mapName = mapDict["name"]
		
		var lineIdx = line["index"]
		
		
		type = typeOveride(type,line,sector,mapName,mapTo666,mapTo667,mapDict)
		
		
		
		if type == 0: continue#i moved this up from below if errors occur undo this
		
		if isHexen:# and type == 0:
			continue
			
		if !typeDict.has(var2str(type)): continue
		
		var targetTag = 0
		
		if line.has("sectorTag"):#hexen line wont have have target tag entry
			 targetTag = line["sectorTag"]
		 
		var typeInfo = typeDict[var2str(type)]
		
		
		
		if backSidedefIdx != -1:
			backSide = sideDefs[backSidedefIdx]
			backSideSector = backSide["sector"]

		#if type == 0: continue
		
		
		var targetSectors = getTargetSectors(tagToSectors,targetTag,typeInfo,line,backSideSector)
			 
			
		
		if targetSectors == null:
			continue
			
			
		
			
		if typeInfo["type"] == WADG.LTYPE.STAIR:#if the type of the line is a stair
			for sec in targetSectors:#we get every target sector
				var stairSectors = getStairSectors(mapDict,mapDict["sectorToFrontSides"][sec],sec,type,sector["index"])#we get every sector in stair chain
				
				if !mapDict["lineToStairSectors"].has(lineIdx):
					mapDict["lineToStairSectors"][lineIdx] = []
				
				
				var stairSectorsForLine = stairSectors.keys()
				#stairSectorsForLine.sort()
				
				mapDict["lineToStairSectors"][lineIdx].append(stairSectorsForLine)
				mapDict["stairLookup"][sec] = stairSectors
				
				
				
				
#				for sectorIdx in stairSectors.keys():
#					for sideIdx in mapDict["sectorToBackSides"][sectorIdx]:
#
#						var stairLineIdx = mapDict["sideToLine"][sideIdx]
#						var stairLine = mapDict["LINEDEFS"][stairLineIdx]
##
#						stairLine["stairIdx"] = stairSectors[sectorIdx]["stairNum"]
#						stairLine["stairInc"] = typeDict[var2str(type)]["inc"]
						
				
				
		if typeInfo["type"] == WADG.LTYPE.STAIR:
			continue
		
		
		var npcTrigger = line["npcTrigger"]
		
		for s in targetSectors:#for every target sector
			if !sectorToInteraction.has(s):
				sectorToInteraction[s] = []#create an interaction entry for sector

			sectorToInteraction[s].append({"type":type,"line":line,"npcTrigger":npcTrigger})#set the interaction type for sector
			





func createStairs(mapDict):
	if !mapDict.has("lineToStairSectors"):
		return
	
	
	for lineIdx in mapDict["lineToStairSectors"].keys():
		var activatorLine = mapDict["LINEDEFS"][lineIdx]
		var stairGroups =  mapDict["lineToStairSectors"][lineIdx]
		var backSideSector = null
		var targetTag = 0
		var backSide = null
		var sideDefs = mapDict["SIDEDEFS"]
		
		var isHexen = false
		var line = mapDict["LINEDEFS"][lineIdx]
		var lineType = activatorLine["type"]
		
		var stairSectors = mapDict["lineToStairSectors"][lineIdx]
		
		var i = 0
		var stairs = removeSubsets(stairSectors)
		
		var typeDict =  $"../LevelBuilder".typeSheet.data
		var sl = mapDict["stairLookup"]
		
		
		for s in stairs:
			var initialSector = s[0]
			mapDict["stairLookup"][initialSector] = mapDict["stairLookup"][initialSector]
			
			var sectorGroup = mapDict["stairLookup"][initialSector]
			
			
			for subSectorIdx in sectorGroup.keys():
				var sectorBackSides= mapDict["sectorToBackSides"][subSectorIdx]
				
				for sideIdx in sectorBackSides:
					var subSectorInfo = sectorGroup[subSectorIdx]
					#var stairLine = mapDict["SIDEDEFS"][sideIdx]
					var stairLine = mapDict["LINEDEFS"][mapDict["sideToLine"][sideIdx]]
					mapDict["sideToLine"]
					stairLine["stairInc"] = typeDict[var2str(lineType)]["inc"]
					stairLine["stairIdx"] = subSectorInfo["stairNum"]
					
				
		
			if !mapDict["sectorToInteraction"].has([initialSector]):
				mapDict["sectorToInteraction"][initialSector] = []#create an interaction entry for sector
		
			mapDict["sectorToInteraction"][initialSector].append({"type":lineType,"line":activatorLine})#set the interaction type for sector
			
		#for s in targetSectors:#for every target sector
		#	if !sectorToInteraction.has(s):
		#		sectorToInteraction[s] = []#create an interaction entry for sector

		#	sectorToInteraction[s].append({"type":type,"line":line,"npcTrigger":npcTrigger})#set the interaction type for sector
					#stairLine["stairInc"] = typeDict[var2str(type)]["inc"]
					
				
				
				#var stairLineIdx = sectorGroup[secteorIdx][sideIdx]#mapDict["sideToLine"][sideIdx]
				#var stairLine = mapDict["LINEDEFS"][stairLineIdx]
		
				#stairLine["stairIdx"] = sectorGroup[stairLineIdx]["stairNum"]
				#stairLine["stairInc"] = typeDict[var2str(line["type"])]["inc"]
			
#		if line.has("sectorTag"):#hexen line wont have have target tag entry
#			 targetTag = line["sectorTag"]
#
#		if line["backSideDef"] != -1:
#			backSide = sideDefs[backSidedefIdx]
#			backSideSector = backSide["sector"]
#
#		#if type == 0: continue
#		var typeDict =  $"../LevelBuilder".typeSheet.data
#
#		if mapDict["isHexen"]:
#			typeDict = $"../LevelBuilder".typeDictHexen
#			isHexen= true
#
#		if line["type"] == 0: continue#i moved this up from below if errors occur undo this
#
#		if isHexen:# and type == 0:
#			continue
#
#		var targetSectors = getTargetSectors(mapDict["tagToSectors"],targetTag,typeDict[var2str(line["type"])],line,backSideSector)
		


func removeSubsets(arrays: Array) -> Array:
	var largestArrays = []
	for i in range(arrays.size()):
		var isSubset = false
		var currentArray = arrays[i]
		
		for j in range(arrays.size()):
			if i != j:
				var otherArray = arrays[j]
				if isArraySubset(currentArray, otherArray):
					isSubset = true
					break
		
		if not isSubset:
			largestArrays.append(currentArray)
	
	return largestArrays

func isArraySubset(array1: Array, array2: Array) -> bool:
	for element in array1:
		if not array2.has(element):
			return false

	return true


func getTargetSectors(tagToSectors,targetTag,typeInfo,line,backSideSector):
	
	var targetSectors = []
	
	#if line["index"] == 846:
	#	breakpoint
	
	
	if !tagToSectors.has(targetTag):#if sectorTag of line invalid skip
		return null
	
	
	if typeInfo["type"] == WADG.LTYPE.SCROLL or typeInfo["type"] == WADG.LTYPE.EXIT:#scroll is a special case that dosen't target oside(this is just a quick fix as all walls in the sector will be targeted which is incorrect)
		targetSectors = [line["frontSector"]]
		return targetSectors
	
	if targetTag != 0:
		targetSectors = tagToSectors[targetTag]#we use tag to lookup target sector index
		
#		if typeInfo["type"] == WADG.LTYPE.TELEPORT and backSideSector != null:#this was put here due to E2M1 sector 54
#			targetSectors.append(backSideSector)
	
	
	if typeInfo["triggerType"] == WADG.TTYPE.DOOR or typeInfo["triggerType"] == WADG.TTYPE.DOOR1:#door types cannot use sector tags to target
		targetTag = 0
		
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


func initSectorToLowestLowTexture(mapDict):
	for sectorIdx in mapDict["SECTORS"].size():
		var sector= mapDict["SECTORS"][sectorIdx]
		
		for i in mapDict["sectorToFrontSides"][sectorIdx]:
			var side = mapDict["SIDEDEFS"][i]
			if !sector.has("lowerTextures"):
				sector["lowerTextures"] = []
				
			if side["lowerName"] != "-":
				if !sector["lowerTextures"].has(side["lowerName"]):
					sector["lowerTextures"].append(side["lowerName"])

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
	
	
	
	if upperTexture  != "-": addRenderable(line,side,oSide,dir,upperTexture,"upper",curMapDict)
	if middleTexture != "-": addRenderable(line,side,oSide,dir,middleTexture,"middle",curMapDict)
	if lowerTexture  != "-": addRenderable(line,side,oSide,dir,lowerTexture,"lower",curMapDict)

	

	var oSideNull = false
	var sector = side["sector"]
	
	
	if oSide != null:#if side has an oSide but that oSide has no texture
		if oSide["upperName"] == "-" and oSide["middleName"] == "-" and oSide["lowerName"] == "-" :
			oSideNull = true
	else:
		oSideNull = true

	if middleTexture == "-" and upperTexture == "-" and lowerTexture == "-" and oSideNull and type != 0:
		addRenderable(line,side,oSide,dir,middleTexture,"trigger",curMapDict)#trigger
	
	

func addRenderable(line : Dictionary,side : Dictionary,oSide,dir:int,textureName :String,type : String,mapDict : Dictionary) -> void:
	var dict : Dictionary = {}
	var alpha : float = 1.0
	var sector : Dictionary =curMapDict["SECTORS"][side["sector"]]

	if !wallMatEntries.has(textureName) and textureName != "F_SKY1":
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
	
	var sType : int = line["type"]
	var scrollVector : Vector2 = Vector2.ZERO
	var typeDict = $"../LevelBuilder".typeSheet
	

	
	if mapDict["isHexen"]:
		typeDict =  load("res://addons/godotWad/resources/lineTypesHexen.tres")#$"../LevelBuilder".typeDictHexen
	
	var row = typeDict.getRow(var2str(sType))
	
	
	if row["type"] == WADG.LTYPE.SCROLL: 
		if row.has("vector"):
			scrollVector =  row["vector"]
		
		if row.has("specialType"):
			scrollVector =  dict["textureOffset"]/Vector2(get_parent().scaleFactor.x,get_parent().scaleFactor.z)
		
	if typeDict.getRow(var2str(sType)).has("alpha"):
		alpha =  typeDict.getRow(var2str(sType))["alpha"]
	
	
	if textureName != "F_SKY1":
		if !wallMatEntries.has(textureName): wallMatEntries[textureName] = []
	
		if !wallMatEntries[textureName].has([sector["lightLevel"],scrollVector,alpha]):
			wallMatEntries[textureName].append([sector["lightLevel"],scrollVector,alpha])
	
	var sectorToInteraction : Dictionary = curMapDict["sectorToInteraction"]
	
	if line.has("stairIdx"):
		dict["stairIdx"] = line["stairIdx"]
		dict["stairInc"] = line["stairInc"]
		
	
	
	if oSide != null:
		dict["oSector"] = oSide["frontSector"]

	var lineType 
	
	
	var entry = typeDict.getRow(var2str(dict["sType"]))
	#var x = typeDict.getRow(var2str(dict["sType"]))
	lineType = entry["type"]
	

	var sectorIdx = dict["sector"]
	#var t= sectorToInteraction[sectorIdx]
	var b1 : bool = !sectorToInteraction.has(dict["sector"])
	var b2 : bool = !sectorToInteraction.has(dict["oSector"])
	var b3 : bool = !line.has("stairIdx")
	var b4 : bool = !WADG.isASwitchTexture(textureName, $"../ImageBuilder".switchTextures)
	var b5 = true
	
	if entry["triggerType"] == WADG.TTYPE.GUN1 or entry["triggerType"] == WADG.TTYPE.GUNR:
		b5 = false

	
	
	if sector["ceilingTexture"] == "F_SKY1" and get_parent().skyWall== get_parent().SKYVIS.ENABLED:#walls to cover sky gap
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

	
	
	if b1 && b2 && b3 && b4 && b5:

		staticRenderables.append(dict)
		
		if !sectorToRenderables.has(dict["sector"]):
			sectorToRenderables[dict["sector"]] = []
		
	
	else:
		dynamicRenderables.append(dict)
		

func parsePallete(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)

	for i in range(0,size/768):
		var pallete = []
		for j in 256:
			pallete.append(Color8(file.get_8(),file.get_8(),file.get_8()))
		
		
		#pallete[255].a = 0
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


		patchTextureEntries[texName] = {"masked":masked,"file":file,"width":width,"height":height,"obsoleteData":obsoleteData,"patchCount":patchCount,"patches":patches}

func parsePatchNames(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	var index = 0
	file.seek(offset)

	var numberOfPname = file.get_32()
		
	for i in numberOfPname:
		var name = file.get_String(8)
		patchNames[index] = name
		index += 1

func parsePatch(lump) -> Dictionary:
	var offset : int = lump["offset"]
	var size : int = lump["size"]
	var file : Node = lump["file"]
	file.seek(offset)
	
	var width : int = file.get_16()
	var height : int= file.get_16()

	var left_offset : int = file.get_16s()
	var top_offset : int = file.get_16s()
	var columnOffsets = []
	if (file.get_position() + width) > file.get_len():
		return {}
	for i in width:
		columnOffsets.append(file.get_32())

	return {"width":width,"height":height,"left_offset":left_offset,"top_offset":top_offset,"columnOffsets":columnOffsets}

func parseTextmap(lump,lumpName):
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	var content = file.get_String(size)
	content[content.find(";")] = "}"
	content = content.split("}")

	for i in content.size():
		content[i] = content[i].strip_escapes()

	textMap = content

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
	audio.loop_end = numberOfSamples

	var data = []
	
	for i in range(0,numberOfSamples - 4):#4 bytes of padding at end of sample:
		data.append(file.get_8()-128)
	
	audio.data = data
	$"../ResourceManager".soundCache[lumpName] = audio
	
	

var midiControl = [
	"instrument",
	"bank select",
	"modulation pot",
	"volume",
	"pan",
	"expression pot",
	"reverb depth",
	"chorus depth",
	"sustain pedal",
	"soft pedal",
]

func parseD_(lump,lumpName):
	return
	if lumpName != "D_E1M1":
		return
	
	#toMidi()
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	var instrumentPatchs = []
	var measureCount = 0
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
			
	
	file.seek(offset+startOffset)
	var infoByte #= file.get_8()
	var channelNumber = 0
	var event         = 7
	var last          = 0
	var data
	var delayCount = 0
	
	

	while event != 6:
		
		infoByte = file.get_8()
		channelNumber = (infoByte & 0b00001111)
		event         = (infoByte & (0b01110000)) >> 4
		last          = (infoByte & (0b10000000)) >> 7
		
		

		
		if event == 6:#song over
			breakpoint
			return
			
		
		data = file.get_8()
		
		
		if event == 0:
			var noteNumber = data & 0b01111111
			print("channel ",channelNumber," release note:",noteNumber)
			
		if event == 1:
			var noteNumber = data & 0b01111111
			var data2 = file.get_8()#play note reads an extra byte
			var volume = data2 & 0b01111111
			print("channel ",channelNumber," play note:",noteNumber)
			
		if event == 2:
			var bendAmount = data & 0b01111111
			print("pitch bend")
			
		if event == 3:
			var eventNum = data & 0b01111111
			print("system event:",eventNum)
			
		if event == 4:
			var controller = data & 0b01111111
			var data2 = file.get_8()
			if midiControl.has(controller):
				print("controller:", midiControl[controller])
			else:
				print("conroller unk")
			
		if event == 5:
			print("end of measure:", measureCount)
			measureCount += 1
		
		#if last:
		#	breakpoint
		
		while last:
			var delay = file.get_8()
			last = (delay & 0x7f)
			delayCount += 1
		
		#if event == 7:
		#	print("empty")
		
	breakpoint
	return

func getStairSectors(mapDict,frontSides,sectorIdx,type,fSector):
	var stairDict = {}
	stairDict[sectorIdx] = null
	var ret = getNextStairSector(mapDict,stairDict,type,fSector)
	
	while ret != false:
		ret = getNextStairSector(mapDict,stairDict,type,fSector)
		
	return stairDict
	

func getNextStairSector(mapDict,stairDict,type,fSector):
	var curSecIdx = stairDict.keys().back()
	var frontSides = mapDict["sectorToFrontSides"][curSecIdx]
	var curFloorTexture = mapDict["SECTORS"][curSecIdx]["floorTexture"]
	var allNull
	
	
	for sideIdx in frontSides:#for every node facing inwards towards sector
		
		var side = mapDict["SIDEDEFS"][sideIdx]#get entry for side
		
		var sec = sectorToSides[side["sector"]]
		var x = mapDict["sideToLine"][sideIdx]
		var line = mapDict["LINEDEFS"][x]
		
		if line["frontSideDef"] != sideIdx:
			continue
			
		
		if side["backSector"] != null:#if side has back sector
			var oSector = side["backSector"]
			var oFloorTexture = mapDict["SECTORS"][oSector]["floorTexture"]
			if oFloorTexture == curFloorTexture:#if opposing floor is same texture as current floor 
				if !stairDict.has(oSector):#if a previous sector of the stairs isn't the oSide of the side
					if oSector != fSector:
						stairDict[curSecIdx] = {"sideIdx":sideIdx,"stairNum":stairDict.keys().size(),"stairType":type}
						stairDict[oSector] = null
						return true
		
				
	
	stairDict[curSecIdx] = {"sideIdx":null,"stairNum":stairDict.keys().size()}
	return false

func parseDemo(lump,lumpName):
	
	var offset = lump["offset"]
	var size = lump["size"]
	var file = lump["file"]
	file.seek(offset)
	
	var version = file.get_8()
	
	if version != 109:
		return
	
	var skill = file.get_8()
	var episode = file.get_8()
	var map = file.get_8()
	var multiplayerRule = file.get_8()
	var respawn = file.get_8()
	var faat = file.get_8()
	var nomonsters = file.get_8()
	var recordingPlayer = file.get_8()
	var greenGuy= file.get_8()
	var indigoGuy= file.get_8()
	var brownGuy= file.get_8()
	var redGuy= file.get_8()
	
	var numberOfTicks = (size-(12*8))/4
	#breakpoint
	
	
func toMidi():
	var file = File.new()
	file.endian_swap = true
	file.open("res://dbg/test.midi", File.WRITE)
	file.store_string("MThd")
	file.store_32(0x06)#chunk size
	file.store_16(0x00)#midi format single (0)
	file.store_16(0x01)#number of trackk
	file.store_16(0x46)#number of trackk
	
	
	file.store_string("MTrk")
	file.close()
	


