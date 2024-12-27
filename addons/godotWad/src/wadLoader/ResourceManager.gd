@tool
extends Node

signal fileWaitDone
signal subFileWaitDone
var materialCache : Dictionary = {}
var soundCache : Dictionary = {}
var textureCache : Dictionary= {}
var spriteMaterialCache : Dictionary = {}
var flatCache : Dictionary = {}
var spriteCache : Dictionary = {}
var spriteOffsetCache : Dictionary = {}
var waitingForFiles : Array = []
var filesToUpdate : Array = []
var animtedTexturesWaiting : Array = []
var font = null
var audioLumps : Dictionary = {}

var cubeMapShader = preload("res://addons/godotWad/shaders/cubemap.gdshader")
var cubeMapShaderOneSided = preload("res://addons/godotWad/shaders/cubemapOneSided.gdshader")
var useInstancedParameters = false
@onready var root = get_tree().get_root()
@onready var isEditor = Engine.is_editor_hint()
@onready var mutex : Mutex = Mutex.new()
var pngImportTemplate : String = ""
@onready var imageBuilder = $"../ImageBuilder"
@onready var levelBuilder = $"../LevelBuilder"
@onready var materialManager = $"../MaterialManager"
@onready var musConverter = $"../musConverter"
@onready var parent : WAD_Map= get_parent()
func _physics_process(delta):
	var t = 3

func _ready():
	set_meta("hidden",true)

enum LUMP{
	name,
	file,
	offset,
	size,
}

func clear():
	$"../MaterialManager".materialCache = {}
	soundCache = {}
	textureCache = {}
	flatCache = {}
	spriteCache = {}
	spriteMaterialCache = {}
	font = null
	imageBuilder.patchCache = {}
	imageBuilder.patchOffsetCache = {}
	parent.flatTextureEntries = {}
	parent.textureEntryFiles = {}
	parent.patchTextureEntries = {}
	
func fetchPatchedTexture(textureName : String,rIndex : int= false) -> Texture2D:
	
	if !parent.toDisk:
		return fetchPatchedTextureRuntime(textureName,rIndex)
	else:
		return fetchPatchedTextureDisk(textureName,rIndex)
	
	
var fontCache = {}


func fetchFontDepends(fontName):
	var x = fontCache[fontName]

func fetchBitmapFont(fontName : String):
	
	var grayscale = false
	var fontnameTrue = fontName
	if fontName.find("-grayscale") != -1:
		fontnameTrue = fontName.split("-")[0]
		grayscale = true
	
	var fontDict = parent.getFont(fontnameTrue)

	if !parent.toDisk:
		if fontCache.has(fontName):
			return fontCache[fontName]
		else:
			fontCache[fontName] =  createBitmapFont(fontDict,grayscale)
			return fontCache[fontName]
	else:
		var path = WADG.destPath+parent.gameName+"/fonts/" + fontName +".tres"
		
		
		if !ResourceLoader.exists(path):
			
			font = createBitmapFont(fontDict,grayscale)
			ResourceSaver.save(font,path)
		
		return ResourceLoader.load(path)
			
		

func createBitmapFontTextures(fontName : StringName,greyscale = false):
	var fontDict =parent.getFont(fontName)
	
	for i in fontDict:
		fetchDoomGraphic(fontDict[i][0])

func createBitmapFont(fontDict : Dictionary,greyscale = false):
	var parsedFontDict = fontDict.duplicate()
	
	var size = 16.0
	
	var img : Image = createFontImage(parsedFontDict,greyscale)
	var srcH = img.get_height()
	var srcW = img.get_width()
	var font : FontFile = FontFile.new()
	var ratioH = size/srcH * 1.1
	var ratioW = size/srcW
	
	font.set_texture_image(0,Vector2(size,0),0,img)
	font.set_cache_ascent(0, size, 0.5 * ratioH * srcH)#this will be used for newline
	font.set_cache_descent(0, size, parsedFontDict[parsedFontDict.keys()[0]].get_height()*2.5)#this will be used for newline
	
	var runningX = 0
	
	parsedFontDict[32] = null #space character

	for i in parsedFontDict:
		
		var texture = parsedFontDict[i]
		
		var charW= 0
		var charH = 0
		

		if parsedFontDict[i] != null:
			charW = texture.get_width()
			charH = texture.get_height()
		else:
			charW = parsedFontDict[parsedFontDict.keys()[0]].get_width()
			charH = parsedFontDict[parsedFontDict.keys()[0]].get_height()
		
		var offset = Vector2i(0,0)
		
		
		
		if parsedFontDict[i] != null:
			offset = fontDict[i][1]
		

		font.set_glyph_advance(0, size, i, Vector2(charW*ratioH, 0))#the true tickness/width of char
		font.set_glyph_offset(0, Vector2i(size, 0), i, Vector2i(0, -3)+offset)#will shift the final up/down
		font.set_glyph_size(0, Vector2i(size, 0), i, Vector2(charW, charH)*ratioH)#the visual size of the char
		font.set_glyph_uv_rect(0,Vector2i(size, 0),i,Rect2(runningX,0,charW,charH))#defines the uv area

		if parsedFontDict[i] == null:
			null
			#font.set_glyph_texture_idx(0,Vector2i(0,0),i,0)
		else:
			font.set_glyph_texture_idx(0,Vector2i(size,0),i,0)
		
		runningX +=  charW
	
	font.allow_system_fallback = true
	
	return font

func createFontImage(numberChars,greyscale) -> Image:
	
	var totalW : int = 0
	var totalY : int = 0
	var maxY : int = 0
	var fontImages : Array[Image] = []
	
	for i in numberChars:
		numberChars[i] = fetchDoomGraphic(numberChars[i][0])
		if greyscale:
			var t  = numberChars[i]
			numberChars[i] = ImageTexture.create_from_image(convertImageToGrayscale(numberChars[i].get_image()))
	
	for i in numberChars:
		var txt = numberChars[i]
		totalW += txt.get_width()
		if txt.get_height() > maxY:
			maxY = txt.get_height()
		
	
	
	var img : Image = Image.create(totalW,maxY,false,Image.FORMAT_RGBA8)
	var runningWdith : int = 0
	
	for i : int in numberChars:
		var txt = numberChars[i]
		img.blit_rect(txt.get_image(),Rect2(0,0,txt.get_width(),txt.get_height()),Vector2(runningWdith,0))
		runningWdith += txt.get_width()
	
	return img

func convertImageToGrayscale(image: Image) -> Image:
	if not image.is_empty():
		# Loop through each pixel
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				# Get the pixel color at (x, y)
				var color = image.get_pixel(x, y)
				
				# Convert color to HSV
				var hsv = EGLO.rgbToHSV(color.r,color.g,color.b)
				# Set saturation to 0 (grayscale)
				hsv[1] = 0
				
				# Convert back to Color from HSV
				var grayscale_color = Color.from_hsv(hsv[0]*255, hsv[1]*255, hsv[2]*255, color.a)
				# Update the pixel color
				image.set_pixel(x, y, grayscale_color)
		
	
	# Return the modified image
	return image


	

func fetchPatchedTextureRuntime(textureName : StringName,rIndex : bool= false) -> Texture2D:
	
	if textureName == &"-":
		return null
		
	if textureName == &"AASTINKY": 
		return null
	
	if textureCache.has(textureName):
		return textureCache[textureName]
	


	var texture : Texture = null
	var subStr : StringName= textureName.substr(0,textureName.length()-1)
	
	if imageBuilder.animatedTextures.has(subStr):
		var frames = imageBuilder.animatedTextures[subStr]
		texture = createAnimatedPatchedTexture(frames)
		texture.speed_scale = 3
		
		
	elif imageBuilder.animatedKey.has(textureName):
		
		var frames = imageBuilder.animatedKey[textureName]
		var index = frames.find(textureName)
		if index != 0:
			frames.invert()
		texture = createAnimatedPatchedTexture(frames)
		texture.current_frame = index
		texture.speed_scale = 0
		
	else:
		if parent.patchTextureEntries.has(textureName):
			texture = imageBuilder.createPatchedTexture(parent.patchTextureEntries[textureName],rIndex)
			
	
	
	
	if texture == null:
		return null
	
		
	textureCache[textureName] = texture
	
	return textureCache[textureName]
	

func fetchTextureFromFile(path):
	
	
	var textureName = path.get_file().split(".")[0].to_upper()
	
	if textureCache.has(textureName):
		return textureCache[textureName]
		
		
	var patchTextureEntries =  parent.patchTextureEntries
	
	if !patchTextureEntries.has(textureName):
		#var pte = parent.flatTextureEntries
		var t = loadImageFileAsTexture(path)
		textureCache[textureName] = t
		return t

func fetchPatchedTextureDisk(textureName : String,rIndex : bool= false):
	rIndex = false
	
	
	if textureName == &"-":
		breakpoint
	
	var patchTextureEntries =  parent.patchTextureEntries
	var texture = null
	var subStr = textureName.substr(0,textureName.length()-1)
	
	if imageBuilder.animatedKey.has(textureName):
		if ResourceLoader.exists(WADG.destPath+parent.gameName+"/textures/animated/"+textureName+".tres"):
			return load(WADG.destPath+parent.gameName+"/textures/animated/"+textureName+".tres")
		
		
		var frames = imageBuilder.animatedKey[textureName]
		texture = createAnimatedPatchedTexture(frames)
		texture.speed_scale = 0
		ResourceSaver.save(texture,WADG.destPath+parent.gameName+"/textures/animated/"+subStr+".tres")
		
		
	elif imageBuilder.animatedTextures.has(subStr):
		if ResourceLoader.exists(WADG.destPath+parent.gameName+"/textures/animated/"+textureName+".tres"):
			return load(WADG.destPath+parent.gameName+"/textures/animated/"+textureName+".tres")
		
		var frames = imageBuilder.animatedTextures[subStr]
		texture = createAnimatedPatchedTexture(frames)
		ResourceSaver.save(texture,WADG.destPath+parent.gameName+"/textures/animated/"+subStr+".tres")
	
	
	
	elif textureName in parent.patchTextureEntries:
		if WADG.doesFileExist(WADG.destPath+parent.gameName+"/textures/"+textureName+".png"):
			
			texture = ResourceLoader.load(WADG.destPath+parent.gameName+"/textures/"+textureName+".png","",0)
			return texture
			
		texture = imageBuilder.createPatchedTexture(patchTextureEntries[textureName],rIndex)
		texture.get_image().save_png(WADG.destPath+parent.gameName+"/textures/"+textureName+".png")
	
		addFileToWaitList(WADG.destPath+parent.gameName+"/textures/"+textureName+".png")
		
		
	if texture == null:
		print("TEXTURE WAS NULL:",textureName)
		return null
	
	return texture
	


func addFileToWaitList(path):
	#var file = File.new()
	
	var fileName = path.get_basename().get_file()
	var fileHash = fileName + "-" + path.md5_text()
	
	var pre = "res://.godot/imported/" + fileHash.split("-",false)[0] + ".png-"  + fileHash.split("-")[1] + ".md5" #the file in super.import for filename-md5Code 
	
	

	if FileAccess.file_exists(pre):
		DirAccess.remove_absolute(pre)

	
	if !imageBuilder.skyboxTextures.has(path.get_file()):
		createImportFile(path)
	else:
		createImportFilePNG(path)
		
	var p = getImportPath(path)
	waitingForFiles.append(p)
	filesToUpdate.append(path)
	




func fetchFlat(name : String,rIndexed : bool =false) -> Texture2D:
	if !parent.toDisk:
		return fetchFlatRuntime(name,rIndexed)
	else:
		return fetchFlatDisk(name,rIndexed)

func fetchFlatRuntime(name : String,rIndexed : bool =false) -> Texture:
	
	rIndexed = false
	
	var fte : Dictionary = parent.flatTextureEntries
	
	if !fte.has(name):
		return null
	
	

	if typeof(fte[name]) == TYPE_STRING:
		if !flatCache.has(name):
			
			var img : Image
			
			if fte[name].find(".pk3") != -1 or fte[name].find(".zip") != -1:
				img = loadPngFromZip(fte[name])
				var t = img.get_format()
				
			else: 
				img = Image.load_from_file(fte[name])
				var t = img.get_format()
				
			
			var texture : ImageTexture= ImageTexture.new()
			texture = texture.create_from_image(img)

			flatCache[name] = texture
		
		return flatCache[name]
		
	
	var textureFileEntry : Array = fte[name]
	
	var subStr : String = name.substr(0,name.length()-1)
	
	if imageBuilder.animatedTextures.has(subStr):
		if !flatCache.has(name):
			var textureNames : Array = imageBuilder.animatedTextures[subStr]
			var animatedTexture : Texture2D = createAnimatedFlat(textureNames,rIndexed,true)
			flatCache[name] = animatedTexture
			
			
	elif !flatCache.has(name):
		var  texture : Texture2D
		texture =  imageBuilder.parseFlat(textureFileEntry,rIndexed)
		flatCache[name] = texture
	
	return flatCache[name]
	



func fetchFlatDisk(name : String,rIndexed : bool):
	rIndexed = false
	
	var fte = parent.flatTextureEntries
	
	if !fte.has(name):
		
		return null
	
	var subStr = name.substr(0,name.length()-1)

	var textureFileEntry = fte[name]
	
	if imageBuilder.animatedTextures.has(subStr):#if it's an animated flat
		if !ResourceLoader.exists(WADG.destPath+parent.gameName+"/textures/animated/"+subStr+".tres"):
			
			var textureNames = imageBuilder.animatedTextures[subStr]
			var animatedTexture = createAnimatedFlat(textureNames,rIndexed,true)
			
			ResourceSaver.save(animatedTexture,WADG.destPath+parent.gameName+"/textures/animated/"+subStr+".tres")
			
			return

			
		else:
			
			var r = ResourceLoader.load(WADG.destPath+parent.gameName+"/textures/animated/"+subStr+".tres","",0)
			#var r = ResourceLoader.load(WADG.destPath+get_parent().gameName+"/textures/animated/"+subStr+".tres","")
			return r
			
			
	var resourcePath = WADG.destPath+parent.gameName+"/textures/"+name+".png"
	
	
	if !ResourceLoader.exists(resourcePath):#if it's a non-animated flat
		var texture =imageBuilder.parseFlat(textureFileEntry,rIndexed)
		texture.get_image().save_png(resourcePath)
		addFileToWaitList(resourcePath)
		return
	
	var t = ResourceLoader.load(resourcePath,"",0)
	#var t : Texture2D= ResourceLoader.load(WADG.destPath+get_parent().gameName+"/textures/"+name+".png")
	#if t.resource_path.is_empty():
	#	print("setting path of ",name," to ",resourcePath)
	#	t.resource_path = resourcePath
	#print("type of loaded texture:" , t.get_class())
	#print("loaded texture load_path",t.load_path)
	#print("loaded texture resrouce path:",t.resource_path)
	#print("loaded texture UID:",ResourceLoader.get_resource_uid(resourcePath))
	
	
	#t.resource_path = WADG.destPath+get_parent().gameName+"/textures/"+name+".png"
	#print_debug("fetched cached texture load_path:",t.load_path,"of tyepe:",t.get_class())
	return t
		

	
func fetchDoomGraphicThreaded(patchNames : PackedStringArray ,flipH : bool =false,raw = false) -> Array[Texture2D]:
	
	var tarr : Array[Thread] = []
	var results : Array[Texture2D] =[]
	
	for i in patchNames.size():
		var t = Thread.new()
		var err = t.start(fetchDoomGraphic.bind(patchNames[i]))
		if err != OK:
			breakpoint
		#var err = t.start(fetchDoomGraphic.bind(patchNames[i]))
		tarr.append(t)
	
	
	
	for i : Thread in tarr:
		results.append(i.wait_to_finish())

	return results

func fetchDoomGraphic(patchName : String,flipH : bool =false,raw = false) -> Texture2D:
	

	if patchName.find("_flipped") != -1:
		var s: = patchName.split("_flipped")
		patchName = s[0]
		flipH = true
	
	if !isEditor:
		parent.toDisk = false
	
	if get_parent().wadInit == false:
		parent.loadWads()

	if !parent.toDisk:
		return fetchDoomGraphicRuntime(patchName,flipH,raw)
	else:
		return fetchDoomGraphicDisk(patchName,flipH,raw)

func fetchDoomGraphicOffset(patchName : String):
	return imageBuilder.getDoomGraphicOffests(patchName)

func createAnimatedFlat(nameArr:Array,rIndexed:bool,runtime:bool) -> AnimatedTexture:
	var flatTextureEntries : Dictionary= parent.flatTextureEntries
	var texture : Texture2D = null
	var animatedTexture : AnimatedTexture= AnimatedTexture.new()
	var count : int= 0
	
	animatedTexture.frames = nameArr.size()
	
	for name : String in nameArr:
		var textureFileEntry : Array = flatTextureEntries[name]
		texture = imageBuilder.parseFlat(textureFileEntry,rIndexed)
		
		if parent.toDisk:#if to disk we save each frame to disk
			texture.get_image().save_png(WADG.destPath+parent.gameName+"/textures/"+name+".png")
			addFileToWaitList(WADG.destPath+parent.gameName+"/textures/"+name+".png")
			
		animatedTexture.set_frame_texture(count,texture)

		count +=1
		
	return animatedTexture


func fetchAnimatedSimple(outName : String,inNames : Array,timeScale : int = 4,oneShot = false):
	var animArr = []
	var toDisk: bool = get_parent().toDisk
	var path = WADG.destPath+parent.gameName+"/textures/animated/"+outName+".tres"
	
	if !toDisk and spriteCache.has(outName+"_anim"):
		return spriteCache[outName+"_anim"]
	
	if toDisk and WADG.doesFileExist(path):
		return ResourceLoader.load(path,"",0)
	
	
	for i in inNames:
		animArr.append(fetchDoomGraphic(i))
	
	
	var animatedTexture = AnimatedTexture.new()
	animatedTexture.frames = animArr.size()
	animatedTexture.speed_scale = timeScale
	animatedTexture.one_shot = oneShot
	

	for i in animArr.size():
		animatedTexture.set_frame_texture(i,animArr[i])
	
	if toDisk:
		
		ResourceSaver.save(animatedTexture,path)
		return ResourceLoader.load(path,"",0)
		
	if !toDisk:
		spriteCache[outName+"_anim"] = animatedTexture
		
		return animatedTexture
		
	

	
	
func createAnimatedPatchedTexture(nameArr):
	var textureEntries = parent.patchTextureEntries
	var texture = null
	var animatedTexture = AnimatedTexture.new()
	var count = 0
	
	
	animatedTexture.frames = nameArr.size()
	
	
	
	for name in nameArr:
		
		if !textureEntries.has(name):
			print("missing animation frame:",name)
			continue
		
		var textureFileEntry = textureEntries[name]
		texture = imageBuilder.createPatchedTexture(textureFileEntry)
		
		if parent.toDisk:#if to disk we save each frame to disk
			texture.get_image().save_png(WADG.destPath+parent.gameName+"/textures/"+name+".png")
			addFileToWaitList(WADG.destPath+parent.gameName+"/textures/"+name+".png")
		
		animatedTexture.set_frame_texture(count,texture)

		count +=1
		
	return animatedTexture

func fetchDoomGraphicRuntime(patchName : String,flipH : bool,raw = false) -> Texture2D:
	
	
	if !parent.flatTextureEntries.has(patchName):
		return null
		
	
	if raw:
		var texture = ImageTexture.create_from_image(imageBuilder.createDoomGraphic(patchName,false,raw))
		
	if !spriteCache.has(patchName) and !flipH:
		var texture = ImageTexture.create_from_image(imageBuilder.createDoomGraphic(patchName,false,raw))
		
		
			
		spriteCache[patchName] = texture
		
		spriteOffsetCache[patchName] =imageBuilder.getDoomGraphicOffests(patchName)
	
	if !spriteCache.has(patchName+"_flipped") and flipH:
		var texture = ImageTexture.new()
		var img  : Image = imageBuilder.createDoomGraphic(patchName,false)
		img.flip_x()
		
		texture = texture.create_from_image(img)
		
		
		spriteCache[patchName+"_flipped"] = texture
	
	
	if !flipH:
		#mutex.unlock()
		return spriteCache[patchName]
	else:
		#mutex.unlock()
		return spriteCache[patchName+"_flipped"]

func fetchDoomGraphicDisk(patchName,flipH,raw):
	if !parent.flatTextureEntries.has(patchName):
		print("no entry for patch found in wad for:",patchName)
		return null
	
	
	var path = WADG.destPath+parent.gameName+"/sprites/"+patchName+".png"
	
	
	
	if flipH:
		path = WADG.destPath+parent.gameName+"/sprites/"+patchName+ "_flipped.png"

	if patchName.find("\\") != -1:
		path = WADG.destPath+parent.gameName+"/sprites/"+patchName.replace("\\","bs")+".png"

	
	if waitingForFiles.has(getImportPath(path)):
		return null
		

	if WADG.doesFileExist(path):
		var ret = ResourceLoader.load(path,"Texture2D",0)
		return ret
		
	
	var texture = ImageTexture.new()
	var offsetPath = path.replace(".png",".txt")
	
	
	if !WADG.doesFileExist(path) and !flipH:
		texture = texture.create_from_image(imageBuilder.createDoomGraphic(patchName,false))
		
		#texture.flags -= texture.FLAG_REPEAT
		
		spriteOffsetCache[patchName] = imageBuilder.getDoomGraphicOffests(patchName)
		

	if !WADG.doesFileExist(path) and flipH:
	
		var img =imageBuilder.createDoomGraphic(patchName,false,raw)
		img.flip_x()
		texture = texture.create_from_image(img)
		
		spriteOffsetCache[patchName] =imageBuilder.getDoomGraphicOffests(patchName)
		
	#texture.flags -= texture.FLAG_REPEAT
	texture.get_image().save_png(path)
	addFileToWaitList(path)
	

func createOffsetFile(offsetPath,patchName):
	if !WADG.doesFileExist(offsetPath):
		var file = FileAccess.open(offsetPath,FileAccess.WRITE)
		
		var offset = imageBuilder.getDoomGraphicOffests(patchName)
		file.store_32(offset.x)
		file.store_32(offset.y)
		file.close()
		
		

func saveSound(soundName,audio):
	if parent.toDisk:
		if !FileAccess.file_exists(WADG.destPath+parent.gameName+"/sounds/" + soundName +".tres"):
			ResourceSaver.save(audio,WADG.destPath+parent.gameName+"/sounds/" + soundName +".tres")
	else:
		soundCache[soundName] = audio


func saveAllSondsToDisk():
	for i in soundCache.keys():
		saveSound(i,soundCache[i])

func fetchSound(soundName,diskOverride : bool=false):
	
	
	if !isEditor:
		parent.toDisk = false
	
	if parent.wadInit == false:
		parent.loadWads()
	
	
	if parent.toDisk or diskOverride == true:
		if !WADG.doesFileExist(WADG.destPath+parent.gameName+"/sounds/" + soundName +".tres"):
			if soundCache.has(soundName):
				saveSound(soundName,soundCache[soundName])
			else:
				return null
		return load(WADG.destPath+parent.gameName+"/sounds/" + soundName +".tres")
	else:
		if soundCache.has(soundName):
			return soundCache[soundName]
		elif audioLumps.has(soundName):
			$"../LumpParser".parseDs(audioLumps[soundName],soundName)
			audioLumps.erase(soundName)
			return soundCache[soundName]
	



	

func fetchRuntimeScene(scene,entityCache):
	if entityCache.get_node_or_null(scene.name) == null:
		entityCache.add_child(scene)
	
	return entityCache.get_node(scene.name)


var doDupe = true
var entityC = {}


func getSceneRuntimeName(sceneName):
	var runtimePath = sceneName.substr(sceneName.rfind("/")+1,-1)
	runtimePath  = runtimePath.split(".")[0]
	return runtimePath.to_lower()



func loadPngFromZip(path) -> Image:
	var img = Image.new()
	var zipType = ""
	
	if path.find(".pk3") != -1:
		zipType = ".pk3"
	if path.find(".zip")!= -1:
		zipType = ".zip"
	
	var zipPath = path.substr(0,path.find(zipType))
	var zipDirectory = path.substr(path.find(zipType)+5,-1)
	var zip : ZIPReader = ZIPReader.new()
	
	zip.open(zipPath+zipType)
	var data: PackedByteArray = zip.read_file(zipDirectory)
	img.load_png_from_buffer(data)
	return img
	
func loadImageFileAsTexture(path : String):
	var image = Image.new()
	
	
	var zipType = ""
	
	if path.find(".pk3") != -1:
		zipType = ".pk3"
	if path.find(".zip")!= -1:
		zipType = ".zip"
	
	if path.find(".pk3") != -1 or path.find(".zip") != -1:
		image = loadPngFromZip(path)

	
	else:
		var error = image.load(path)
		if error != 0:
			var file = FileAccess.open(path,FileAccess.READ)
			if file == null:
				return false
			var data = file.get_buffer(file.get_length())
			var e = image.load_png_from_buffer(data)
		
		
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

var file = FileAccess

func updateWaitingFor():
	var newWaiting = []
	
	for i in waitingForFiles:
		if !file.file_exists(i):
			newWaiting.append(i)
			
	waitingForFiles = newWaiting

func importDisableDetect3D(path):
	var file = FileAccess.open(path, FileAccess.READ_WRITE)

	var content = file.get_as_text()
	
	if content.find("detect_3d=true"):
		print("detect 3d is 2")
		
	content = content.replace("detect_3d=true","detect_3d=false")
	content = content.replace("detect_3d=false","flags/repeat=true")
	content = content.replace("flags/filter=false","flags/filter=true")
	content = content.replace("flags/mipmaps=false","flags/mipmaps=true")

	
	file.store_string(content)
	file.close()

func createImportFile(path : String):
	if pngImportTemplate.is_empty():
		var file = FileAccess.open("res://addons/godotWad/importSettingsGodot4.txt", FileAccess.READ)
		pngImportTemplate = file.get_as_text()
		file.close()
	
	#var fileName = path.get_basename().get_file()
	var fileName = path.get_file()
	var fileHash = fileName + "-" + path.md5_text()

	
	var id = ResourceUID.create_id()
	var content = pngImportTemplate
	content = content % [ResourceUID.id_to_text(id),fileHash,path,fileHash]
	ResourceUID.add_id(id,path)
	
	

	file = FileAccess.open(path+".import",FileAccess.WRITE)
	
	file.store_string(content)
	file.close()
	
	

func createImportFilePNG(path : String):
	var file = FileAccess.open("res://addons/godotWad/importSettingsGodot4.txt", FileAccess.READ)
	
	#var fileName = path.get_basename().get_file()
	var fileName = path.get_file()
	var fileHash = fileName + "-" + path.md5_text()
	
	
	
	
	var id = ResourceUID.create_id()
	var content = file.get_as_text()
	content = content % [ResourceUID.id_to_text(id),fileHash,path,fileHash]
	ResourceUID.add_id(id,path)
	
	file.close()
	file.open(path+ ".import",FileAccess.WRITE)
	file.store_string(content)
	file.close()
	
	
func getImportPath(path):
	var fileName = path.get_basename().get_file()
	var fileHash = fileName + ".png-" + path.md5_text()
	return ".godot/imported/" + fileHash + ".md5"
	
	
var ui : Window = null
func waitForFilesToExist(editorInterface,subwait = false):
	var count = 0
	



	var start = Time.get_ticks_msec() / 1000.0
	var pSize = 0
	var initialSize = waitingForFiles.size()
	
	ui = null

 
	while(!waitingForFiles.is_empty()):
		if waitingForFiles.size() != pSize:
			pSize = waitingForFiles.size()
			start = Time.get_ticks_msec() / 1000.0
			
			if ui != null:
				var diff= float(initialSize-pSize)
				var val = diff/initialSize
				ui.setLoaded(diff)
				ui.setProgress(val * 100.0)
				ui.setArr(waitingForFiles)
				
				
		if ui != null:
			if count % 10 == 0:
				ui.setTime(count)
		
		
		updateWaitingFor()
		
		OS.delay_msec(150)
		count += 1
	
	#if ui == null:
		#print("progress bar is null")
	#if ui!= null:
		#print("freeing progress bar")
		#ui.queue_free()

	if subwait==false:
		call_deferred("emit_signal","fileWaitDone")
	else:
		call_deferred("emit_signal","subFileWaitDone")





func fetchMusAndPlayer(tree : SceneTree,fileName : String):
	
	var midiP = fetchMidiPlayer(get_tree())
	var data = fetchMus(fileName)
	
	
	ENTG.setMidiPlayerData(midiP,data)
	return midiP

	

func fetchMidiPlayer(tree : SceneTree):
	
	
	if !tree.has("midiPlayer"):
		tree.setMeta("midiPlayer",ENTG.createMidiPlayer(SETTINGS.getSetting(tree,"soundFont")))
	
	#if midiPlayer == null:
	#	midiPlayer = ENTG.createMidiPlayer(SETTINGS.getSetting(get_tree(),"soundFont"))
		
	return tree.getMeta("midiPlayer")


func fetchMidiOrMus(fileName):
	
	var midiList=  parent.musListPre
	
	if parent.midiListPre.has(fileName):
		return getRawMidiData(fileName)
		
	elif parent.musListPre.has(fileName):
		return createMidiFromMus(fileName)
		

func fetchMus(fileName) -> PackedByteArray:
	if !parent.toDisk:
		if parent.musList.has(fileName):
			return parent.musList[fileName]
		
		if !parent.musListPre.has(fileName):
			return []
	
		parent.musList[fileName] = createMidiFromMus(fileName)
		return parent.musList[fileName]
		
	else:
		
		var midiPath = WADG.destPath+parent.gameName+"/music/midi/"+fileName+".mid"
		
		if !WADG.doesFileExist(midiPath):
			var file = FileAccess.open(midiPath,FileAccess.WRITE)
			file.store_buffer(createMidiFromMus(fileName))
			file.close()
			
			
		
		return FileAccess.get_file_as_bytes(midiPath)
		
	
	

func createMidiFromMus(fileName : String) -> PackedByteArray:
	
	var musListPre = parent.musListPre
	
	if !musListPre.has(fileName):
		print_debug("missing mus file:",fileName)
		return []
	
	var t = musListPre[fileName]
	var file = t[0]
	var offset = t[1]
	var size = t[2]
	
	file.seek(offset)
	var a = Time.get_ticks_msec()
	var midiData = musConverter.convertMusToMidi(file.get_buffer(size))
	SETTINGS.setTimeLog(get_tree(),"mus2mid time:",a)
	return midiData

func getRawMidiData(fileName : String):
	var midiListPre =parent.midiListPre
	
	var t = midiListPre[fileName]
	var file = t[0]
	var offset = t[1]
	var size = t[2]
	
	file.seek(offset)
	
	return file.get_buffer(size)
	
	
