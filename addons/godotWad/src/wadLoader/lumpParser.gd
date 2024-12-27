@tool
extends Node

var format = "DOOM"

@onready var parent : WAD_Map = get_parent()

var lineDefs : Array[Dictionary]= []
var staticRenderables : Array[Dictionary] = []
var dynamicRenderables : Array[Dictionary] = []
var patchTextureEntries : Dictionary = {}
var flatMatEntries : Dictionary = {}
var wallMatEntries : Dictionary = {}
var flatTextureEntries : Dictionary = {}
var textureEntryFiles := {}
var textMap = []
var palletes : Array[Array]= []
var lightSectors : PackedInt32Array = []
var colorMaps : Array[Image]= []
var patchNames : Dictionary = {}
var curMapDict : Dictionary
var sectorToSides : Dictionary= {}
var sectorToRenderables : Dictionary= {}
var versionLumpName : String= ""
var isOldLegacy = false
var minDim = Vector3(INF,INF,INF)
var maxDim =  Vector3(-INF,-INF,-INF)
var extraColorTablesPre : Dictionary = {}
var extraColorTables: Dictionary = {}
var typeDict : Dictionary = {}


var mutex : Mutex = Mutex.new()
enum LUMP{
	name,
	file,
	offset,
	size,
}


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
	



var pLump : String = ""

func addMapEntry(lumps : Array,curIdx : int):
	var mapLumps :  PackedStringArray = ["THINGS","LINEDEFS","SIDEDEFS","VERTEXES","SEGS","SSECTORS","NODES","SECTORS","REJECT","BLOCKMAP","BEHAVIOR","SCRIPTS"]
	var ignores : Array[String] = ["REJECT","BLOCKMAP","NODES"]
	
	var mapName : StringName = lumps[curIdx][LUMP.name]
	var localMapDict : Dictionary = {}
	var numLumps : int = lumps.size()
	while(curIdx < numLumps):
		curIdx +=1
		
		#if curIdx >= numLumps-1:
		if curIdx >= numLumps:
			curIdx += 1
			break
		
		var lump = lumps[curIdx]
		var lumpName = lumps[curIdx][LUMP.name]
		
		if !mapLumps.has(lumpName):
			break
			
		if !ignores.has(lumpName):
			localMapDict[lumpName] = {"file":lumps[curIdx][LUMP.file],"offset":lumps[curIdx][LUMP.offset],"size":lumps[curIdx][LUMP.size]}
			
	
	
	get_parent().maps[mapName] = localMapDict
	return curIdx

func addTextMapEntry(lumps : Array, curIdx : int):
	
	var mapName : String = lumps[curIdx][LUMP.name]
	var localMapDict : Dictionary = {}
	
	while(true):
		curIdx +=1
		var lump = lumps[curIdx]
		var lumpName = lumps[curIdx][LUMP.name]
		
		if lumpName == &"ENDMAP":
			break
		
		localMapDict[lumpName] = {"file":lumps[curIdx][LUMP.file],"offset":lumps[curIdx][LUMP.offset],"size":lumps[curIdx][LUMP.size]}
		
	get_parent().maps[mapName] = localMapDict
	return curIdx

func parseLumps(lumps : Array,isHexen : bool = false) :
	var mapLumps :  Array[String] = ["THINGS","LINEDEFS","SIDEDEFS","VERTEXES","SEGS","SSECTORS","NODES","SECTORS","REJECT","BLOCKMAP","BEHAVIOR","SCRIPTS"]
	var a = Time.get_ticks_msec()
	var parent: Node = get_parent()
	var everyLumpIsSound = false
	colorMaps = []
	
	for lump in lumps:
		var lumpName = lump[LUMP.name]
		if lumpName == "PLAYPAL": 
			parsePallete(lump)
			break
			
	
	var lumpIdx : int = 0
	while lumpIdx < lumps.size():#while we havnet checked every lump
	#for lumpIdx : int in lumps.size():
		var lump : Array = lumps[lumpIdx]
		var lumpName : String = lump[LUMP.name]
		lumpIdx += 1
		
		if lumpName == "SNDCURVE":
			if isHexen:
				everyLumpIsSound = true
		
		
		if everyLumpIsSound:
			if lumpName == "WINNOWR":#hack
				everyLumpIsSound = false
			else:
				parseDs(lump,lumpName)
				continue
		
		if mapLumps.has(lumpName):
			var curLumpIdx : int = lumpIdx
			var curLumpName : String = lumpName 
			curLumpIdx -=1#go back one
			
			while mapLumps.has(curLumpName) and curLumpIdx > 0:#as lonong as we find a map lump and we're not at the 
				curLumpName = lumps[curLumpIdx][LUMP.name]
				curLumpIdx -= 1
			
			#if curLumpIdx == 0:
			#	continue
			
			lumpIdx = addMapEntry(lumps,curLumpIdx+1)
			if lumpIdx == lumps.size()-1:
				break
			else:
				continue
			
		if lumpName == "TEXTMAP":
			lumpIdx = addTextMapEntry(lumps,lumpIdx-2)
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
			if !parent.toDisk or Engine.is_editor_hint():
				$"../ResourceManager".audioLumps[lumpName] = lump
			else:
				parseDs(lump,lumpName)
		elif lumpName.substr(0,2) == "D_": 
			#print("d")
			parseD_(lump,lumpName)
		elif lumpName.substr(0,2) == "DP": continue
		#elif lumpName.substr(0,4) == "DEMO": dont need to parse until requested
		#	parseDemo(lump,lumpName)
		elif lumpName == "VERSION":
			parseVersion(lump)
		elif lumpName == "TINTTAB":
			parse256colorMap(lump)
		else: 
			getMagic(lump,pLump)
			flatTextureEntries[lumpName] = lump
		
		
		pLump = lumpName
	
	parent.colorMaps = colorMaps
	parent.palletes = palletes
	parent.patchTextureEntries = patchTextureEntries
	parent.flatTextureEntries = flatTextureEntries
	parent.patchNames = patchNames
	SETTINGS.setTimeLog(get_tree(),"parseLumps",a)


func populateMapDict(lumps : Array) :
	var mapLumps :  Array[String] = ["THINGS","LINEDEFS","SIDEDEFS","VERTEXES","SEGS","SSECTORS","NODES","SECTORS","REJECT","BLOCKMAP","BEHAVIOR","SCRIPTS"]
	
	var lumpIdx : int = 0
	while lumpIdx < lumps.size():
		var lump : Array = lumps[lumpIdx]
		var lumpName : String = lump[LUMP.name]
		lumpIdx += 1
	
		if mapLumps.has(lumpName):
			var curLumpIdx : int = lumpIdx
			var curLumpName : String = lumpName
			curLumpIdx -=1
				
			while mapLumps.has(curLumpName) and curLumpIdx > 0:
				curLumpName = lumps[curLumpIdx][LUMP.name]
				curLumpIdx -= 1
				
				if curLumpIdx == 0:
					continue
					
				lumpIdx = addMapEntry(lumps,curLumpIdx+1)
				continue
				
			if lumpName == "TEXTMAP":
				lumpIdx = addTextMapEntry(lumps,lumpIdx-2)
				
		
	

func parseMap(mapDict : Dictionary,isHexen : bool = false,is64 : bool = false):
	var a : int = Time.get_ticks_msec()
	if mapDict.has("TEXTMAP"):
		parseTextMap(mapDict,isHexen)
		return
	
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
	mapDict["dynamicFloors"] = PackedInt32Array()
	mapDict["dynamicCeilings"] = PackedInt32Array()
	mapDict["fakeFloors"] = {}
	mapDict["fakeCeilings"] = {}
	mapDict["lineToStairSectors"] = {}
	mapDict["sideToLine"] = {}
	mapDict["entities"] = {}
	lightSectors = []
	staticRenderables = []
	dynamicRenderables = []
	
	mapDict["BB"] = Vector3.ZERO
	minDim.x = INF
	minDim.z = INF
	minDim.y = INF
	maxDim.x =-INF
	maxDim.z = -INF
	maxDim.y = -INF

	typeDict = get_parent().typeDict.data
	
	if mapDict.has("BEHAVIOR"): 
		mapDict["isHexen"] = true
	
	var isZipped = false
	if mapDict[mapDict.keys()[0]].has("zip"):
		isZipped = true
	
	if !isZipped:
		for lumpName : StringName in mapDict.keys():
			if lumpName == "LINEDEFS" and mapDict["isHexen"] == false: mapDict["lineDefsParsed"] = parseLinedef(mapDict[lumpName])
			if lumpName == "LINEDEFS" and mapDict["isHexen"] == true: mapDict["lineDefsParsed"] = parseLinedefHexen(mapDict[lumpName])
			elif lumpName == "SIDEDEFS" : mapDict["sideDefsParsed"] = parseSidedef(mapDict[lumpName])
			elif lumpName == "SECTORS"  : mapDict["sectorsParsed"] = parseSector(mapDict[lumpName],mapDict)
			elif lumpName == "VERTEXES" : mapDict["vertexesParsed"] = parseVertices(mapDict[lumpName])
			elif lumpName == "THINGS" and get_parent().is64: mapDict["thingsParsed"] = parseThings64(mapDict[lumpName])
			elif lumpName == "THINGS" and mapDict["isHexen"] == false: mapDict["thingsParsed"] = parseThings(mapDict[lumpName])
			elif lumpName == "THINGS" and mapDict["isHexen"] == true: mapDict["thingsParsed"] = parseThingsHexen(mapDict[lumpName])
			elif lumpName == "BEHAVIOR": continue
	else:
		for lumpName in mapDict.keys():
			#if lumpName == "TEXTMAP": parseTextmapPreZip(mapDict[lumpName],lumpName)
			if lumpName == "LINEDEFS" and mapDict["isHexen"] == false: mapDict["lineDefsParsed"] = parseLinedef(mapDict[lumpName])
			if lumpName == "LINEDEFS" and mapDict["isHexen"] == true: mapDict["lineDefsParsed"] = parseLinedefHexenZip(mapDict[lumpName])
			elif lumpName == "SIDEDEFS" : mapDict["sideDefsParsed"] = parseSidedefZip(mapDict[lumpName])
			elif lumpName == "SECTORS"  : mapDict["sectorsParsed"] = parseSectorZip(mapDict[lumpName],mapDict)
			elif lumpName == "VERTEXES" : mapDict["vertexesParsed"] = parseVerticesZip(mapDict[lumpName])
			elif lumpName == "THINGS" and get_parent().is64: mapDict["thingsParsed"] = parseThings64(mapDict[lumpName])
			elif lumpName == "THINGS" and mapDict["isHexen"] == false: mapDict["thingsParsed"] = parseThings(mapDict[lumpName])
			elif lumpName == "THINGS" and mapDict["isHexen"] == true: mapDict["thingsParsed"] = parseThingsHexenZip(mapDict[lumpName])
			elif lumpName == "BEHAVIOR": continue
			
			
			
	mapDict["minDim"] = Vector3(minDim.x,minDim.z,minDim.y)
	mapDict["maxDim"] = Vector3(maxDim.x,maxDim.z,maxDim.y)  
	mapDict["BB"] = mapDict["maxDim"] - mapDict["minDim"]
	
	SETTINGS.setTimeLog(get_tree(),"parse map",a)
	
	

func parseTextMap(mapDict,isHexen = false):
	
	var textmapLump = mapDict["TEXTMAP"]
	
	var content = null
	
	if textmapLump.has("zip"):
		content = textmapLump["zip"][0].read_file(textmapLump["zip"][1])
		content = content.slice(textmapLump["offset"],textmapLump["offset"]+textmapLump["size"])
		
		content = content.get_string_from_ascii().to_upper() 
	
	else:
		var offset = textmapLump["offset"]
		var size = textmapLump["size"]
		var file = parent.fileLookup[textmapLump["file"]]
		file.seek(offset)
		
		content  = file.get_buffer(size).get_string_from_ascii().to_upper() 
	
	content = content.replace("\n","")
	content[content.find(";")] = "}"
	content = content.split("}")

	
	curMapDict = mapDict
	mapDict["vertexesParsed"] = [] as PackedVector2Array
	mapDict["lineDefsParsed"] = [] as Array[Dictionary]
	mapDict["sideDefsParsed"] = [] as Array[Dictionary]
	mapDict["sectorsParsed"] = [] as Array[Dictionary]
	mapDict["THINGS"] = []
	mapDict["thingsParsed"] = [] as Array[Dictionary]
	mapDict["tagToSectors"] = {}
	mapDict["actionSectorTags"] = {}
	mapDict["taggedSidedefs"] = {}
	mapDict["sectorToSides"] = {}
	mapDict["sectorToFrontSides"] = {}
	mapDict["sectorToBackSides"] = {}
	mapDict["interactables"] = []
	mapDict["sectorToInteraction"] = {}
	mapDict["staticRenderables"] = []
	mapDict["dynamicFloors"] = []
	mapDict["dynamicCeilings"] = []
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
	
	for i in content:
		var idx = content.find(i)
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
	mapDict["mapName"] = pLump

	
func print_bits(value):
	var binary_string = ""

	# Loop through each bit of the variable
	for i in range(15, -1, -1): # assuming 32-bit integer
		# Check if the bit is set
		if value & (1 << i) != 0:
			binary_string += "1"
		else:
			binary_string += "0"

	print(binary_string)



func parseSector(lump : Dictionary,mapDict : Dictionary) -> Array[Dictionary]:
	var scaleFactor = parent.scaleFactor
	
	var offset : int= lump["offset"]
	var size : int= lump["size"]
	var file : FileAccess = parent.fileLookup[lump["file"]]
	file.seek(offset)
	var sectors : Array[Dictionary]= []

	#for i in size/(2*5 + 8*2):
	for i in size/26:
		var floorHeight : float= get_16s(file)*  scaleFactor.y
		var ceilingHeight : float= get_16s(file) *  scaleFactor.y
		var floorTexture : StringName= file.get_buffer(8).get_string_from_ascii()
		var ceilingTexture : StringName= file.get_buffer(8).get_string_from_ascii()
		var lightLevel : float= file.get_16()
		var type : int= file.get_16()
		var tagNum : int= file.get_16()
		
		
		
		var lighting : int= (type & 0b0000000000011111)
		var damage : int=   (type & 0b0000000001100000) >> 5
		var secret : int=   (type & 0b0000000010000000) >> 7
		var friction: int=  (type & 0b0000000010000000) >> 8
		var wind : int=     (type & 0b0000000100000000) >> 9
		var unk : int=      (type & 0b0000001000000000) >> 10
		var noSecSound: int=(type & 0b0000010000000000) >> 11
		var noMovSound: int=(type & 0b0000100000000000) >> 12
		
		
		sectors.append({"floorHeight":floorHeight,"ceilingHeight":ceilingHeight,"floorTexture":floorTexture,"ceilingTexture":ceilingTexture,"lightLevel":lightLevel,"type":type,"tagNum":tagNum,"index":i})
		

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
			curMapDict["tagToSectors"][tagNum] = PackedInt32Array()

		curMapDict["tagToSectors"][tagNum].append(i)
		mapDict["sectorToSides"][i] = PackedInt32Array()
		mapDict["sectorToFrontSides"][i] = PackedInt32Array()
		mapDict["sectorToBackSides"][i] = PackedInt32Array()

		minDim.z = min(minDim.z,floorHeight)
		maxDim.z = max(maxDim.z,ceilingHeight)


	return sectors
	
	
func parseSectorZip(lump,mapDict):
	var scaleFactor = parent.scaleFactor
	
	var offset = lump["offset"]
	var size = lump["size"]
	var data : PackedByteArray = lump["zip"][0].read_file(lump["zip"][1])
	var curPos : int = lump["offset"]
	var sectors  : Array[Dictionary] = []

	#for i in size/(2*5 + 8*2):
	for i in size/16:
		
		var floorHeight = data.decode_s16(curPos)*  scaleFactor.y
		curPos += 2
		var ceilingHeight = data.decode_s16(curPos) *  scaleFactor.y
		curPos += 2
		
		var floorTexture = data.slice(curPos,curPos+8).get_string_from_ascii()
		curPos += 8
		var ceilingTexture = data.slice(curPos,curPos+8).get_string_from_ascii()
		curPos += 8
		var lightLevel = data.decode_u16(curPos)
		curPos += 2
		var type = data.decode_u16(curPos)
		curPos += 2
		var tagNum =  data.decode_u16(curPos)
		curPos += 2
		
		
		#var floorHeight = get_16s(file)*  scaleFactor.y
		#var ceilingHeight = get_16s(file) *  scaleFactor.y
		#var floorTexture = file.get_buffer(8).get_string_from_ascii()
		#var ceilingTexture = file.get_buffer(8).get_string_from_ascii()
		#var lightLevel = file.get_16()
		#var type = file.get_16()
		#var tagNum = file.get_16()
		
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
			curMapDict["tagToSectors"][tagNum] = PackedInt32Array()

		curMapDict["tagToSectors"][tagNum].append(i)
		mapDict["sectorToSides"][i] = PackedInt32Array()
		mapDict["sectorToFrontSides"][i] = PackedInt32Array()
		mapDict["sectorToBackSides"][i] = PackedInt32Array()

		minDim.z = min(minDim.z,floorHeight)
		maxDim.z = max(maxDim.z,ceilingHeight)


	return sectors

func parseSectorUDMF(data,mapDict):
	var scaleFactor = parent.scaleFactor
	var floorHeight = 0
	var ceilingHeight = 0
	var floorTexture = "-"
	var ceilingTexture = "-"
	var lightLevel = 0
	var type = 0
	var tagNum = 0
	var index = mapDict["sectorsParsed"].size()
	
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
		if valName == "ID": tagNum = int(value)


	if !flatMatEntries.has(floorTexture): flatMatEntries[floorTexture] = []
	if !flatMatEntries.has(ceilingTexture): flatMatEntries[ceilingTexture] = []
		
	if !flatMatEntries[floorTexture].has(lightLevel): 
		if !flatMatEntries[floorTexture].has([lightLevel,Vector2.ZERO]):
			flatMatEntries[floorTexture].append([lightLevel,Vector2.ZERO,0])
				
	if !flatMatEntries[ceilingTexture].has(lightLevel):
		if !flatMatEntries[ceilingTexture].has([lightLevel,Vector2.ZERO]):
			flatMatEntries[ceilingTexture].append([lightLevel,Vector2.ZERO,0])
		
	if !curMapDict["tagToSectors"].has(tagNum):
		curMapDict["tagToSectors"][tagNum] = PackedInt32Array()

	curMapDict["tagToSectors"][tagNum].append(index)
	mapDict["sectorToSides"][index] = PackedInt32Array()
	mapDict["sectorToFrontSides"][index] = PackedInt32Array()
	mapDict["sectorToBackSides"][index] = PackedInt32Array()

	minDim.z = min(minDim.z,floorHeight)
	maxDim.z = max(maxDim.z,ceilingHeight)
	
	
	var dict = {"floorHeight":floorHeight,"ceilingHeight":ceilingHeight,"floorTexture":floorTexture,"ceilingTexture":ceilingTexture,"lightLevel":lightLevel,"type":type,"tagNum":tagNum,"index":index}
	mapDict["sectorsParsed"].append(dict)
	
	
func parseLinedef(lump) -> Array[Dictionary]:
	var offset =  lump["offset"]
	var size = lump["size"]
	var file =  parent.fileLookup[lump["file"]]
	
	var lineDefs : Array[Dictionary]= []
	var actionSectorTags : Dictionary = curMapDict["actionSectorTags"]
	
	file.seek(offset)
	
	for i in size/(2*7):
		
		#if i == 27:
		#	breakpoint
		
		var startVert = file.get_16()
		var endVert = file.get_16()
		var flags = file.get_16()
		var type = file.get_16()
		var sectorTag = 0
		if isOldLegacy:
			sectorTag = get_16s(file)
		else:
			sectorTag = file.get_16()
		
		
		var frontSidedef = get_16s(file)
		var backSidedef = get_16s(file)
		
		
		if !typeDict.has(str(type)):
			type = 0
		
		if sectorTag < 0:
			breakpoint
		
		if type == -1: type = 0
		if frontSidedef != -1: curMapDict["sideToLine"][frontSidedef] = i
		if backSidedef != -1: curMapDict["sideToLine"][backSidedef] = i
		
		lineDefs.append({"startVert":startVert,"endVert":endVert,"flags":flags,"type":type,"sectorTag":sectorTag,"frontSideDef":frontSidedef,"backSideDef":backSidedef,"index":i})


	return lineDefs

func parseLinedefUMDF(data,mapDict):
	data = data.replace(" ","")
	data = data.split("{")
	var lindefIndex = int(data[0].split("//")[1])
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
	var arg1
	var arg2
	var arg3
	var arg4
	var arg5
	var alpha = 1.0
	#var typeDict = get_parent().typeDict.get_data()
	var typeDict  = parent.configToLineTypes["Hexen"]
	var argsStr : Dictionary = {}
	var flagsStr : Dictionary = {}
	var args = [null,null,null,null,null]
	var twoSided = false
	var id = 0
	var udmfData = {}
	var lowerUnpegged = false
	var upperUnpegged = false
	
	for i in data:
		i = i.split("=")
		var valName : StringName = i[0]
		var value = i[1]
		
		if valName == &"V1": v1 = int(value)
		elif valName == &"V2": v2 = int(value)
		elif valName == &"SIDEFRONT": frontSide = int(value)
		elif valName == &"SIDEBACK": backSide = int(value)
		elif valName == &"BLOCKING": flagsStr["BLOCKING"] = sBool(value)
		elif valName == &"SPECIAL": type = int(value)
		elif valName == &"ARG0": args[0] = value
		elif valName == &"ARG1": args[1] = value
		elif valName == &"ARG2": args[2] = value
		elif valName == &"ARG3": args[3] = value
		elif valName == &"ARG5": args[4] = value
		elif valName == &"PLAYERUSE": flagsStr["PLAYERUSE"] = sBool(value)
		elif valName == &"ID": id = value
		elif valName == &"ALPHA" : alpha = float(value)
		elif valName == &"TWOSIDED" : twoSided = true
		elif valName == &"DONTPEGBOTTOM" : lowerUnpegged = true
		elif valName == &"DONTPEGTOP" : lowerUnpegged = true
		elif valName == &"DONTDRAW": pass
		elif valName == &"JUMPOVER": pass
		elif valName == &"REPEATSPECIAL": pass
		elif valName == &"PLAYERCROSS": pass
		elif valName == &"BLOCKEVERYTHING": pass
		elif valName == &"LOCKNUMBER": pass
		elif valName == &"IMPACT": pass
		elif valName == &"MISSILECROSS": pass
		elif valName == &"ANYCROSS": pass
		elif valName == &"BLOCKMONSTERS": pass
		elif valName == &"SECRET": pass
		elif valName == &"CHECKSWITCHRANGE": pass
		elif valName == &"BLOCKPLAYERS": pass
		elif valName == &"CLIPMIDTEX": pass
		elif valName == &"BLOCKSOUND": pass
		elif valName == &"WRAPMIDTEX":pass
		elif valName == &"MIDTEX3D" : pass
		elif valName == &"MIDTEX3DIMPASSIBLE" : pass
		elif valName == &"ARG0STR" : pass
		else:
			breakpoint
			

	udmfData["twoSided"] = twoSided
	udmfData["lowerUnpegged"] = lowerUnpegged
	udmfData["upperUnpegged"] = upperUnpegged
	
	
	if flagsStr.has("BLOCKING"): 
		blocking = flagsStr["BLOCKING"]
	
	if blocking:
		flags = 1

	if type == 13:
		breakpoint

	if typeDict.has(str(type)) and type != 0:
		var typeInfo : Dictionary = typeDict[str(type)]
		
		
		
		for i in range(1,6):
			var argNameStr : String = "arg"+str(i)
			if !typeInfo[argNameStr].is_empty():
				argsStr[typeInfo[argNameStr]] = getHexenArgValue(typeInfo[argNameStr],args[i-1])
		
		#for i in flagsStr:
		#	breakpoint
		
		if argsStr.has("sectorTag"): 
			sectorTag = argsStr["sectorTag"]
		
	
	if type == 13:
		breakpoint
	udmfData["args"] = argsStr
	var dict = {"startVert":v1,"endVert":v2,"flags":flags,"type":type,"sectorTag":sectorTag,"frontSideDef":frontSide,"backSideDef":backSide,"index":lindefIndex,"udmfData":udmfData}
	if alpha != 1.0:
		dict["alpha"] = alpha
	mapDict["lineDefsParsed"].append(dict)
	

func sBool(str : String) -> bool:
	if str == "TRUE":
		return true
		
	return false
		

func parseLinedefHexen(lump) -> Array[Dictionary]:
	var scaleFactor = get_parent().scaleFactor
	var offset = lump["offset"]
	var size = lump["size"]
	var file = parent.fileLookup[lump["file"]]
	file.seek(offset)
	var lineDefs : Array[Dictionary] = []
	var actionSectorTags = curMapDict["actionSectorTags"]
	var numLindef = size/((5*2)+6)
	var typeDict =  get_parent().typeDict.data
	
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
		
		var frontSidedef = get_16s(file)
		var backSidedef = get_16s(file)
		
		if frontSidedef < -1:
			breakpoint
		
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
		
		
		
		
		if frontSidedef != -1: curMapDict["sideToLine"][frontSidedef] = i
		if backSidedef != -1: curMapDict["sideToLine"][backSidedef] = i
		
		var typeStr : StringName= str(type)
		
		if !typeDict.has(typeStr):
			type = 0
		elif typeDict[typeStr]["str"].is_empty():
			type = 0
		
		var dict = {"startVert":startVert,"endVert":endVert,"flags":flags,"type":type,"frontSideDef":frontSidedef,"backSideDef":backSidedef,"index":i,"triggerType":trigger}
		

		if !typeDict.has(typeStr):
			lineDefs.append(dict)
			continue
		
		
		if typeDict[typeStr]["str"].is_empty():
			lineDefs.append(dict)
			continue
		
		dict["trigger"] = trigger
		
		if typeDict[typeStr].has("arg1"):
			var argName = typeDict[typeStr]["arg1"]
			dict[argName] = arg1
			
		if typeDict[typeStr].has("arg2"):
			var argName = typeDict[typeStr]["arg2"]
			dict[argName] = arg2
		
		if typeDict[typeStr].has("arg3"):
			var argName = typeDict[typeStr]["arg3"]
			dict[argName] = arg3
		
		if typeDict[typeStr].has("arg4"):
			var argName = typeDict[typeStr]["arg4"]
			dict[argName] = arg4
		
		if typeDict[typeStr].has("arg5"):
			var argName = typeDict[typeStr]["arg5"]
			dict[argName] = arg5
			
		lineDefs.append(dict)


	return lineDefs

func parseLinedefHexenZip(lump):
	var zip : ZIPReader = lump["zip"][0]
	var data : PackedByteArray = zip.read_file(lump["zip"][1])
	var scaleFactor = get_parent().scaleFactor
	var offset = lump["offset"]
	var size = lump["size"]
	var curPos = lump["offset"]
	#var file = lump["file"]
	#file.seek(offset)
	
	var lineDefs : Array[Dictionary] = []
	var actionSectorTags = curMapDict["actionSectorTags"]
	var numLindef = size/((5*2)+6)
	var typeDict =  get_parent().typeDict.data
	
	for i in numLindef:
		
		
		
		var startVert = data.decode_u16(curPos)
		curPos += 2
		var endVert = data.decode_u16(curPos)
		curPos += 2
		var flags = data.decode_u16(curPos)
		curPos += 2
		var type = data.decode_u8(curPos)
		curPos += 1
		
		
		var arg1 = data.decode_u8(curPos)
		curPos += 1
		var arg2 = data.decode_u8(curPos)
		curPos += 1
		var arg3 = data.decode_u8(curPos)
		curPos += 1
		var arg4 = data.decode_u8(curPos)
		curPos += 1
		var arg5 = data.decode_u8(curPos)
		curPos += 1

		
		var frontSidedef = data.decode_s16(curPos)
		curPos += 2
		var backSidedef = data.decode_s16(curPos)
		curPos += 2
		
		if frontSidedef < -1:
			breakpoint

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
		#
		var triggerFlag = flags & 0b1110000000000
		var trigger
		#
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
	
		if frontSidedef != -1: curMapDict["sideToLine"][frontSidedef] = i
		if backSidedef != -1: curMapDict["sideToLine"][backSidedef] = i
		#
		var typeStr = str(type)
		
		if !typeDict.has(typeStr):
			type = 0
		elif typeDict[typeStr]["str"].is_empty():
			type = 0
		
		var dict = {"startVert":startVert,"endVert":endVert,"flags":flags,"type":type,"frontSideDef":frontSidedef,"backSideDef":backSidedef,"index":i,"triggerType":trigger}
		
#
		if !typeDict.has(typeStr):
			lineDefs.append(dict)
			continue


		if typeDict[typeStr]["str"].is_empty():
			lineDefs.append(dict)
			continue
		
		dict["trigger"] = trigger
		
		if typeDict[typeStr].has("arg1"):
			var argName = typeDict[typeStr]["arg1"]
			dict[argName] = arg1
			
		if typeDict[typeStr].has("arg2"):
			var argName = typeDict[typeStr]["arg2"]
			dict[argName] = arg2
		
		if typeDict[typeStr].has("arg3"):
			var argName = typeDict[typeStr]["arg3"]
			dict[argName] = arg3
		#
		if typeDict[typeStr].has("arg4"):
			var argName = typeDict[typeStr]["arg4"]
			dict[argName] = arg4
		#
		if typeDict[typeStr].has("arg5"):
			var argName = typeDict[typeStr]["arg5"]
			dict[argName] = arg5
			#
		lineDefs.append(dict)
#

	return lineDefs

func parseSidedef(lump) -> Array[Dictionary]:
	var scaleFactor = get_parent().scaleFactor
	var offset = lump["offset"]
	var size = lump["size"]
	var file : FileAccess=  parent.fileLookup[lump["file"]]
	file.seek(offset)
	var sidedef : Array[Dictionary]= []

	for i in size/30:
		var xOffset : float= get_16s(file) * scaleFactor.x
		var yOffset : float= get_16s(file) * scaleFactor.y
		var upperName : StringName= file.get_buffer(8).get_string_from_ascii().to_upper()
		var lowerName : StringName= file.get_buffer(8).get_string_from_ascii().to_upper()#doortrak is lowercase
		var middleName : StringName= file.get_buffer(8).get_string_from_ascii().to_upper()
		var sector : int = file.get_16()
		
		
		sidedef.append({"xOffset":xOffset,"yOffset":yOffset,"upperName":upperName,"lowerName":lowerName,"middleName":middleName,"sector":sector,"index":i})

	return sidedef
	

func parseSidedefZip(lump):
	var zip : ZIPReader = lump["zip"][0]
	var data : PackedByteArray = zip.read_file(lump["zip"][1])
	
	var scaleFactor = get_parent().scaleFactor
	var offset = lump["offset"]
	var size = lump["size"]
	
	var curPos = offset
	
	var sidedef : Array[Dictionary] = []

	for i in size/30:
		
		var xOffset = data.decode_s16(curPos) * scaleFactor.x
		curPos+=2
		var yOffset = data.decode_s16(curPos) * scaleFactor.y
		curPos+=2
		#bytes.slice(tOffset,tOffset+8).get_string_from_ascii()
		
		var upperName = data.slice(curPos,curPos+8).get_string_from_ascii()
		curPos+=8
		var lowerName = data.slice(curPos,curPos+8).get_string_from_ascii()
		curPos+=8
		var middleName = data.slice(curPos,curPos+8).get_string_from_ascii()
		curPos+=8
		#var upperName = file.get_buffer(8).get_string_from_ascii().to_upper()
		#var lowerName = file.get_buffer(8).get_string_from_ascii().to_upper()#doortrak is lowercase
		#var middleName = file.get_buffer(8).get_string_from_ascii().to_upper()
		var sector = data.decode_u16(curPos)
		curPos+=2
		#var xOffset = get_16s(file) * scaleFactor.x
		#var yOffset = get_16s(file) * scaleFactor.y
		#var upperName = file.get_buffer(8).get_string_from_ascii().to_upper()
		#var lowerName = file.get_buffer(8).get_string_from_ascii().to_upper()#doortrak is lowercase
		#var middleName = file.get_buffer(8).get_string_from_ascii().to_upper()
		#var sector = file.get_16()
		
		
		sidedef.append({"xOffset":xOffset,"yOffset":yOffset,"upperName":upperName,"lowerName":lowerName,"middleName":middleName,"sector":sector,"index":i})

	return sidedef

func parseSidedefUDMF(data,mapDict : Dictionary):
	data = data.replace(" ","")
	data = data.split("{")
	data = data[1].split(";",false)
	var scaleFactor : Vector3 = get_parent().scaleFactor
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
		elif valName == "TEXTURETOP": upperName = value
		elif valName == "TEXTUREMIDDLE": middleName = value
		elif valName == "TEXTUREBOTTOM": lowerName = value
		elif valName == "OFFSETY_MID": yOffset = int(value) * scaleFactor.y
		elif valName == "OFFSETX_MID": xOffset = int(value) * scaleFactor.x

		
	
	
	
	var index = mapDict["sideDefsParsed"].size()
	var dict : Dictionary = {"xOffset":xOffset,"yOffset":yOffset,"upperName":upperName,"lowerName":lowerName,"middleName":middleName,"sector":sector,"index":index}
	
	mapDict["sideDefsParsed"].append(dict)
	

func parseVertices(lump) -> PackedVector2Array:
	var scaleFactor = get_parent().scaleFactor
	var offset = lump["offset"]
	var size = lump["size"]
	var file = parent.fileLookup[lump["file"]]
	var vertices : PackedVector2Array = []
	file.seek(offset)

	for i in size/4:
		var posX = get_16s(file) * scaleFactor.x
		var posY = -get_16s(file) * scaleFactor.z
		
		
		minDim.x = min(minDim.x,posX)
		minDim.y = min(minDim.y,posY)
		maxDim.x = max(maxDim.x,posX)
		maxDim.y = max(maxDim.y,posY)
		
		vertices.append(Vector2(posX,posY))



	return vertices
	

func parseVerticesZip(lump):
	var scaleFactor = get_parent().scaleFactor
	var offset = lump["offset"]
	var size = lump["size"]
	var data : PackedByteArray = lump["zip"][0].read_file(lump["zip"][1])
	var vertices : PackedVector2Array = []
	
	var curPos : int = offset

	for i in size/4:
		
		var posX = data.decode_s16(curPos) * scaleFactor.x
		curPos += 2
		var posY = -data.decode_s16(curPos) * scaleFactor.z
		curPos += 2

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
		
	var vert = Vector2(values[0],values[1])* Vector2(-scaleFactor.x,scaleFactor.z)
	mapDict["vertexesParsed"].append(vert)
	

func parseThings(lump : Dictionary) ->  Array[Dictionary]:
	
	var scaleFactor = get_parent().scaleFactor
	var offset = lump["offset"]
	var size = lump["size"]
	var file =  parent.fileLookup[lump["file"]]
	file.seek(offset)
	var things : Array[Dictionary]= []

	for i in size/(2*5):
		var pos : Vector3= Vector3(get_16s(file),-INF,-get_16s(file))* Vector3(scaleFactor.x,scaleFactor.y,scaleFactor.z)
		var rot : int = get_16s(file)
		var type : int= file.get_16()
		var flags : int= file.get_16()
		#if !things.has(type): things[type] = []


		
		things.append({"type":type,"pos":pos,"rot":rot-90,"flags":flags})

	return things
	

func parseThingsUDMF(data,mapDict):
	var udmfFlags : Dictionary = {}
	
	
	udmfFlags["dm"] = true
	udmfFlags["single"] = true
	udmfFlags["co-op"] = true
	
	
	var type : int = 0
	var skill1 : bool= 0
	var skill2 : bool = 0
	var skill3 : bool= 0
	var skill4 : bool = 0
	var flags = 0
	var singlePlayer : bool = true
	var cooperative : bool = true
	var dm : bool = true
	var invisible : bool = true
	
	data = data.replace(" ","")
	data = data.split("{")
	data = data[1].split(";",false)
	
	var values = []
	
	for i in data:
		i = i.split("=")
		var valName = i[0]
		var value = i[1].to_lower()
		var scaleFactor = get_parent().scaleFactor
		
		if valName == "X": udmfFlags["x"] = float(value) * -scaleFactor.x
		elif valName == "Y": udmfFlags["y"] = float(value) *   scaleFactor.z
		elif valName == "ANGLE": udmfFlags["angle"] = float(value) + 90
		elif valName == "TYPE": udmfFlags["type"] = int(value)
		elif valName == "SKILL1" : udmfFlags["skill1"] = str_to_var(value)
		elif valName == "SKILL2" : udmfFlags["skill2"] = str_to_var(value)
		elif valName == "SKILL3" : udmfFlags["skill3"] = str_to_var(value)
		elif valName == "SKILL4" : udmfFlags["skill4"] = str_to_var(value)
		elif valName == "SKILL5" : udmfFlags["skill5"] = str_to_var(value)
		elif valName == "SKILL6" : udmfFlags["skill6"] = str_to_var(value)
		elif valName == "SKILL7" : udmfFlags["skill7"] = str_to_var(value)
		elif valName == "SKILL8" : udmfFlags["skill8"] = str_to_var(value)
		elif valName == "SINGLE" : udmfFlags["singlePlayer"] = str_to_var(value)
		elif valName == "DM" : udmfFlags["dm"] = str_to_var(value)
		elif valName == "COOP" : udmfFlags["co-op"] = str_to_var(value)
		elif valName == "INVISIBLE" : udmfFlags["invisible"] = str_to_var(value)
		elif valName == "CLASS1" : udmfFlags["class1"] = str_to_var(value)
		elif valName == "CLASS2" : udmfFlags["class2"] = str_to_var(value)
		elif valName == "CLASS3" : udmfFlags["class3"] = str_to_var(value)
		elif valName == "CLASS4" : udmfFlags["class4"] = str_to_var(value)
		elif valName == "CLASS5" : udmfFlags["class5"] = str_to_var(value)
	

	mapDict["thingsParsed"].append(udmfFlags)

		
func parseThingsHexen(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	
	var x = parent.fileLookup
	var file =parent.fileLookup[lump["file"]]
	file.seek(offset)
	var things : Array[Dictionary]= []

	var numThingEntry = size/((2*7)+(6))
	for i in size/((2*7)+(6)):
		var id = file.get_16()
		var pos = Vector3(get_16s(file),-INF,-get_16s(file))*get_parent().scaleFactor
		var height = get_16s(file)
		var rot = get_16s(file)
		var DoomEd = get_16s(file)
		var flags = get_16s(file)
		var hexenSpecial = file.get_8()
		
		var arg1 = file.get_8()
		var arg2 = file.get_8()
		var arg3 = file.get_8()
		var arg4 = file.get_8()
		var arg5 = file.get_8()
		
		things.append({"type":DoomEd,"pos":pos,"rot":rot,"flags":flags})

	return things



func parseThingsHexenZip(lump):
	var offset = lump["offset"]
	var size = lump["size"]
	var zip : ZIPReader = lump["zip"][0]
	var data : PackedByteArray = zip.read_file(lump["zip"][1])
	var curPos = offset
	var things : Array[Dictionary]= []
	var numThingEntry = size/((2*7)+(6))
	
	for i in size/((2*7)+(6)):
		var id = data.decode_u16(curPos)
		curPos += 2
		var pos = Vector3(data.decode_s16(curPos),-INF,-data.decode_s16(curPos+2))*get_parent().scaleFactor
		curPos += 4
		var height =  data.decode_s16(curPos)
		curPos += 2
		var rot =  data.decode_s16(curPos)
		curPos += 2
		var DoomEd =  data.decode_s16(curPos)
		curPos += 2
		var flags =  data.decode_s16(curPos)
		curPos += 2
		var hexenSpecial = data.decode_u8(curPos)
		curPos += 1
		
		var arg1 = data.decode_u8(curPos)
		curPos += 1
		var arg2 = data.decode_u8(curPos)
		curPos += 1
		var arg3 = data.decode_u8(curPos)
		curPos += 1
		var arg4 = data.decode_u8(curPos)
		curPos += 1
		var arg5 = data.decode_u8(curPos)
		curPos += 1
		
		things.append({"type":DoomEd,"pos":pos,"rot":rot,"flags":flags})
	#file.seek(offset)
	#var things = []
#
	#var numThingEntry = size/((2*7)+(6))
	#for i in size/((2*7)+(6)):
		#var id = file.get_16()
		#var pos = Vector3(get_16s(file),-INF,-get_16s(file))*get_parent().scaleFactor
		#var height = get_16s(file)
		#var rot = get_16s(file)
		#var DoomEd = get_16s(file)
		#var flags = get_16s(file)
		#var hexenSpecial = file.get_8()
		#
		#var arg1 = file.get_8()
		#var arg2 = file.get_8()
		#var arg3 = file.get_8()
		#var arg4 = file.get_8()
		#var arg5 = file.get_8()
		#
		#things.append({"type":DoomEd,"pos":pos,"rot":rot,"flags":flags})
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

func typeOveride(type : int,line : Dictionary ,mapName : String,mapTo666 : Dictionary,mapTo667:Dictionary,mapDict:Dictionary) -> int:
	
	var npcTrigger = null
	var map666entry = null
	var map667entry = null


	
	
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
		var oSector = mapDict["sectorsParsed"][line["backSector"]]
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
	#typeDict = get_parent().typeDict.data
	var sideDefs : Array[Dictionary] = mapDict["sideDefsParsed"]

	var a = Time.get_ticks_msec()
	initSectorToSides(mapDict)
	#print("sec to side:",Time.get_ticks_msec()-a)
	#a = Time.get_ticks_msec()
	initSectorNeighbours(mapDict)
	#print("sec neighbour:",Time.get_ticks_msec()-a)
	#a = Time.get_ticks_msec()
	createSectorToInteraction(mapDict)
	#print("sec to interaction:",Time.get_ticks_msec()-a)
	#a = Time.get_ticks_msec()
	initSectorToLowestLowTexture(mapDict)
	#print("init sector to low:",Time.get_ticks_msec()-a)
	
	createStairs(mapDict)
	a = Time.get_ticks_msec()
	
	
	for line : Dictionary in mapDict["lineDefsParsed"]:

		var frontSidedefIdx : int = line["frontSideDef"]
		var backSidedefIdx = line["backSideDef"]
		var frontSide : Dictionary= sideDefs[frontSidedefIdx]
		
		var backSide = null
		if backSidedefIdx != -1:
			backSide = sideDefs[backSidedefIdx]
			
		procSide(line,frontSide,backSide)
		
		if backSidedefIdx!=-1:
			procSide(line,backSide,frontSide,-1)

	
	mapDict["staticRenderables"] = staticRenderables
	mapDict["dynamicRenderables"] = dynamicRenderables
	mapDict["sectorToRenderables"] = sectorToRenderables

func createSectorToInteraction(mapDict) ->  void:
	
	var tagToSectors : Dictionary = mapDict["tagToSectors"]
	#var typeDict : Dictionary=  $"../LevelBuilder".typeSheet.data
	var interactables : Array = mapDict["interactables"]
	var sectorToInteraction : Dictionary = mapDict["sectorToInteraction"]
	var sideDefs : Array = mapDict["sideDefsParsed"]
	var isHexen : bool = false
	
	if mapDict["isHexen"]:
		isHexen= true
	
	sectorToSides = mapDict["sectorToSides"]
	
	for line in mapDict["lineDefsParsed"]:#action sectors and interactables

		var backSidedefIdx : int = line["backSideDef"]
		var backSide = null
		var backSideSector = null
		var sector : Dictionary = mapDict["sectorsParsed"][line["frontSector"]]
		
		var type : int = line["type"]
		var mapTo666 : Dictionary = $"../LevelBuilder".mapTo666
		var mapTo667 : Dictionary = $"../LevelBuilder".mapTo667
		var mapName : String = mapDict["name"]
		
		var lineIdx : int = line["index"]
		
		
		type = typeOveride(type,line,mapName,mapTo666,mapTo667,mapDict)
		
		
		
		if type == 0: continue#i moved this up from below if errors occur undo this
		
	
		
		var t0 = str(type)
		if !typeDict.has(t0): continue
		
		var targetTag : int = 0
		
		if line.has("sectorTag"):#hexen line wont have have target tag entry
			targetTag = line["sectorTag"]
		 
		
		
		var typeInfo : Dictionary = typeDict[t0]


		if backSidedefIdx != -1:
			backSide = sideDefs[backSidedefIdx]
			backSideSector = backSide["sector"]

		var targetSectors : PackedInt32Array= []
		var teleportPointTarget : Vector2 = -Vector2.INF
		if targetTag != null:
			targetSectors  = getTargetSectors(tagToSectors,targetTag,typeInfo,line,backSideSector)
			 
		if typeInfo.has("specialType"):
			if typeof( typeInfo["specialType"]) == TYPE_STRING:
				if typeInfo["specialType"] == "lineTag":
					for i in mapDict["lineDefsParsed"]:
						if i["sectorTag"] == line["sectorTag"]:
							if i!= line:
								#if targetSectors == null:
								#	targetSectors = []
								targetSectors.append(i["frontSector"])
								var diff =  mapDict["vertexesParsed"][i["endVert"]] - mapDict["vertexesParsed"][i["startVert"]]
								var point =  mapDict["vertexesParsed"][i["startVert"]] + (diff * 0.5)
								teleportPointTarget = point
								
				if typeInfo["specialType"] == "fakeFloorAndCeiling":
					if targetSectors != null:
						createFakeFloorAndCeil(sector,targetSectors)
						
				if typeInfo["specialType"] == "fakeFloorAndCeilingLegacy":
					if targetSectors != null:
						createFakeFloorAndCeil(sector,targetSectors,true)
				
		if targetSectors == null:
			continue
			
			
		
		if typeInfo["type"] == WADG.LTYPE.STAIR:#if the type of the line is a stair
			for sec in targetSectors:#we get every target sector
				var stairSectors = getStairSectors(mapDict,mapDict["sectorToFrontSides"][sec],sec,type,sector["index"])#we get every sector in stair chain
				
				if !mapDict["lineToStairSectors"].has(lineIdx):
					mapDict["lineToStairSectors"][lineIdx] = []
				
				
				var stairSectorsForLine = stairSectors.keys()

				mapDict["lineToStairSectors"][lineIdx].append(stairSectorsForLine)
				mapDict["stairLookup"][sec] = stairSectors
				
				
		
		if targetSectors.size() == 0:
			continue
		
		if typeInfo["type"] == WADG.LTYPE.STAIR:
			continue
			
		if typeInfo["type"] == WADG.LTYPE.TELEPORT:
			var npcTrigger = line["npcTrigger"]
			var target = targetSectors[0]
			if !sectorToInteraction.has(target):
				sectorToInteraction[target] = []#create an interaction entry for sector
			
			sectorToInteraction[target].append({"type":type,"line":lineIdx,"npcTrigger":npcTrigger,"teleportTargets":targetSectors,"teleportPointTarget": teleportPointTarget})#set the interaction type for sector
			continue
		for s : int in targetSectors:#for every target sector
			var npcTrigger = line["npcTrigger"]
			
			if !sectorToInteraction.has(s):
				sectorToInteraction[s] = []#create an interaction entry for sector
			var dict = {"type":type,"line":lineIdx,"npcTrigger":npcTrigger}
			
			if line.has("triggerType"):
				dict["triggerType"] = line["triggerType"]
			
			sectorToInteraction[s].append(dict)#set the interaction type for sector
	
	
	for sector : Dictionary in mapDict["sectorsParsed"]:
		if sector["type"] == 0 : continue
		

		if !parent.sectorSpecials.has(sector["type"]):
			return
		
		
		var entry : Dictionary = parent.sectorSpecials[sector["type"]]
		var secIndex : int = sector["index"]
		
		if entry["light type"] != 0 and entry["light type"] <4:
			if !lightSectors.has(secIndex):
				lightSectors.append(secIndex)
		
		if !entry.has("action type"):
			continue
		
		var dict : Dictionary = {"type":entry["action type"]}
		
		if entry["triggerType"] == "time":
			dict["timerTrigger"] = entry["type arg"]
		
		if !sectorToInteraction.has(secIndex):
				sectorToInteraction[secIndex] = []
		
		sectorToInteraction[sector["index"]].append(dict)
		
		





func createStairs(mapDict):
	if !mapDict.has("lineToStairSectors"):
		return
	
	#var typeDict =  $"../LevelBuilder".typeSheet.data
	
	for lineIdx in mapDict["lineToStairSectors"].keys():
		
		var stairGroups =  mapDict["lineToStairSectors"][lineIdx]
		var backSideSector = null
		var targetTag = 0
		var backSide = null
		var sideDefs = mapDict["sideDefsParsed"]
		
		var isHexen = false
		var line = mapDict["lineDefsParsed"][lineIdx]
		var lineType = line["type"]
		
		var stairSectors = mapDict["lineToStairSectors"][lineIdx]
		
		var stairs = removeSubsets(stairSectors)
		
		var sl = mapDict["stairLookup"]
		
		
		for s in stairs:
			var initialSector = s[0]
			mapDict["stairLookup"][initialSector] = mapDict["stairLookup"][initialSector]
			
			var sectorGroup = mapDict["stairLookup"][initialSector]
			
			
			for subSectorIdx in sectorGroup.keys():
				var sectorBackSides= mapDict["sectorToBackSides"][subSectorIdx]
				
				for sideIdx in sectorBackSides:
					var subSectorInfo = sectorGroup[subSectorIdx]
					var stairLine = mapDict["lineDefsParsed"][mapDict["sideToLine"][sideIdx]]
					mapDict["sideToLine"]
					stairLine["stairInc"] = typeDict[str(lineType)]["inc"]
					stairLine["stairIdx"] = subSectorInfo["stairNum"]
					
				
		
			if !mapDict["sectorToInteraction"].has([initialSector]):
				mapDict["sectorToInteraction"][initialSector] = []#create an interaction entry for sector
		
			mapDict["sectorToInteraction"][initialSector].append({"type":lineType,"line":lineIdx})#set the interaction type for sector
			

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


func getTargetSectors(tagToSectors : Dictionary,targetTag : int,typeInfo : Dictionary,line : Dictionary,backSideSector) -> PackedInt32Array:
	
	var targetSectors : PackedInt32Array= []
	
	if !tagToSectors.has(targetTag):#if sectorTag of line invalid skip
		return []
	
	if typeInfo["type"] == WADG.LTYPE.SCROLL or typeInfo["type"] == WADG.LTYPE.EXIT:#scroll is a special case that dosen't target oside(this is just a quick fix as all walls in the sector will be targeted which is incorrect)
		
		if typeInfo["direction"] == WADG.DIR.UP or typeInfo["direction"] == WADG.DIR.DOWN:#boom ceil/floor scroller:
			return tagToSectors[targetTag]
			
		targetSectors = [line["frontSector"]]
		return targetSectors
	
	if targetTag != 0:
		targetSectors = tagToSectors[targetTag]#we use tag to lookup target sector index
		
#		if typeInfo["type"] == WADG.LTYPE.TELEPORT and backSideSector != null:#this was put here due to E2M1 sector 54
#			targetSectors.append(backSideSector)
	
	if typeInfo.has("triggerType"):
		if typeInfo["triggerType"] == WADG.TTYPE.DOOR or typeInfo["triggerType"] == WADG.TTYPE.DOOR1:#door types cannot use sector tags to target
			targetTag = 0
		
	if targetTag == 0 and backSideSector != null:#0 tagged so the back sector is targeted
		targetSectors = [backSideSector]
	
	return targetSectors


func initSectorToSides(mapDict)-> void:
	var sideDefs = mapDict["sideDefsParsed"]
	var tagToSectors = mapDict["tagToSectors"]

	var lineIdx : int= 0
	for line : Dictionary in mapDict["lineDefsParsed"]:
		var frontSidedefIdx : int= line["frontSideDef"]
		var backSidedefIdx : int= line["backSideDef"]
		var frontSide = sideDefs[frontSidedefIdx]
		var frontSector : int= frontSide["sector"]
		var backSide = null
		var backSideSector = null

 
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


func initSectorToLowestLowTexture(mapDict : Dictionary):
	for sectorIdx in mapDict["sectorsParsed"].size():
		var sector= mapDict["sectorsParsed"][sectorIdx]
		
		for i in mapDict["sectorToFrontSides"][sectorIdx]:
			var side = mapDict["sideDefsParsed"][i]
			if !sector.has("lowerTextures"):
				sector["lowerTextures"] = PackedStringArray()
				
			if side["lowerName"] != "-":
				if !sector["lowerTextures"].has(side["lowerName"]):
					sector["lowerTextures"].append(side["lowerName"])
					
					
	

func initSectorNeighbours(mapDict : Dictionary):
	var sectors : Array = mapDict["sectorsParsed"]
	var sectorToSides : Dictionary = mapDict["sectorToSides"]
	var sectorToFrontSides : Dictionary= mapDict["sectorToFrontSides"]
	var sectorToBackSides : Dictionary= mapDict["sectorToBackSides"]
	var sides : Array = mapDict["sideDefsParsed"]
	var sectorIdx : int = 0



	for sector : Dictionary in sectors:#for each sector
		var neighbourSectors : PackedInt32Array = []
		var secSides = sectorToSides[sectorIdx]


		for lineIdx : int in secSides:#go through each line in sector
			var line : Dictionary= sides[lineIdx]
			var frontSectorIdx : int = line["frontSector"]
			var backSectorIdx = line["backSector"]

			if !neighbourSectors.has(frontSectorIdx) and frontSectorIdx != sectorIdx:
				neighbourSectors.append(frontSectorIdx)

			
			if backSectorIdx != null:
				if !neighbourSectors.has(backSectorIdx) and backSectorIdx != null and backSectorIdx != sectorIdx:
					neighbourSectors.append(backSectorIdx)

		sector["nieghbourSectors"] = neighbourSectors
		sectorIdx += 1
		
	sectorIdx= 0
	
	for sector : Dictionary in sectors:
		var idx : int= sector["index"]
		var lowestNeighFloorInc : float = sector["floorHeight"]
		var lowestNeighCeilInc : float = sector["ceilingHeight"]
		var highestNeighFloorInc : float = sector["floorHeight"]
		var highestNeighCeilInc : float = sector["ceilingHeight"]
		
		var lowestNeighFloorExc : float= INF#sector["floorHeight"]#inc = including self , exc = excluding self
		var lowestNeighCeilExc : float= INF#sector["ceilingHeight"]
		var highestNeighFloorExc : float= -INF#sector["floorHeight"]
		var highestNeighCeilExc : float=  -INF#sector["ceilingHeight"]
		
		var closetNeighCeil : float= INF
		var closetNeighFloor : float= INF
		
		var nextHighestFloor : float= INF
		var nextLowestFloor : float= -INF
		
		
		var nextHighestCeil : float= INF
		var nextLowestCeil : float= -INF
		
		var brightestNeighValue : float= -INF
		var darkestNeighValue : float= INF

		for neighSectorIdx : int in sector["nieghbourSectors"]:
			var neighSector : Dictionary = sectors[neighSectorIdx]
			
			var nfloorHeight : float= neighSector["floorHeight"]
			var nCeilHeight : float = neighSector["ceilingHeight"]
			
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


func procSide(line : Dictionary ,side: Dictionary,oSide,dir : int = 1) -> void:
	var type : int = line["type"]
	
	var upperTexture : StringName = side["upperName"]
	var middleTexture : StringName = side["middleName"]
	var lowerTexture  : StringName = side["lowerName"]
	var udmfData = null
	
	if line.has("udmfData"):
		udmfData = line["udmfData"]
	if upperTexture  != "-": addRenderable(line,side,oSide,dir,upperTexture,"upper",curMapDict,udmfData)
	if middleTexture != "-": addRenderable(line,side,oSide,dir,middleTexture,"middle",curMapDict,udmfData)
	if lowerTexture  != "-": addRenderable(line,side,oSide,dir,lowerTexture,"lower",curMapDict,udmfData)


	var oSideNull : bool = false
	var sector : int = side["sector"]
	
	
	if oSide != null:#if side has an oSide but that oSide has no texture
		if oSide["upperName"] == "-" and oSide["middleName"] == "-" and oSide["lowerName"] == "-" :
			oSideNull = true
	else:
		oSideNull = true

	var hasCollision : bool = line["flags"] & LINDEF_FLAG.BLOCK_CHARACTERS == 1
	
	if middleTexture == "-" and upperTexture == "-" and lowerTexture == "-" and oSide != null and hasCollision and type == 0:
		if parent.invisibleWalls == parent.INVISIBLE_WALLS.enabled:
			addRenderable(line,side,oSide,dir,middleTexture,"invisibleWall",curMapDict,udmfData)
	
	elif middleTexture == "-" and upperTexture == "-" and lowerTexture == "-" and oSideNull and type != 0:
		addRenderable(line,side,oSide,dir,middleTexture,"trigger",curMapDict,udmfData)#trigger
	
	

func addRenderable(line : Dictionary,side : Dictionary,oSide,dir:int,textureName :String,type : String,mapDict : Dictionary,udmfData) -> void:
	var dict : Dictionary = {}
	var alpha : float = 1.0
	var sector : Dictionary =curMapDict["sectorsParsed"][side["sector"]]
	
	if line.has("alpha"):
		alpha = line["alpha"] 
	
	if textureName == "doortrak":
		breakpoint
	
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
	var scrollVector  = Vector2.ZERO

	
	if udmfData != null:
		dict["udmfData"] = udmfData
	
	var row  : Dictionary = {"type": 0}
	if typeDict.has(str(sType)):
		row = typeDict[str(sType)]
		
		if row["str"].is_empty():
			row = {"type":0}
			dict["type"] = "0" 
	
	
	
	
	if row["type"] == WADG.LTYPE.SCROLL: 
		if row.has("vector"):
			scrollVector =  row["vector"]
		
		if row.has("specialType"):
			scrollVector =  dict["textureOffset"]/Vector2(get_parent().scaleFactor.x,get_parent().scaleFactor.z)
		
	if row.has("alpha"):
		if typeof(row["alpha"]) == TYPE_FLOAT:
		#if !row["alpha"].is_empty():
			alpha = row["alpha"]
	
	dict["scroll"] = scrollVector
	dict["alpha"] = alpha
	
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


	var b1 : bool = false
	var b2 : bool = false
	var b3 : bool = false
	var b4 : bool = false
	var b5 : bool = false
	var secIdx : int = dict["sector"]
	
	b1 = !sectorToInteraction.has(secIdx)
	
	
	if b1 == false:#light types situation
		var isLightOnly = true
		for i in sectorToInteraction[secIdx]:
			var lineType = i["type"]
			
			if typeDict[str(lineType)]["type"] != WADG.LTYPE.LIGHT:
				isLightOnly = false
		
		b1 = isLightOnly
		
	if b1 == false :#teleport situation

		var allTeleports: = true
		
		for i in sectorToInteraction[secIdx]:
			var lineType = i["type"]
			if typeDict[str(lineType)]["type"] == WADG.LTYPE.TELEPORT:
				for t in i["teleportTargets"]:
					if !mapDict["dynamicFloors"].has(t):
						mapDict["dynamicFloors"].append(t)
			else:
				allTeleports = false
				
				
		b1 = allTeleports
	
	if b1:
		b2 = !sectorToInteraction.has(dict["oSector"])
		if b2:
			b3 = !line.has("stairIdx")
			if b3:
				b4 = !WADG.isASwitchTexture(textureName, $"../ImageBuilder".switchTextures)
				b5 = true
			
	
	if row.has("triggerType"):
		if row["triggerType"] == WADG.TTYPE.GUN1 or row["triggerType"] == WADG.TTYPE.GUNR:
			b5 = false

	
	
	if sector["ceilingTexture"] == "F_SKY1" and get_parent().skyWall== get_parent().SKYVIS.ENABLED:#walls to cover sky gap
		var sky : bool  = false
		
		if oSide == null: sky = true
		
		if oSide != null:
			if oSide["upperName"] == "-" and oSide["middleName"] == "-" and oSide["lowerName"] == "-":
				sky = true
		
		if sky:
			
			var dict2 : Dictionary = dict.duplicate(true) 
			dict2.type = "skyUpper"
			dict2["textureName"] = "F_SKY1"
			dict2["texture"] = "F_SKY1"
			staticRenderables.append(dict2)
			
	
	#if !sectorToInteraction.has(dict["sector"]) and !sectorToInteraction.has(dict["oSector"]) and !line.has("stairIdx") and  !$"../ImageBuilder".switchTextures.has(textureName):

	
	
	if b1 && b2 && b3 && b4 && b5:
		
		staticRenderables.append(dict)
		
		if !sectorToRenderables.has(secIdx):
			sectorToRenderables[secIdx] = []
		
	
	else:
		
		
		dynamicRenderables.append(dict)
		
		

func parsePallete(lump):
	var offset = lump[LUMP.offset]
	var size = lump[LUMP.size]
	var file = parent.fileLookup[lump[LUMP.file]]
	file.seek(offset)

	for i in range(0,size/768):
		var pallete = []
		for j in 256:
			pallete.append(Color8(file.get_8(),file.get_8(),file.get_8()))
		
		
		#pallete[255].a = 0
		palletes.append(pallete)

func parseColorMap(lump):
	var offset = lump[LUMP.offset]
	var size = lump[LUMP.size]
	var file = parent.fileLookup[lump[LUMP.file]]
	file.seek(offset)
	var pallete = palletes[0]
	
	for i in 34:
		var image = Image.create(256,1,false,Image.FORMAT_RGB8)

		for j in 256:
			var index =file.get_8()
			image.set_pixel(j,0,pallete[index])

		
		
		var texture : ImageTexture= ImageTexture.create_from_image(image)
		colorMaps.append(texture.get_image())
	
	

func parseColorMapDummy():

	if palletes.size() == 0:
		for i in 32:
			palletes.append([])
			for j in 256:
				palletes[i].append(Color8(255,0,255))

	for i in 34:
		var image = Image.new()
		image.create(256,1,false,Image.FORMAT_RGBA8)
		


		
		var texture = ImageTexture.create_from_image(image)
		

		colorMaps.append(texture.get_image())

func parseTextureLump(lump):#all textures parsed here
	var offset = lump[LUMP.offset]
	var size = lump[LUMP.size]
	var file = parent.fileLookup[lump[LUMP.file]]
	var textureOffsets = []
	file.seek(offset)
	var numTextures = file.get_32()

	
	for i in numTextures:
		textureOffsets.append(file.get_32())

	for tOffset in textureOffsets:
		file.seek(offset + tOffset)

		var texName = file.get_buffer(8).get_string_from_ascii()
		var masked = file.get_32()
		var width = file.get_16()
		var height = file.get_16()
		var obsoleteData = file.get_32()
		var patchCount = file.get_16()
		var patches = []

		for i in patchCount:
			var originX = get_16s(file)
			var originY = get_16s(file)
			var pnameIndex = file.get_16()
			var stepDir = file.get_16()
			var colorMap = file.get_16()
			patches.append({"originX":originX,"originY":originY,"pnamIndex":pnameIndex,"stepDir":stepDir,"colorMap":colorMap})


		patchTextureEntries[texName] = {"masked":masked,"file":file,"width":width,"height":height,"obsoleteData":obsoleteData,"patchCount":patchCount,"patches":patches}

func parseTextureLumpZip(zip : ZIPReader,filePath : String):#all textures parsed here
	var bytes : PackedByteArray = zip.read_file(filePath)
	var curPos = 0

	var textureOffsets : PackedInt32Array = []
	var numTextures = bytes.decode_u32(0)
	curPos += 4
	
	
	textureOffsets.resize(numTextures)
	
	for i in numTextures:
		textureOffsets[i] = bytes.decode_u32(curPos)
		curPos += 4

	for tOffset in textureOffsets:
		
		#file.seek(offset + tOffset)
		var texName : StringName = bytes.slice(tOffset,tOffset+8).get_string_from_ascii()
		curPos += 8
		
		var masked = bytes.decode_u32(curPos)
		curPos += 4
		
		var width = bytes.decode_u16(curPos)
		curPos += 2
		
		var height =bytes.decode_u16(curPos)
		curPos += 2
		
		var obsoleteData = bytes.decode_u32(curPos)
		curPos += 4
		
		
		var patchCount = bytes.decode_u16(curPos)
		curPos += 2
		#var patchCount = file.get_16()
		var patches = []
#
		for i in patchCount:
			var originX = bytes.decode_s16(curPos)
			curPos += 2
			var originY = bytes.decode_s16(curPos)
			curPos += 2
			var pnameIndex = bytes.decode_u16(curPos)
			curPos += 2
			var stepDir = bytes.decode_u16(curPos)
			curPos += 2
			
			var colorMap = bytes.decode_u16(curPos)
			curPos += 2

			patches.append({"originX":originX,"originY":originY,"pnamIndex":pnameIndex,"stepDir":stepDir,"colorMap":colorMap})
#
#
		patchTextureEntries[texName] = {"masked":masked,"zip":[zip,filePath],"width":width,"height":height,"obsoleteData":obsoleteData,"patchCount":patchCount,"patches":patches}


func parsePatchNames(lump):
	var offset = lump[LUMP.offset]
	var size = lump[LUMP.size]
	var file = parent.fileLookup[lump[LUMP.file]]
	var index = 0
	file.seek(offset)

	var numberOfPname = file.get_32()
		
	for i in numberOfPname:
		var name : StringName = file.get_buffer(8).get_string_from_ascii()
		patchNames[index] = name
		index += 1
		
	
	

func parsePatchNamesZip(zip,filePath):
	var bytes : PackedByteArray = zip.read_file(filePath)
	var curPos = 0
	var index = 0
	
	#var numberOfPname = file.get_32()
	var numberOfPname = bytes.decode_u32(curPos)
	curPos += 4
	
	for i in numberOfPname:
		var pName = bytes.slice(curPos,curPos+8).get_string_from_ascii()
		#var pName = file.get_buffer(8).get_string_from_ascii()
		curPos += 8
		patchNames[index] = pName
		index += 1
	

func parsePatch(lump) -> Dictionary:
	
	if OS.get_thread_caller_id() != 1:
		mutex.lock()
		print("thread:%s starting"%OS.get_thread_caller_id())
		
	if typeof(lump) == TYPE_STRING:
		if lump.find(".pk3") != -1 or lump.find(".zip") != -1:
			var img : Image  = $"../ResourceManager".loadPngFromZip(lump)
			img.save_png("res://dbg/test.png")
			return {"pngImage":img,"left_offset":0,"top_offset":0}
		
		var img : Image = Image.load_from_file(lump[0])
		return {"pngImage":img,"left_offset":0,"top_offset":0}
	
	var offset : int = lump[LUMP.offset]
	var size : int = lump[LUMP.size]
	var file : FileAccess = parent.fileLookup[lump[LUMP.file]]
	
	
	
	file.seek(offset)
		
	
	var width : int = file.get_16()
	var height : int= file.get_16()

	if width == 20617 and height == 18254:#it's a png
		file.seek(offset)
		var img = Image.new()
		img.load_png_from_buffer(file.get_buffer(size))
		
		file.seek(offset)
		
		var xOffset : int = 0
		var yOffset : int= 0
		
		for i in range(0,200):
			file.seek(offset+i)
			var str = file.get_buffer(4).get_string_from_ascii() 

			if str == "GRAB":
				file.seek(file.pos)
				xOffset = file.get_32_bigEndian()
				yOffset = file.get_32_bigEndian()
				break
		print("thread:%s finishing"%OS.get_thread_caller_id())
		mutex.unlock()
		return {"pngImage":img,"left_offset":xOffset,"top_offset":yOffset}

		
	var fileLength : int = file.get_length()
	var left_offset : int = get_16s(file)
	var top_offset : int = get_16s(file)
	var columnOffsets : PackedInt32Array = []
	
	if (file.get_position() + width) > fileLength:
		print("thread:%s finishing"%OS.get_thread_caller_id())
		mutex.unlock()
		return {}
	
	columnOffsets = file.get_buffer(width*4).to_int32_array()
	
	
	var corruptColumn = false
	
	for i in columnOffsets:
		if i > fileLength:
			corruptColumn = true
	
	if OS.get_thread_caller_id() != 1:
		mutex.unlock()
		print("thread:%s finishing"%OS.get_thread_caller_id())
	return {"width":width,"height":height,"left_offset":left_offset,"top_offset":top_offset,"columnOffsets":columnOffsets,"corruptColumn":corruptColumn}

func getMagic(lump,lumpName):
	var offset = lump[LUMP.offset]
	var size = lump[LUMP.size]
	var file = parent.fileLookup[lump[LUMP.file]]
	file.seek(offset)
	
	var magic = file.get_16()
	if magic == 21837:#MUS
		parseD_(lump,lumpName)

func parseDs(lump,lumpName):
	
	
	
	if $"../ResourceManager".soundCache.has(lumpName):
		return
	
	var offset = lump[LUMP.offset]
	var size = lump[LUMP.size]
	var file = parent.fileLookup[lump[LUMP.file]]
	file.seek(offset)
	var sampleArr = []
	
	var magic = file.get_16()
	var sampleRate = file.get_16()
	var numberOfSamples = file.get_16()
	var unk = file.get_16()
	
	#var audioPlayer = AudioStreamPlayer.new()
	#audioPlayer.volume_db = -21
	
	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = sampleRate
	audio.loop_end = numberOfSamples

	var data = []
	
	for i in range(0,numberOfSamples - 4):#4 bytes of padding at end of sample:
		data.append(file.get_8()-128)
	
	audio.data = data
	$"../ResourceManager".soundCache[lumpName] = audio
	
	
func parseD_(lump,lumpName):

	#toMidi()
	var offset = lump[LUMP.offset]
	var size = lump[LUMP.size]
	var file = parent.fileLookup[lump[LUMP.file]]
	
	var pre = file.get_position()
	file.seek(offset)
	var magic = file.get_buffer(4).get_string_from_ascii() 
	
	if magic.to_upper() == "MTHD":
		get_parent().midiListPre[lumpName] = [file,offset,size]
	else:
		get_parent().musListPre[lumpName] = [file,offset,size]
	
	file.seek(pre)
	
	


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
	var curFloorTexture = mapDict["sectorsParsed"][curSecIdx]["floorTexture"]
	var allNull
	
	
	for sideIdx in frontSides:#for every node facing inwards towards sector
		
		var side = mapDict["sideDefsParsed"][sideIdx]#get entry for side
		
		var sec = sectorToSides[side["sector"]]
		var x = mapDict["sideToLine"][sideIdx]
		var line = mapDict["lineDefsParsed"][x]
		
		if line["frontSideDef"] != sideIdx:
			continue
			
		
		if side["backSector"] != null:#if side has back sector
			var oSector = side["backSector"]
			var oFloorTexture = mapDict["sectorsParsed"][oSector]["floorTexture"]
			if oFloorTexture == curFloorTexture:#if opposing floor is same texture as current floor 
				if !stairDict.has(oSector):#if a previous sector of the stairs isn't the oSide of the side
					if oSector != fSector:
						stairDict[curSecIdx] = {"sideIdx":sideIdx,"stairNum":stairDict.keys().size(),"stairType":type}
						stairDict[oSector] = null
						return true
		
				
	
	stairDict[curSecIdx] = {"sideIdx":null,"stairNum":stairDict.keys().size()}
	return false

func parseDemo(lump,lumpName):
	
	var offset = lump[LUMP.offset]
	var size = lump[LUMP.size]
	var file = lump[LUMP.file]
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
	



func getHexenArgValue(argStr : String,value):
	
	
	if value == null:
		return
	if argStr == &"sectorTag": 
		return int(value)
	if argStr ==  &"movementSpeed": return float(value)	
	if argStr == &"lightTag": return int(value)
	
	

func parseVersion(lump):
	
	var offset = lump[LUMP.offset]
	var size = lump[LUMP.size]
	var file = parent.fileLookup[LUMP.file]
	
	file.seek(offset)
	versionLumpName = file.get_buffer(size).get_string_from_ascii()
	
	if !versionLumpName.is_empty():
		if versionLumpName.find("Doom Legacy WAD V1.2") != -1:
			isOldLegacy = true
	

func parse256colorMap(lump):
	
	var offset = lump[LUMP.offset]
	var size = lump[LUMP.size]
	var file = parent.fileLookup[lump[LUMP.file]]
	file.seek(offset)
	
	#$"../ImageBuilder".create256colorMap(file.get_buffer(size),palletes[0])
	
func get_16s(file : FileAccess) -> int:
	var ret = file.get_16()
	if ret >= 32768: 
		ret -= 65536 
	
	return ret


func createFakeFloorAndCeil(sectorDict : Dictionary,targetSectors,isLegacy = false,forceTexture= ""):
	

	for i in targetSectors:
		
		if !curMapDict["fakeFloors"].has(i):
			curMapDict["fakeFloors"][i] = []
		if !isLegacy:
			curMapDict["fakeFloors"][i].append([sectorDict["floorHeight"],sectorDict["floorTexture"]])
		else:
			curMapDict["fakeFloors"][i].append([sectorDict["floorHeight"],"WATER0",0.7])
		
		if !isLegacy:
			if !curMapDict["fakeCeilings"].has(i):
				curMapDict["fakeCeilings"][i] = []
			curMapDict["fakeCeilings"][i].append([sectorDict["ceilingHeight"],sectorDict["ceilingTexture"]])
