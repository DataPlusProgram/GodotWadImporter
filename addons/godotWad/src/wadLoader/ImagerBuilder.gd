@tool
extends Node


var flatTextureEntries : Dictionary = {}
var pallete : PackedColorArray= []



func _ready():
	set_meta("hidden",true)
	
	for i in switchTextures.keys():
		for j in switchTextures[i]:
			var idx =  switchTextures[i].find(j)
			if idx == 0: animatedKey[j] = [switchTextures[i][0],switchTextures[i][1]] 
			else: animatedKey[j] = [switchTextures[i][1],switchTextures[i][0]] 
			
			

enum LUMP{
	name,
	file,
	offset,
	size,
}


var animatedTextures = {
	"NUKAGE" : ["NUKAGE1","NUKAGE2","NUKAGE3"],
	"FWATER" : ["FWATER1","FWATER2","FWATER3","FWATER4"],
	"SWATER" : ["SWATER1","SWATER2","SWATER3","SWATER4"],
	"LAVA"   : ["LAVA1","LAVA2","LAVA3","LAVA4"],
	"BLOOD"  : ["BLOOD1","BLOOD2","BLOOD3"],
	"RROCK08" : ["RROCK05","RROCK06","RROCK07","RROCK08"],
	"SLIME04" : ["SLIME01","SLIME02","SLIME03","SLIME04"],
	"SLIME08" : ["SLIME05","SLIME06","SLIME07","SLIME08"],
	"SLIME12" : ["SLIME09","SLIME10","SLIME11","SLIME12"],
	"SFALL"  : ["SFALL1","SFALL2","SFALL3","SFALL4"],
	"SLADRIP" : ["SLADRIP1","SLADRIP2","SLADRIP3"],
	"BFALL": ["BFALL1","BFALL2","BFALL3","BFALL4"],
	"DBRAIN":["DBRAIN1","DBRAIN2","DBRAIN3","DBRAIN4"],
	"BLUD" : ["BLUDA0","BLUDB0","BLUDC0"],
	"FIREWALL":["FIREWALLA","FIREWALLB"]
} 

var switchTextures = {
	"SW1BRCOM" : ["SW1BRCOM","SW2BRCOM"],
	"SW1BRN1"  : ["SW1BRN1","SW2BRN1"],
	"SW1BRN2"  : ["SW1BRN2","SW2BRN2"],
	"SW1BRNGN" : ["SW1BRNGN","SW2BRNGN"],
	"SW1COMP"  : ["SW1COMP","SW2COMP"],
	"SW1STON1"  : ["SW1STON1","SW2STON1"],
	"SW1STON2" : ["SW1STON2","SW2STON2"],
	"SW1SLAD"  : ["SW1SLAD","SW2SLAD"],
	"SW1PIPE" : ["SW1PIPE","SW2PIPE"],
	"SW1EXIT" : ["SW1EXIT","SW2EXIT"],
	"SW1STONE" : ["SW1STONE","SW2STONE"],
	"SW1DIRT":["SW1DIRT","SW2DIRT"],
	"SW1STRTN":["SW1STRTN","SW2STRTN"],
	"SW1MET2":["SW1MET2","SW2MET2"],
	"SW1COMM":["SW1COMM","SW2COMM"],
	"SW1TEK":["SW1TEK","SW2TEK"],
	"SW1METAL":["SW1METAL","SW2METAL"],
	"SW1BROWN":["SW1BROWN","SW2BROWN"],
	"SW1GSTON":["SW1GSTON","SW2GSTON"],
	"SW1CMT":["SW1CMT","SW2CMT"],
	"SW1HOT":["SW1HOT","SW2HOT"],
	"SW1SKIN":["SW1SKIN","SW2SKIN"],
	"SW1GARG":["SW1GARG","SW2GARG"],
	"SW1GRAY":["SW1GRAY","SW2GRAY"],
	"SW1BLUE":["SW1BLUE","SW2BLUE"],
	"SW1PANEL":["SW1PANEL","SW2PANEL"],
	"SW1SATYR":["SW1SATYR","SW2SATYR"],
	"SW1MOD1":["SW1MOD1","SW2MOD1"],
	"SW1ROCK":["SW1ROCK","SW2ROCK"]
}

var animatedKey := {}

var skyboxTextures ={
	"SKY1" : ["E1M1","E1M2","E1M3","E1M4","E1M5","E1M6","E1M7","E1M8","E1M9","MAP01","MAP02","MAP03","MAP04","MAP05","MAP06","MAP07","MAP08","MAP09","MAP10"],
	"SKY2" : ["E2M1","E2M2","E2M3","E2M4","E2M5","E2M6","E2M7","E2M8","E2M9","MAP11","MAP12","MAP13","MAP14","MAP15","MAP16","MAP17","MAP18","MAP19","MAP20"],
	"SKY3" : ["E3M1","E3M2","E3M3","E3M4","E3M5","E3M6","E3M7","E3M8","E3M9","MAP21","MAP22","MAP23","MAP24","MAP25","MAP26","MAP27","MAP28","MAP29","MAP30"],
	"SKY4" : ["E4M1","E4M2","E4M3","E4M4","E4M5","E4M6","E4M7","E4M8","E4M9"],
}


var patchCache : Dictionary = {}
var patchOffsetCache : Dictionary= {}
var missingTextures : Dictionary= {}

@onready var mutex : Mutex = Mutex.new()
@onready var resourceManager = $"../ResourceManager"
@onready var lumpParser = $"../LumpParser"
@onready var parent : WAD_Map = get_parent()

func createPatchedTexture(data,rIndexed = false) -> ImageTexture:
	
	if typeof(data) == TYPE_STRING:
		if data.find(".pk3") != -1 or data.find(".zip") != -1:
			var img : Image = resourceManager.loadPngFromZip(data)
			return ImageTexture.create_from_image(img)
	
	var textureEntries : Dictionary=  parent.patchTextureEntries
	
	var patchNames : Dictionary = parent.patchNames
	var image : Image = Image.create(data["width"],data["height"],false,Image.FORMAT_RGBA8)
	
	var i : int = 0
	for patch : Dictionary in data["patches"]:
		if !patchNames.has(patch["pnamIndex"]):
			print("patch not found")
			return null
		var patchName : StringName= patchNames[patch["pnamIndex"]].to_upper()
		var patchImage : Image = createDoomGraphic(patchName,rIndexed)
		
		
		if patchImage == null:
			return null
		
		var sourceRect : Rect2 = Rect2(Vector2.ZERO,patchImage.get_size())
		image.blend_rect(patchImage,sourceRect,Vector2(patch["originX"],patch["originY"]))
		i+=1
		
	var texture : ImageTexture= ImageTexture.create_from_image(image)
	
	#var t = texture.has_alpha()
	
	return texture

func createCubemap(left : Image,right : Image,top : Image,bottom : Image,front: Image,back : Image):
	var cubemap = Cubemap.new()
	
	if parent.mipMaps == parent.MIP.ON:
		for i in [left,right,top,bottom,front,back]:
			i.generate_mipmaps()
	
	var count = 0

	
	cubemap.create_from_images([left,right,top,bottom,front,back])

	return cubemap
	

func createRawGraphic(patch,size):
	var image = Image.new()
	image = Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)

	
	var file : FileAccess =parent.fileLookup[patch[LUMP.file]]
	var offset : int =patch[LUMP.offset]
	var colorMap : Image  =parent.colorMaps[0]
	
	file.seek(offset)
	
	for x in range(0,size.y):
		for y in range(0,size.x):
			var pix = colorMap.get_pixel(file.get_8(),0)
			image.set_pixel(y,x,pix)
			
			
	return image

func createDoomGraphic(patchName : StringName,rIndexed : bool =false,raw = false) -> Image:
	
	
	if !patchCache.has(patchName):
		
	
		
		var image : Image = Image.new()
		
		
		if flatTextureEntries.is_empty():
			flatTextureEntries = parent.flatTextureEntries
		
		
		if !flatTextureEntries.has(patchName):
			return image
		
		
		
		
		if raw:
			return createRawGraphic(flatTextureEntries[patchName],Vector2(320,200))
		

		mutex.lock()
		var patch : Dictionary= lumpParser.parsePatch(flatTextureEntries[patchName])
		mutex.unlock()
		
		if patch.has("pngImage"):#in case of it being a png
			patchCache[patchName] = patch["pngImage"]
			patchOffsetCache[patchName] = Vector2(patch["left_offset"],patch["top_offset"])
			return patch["pngImage"]
		
		if patch.is_empty():
			return null
		
		
		
		var offset : int = flatTextureEntries[patchName][LUMP.offset]
		var columnOffsets : PackedInt32Array = patch["columnOffsets"]
		var width : int = patch["width"]
		var height : int = patch["height"]
		var file : FileAccess = parent.fileLookup[flatTextureEntries[patchName][LUMP.file]]
		image = Image.create(width,height,false,Image.FORMAT_RGBA8)
		var colorMap : Image  = parent.colorMaps[0]
		
		mutex.lock()
		for x : int in range(0,width):
			
			file.seek(offset + columnOffsets[x])
			if file.eof_reached():
				mutex.unlock()
				return null
			var rowStart : int = 0
				
			while rowStart != 255:
				rowStart = file.get_8()
				if rowStart == 255:
					break
					
				if file.eof_reached():
					return image
				var pixCount : int = file.get_8()

				file.get_8()
				
				
				var pixData := file.get_buffer(pixCount)
				
				for i : int in pixData.size():
					var color : Color = colorMap.get_pixel(pixData[i],0)
					image.set_pixel(x,i+rowStart,color)
					
				#for i : int in pixCount:
					#var pixel : int = file.get_8()
					#var color : Color = colorMap.get_pixel(pixel,0)
#
					#if rIndexed:
						#color = Color(0,0,0,1)
						#color.r = pixel/255.0
					#
					#image.set_pixel(x,i+rowStart,color)
				file.get_8()#dummy 
		
		if parent.mipMaps ==parent.MIP.ON:
			image.generate_mipmaps()
		
		
		
		patchCache[patchName] = image
		patchOffsetCache[patchName] = Vector2(patch["left_offset"],patch["top_offset"])
	
	mutex.unlock()
	return patchCache[patchName]

func getDoomGraphicOffests(patchName : String):
	if patchOffsetCache.has(patchName):
		return patchOffsetCache[patchName]
	else:
		return(Vector2(0,0))


func parseFlat(info:Array,rIndexed : bool= true, dim : Vector2= Vector2(64,64)) -> ImageTexture:
	
	if pallete.is_empty():
		pallete =parent.palletes[0]
	
	var file : FileAccess = parent.fileLookup[info[LUMP.file]]
	
	file.seek(info[LUMP.offset])
	
	
	var buffer :  PackedByteArray = file.get_buffer(info[LUMP.size])
	
	var magic : int = buffer.decode_s32(0)
	if magic == 1196314761:#image is PNG

		var image : Image = Image.new()
		var texture : ImageTexture= ImageTexture.new()
		image.load_png_from_buffer(buffer)
		texture.create_from_image(image)
		return texture
		
	elif magic == -520103681:
		
		var image : Image= Image.new()
		var texture : ImageTexture= ImageTexture.new()
		
		
		image.load_jpg_from_buffer(file.get_buffer(info[LUMP.size]))
		image.load_jpg_from_buffer(file.get_buffer(info[LUMP.size]))
		texture.create_from_image(image)
		return texture
		
	
	var dat : PackedByteArray = buffer
	var image : Image= Image.create(dim.x,dim.y,false,Image.FORMAT_RGB8)#it should be okay to ommit transparency for flats
	#var hasAlpha : bool = false
		
	
	
	var index : int = 0
	for x : int in dim.x:
		for  y : int in dim.y:
			if dat.size() <= index:
				print("flat create error")
				break
			var color : Color = pallete[dat[index]]
			
			if rIndexed:
				color = Color(0,0,0,1)
				color.r = dat[index]/255.0
			
			image.set_pixel(y,x,color)
			index+=1

	var texture : ImageTexture= ImageTexture.create_from_image(image)
	#var t = texture.has_alpha() 

	return texture

func getSkyboxTextureForMap(mapName):
	for tex in skyboxTextures.keys():
		if skyboxTextures[tex].has(mapName):
			return tex
	
	return "SKY1"
	
	


func createTopImage(srcImage:Image):
	
	var imageTop = Image.create(128,128,true,srcImage.get_format())
	var bottomRightPixel = srcImage.get_pixel(0,0)

	
	bottomRightPixel = getAveragePixelColor(srcImage)
	
	imageTop.create(128,128,true,srcImage.get_format())
	
	
	for x in 128:
		for y in 128:
			imageTop.set_pixel(x,y,bottomRightPixel)
	
	
	
	return imageTop

func getAveragePixelColor(srcImage):
	var pixArr = []
	
	for x in srcImage.get_width():
		pixArr.append(srcImage.get_pixel(x,0))
		
	
	
	var avgPixel = Color.WHITE
	for i in pixArr:
		avgPixel += i
	
	avgPixel /= pixArr.size()
	return avgPixel

func createBottomImage(srcImage:Image):
	var imageTop = Image.create(128,128,true,srcImage.get_format())
	
	
	var bottomRightPixel = srcImage.get_pixel(0,127)
	bottomRightPixel.a = 255


	
	
	for x in 128:
		for y in 128:
			imageTop.set_pixel(x,y,bottomRightPixel)

	return imageTop


func create256colorMap(data,pallete):

	var idx = 0
	var image : Image = Image.create(256,256,false,Image.FORMAT_RGBA8)
	for y in 256:
		for x in 256:
			print(idx)
			var index = data[idx]
			image.set_pixel(x,y,pallete[index])
			idx += 1

		var texture = ImageTexture.create_from_image(image)
	
	
