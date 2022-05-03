tool
extends Node


func _ready():
	set_meta("hidden",true)

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
	"SW1CMT":["SW1CMT","SW2CMT"]
	
}

var skyboxTextures ={
	"SKY1" : ["E1M1","E1M2","E1M3","E1M4","E1M5","E1M6","E1M7","E1M8","E1M9","MAP01","MAP02","MAP03","MAP04","MAP05","MAP06","MAP07","MAP08","MAP09","MAP10"],
	"SKY2" : ["E2M1","E2M2","E2M3","E2M4","E2M5","E2M6","E2M7","E2M8","E2M9","MAP11","MAP12","MAP13","MAP14","MAP15","MAP16","MAP17","MAP18","MAP19","MAP20"],
	"SKY3" : ["E3M1","E3M2","E3M3","E3M4","E3M5","E3M6","E3M7","E3M8","E3M9","MAP21","MAP22","MAP23","MAP24","MAP25","MAP26","MAP27","MAP28","MAP29","MAP30"],
	"SKY4" : ["E4M1","E4M2","E4M3","E4M4","E4M5","E4M6","E4M7","E4M8","E4M9"],
}


var patchCache = {}
var flatCache = {}
var missingTextures = {}
var mapName
onready var resourceManager = $"../ResourceManager"

func createTexture(data,rIndexed = false):
	
	var textureEntries =  get_parent().textureEntries
	var pallete = get_parent().palletes[0]
	var colorMap = get_parent().colorMaps[0]
	var patchNames = get_parent().patchNames
	var image = Image.new()
	image.create(data["width"],data["height"],false,Image.FORMAT_RGBA8)
	image.lock()
	
	var i = 0
	for patch in data["patches"]:
		var patchName = patchNames[patch["pnamIndex"]].to_upper()
		var patchImage = parsePatch(patchName,rIndexed)
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
	

func parsePatch(patchName,rIndexed=true):
	if !patchCache.has(patchName):
		var image = Image.new()
		var colorMap = get_parent().colorMaps[0].get_data()
		var patchTextureEntries = get_parent().patchTextureEntries
		
		if !patchTextureEntries.has(patchName):
			return image
		
		
		var patch = $"../LumpParser".parsePatch(patchTextureEntries[patchName])
		var offset = patchTextureEntries[patchName]["offset"]
		var columnOffsets = patch["columnOffsets"]
		var width = patch["width"]
		var height = patch["height"]
		var file = patchTextureEntries[patchName]["file"]

		image.create(width,height,false,Image.FORMAT_RGBA8)
		image.lock()
		for x in range(0,width):
			
			file.seek(offset + columnOffsets[x])
			var rowStart = 0
				
			while rowStart != 255:
				rowStart = file.get_8()
				if rowStart == 255:
					break
				var pixCount = file.get_8()
				var dummy = file.get_8()
				
				for i in pixCount:
					var pixel = file.get_8()
					colorMap.lock()
					var color = colorMap.get_pixel(pixel,0)
					colorMap.unlock()
					
						
					if rIndexed:
						color = Color(0,0,0,1)
						color.r = pixel/255.0
					
					image.set_pixel(x,i+rowStart,color)
				file.get_8()#dummy 
		patchCache[patchName] = image
		image.unlock()
		
	
	return patchCache[patchName]

func parseFlat(info,rIndexed = true, dim = Vector2(64,64)):
	var pallete = get_parent().palletes[0]
	
	info["file"].seek(info["offset"])
	var dat = info["file"].get_buffer(dim.x*dim.y)
	var datConverted = [] 
	
	
	
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
	

func getSkyboxTextureForMap():
	for tex in $"../ImageBuilder".skyboxTextures.keys():
		if $"../ImageBuilder".skyboxTextures[tex].has(mapName):
			return tex
	
	return "SKY1"
	
	


func createTopImage(srcImage:Image):
	var imageTop = Image.new()
	
	srcImage.lock()
	var bottomRightPixel = srcImage.get_pixel(0,0)
	srcImage.unlock()
	
	imageTop.create(128,128,true,srcImage.get_format())
	
	
	imageTop.lock()
	for x in 128:
		for y in 128:
			imageTop.set_pixel(x,y,bottomRightPixel)
	imageTop.unlock()
	
	
	
	return imageTop

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
