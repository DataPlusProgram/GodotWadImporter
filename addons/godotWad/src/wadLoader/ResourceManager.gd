tool
extends Node

signal fileWaitDone

var materialCache = {}
var soundCache = {}
var textureCache = {}
var spriteMaterialCache = {}
var flatCache = {}
var spriteCache = {}
var spriteOffsetCache = {}
var waitingForFiles = []
var animtedTexturesWaiting  = []
var font = null
var cubeMapShader = preload("res://addons/godotWad/shaders/cubemap.shader")
var cubeMapShaderOneSided = preload("res://addons/godotWad/shaders/cubemapOneSided.shader")

var skyMatOneSided = null
var skyMatDoubleSided = null
var lastSkyName = ""

onready var imageBuilder = $"../ImageBuilder"
onready var levelBuilder = $"../LevelBuilder"

func _ready():
	
	set_meta("hidden",true)

func clear():
	materialCache = {}
	soundCache = {}
	textureCache = {}
	flatCache = {}
	spriteCache = {}
	spriteMaterialCache = {}
	font = null
	imageBuilder.patchCache = {}
	imageBuilder.patchOffsetCache = {}
	get_parent().flatTextureEntries = {}
	get_parent().patchTextureEntries = {}
	
func fetchPatchedTexture(textureName : String,saveAsFlat = false,rIndex = false) -> Texture:
	
	
	if !get_parent().toDisk:
		return fetchPatchedTextureRuntime(textureName,saveAsFlat,rIndex)
	else:
		return fetchPatchedTextureDisk(textureName,rIndex)
	
func fetchMaterial(textureName : String,texture : Texture,lightLevel : float,scroll : Vector2,alpha : float,lightInc : float = 0,skyDoubleSided:bool=false) -> Material:
	
	if texture == null:
		return null
	if !get_parent().toDisk:
		return fetchMaterialRuntime(texture.get_instance_id(),texture,lightLevel,scroll,alpha,lightInc,skyDoubleSided)
	else:
		return fetchMaterialDisk(textureName,texture,lightLevel,scroll,alpha,lightInc,skyDoubleSided)
	
	

func fetchSpriteMaterial(spriteName : String,fovIndependent = false):
	
	
	if get_parent().toDisk:
		if spriteName.find("\\") != -1:
			spriteName = spriteName.replace("\\","bs")
		
		var matPath : String = WADG.destPath +get_parent().gameName + "/materials/" + spriteName +".tres"
		
		if matPath.find("\\") != -1:
			matPath = matPath.replace("\\","bs")
		
		
		
		if ResourceLoader.exists(matPath):
			return ResourceLoader.load(matPath,"",true)
		
		var mat : Resource = createSpriteMat(spriteName,load(WADG.destPath+get_parent().gameName +"/sprites/"+spriteName+".png"),fovIndependent)
		ResourceSaver.save(matPath,mat)
		return ResourceLoader.load(matPath,"",true)
		#return  load(matPath)
	else:
		if materialCache.has(spriteName):
			return materialCache[spriteName]
		
		if !spriteCache.has(spriteName):
			return null
		var mat =  createSpriteMat(spriteName,spriteCache[spriteName],fovIndependent)
		
		materialCache[spriteName] = mat
		
		return materialCache[spriteName]
		
	
	

func createSpriteMat(spriteName: String,texture : Texture,fovIndependant : bool) -> Resource:
	var mat
	if !fovIndependant:
		mat = load("res://addons/godotWad/scenes/quad3Dsprite.tres").duplicate()
		mat.albedo_texture = texture
	else:
		mat = load("res://addons/godotWad/scenes/fovIndep.tres").duplicate()
		mat.set_shader_param("texture_albedo",texture)
	
	
	return mat
	

func fetchBitmapFont(numberChars):
	print("in fetch bitmap font")
	if !get_parent().toDisk:
		get_parent().toDisk = false
		if font == null:
			font = createBitmapFont(numberChars)
		return font
		
		
	if get_parent().toDisk:
		var fontPath = WADG.destPath+"/"+get_parent().gameName+"/fonts/bm.tres"
		if !WADG.doesFileExist(fontPath):
			print("font doesn't exist creating....")
			font = createBitmapFont(numberChars)
			print("ret from font")
			ResourceSaver.save(fontPath,font)
		
		return ResourceLoader.load(fontPath)
		
		
	
	
func createBitmapFont(numberChars):
	
	var font : BitmapFont = BitmapFont.new()
	
	if numberChars.size() == 0:
		return
	for i in range (0,10):
		var tex = fetchDoomGraphic(numberChars[i])
		font.add_texture(tex)
		font.add_char(48+i,i,Rect2(Vector2.ZERO,tex.get_size()))
	
	
	var baseLineH =  fetchDoomGraphic(numberChars[0]).get_size().y
	var tex : Texture = fetchDoomGraphic(numberChars[10])
	var hH = tex.get_size().y /2.0
	font.add_texture(tex)
	font.add_char(45,10,Rect2(Vector2(0,0),tex.get_size()),Vector2(0,baseLineH/2.0-hH))
	
	tex = fetchDoomGraphic(numberChars[11])
	font.add_texture(tex)
	font.add_char(37,11,Rect2(Vector2(0,0),tex.get_size()))
	
	font.height = baseLineH
	
	var fontPath = WADG.destPath+get_parent().gameName+"/fonts/bm.tres"
	return font
	#ResourceSaver.save(fontPath,font)

func fetchPatchedTextureRuntime(textureName : String,saveAsFlat : bool=false,rIndex : bool= false) -> Texture:
	
	if textureName == "-":
		return null
		
	if textureName == "AASTINKY": 
		return null
		
	if textureCache.has(textureName):
		return textureCache[textureName]
	
	
	
	rIndex = false
	var patchTextureEntries =  get_parent().patchTextureEntries
	
	if !patchTextureEntries.has(textureName):
		return null
	 
	var texture = null
	
	
	var subStr = textureName.substr(0,textureName.length()-1)
	var k = imageBuilder.animatedKey
	if imageBuilder.animatedTextures.has(subStr):
		var frames = imageBuilder.animatedTextures[subStr]
		texture = createAnimatedPatchedTexture(frames,false,true)
		texture.fps = 3
		
		
	elif imageBuilder.animatedKey.has(textureName):
		
		var frames = imageBuilder.animatedKey[textureName]
		var index = frames.find(textureName)
		if index != 0:
			frames.invert()
		texture = createAnimatedPatchedTexture(frames,false,true)
		texture.current_frame = index
		texture.fps = 0
		
	else:
		texture = imageBuilder.createPatchedTexture(patchTextureEntries[textureName],rIndex)
	
	
	
	if texture == null:
		return null
	
		
	textureCache[textureName] = texture
	
	return textureCache[textureName]
	

func fetchTextureFromFile(path):
	
	
	var textureName = path.get_file().split(".")[0].to_upper()
	
	if textureCache.has(textureName):
		return textureCache[textureName]
		
		
	var patchTextureEntries =  get_parent().patchTextureEntries
	
	if !patchTextureEntries.has(textureName):
		var pte = get_parent().flatTextureEntries
		var t = loadImageFileAsTexture(path)
		textureCache[textureName] = t
		return t

func fetchPatchedTextureDisk(textureName : String,rIndex : bool= false):
	rIndex = false
	
	
	if textureName == "-":
		breakpoint
	
	var patchTextureEntries =  get_parent().patchTextureEntries
	var texture = null
	var subStr = textureName.substr(0,textureName.length()-1)
	
	if imageBuilder.animatedKey.has(textureName):
		if ResourceLoader.exists(WADG.destPath+get_parent().gameName+"/textures/animated/"+textureName+".tres"):
			return load(WADG.destPath+get_parent().gameName+"/textures/animated/"+textureName+".tres")
		
		
		var frames = imageBuilder.animatedKey[textureName]
		texture = createAnimatedPatchedTexture(frames,false,true)
		texture.fps = 0
		ResourceSaver.save(WADG.destPath+get_parent().gameName+"/textures/animated/"+subStr+".tres",texture)
		
		
	elif imageBuilder.animatedTextures.has(subStr):
		if ResourceLoader.exists(WADG.destPath+get_parent().gameName+"/textures/animated/"+textureName+".tres"):
			return load(WADG.destPath+get_parent().gameName+"/textures/animated/"+textureName+".tres")
		
		var frames = imageBuilder.animatedTextures[subStr]
		texture = createAnimatedPatchedTexture(frames,false,true)
		ResourceSaver.save(WADG.destPath+get_parent().gameName+"/textures/animated/"+subStr+".tres",texture)
	
	
	
	elif textureName in get_parent().patchTextureEntries:
		if WADG.doesFileExist(WADG.destPath+get_parent().gameName+"/textures/"+textureName+".png"):
			
			texture = ResourceLoader.load(WADG.destPath+get_parent().gameName+"/textures/"+textureName+".png","",true)
			return texture
			
		texture = imageBuilder.createPatchedTexture(patchTextureEntries[textureName],rIndex)
		texture.get_data().save_png(WADG.destPath+get_parent().gameName+"/textures/"+textureName+".png")
	
		addFileToWaitList(WADG.destPath+get_parent().gameName+"/textures/"+textureName+".png")
		
		
	if texture == null:
		print("TEXTURE WAS NULL:",textureName)
		return null
	
	return texture
	


func addFileToWaitList(path):
	var file = File.new()
	
	var fileName = path.get_basename().get_file()
	var fileHash = fileName + "-" + path.md5_text()
	
	var pre = "res://.import/" + fileHash.split("-",false)[0] + ".png-"  + fileHash.split("-")[1] + ".md5" #the file in .import for filename-md5Code 
	
	
	var p0 = WADG.getAllFlat("res://.import/")


	if file.file_exists(pre):
		var dir = Directory.new()
		dir.remove(pre)#we delete the old .md5 to ensure data gets updated
	
	
	if !imageBuilder.skyboxTextures.has(path.get_file()):
		createImportFile(path)
	else:
		createImportFilePNG(path)
		
	var p = getImportPath(path)
	waitingForFiles.append(p)
	


func fetchMaterialDisk(textureName,texture,lightLevel,scroll,alpha,lightInc,skyDoubleSided:bool):
	var mat
	
	
	lightLevel = WADG.getLightLevel(lightLevel)
	var tintParam = range_lerp(lightLevel,0,16,0.0,1.0)
	var materialKey = String(textureName) +"," + String(lightLevel)+ "," + String(scroll) + "," + String(alpha)
	var path = WADG.destPath+get_parent().gameName+"/materials/" + textureName + materialKey +".tres"
	
	textureName += "-" + String(lightLevel)
		

	if WADG.doesFileExist(path):
		mat = ResourceLoader.load(path)
		mat.resource_path = path
		return mat
		return ResourceLoader.load(path)
	
	
	if !get_parent().dontUseShader: mat = createMatShader(texture,lightLevel,scroll,alpha)
	
	var shader = load("res://addons/godotWad/shaders/base2.shader")
	mat.set_shader_param("tint",Color(tintParam,tintParam,tintParam))
	mat.shader = shader
	

	var pack = PackedScene.new()
	var err = ResourceSaver.save(path,mat)

	mat = load(path)
	mat.resource_path = path
	
	return mat
	#return WADG.destPath+get_parent().gameName+"/materials/" + textureName +".tres"
	return  load(WADG.destPath+get_parent().gameName+"/materials/" + textureName +".tres")


func fetchMaterialRuntime(textureName,texture,lightLevel,scroll,alpha,lightInc,skyDoubleSided):
	
	var mat
	var materialKey = String(textureName) +"," + String(lightLevel)+ "," + String(scroll) + "," + String(alpha)
	
	if materialCache.has(materialKey):
		return materialCache[materialKey]
	
	
	lightLevel = WADG.getLightLevel(lightLevel)
	var tintParam = range_lerp(lightLevel,0,16,0.0,1.0)

		
	if !get_parent().dontUseShader: mat = createMatShader(texture,lightLevel,scroll,alpha)

	materialCache[materialKey] = mat
		
	var shader = load("res://addons/godotWad/shaders/base2.shader")
		
	mat.set_shader_param("tint",Color(tintParam,tintParam,tintParam))
	mat.shader = shader
	mat = materialCache[materialKey]
	
	
	if mat == null:
		breakpoint
	
	return mat


func createMatSpatial(texture,sector):
	var mat = SpatialMaterial.new()
	var sectorLightLevel = sector["lightLevel"]/255
	sectorLightLevel = sectorLightLevel
	#var lightLevel = max(31-(sectorLightLevel/8),0)
	
	mat.albedo_color = Color(sectorLightLevel,sectorLightLevel,sectorLightLevel)
	mat.albedo_texture = texture
	
	if texture.has_alpha():#at the moment this is also true which will need to be fixed if it makes performance bad
		mat.params_use_alpha_scissor = true
	return mat


	
func createMatShader(texture,lightLevel,scroll,alpha):
#	if alpha != 1:
#		breakpoint
	
	var shader = load("res://addons/godotWad/shaders/base2.shader")
	var sectorLightLevel = lightLevel#sector["lightLevel"]/255.0
	var mat = ShaderMaterial.new()
	#var scrollSpeed = Vector2(0,0)
	mat.shader = shader
	
	mat.set_shader_param("texture_albedo" , texture)
	mat.set_shader_param("scrolling",scroll)
	mat.set_shader_param("alpha",1)
	
	return mat


func fetchFlat(name : String,rIndexed : bool =false) -> ImageTexture:
	if !get_parent().toDisk:
		return fetchFlatRuntime(name,rIndexed)
	else:
		return fetchFlatDisk(name,rIndexed)

func fetchFlatRuntime(name : String,rIndexed : bool =false) -> ImageTexture:
	
	rIndexed = false
	
	var fte = get_parent().flatTextureEntries
	
	if !fte.has(name):
		return null
	
	var subStr = name.substr(0,name.length()-1)

	
	var textureFileEntry = fte[name]
	var textureObj = null
	
	
	if $"../ImageBuilder".animatedTextures.has(subStr):
		if !flatCache.has(name):
			var textureNames = $"../ImageBuilder".animatedTextures[subStr]
			var animatedTexture = createAnimatedFlat(textureNames,rIndexed,true)
			flatCache[name] = animatedTexture
			
			
	elif !flatCache.has(name):
		var texture
		var flag = false
		texture =  $"../ImageBuilder".parseFlat(textureFileEntry,rIndexed)
		flatCache[name] = texture
	
	return flatCache[name]
	



func fetchFlatDisk(name,rIndexed):
	rIndexed = false
	
	var fte = get_parent().flatTextureEntries
	
	if !fte.has(name):
		
		return null
	
	var subStr = name.substr(0,name.length()-1)

	var textureFileEntry = fte[name]
	
	if $"../ImageBuilder".animatedTextures.has(subStr):#if it's an animated flat
		if !ResourceLoader.exists(WADG.destPath+get_parent().gameName+"/textures/animated/"+subStr+".tres"):
			
			var textureNames = $"../ImageBuilder".animatedTextures[subStr]
			var animatedTexture = createAnimatedFlat(textureNames,rIndexed,true)
			
			ResourceSaver.save(WADG.destPath+get_parent().gameName+"/textures/animated/"+subStr+".tres",animatedTexture)
			
			return

			
		else:
			
			var r = ResourceLoader.load(WADG.destPath+get_parent().gameName+"/textures/animated/"+subStr+".tres","",true)
			return r
			
			
	
	if !ResourceLoader.exists(WADG.destPath+get_parent().gameName+"/textures/"+name+".png"):#if it's a non-animated flat
		var texture = $"../ImageBuilder".parseFlat(textureFileEntry,rIndexed)
		texture.get_data().save_png(WADG.destPath+get_parent().gameName+"/textures/"+name+".png")
		addFileToWaitList(WADG.destPath+get_parent().gameName+"/textures/"+name+".png")
		return
		

	var t = ResourceLoader.load(WADG.destPath+get_parent().gameName+"/textures/"+name+".png","",true)
	return t
		

	

func fetchSkyMat(texName,skyDoubleSided : bool = false):

	if !get_parent().toDisk:
		return fetchSkyMatRuntime(texName,skyDoubleSided)
	else:
		return fetchSkyMatDisk(texName,skyDoubleSided)


func fetchSkyMatRuntime(texName,skyDoubleSided):
	
	
	if skyMatDoubleSided == null or lastSkyName != texName:
		lastSkyName = texName
		skyMatDoubleSided = createSkyMat(texName,true)
		return skyMatDoubleSided
	
	if skyMatOneSided == null or lastSkyName != texName:
		lastSkyName = texName
		skyMatOneSided = createSkyMat(texName,false)
		return skyMatOneSided
	
	if skyDoubleSided == true: 
		return skyMatDoubleSided
	else: 
		return skyMatOneSided
	
	
	
	


func fetchSkyMatDisk(texName,skyDoubleSided : bool = false):

	var textureName = texName#+String(skyDoubleSided)
	var path = WADG.destPath+get_parent().gameName+"/materials/" + textureName +".tres"

	if !ResourceLoader.exists(textureName):

		var mat = createSkyMat(texName,skyDoubleSided)

		var pack = PackedScene.new()
		
		var err = ResourceSaver.save(path,mat)


	var ret = load(path)
	return ret
	


func fetchDoomGraphic(patchName : String,flipH : bool =false) -> Texture:
	
	
	#if patchName.find("\\") != -1:
	#	patchName = patchName.replace("\\","")
	
	if patchName.find("_flipped") != -1:
		var s = patchName.split("_flipped")
		patchName = s[0]
		flipH = true
	
	if !Engine.editor_hint:
		get_parent().toDisk = false
	
	if get_parent().wadInit == false:
		get_parent().loadWads()

	
	
	
	if !get_parent().toDisk:
		return fetchDoomGraphicRuntime(patchName,flipH)
	else:
		return fetchDoomGraphicDisk(patchName,flipH)

func fetchDoomGraphicOffset(patchName : String):
	return $"../ImageBuilder".getDoomGraphicOffests(patchName)

func createAnimatedFlat(nameArr,rIndexed,runtime):
	var flatTextureEntries = get_parent().flatTextureEntries
	var texture = null
	var animatedTexture = AnimatedTexture.new()
	var count = 0
	
	animatedTexture.frames = nameArr.size()
	
	for name in nameArr:
		var textureFileEntry = flatTextureEntries[name]
		texture = $"../ImageBuilder".parseFlat(textureFileEntry,rIndexed)
		
		if get_parent().toDisk:#if to disk we save each frame to disk
			texture.get_data().save_png(WADG.destPath+get_parent().gameName+"/textures/"+name+".png")
			addFileToWaitList(WADG.destPath+get_parent().gameName+"/textures/"+name+".png")
			
		animatedTexture.set_frame_texture(count,texture)

		count +=1
		
	return animatedTexture


func fetchAnimatedSimple(outName : String,inNames : Array,fps : int = 4):
	var animArr = []
	
	var path = WADG.destPath+get_parent().gameName+"/textures/animated/"+outName+".tres"
	
	if !get_parent().toDisk and spriteCache.has(outName+"_anim"):
		return spriteCache[outName+"_anim"]
	
	if get_parent().toDisk and WADG.doesFileExist(path):
		return ResourceLoader.load(path,"",true)
	
	
	for i in inNames:
		animArr.append(fetchDoomGraphic(i))
	
	
	var animatedTexture = AnimatedTexture.new()
	animatedTexture.frames = animArr.size()
	animatedTexture.fps = fps
	
	for i in animArr.size():
		animatedTexture.set_frame_texture(i,animArr[i])
	
	if get_parent().toDisk:
		ResourceSaver.save(path,animatedTexture)
		return ResourceLoader.load(path,"",true)
		
	if !get_parent().toDisk:
		spriteCache[outName+"_anim"] = animatedTexture
		return animatedTexture
	
	

func createAnimatedPatchedTexture(nameArr,rIndexed,runtime):
	var textureEntries = get_parent().patchTextureEntries
	var texture = null
	var animatedTexture = AnimatedTexture.new()
	var count = 0
	
	
	animatedTexture.frames = nameArr.size()
	
	
	
	for name in nameArr:
		
		if !textureEntries.has(name):
			print("missing animation frame:",name)
			continue
		
		var textureFileEntry = textureEntries[name]
		texture = $"../ImageBuilder".createPatchedTexture(textureFileEntry)
		
		if get_parent().toDisk:#if to disk we save each frame to disk
			texture.get_data().save_png(WADG.destPath+get_parent().gameName+"/textures/"+name+".png")
			addFileToWaitList(WADG.destPath+get_parent().gameName+"/textures/"+name+".png")
		
		animatedTexture.set_frame_texture(count,texture)

		count +=1
		
	return animatedTexture

func fetchDoomGraphicRuntime(patchName : String,flipH : bool) -> ImageTexture:
	
	if !get_parent().flatTextureEntries.has(patchName):
		return null
		
		
		
	if !spriteCache.has(patchName) and !flipH:
		var texture = ImageTexture.new()
		texture.create_from_image($"../ImageBuilder".createDoomGraphic(patchName,false))
		
		texture.flags -= texture.FLAG_REPEAT
		
		if get_parent().textureFiltering == false: 
			texture.flags -= Texture.FLAG_FILTER
		if get_parent().mipMaps == get_parent().MIP.OFF:
			texture.flags -= Texture.FLAG_MIPMAPS
		
		spriteCache[patchName] = texture
		spriteOffsetCache[patchName] = $"../ImageBuilder".getDoomGraphicOffests(patchName)
		
	
	if !spriteCache.has(patchName+"_flipped") and flipH:
		var texture = ImageTexture.new()
		var img  : Image = $"../ImageBuilder".createDoomGraphic(patchName,false)
		img.flip_x()
		
		texture.create_from_image(img)
		texture.flags -= texture.FLAG_REPEAT
		
		if get_parent().textureFiltering == false: 
			texture.flags -= Texture.FLAG_FILTER
		if get_parent().mipMaps == get_parent().MIP.OFF:
			texture.flags -= Texture.FLAG_MIPMAPS
		
		spriteCache[patchName+"_flipped"] = texture
	
	
	if !flipH:
		return spriteCache[patchName]
	else:
		return spriteCache[patchName+"_flipped"]

func fetchDoomGraphicDisk(patchName,flipH):
	if !get_parent().flatTextureEntries.has(patchName):
		print("no entry for patch found in wad for:",patchName)
		return null
	
	
	var path = WADG.destPath+get_parent().gameName+"/sprites/"+patchName+".png"
	
	
	
	if flipH:
		path = WADG.destPath+get_parent().gameName+"/sprites/"+patchName+ "_flipped.png"

	if patchName.find("\\") != -1:
		path = WADG.destPath+get_parent().gameName+"/sprites/"+patchName.replace("\\","bs")+".png"

	
	if waitingForFiles.has(getImportPath(path)):
		return null
		

	if WADG.doesFileExist(path):
		var ret = ResourceLoader.load(path,"Texture",true)
		return ret
		
	
	var texture = ImageTexture.new()
	var offsetPath = path.replace(".png",".txt")
	
	

	
	
	if !WADG.doesFileExist(path) and !flipH:
		texture.create_from_image($"../ImageBuilder".createDoomGraphic(patchName,false))
		texture.get_data().save_png(path)
		texture.flags -= texture.FLAG_REPEAT
		
		spriteOffsetCache[patchName] = $"../ImageBuilder".getDoomGraphicOffests(patchName)
		

	if !WADG.doesFileExist(path) and flipH:
	
		var img = $"../ImageBuilder".createDoomGraphic(patchName,false)
		img.flip_x()
		texture.create_from_image(img)
		
		spriteOffsetCache[patchName] = $"../ImageBuilder".getDoomGraphicOffests(patchName)
		

	texture.get_data().save_png(path)
	texture.flags -= texture.FLAG_REPEAT
	
	addFileToWaitList(path)
	

func createOffsetFile(offsetPath,patchName):
	if !WADG.doesFileExist(offsetPath):
		var file = File.new()
		file.open(offsetPath,File.WRITE)
		
		var offset = $"../ImageBuilder".getDoomGraphicOffests(patchName)
		file.store_32(offset.x)
		file.store_32(offset.y)
		file.close()
		
		

func saveSound(soundName,audio):
	if get_parent().toDisk:
		var file = File.new()
		if !file.file_exists(WADG.destPath+get_parent().gameName+"/sounds/" + soundName +".tres"):
			ResourceSaver.save(WADG.destPath+get_parent().gameName+"/sounds/" + soundName +".tres",audio)
	else:
		soundCache[soundName] = audio


func saveAllSondsToDisk():
	for i in soundCache.keys():
		saveSound(i,soundCache[i])

func fetchSound(soundName,diskOverride : bool=false):
	
	
	if !Engine.editor_hint:
		get_parent().toDisk = false
	
	if get_parent().wadInit == false:
		 get_parent().loadWads()
	
	
	if get_parent().toDisk or diskOverride == true:
		if !WADG.doesFileExist(WADG.destPath+get_parent().gameName+"/sounds/" + soundName +".tres"):
			if soundCache.has(soundName):
				saveSound(soundName,soundCache[soundName])
				
		return load(WADG.destPath+get_parent().gameName+"/sounds/" + soundName +".tres")
	else:
		if soundCache.has(soundName):
			return soundCache[soundName]
	

func createSkyMat(texName : String,skyDoubleSided : bool =false):
	var matKey = texName+String(skyDoubleSided)
	if $"../ResourceManager".materialCache.has(matKey) and !get_parent().toDisk:
		return $"../ResourceManager".materialCache[matKey]
	
	var image : Image
	var txt = fetchPatchedTexture(texName,false)
	if txt == null:
		return
	image = txt.get_data()
	var colArr : PoolByteArray = []
	

	var srcRectA = Rect2(Vector2(0,0),Vector2(128,128))
	var srcRectB = Rect2(Vector2(128,0),Vector2(128,128))
	
	
	
	var imageTop = $"../ImageBuilder".createTopImage(image)
	var imageBottom = $"../ImageBuilder".createBottomImage(image)
	var imageLeft = image.get_rect(srcRectA)
	var imageRight = image.get_rect(srcRectB)
	var imageFront = imageLeft.duplicate()
	var imageBack = imageRight.duplicate()
	
	
	imageBack.flip_x()
	imageLeft.flip_x()

	var cubemap = $"../ImageBuilder".createCubemap(imageLeft,imageRight,imageTop,imageBottom,imageFront,imageBack)
	
	var mat = ShaderMaterial.new()
	

	if skyDoubleSided:
		mat.shader = cubeMapShader
	else:
		mat.shader = cubeMapShaderOneSided
	
	mat.set_shader_param("cube_map",cubemap)
	
	if !get_parent().toDisk:
		materialCache[matKey] = mat
	
	return mat

	

func fetchRuntimeScene(scene,entityCache):
	if entityCache.get_node_or_null(scene.name) == null:
		entityCache.add_child(scene)
	
	return entityCache.get_node(scene.name)


var doDupe = true
var entityC = {}


func getSceneRuntimeName(sceneName):
	var runtimePath = sceneName.substr(sceneName.find_last("/")+1,-1)
	runtimePath  = runtimePath.split(".")[0]
	return runtimePath.to_lower()


			
			
func loadImageFileAsTexture(path):
	var image = Image.new()
	var error = image.load(path)
	
	if error != 0:
		var file = File.new()
		if file.open(path,File.READ) != 0:
			return false
		var data = file.get_buffer(file.get_len())
		var e = image.load_png_from_buffer(data)
		
		
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

var file = File.new()

func updateWaitingFor():
	var newWaiting = []
	
	for i in waitingForFiles:
		if !file.file_exists(i):
			newWaiting.append(i)
			
	waitingForFiles = newWaiting

func importDisableDetect3D(path):
	var file = File.new()
	var err = file.open(path, File.READ_WRITE)

	var content = file.get_as_text()
	
	if content.find("detect_3d=true"):
		print("detect 3d is 2")
		
	content = content.replace("detect_3d=true","detect_3d=false")
	content = content.replace("detect_3d=false","flags/repeat=true")
	content = content.replace("flags/filter=false","flags/filter=true")
	content = content.replace("flags/mipmaps=false","flags/mipmaps=true")

	
	file.store_string(content)
	file.close()

func createImportFile(path):
	var file = File.new()
	var err = file.open("res://addons/godotWad/importSettings.txt", File.READ)
	
	var fileName = path.get_basename().get_file()
	var fileHash = fileName + "-" + path.md5_text()
	
	var content = file.get_as_text()
	content = content % [fileHash,fileHash,path,fileHash,fileHash,String($"..".textureFiltering).to_lower()]
	
	file.close()
	file.open(path+".import",File.WRITE)
	file.store_string(content)
	file.close()

func createImportFilePNG(path):
	var file = File.new()
	var err = file.open("res://addons/godotWad/importSettingsPNG.txt", File.READ)
	
	var fileName = path.get_basename().get_file()
	var fileHash = fileName + "-" + path.md5_text()
	
	var content = file.get_as_text()
	content = content % [fileHash,path,fileHash]
	
	
	file.close()
	file.open(path+".import",File.WRITE)
	file.store_string(content)
	file.close()
	
	
func getImportPath(path):
	var fileName = path.get_basename().get_file()
	var fileHash = fileName + ".png-" + path.md5_text()
	return ".import/" + fileHash + ".md5"
	
	

func waitForFilesToExist(editorInterface):
	
	var count = 0
	if editorInterface != null:
		editorInterface.get_resource_filesystem().scan()

	var start = OS.get_system_time_secs()
	var pSize = waitingForFiles.size()
	var initialSize = pSize
	var ui : WindowDialog = null
	
	if pSize > 0:
		ui = load("res://addons/godotWad/scenes/ui/progressBar/progressBar.tscn").instance()
		get_tree().get_root().add_child(ui)
		ui.setTotal(pSize)
		ui.popup_centered_ratio(0.4)
		
	
	while(!waitingForFiles.empty()):
		if waitingForFiles.size() != pSize:
			pSize = waitingForFiles.size()
			start = OS.get_system_time_secs()
			
			if ui != null:
				var diff= float(initialSize-pSize)
				var val = diff/initialSize
				ui.setLoaded(diff)
				ui.setProgress(val * 100.0)
				ui.setArr(waitingForFiles)
				
				
		if ui != null:
			if count % 10 == 0:
				ui.setTime(count)
			
		if OS.get_system_time_secs()-start > 10:
			print("BIG ERROR: files coundn't be found:",$ResourceManager.waitingForFiles)
			break
			
		
		if !editorInterface.get_resource_filesystem().is_scanning():
			updateWaitingFor()
		
		
		OS.delay_msec(1)
		count += 1
	
	if ui!= null:
		ui.hide()
	
	emit_signal("fileWaitDone")
