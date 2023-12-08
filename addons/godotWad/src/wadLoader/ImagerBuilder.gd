tool
extends Node


func _ready():
	set_meta("hidden",true)
	
	for i in switchTextures.keys():
		for j in switchTextures[i]:
			var idx =  switchTextures[i].find(j)
			if idx == 0: animatedKey[j] = [switchTextures[i][0],switchTextures[i][1]] 
			else: animatedKey[j] = [switchTextures[i][1],switchTextures[i][0]] 
			
			
	

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
	"BLUD" : ["BLUDA0","BLUDB0","BLUDC0"]
} 

var switchTextures = {
	"SW1BRCOM" : ["SW1BRCOM","SW2BRCOM"],
	"SW1BRN1"  : ["SW1BRN1","SW2BRN1"],
	"SW1BRN2"  : ["SW1BRN2","SW2BRN2"],
	"SW1BRNGN" : ["SW1BRNGN","SW2BRNGN"],
	"SW1COMP"  : ["SW1COMP","SW2COMP"],
	"SW1STON1"  : ["SW1STON1","SW2STON1"],
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
	"SW2BROWN":["SW2BROWN","SW1BROWN"],
	"SW1GSTON":["SW1GSTON","SW2GSTON"],
	"SW1CMT":["SW1CMT","SW2CMT"],
	"SW1HOT":["SW1HOT","SW2HOT"],
	"SW1SKIN":["SW1SKIN","SW2SKIN"],
	"SW1GARG":["SW1GARG","SW2GARG"],
	"SW1GRAY":["SW1GRAY","SW2GRAY"]
	
}

var animatedKey = {}

var skyboxTextures ={
	"SKY1" : ["E1M1","E1M2","E1M3","E1M4","E1M5","E1M6","E1M7","E1M8","E1M9","MAP01","MAP02","MAP03","MAP04","MAP05","MAP06","MAP07","MAP08","MAP09","MAP10"],
	"SKY2" : ["E2M1","E2M2","E2M3","E2M4","E2M5","E2M6","E2M7","E2M8","E2M9","MAP11","MAP12","MAP13","MAP14","MAP15","MAP16","MAP17","MAP18","MAP19","MAP20"],
	"SKY3" : ["E3M1","E3M2","E3M3","E3M4","E3M5","E3M6","E3M7","E3M8","E3M9","MAP21","MAP22","MAP23","MAP24","MAP25","MAP26","MAP27","MAP28","MAP29","MAP30"],
	"SKY4" : ["E4M1","E4M2","E4M3","E4M4","E4M5","E4M6","E4M7","E4M8","E4M9"],
}


var patchCache = {}
var patchOffsetCache = {}
var missingTextures = {}

onready var resourceManager = $"../ResourceManager"

func createPatchedTexture(data,rIndexed = false):
	
	var textureEntries =  get_parent().patchTextureEntries
	var pallete = get_parent().palletes[0]
	var colorMap = get_parent().colorMaps[0]
	var patchNames = get_parent().patchNames
	var image = Image.new()
	image.create(data["width"],data["height"],false,Image.FORMAT_RGBA8)
	image.lock()
	
	var i = 0
	for patch in data["patches"]:
		if !patchNames.has(patch["pnamIndex"]):
			print("patch not found")
			return
		var patchName = patchNames[patch["pnamIndex"]].to_upper()
		var patchImage = createDoomGraphic(patchName,rIndexed)
		
		
		if patchImage == null:
			return null
		
		var sourceRect = Rect2(Vector2.ZERO,patchImage.get_size())
		image.blend_rect(patchImage,sourceRect,Vector2(patch["originX"],patch["originY"]))
		i+=1
		
	image.unlock()
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	
	if get_parent().textureFiltering == false: texture.flags -= Texture.FLAG_FILTER
	if get_parent().mipMaps == get_parent().MIP.OFF: texture.flags -= Texture.FLAG_MIPMAPS
	if get_parent().mipMaps == get_parent().MIP.EXCLUDE_FOR_TRANSPARENT and image.detect_alpha(): texture.flags -= Texture.FLAG_MIPMAPS
	
	
	return texture

func createCubemap(left,right,top,bottom,front,back):
	var cubemap = CubeMap.new()
	
	cubemap.set_side(0,left)
	cubemap.set_side(1,right)
	cubemap.set_side(2,bottom)
	cubemap.set_side(3,top)
	cubemap.set_side(4,front)
	cubemap.set_side(5,back)
	
	if get_parent().textureFilterSkyBox == false:
		cubemap.flags -= cubemap.FLAG_FILTER
	return cubemap
	

func createDoomGraphic(patchName : String,rIndexed : bool =true) -> Image:
	
	if !patchCache.has(patchName):
		var image = Image.new()
		var colorMap : Image  = get_parent().colorMaps[0].get_data()
		var flatTextureEntries : Dictionary = get_parent().flatTextureEntries
		
		if !flatTextureEntries.has(patchName):
			return image
		
		
		var patch : Dictionary = $"../LumpParser".parsePatch(flatTextureEntries[patchName])
		
		if patch.empty():
			return null
		
		var offset : int = flatTextureEntries[patchName]["offset"]
		var columnOffsets : Array = patch["columnOffsets"]
		var width : int = patch["width"]
		var height : int = patch["height"]
		var file : Node = flatTextureEntries[patchName]["file"]
		
		image.create(width,height,false,Image.FORMAT_RGBA8)
		image.lock()
		for x in range(0,width):
			
			file.seek(offset + columnOffsets[x])
			if file.eof_reached():
				return null
			var rowStart : int = 0
				
			while rowStart != 255:
				rowStart = file.get_8()
				if rowStart == 255:
					break
				var pixCount : int = file.get_8()
				var dummy : int = file.get_8()
				
				
				for i in pixCount:
					var pixel : int = file.get_8()
					colorMap.lock()
					var color : Color = colorMap.get_pixel(pixel,0)
					colorMap.unlock()
					
					
						
					if rIndexed:
						color = Color(0,0,0,1)
						color.r = pixel/255.0
					
					image.set_pixel(x,i+rowStart,color)
				file.get_8()#dummy 
		
		image.unlock()
		patchCache[patchName] = image
		patchOffsetCache[patchName] = Vector2(patch["left_offset"],patch["top_offset"])
		
	
	return patchCache[patchName]

func getDoomGraphicOffests(patchName : String):
	if patchOffsetCache.has(patchName):
		return patchOffsetCache[patchName]
	else:
		return(Vector2(0,0))


func parseFlat(info,rIndexed = true, dim = Vector2(64,64)):
	var pallete = get_parent().palletes[0]
	
	info["file"].seek(info["offset"])
	
	var magic =  info["file"].get_32()
	if magic == 1196314761:#image is PNG
		info["file"].seek(info["offset"])
		
		var image = Image.new()
		var texture = ImageTexture.new()
		var buffer = info["file"].get_buffer(info["size"])
		
		
		image.load_png_from_buffer(buffer)
		texture.create_from_image(image)
		return texture
	elif magic == -520103681:
		
		info["file"].seek(info["offset"])
		
		var image = Image.new()
		var texture = ImageTexture.new()
		var buffer = info["file"].get_buffer(info["size"])
		
		
		image.load_jpg_from_buffer(buffer)
		texture.create_from_image(image)
		return texture
		
	
	info["file"].seek(info["offset"])
	var dat = info["file"].get_buffer(dim.x*dim.y)
	var datConverted = [] 
	
	if info["name"] == "ICON":
		breakpoint
		
	else:
		"corrupt magic number"
	var image = Image.new()
	image.create(dim.x,dim.y,false,Image.FORMAT_RGBA8)
	image.lock()
	var index = 0
	for x in dim.x:
		for y in dim.y:
			var color = pallete[dat[index]]
			
			if rIndexed:
				color = Color(0,0,0,1)
				color.r = dat[index]/255.0
			
			image.set_pixel(y,x,color)
			index+=1
	image.unlock()
	
	var texture = ImageTexture.new()
	
	texture.create_from_image(image)
	
	if get_parent().textureFiltering == false: texture.flags -= Texture.FLAG_FILTER
	if get_parent().mipMaps == get_parent().MIP.OFF:texture.flags -= Texture.FLAG_MIPMAPS
	if get_parent().mipMaps == get_parent().MIP.EXCLUDE_FOR_TRANSPARENT and image.detect_alpha(): texture.flags -= Texture.FLAG_MIPMAPS

	return texture
	

func getSkyboxTextureForMap(mapName):
	for tex in $"../ImageBuilder".skyboxTextures.keys():
		if $"../ImageBuilder".skyboxTextures[tex].has(mapName):
			return tex
	
	return "SKY1"
	
	


func createTopImage(srcImage:Image):
	var imageTop = Image.new()
	
	srcImage.lock()
	var bottomRightPixel = srcImage.get_pixel(0,0)
	srcImage.unlock()
	
	bottomRightPixel = getAveragePixelColor(srcImage)
	
	imageTop.create(128,128,true,srcImage.get_format())
	
	
	imageTop.lock()
	for x in 128:
		for y in 128:
			imageTop.set_pixel(x,y,bottomRightPixel)
	imageTop.unlock()
	
	
	
	return imageTop

func getAveragePixelColor(srcImage):
	srcImage.lock()
	var pixArr = []
	
	for x in srcImage.get_width():
		pixArr.append(srcImage.get_pixel(x,0))
		
	srcImage.unlock()
	
	var avgPixel = Color.white
	for i in pixArr:
		avgPixel += i
	
	avgPixel /= pixArr.size()
	return avgPixel

func createBottomImage(srcImage:Image):
	var imageTop = Image.new()
	
	srcImage.lock()
	var bottomRightPixel = srcImage.get_pixel(0,127)
	bottomRightPixel.a = 255
	srcImage.unlock()
	
	imageTop.create(128,128,true,srcImage.get_format())
	
	
	imageTop.lock()
	for x in 128:
		for y in 128:
			imageTop.set_pixel(x,y,bottomRightPixel)
	imageTop.unlock()
	
	return imageTop
