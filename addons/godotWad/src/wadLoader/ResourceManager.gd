tool
extends Node

var materialCache = {}
var soundCache = {}
var textureCache = {}
var nextPassCache = {}
#var patchCache = {}
var flatCache = {}
var spriteCache = {}
var mapName



var cubeMapShader = preload("res://addons/godotWad/shaders/cubemap.shader")
var cubeMapShaderOneSided = preload("res://addons/godotWad/shaders/cubemapOneSided.shader")

var skyMatOneSided = null
var skyMatDoubleSided = null

onready var imageBuilder = $"../ImageBuilder"
onready var levelBuilder = $"../LevelBuilder"

func _ready():
	set_meta("hidden",true)


func fetchTexture(textureName,saveAsFlat = false,rIndex = false):
	
	
	if !get_parent().toDisk:
		return fetchTextureRuntime(textureName,saveAsFlat,rIndex)
	else:
		return fetchTextureDisk(textureName,rIndex)
	
func fetchMaterial(textureName,texture,lightLevel,scroll,alpha,lightInc = 0,skyDoubleSided:bool=false):
	if !get_parent().toDisk:
		return fetchMaterialRuntime(textureName,texture,lightLevel,scroll,alpha,lightInc,skyDoubleSided)
	else:
		return fetchMaterialDisk(textureName,texture,lightLevel,scroll,alpha,lightInc,skyDoubleSided)
	
	
	
	

func fetchTextureRuntime(textureName,saveAsFlat=false,rIndex= false):
	
	if textureName == "-":
		return null
		
	if textureName == "AASTINKY": 
		return null
		
	if textureCache.has(textureName):
		return textureCache[textureName]
	
	
	
	rIndex = false
	var textureEntries =  get_parent().textureEntries
	
	if !textureEntries.has(textureName):
		print("missing texture ",textureName)
		return null
	
	var texture = null
	
	
	var subStr = textureName.substr(0,textureName.length()-1)
	
	if imageBuilder.switchTextures.has(textureName) :
		var frames = imageBuilder.switchTextures[textureName]
		texture = createAnimatedTexture(frames,false,true)
		texture.fps = 0
		
	elif imageBuilder.animatedTextures.has(subStr):
		var frames = imageBuilder.animatedTextures[subStr]
		texture = createAnimatedTexture(frames,false,true)
		
	else:
		texture = imageBuilder.createTexture(textureEntries[textureName],rIndex)
	
	
	
	if texture == null:
		return null
	

	if saveAsFlat:
		flatCache[textureName] = texture
		
	textureCache[textureName] = texture
	
	return textureCache[textureName]
	

func fetchTextureDisk(textureName,rIndex= false):
	
	rIndex = false
	var textureEntries =  get_parent().textureEntries
	
	var texture = null
	
	
	var subStr = textureName.substr(0,textureName.length()-1)
	
	if imageBuilder.switchTextures.has(textureName):
		if ResourceLoader.exists("res://wadFiles/textures/animated/"+textureName+".tres"):
			return load("res://wadFiles/textures/animated/"+textureName+".tres")
		
		
		
		var frames = imageBuilder.switchTextures[textureName]
		texture = createAnimatedTexture(frames,false,true)
		texture.fps = 0
		ResourceSaver.save("res://wadFiles/textures/animated/"+subStr+".tres",texture)
		return  load("res://wadFiles/textures/animated/"+subStr+".tres")
		
	elif imageBuilder.animatedTextures.has(subStr):
		
		if ResourceLoader.exists("res://wadFiles/textures/animated/"+textureName+".tres"):
			return load("res://wadFiles/textures/animated/"+textureName+".tres")
		
		var frames = imageBuilder.animatedTextures[subStr]
		texture = createAnimatedTexture(frames,false,true)
		ResourceSaver.save("res://wadFiles/textures/animated/"+subStr+".tres",texture)
		return  load("res://wadFiles/textures/animated/"+subStr+".tres")
	
	
	elif textureName in get_parent().textureEntries:
		if ResourceLoader.exists("res://wadFiles/textures/"+name+".png"):
			return load("res://wadFiles/textures/"+name+".png")
		
		texture = imageBuilder.createTexture(textureEntries[textureName],rIndex)
		texture.get_data().save_png("res://wadFiles/textures/"+textureName+".png")
		waitForTextureToExist(textureName)
		var t = load("res://wadFiles/textures/"+textureName+".png")
		return load("res://wadFiles/textures/"+textureName+".png")
		
	else:
		
		texture = fetchFlatDisk(textureName,rIndex)
		return texture
		
	
	if texture == null:
		return null
	
	
	

func waitForTextureToExist(name):

	var waitThread = Thread.new()
	waitThread.start(self,"waitForTextureToExistTF",name)
	waitThread.wait_to_finish()
	

func waitForTextureToExistTF(name):
	var file = File.new()
	
	
	while !(file.file_exists("res://wadFiles/textures/"+name+".png.import")):
		#print("waiting for ","res://wadFiles/textures/"+name+".png.import")
		OS.delay_msec(200)
		get_parent().editorFileSystem.scan()



func waitForFileToExist(path):
	var waitThread = Thread.new()
	waitThread.start(self,"waitForFileToExistTF",path)
	waitThread.wait_to_finish()
	

func waitForFileToExistTF(path):
	var file = File.new()
	
	while !(file.file_exists(path)):
		OS.delay_msec(200)
		get_parent().editorFileSystem.scan()
		





func fetchMaterialDisk(textureName,texture,lightLevel,scroll,alpha,lightInc,skyDoubleSided:bool):
	
	
	var mat

	
	lightLevel = WADG.getLightLevel(lightLevel)

	var tintParam = range_lerp(lightLevel,0,16,0.0,1.0)
	var path = "res://wadFiles/materials/" + textureName +  String(skyDoubleSided)+ ".tres"
	
	
	textureName += "-" + String(lightLevel)

	if ResourceLoader.exists("res://wadFiles/materials/" + textureName +".tres"):
		return  load("res://wadFiles/materials/" + textureName +".tres")
	
	print("creating  mat:",textureName)
	
	if !get_parent().dontUseShader: mat = createMatShader(texture,lightLevel,scroll,alpha)
	
	var shader = load("res://addons/godotWad/shaders/base2.shader")
	mat.set_shader_param("tint",Color(tintParam,tintParam,tintParam))
	mat.shader = shader
		
	var pack = PackedScene.new()
	var err = ResourceSaver.save("res://wadFiles/materials/" + textureName +".tres",mat)
	waitForFileToExist("res://wadFiles/materials/" + textureName +".tres")
		

	
	return  load("res://wadFiles/materials/" + textureName +".tres")


func fetchMaterialRuntime(textureName,texture,lightLevel,scroll,alpha,lightInc,skyDoubleSided):
	
	var mat
	var materialKey = textureName +"," + String(lightLevel)+ "," + String(scroll) + "," + String(alpha)
	

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
	var scrollSpeed = Vector2(0,0)
	mat.shader = shader
	
	#if sType!= 0:
	#	var typeInfo = $"../LevelBuilder".typeDict[sType]
	#	if typeInfo.has("vector"):

			
	mat.set_shader_param("texture_albedo" , texture)
	mat.set_shader_param("scrolling",scrollSpeed)
	mat.set_shader_param("alpha",1)
	
	return mat


func fetchFlat(name,rIndexed=false):
	
	
	if !get_parent().toDisk:
		return fetchFlatRuntime(name,rIndexed)
	else:
		return fetchFlatDisk(name,rIndexed)

func fetchFlatRuntime(name,rIndexed=false):
	
	
	#if name == "F_SKY1":
	#	breakpoint
	
	if flatCache.has(name):
		return flatCache[name]
	
	rIndexed = false
	
	var textureEntries = get_parent().patchTextureEntries
	
	if !textureEntries.has(name):
		return null
	
	var subStr = name.substr(0,name.length()-1)

	
	var textureFileEntry = textureEntries[name]
	var textureObj = null
	
	
	if $"../ImageBuilder".animatedTextures.has(subStr):
		if !flatCache.has(name):
		
			var textureNames = $"../ImageBuilder".animatedTextures[subStr]
			var animatedTexture = createAnimatedFlat(textureNames,rIndexed,true)
			flatCache[name] = animatedTexture
			return flatCache[name]
			
			
	elif !flatCache.has(name):
		var texture
		var flag = false
		texture =  $"../ImageBuilder".parseFlat(textureFileEntry,rIndexed)
		flatCache[name] = texture

	return flatCache[name]
	



func fetchFlatDisk(name,rIndexed):
	rIndexed = false
	
	var textureEntries = get_parent().patchTextureEntries
	
	if !textureEntries.has(name):
		return null
	
	var subStr = name.substr(0,name.length()-1)

	var textureFileEntry = textureEntries[name]
	
	if $"../ImageBuilder".animatedTextures.has(subStr):#if it's an animated flat
		if !ResourceLoader.exists("res://wadFiles/textures/animated/"+subStr+".tres"):
			
			var textureNames = $"../ImageBuilder".animatedTextures[subStr]
			var animatedTexture = createAnimatedFlat(textureNames,rIndexed,true)
			
			ResourceSaver.save("res://wadFiles/textures/animated/"+subStr+".tres",animatedTexture)

			
			waitForFileToExist("res://wadFiles/textures/animated/"+subStr+".tres")
			
			var r = load("res://wadFiles/textures/animated/"+subStr+".tres")
			
			return r
			
		else:
			
			var r = load("res://wadFiles/textures/animated/"+subStr+".tres")
			return r
			
			
	
	if !ResourceLoader.exists("res://wadFiles/textures/"+name+".png"):#if it's a non-animated flat
		var texture = $"../ImageBuilder".parseFlat(textureFileEntry,rIndexed)
		texture.get_data().save_png("res://wadFiles/textures/"+name+".png")
		waitForTextureToExist(name)
	return load("res://wadFiles/textures/"+name+".png")
		

	

func fetchSkyMat(skyDoubleSided : bool = false):
	if !get_parent().toDisk:
		return fetchSkyMatRuntime(skyDoubleSided)
	else:
		return fetchSkyMatDisk(skyDoubleSided)


func fetchSkyMatRuntime(skyDoubleSided):
	
	if skyMatDoubleSided == null:
		skyMatDoubleSided = createSkyMat(true)
	
	if skyMatOneSided == null:
		skyMatOneSided = createSkyMat(false)
	
	if skyDoubleSided == true: return skyMatDoubleSided
	else: return skyMatOneSided
	
	
	
	


func fetchSkyMatDisk(skyDoubleSided : bool = false):
	var texName = $"../ImageBuilder".getSkyboxTextureForMap()
	var textureName = texName+String(skyDoubleSided)
	
	if !ResourceLoader.exists("res://wadFiles/materials/" + textureName +".tres"):
		print("creating sky mat")
		var mat = createSkyMat(skyDoubleSided)
		
		var pack = PackedScene.new()
		var err = ResourceSaver.save("res://wadFiles/materials/" + textureName+".tres",mat)
		waitForFileToExist("res://wadFiles/materials/" + textureName +".tres")
	
	
	return  load("res://wadFiles/materials/" + textureName +".tres")
	


func fetchPatch(patchName):
	if !Engine.editor_hint:
		get_parent().toDisk = false
	
	if get_parent().wadInit == false:
		 get_parent().loadWads()
	
	
	
	if !get_parent().toDisk:
		return fetchPatchRuntime(patchName)
	else:
		return fetchPatchDisk(patchName)

func createAnimatedFlat(nameArr,rIndexed,runtime):
	
	
	var textureEntries = get_parent().patchTextureEntries
	#var textureFileEntry = textureEntries[name]
	var texture = null
	var animatedTexture = AnimatedTexture.new()
	var count = 0
	
	animatedTexture.frames = nameArr.size()
	
	for name in nameArr:
		var textureFileEntry = textureEntries[name]
				
		texture = $"../ImageBuilder".parseFlat(textureFileEntry,rIndexed)
		
		if get_parent().toDisk:#if to disk we save each frame to disk
			texture.get_data().save_png("res://wadFiles/textures/"+name+".png")
			waitForTextureToExist(name)
			texture = load("res://wadFiles/textures/"+name+".png")
			
		animatedTexture.set_frame_texture(count,texture)

		count +=1
		
	return animatedTexture

func createAnimatedTexture(nameArr,rIndexed,runtime):
	var textureEntries = get_parent().textureEntries
	#var textureFileEntry = textureEntries[name]
	var texture = null
	var animatedTexture = AnimatedTexture.new()
	var count = 0
	
	animatedTexture.frames = nameArr.size()
	
	for name in nameArr:
		var textureFileEntry = textureEntries[name]
				
		#texture = $"../ImageBuilder".parseFlat(textureFileEntry,rIndexed)
	#	text = $"../ImageBuilder".parseFlat(textureFileEntry,rIndexed)
		texture = $"../ImageBuilder".createTexture(textureFileEntry)
		if get_parent().toDisk:#if to disk we save each frame to disk
			texture.get_data().save_png("res://wadFiles/textures/"+name+".png")
			waitForTextureToExist(name)
			texture = load("res://wadFiles/textures/"+name+".png")
			
		animatedTexture.set_frame_texture(count,texture)

		count +=1
		
	return animatedTexture

func fetchPatchRuntime(patchName):
	
	if !get_parent().patchTextureEntries.has(patchName):
		return
		
	if !spriteCache.has(patchName):
		var texture = ImageTexture.new()
		texture.create_from_image($"../ImageBuilder".parsePatch(patchName,false))
		
		if get_parent().textureFiltering == false: 
			texture.flags -= Texture.FLAG_FILTER
		if get_parent().mipMaps == get_parent().MIP.OFF:
			texture.flags -= Texture.FLAG_MIPMAPS
		
		spriteCache[patchName] = texture
	return spriteCache[patchName]

func fetchPatchDisk(patchName):
	
	if !get_parent().patchTextureEntries.has(patchName):
		print("no entry for patch found in wad")
		return
	
	var path = "res://wadFiles/sprites/"+patchName+".png"
	
	if !ResourceLoader.exists(path):
		print("sprite file:", path ," dosen't exist creating...")
		var texture = ImageTexture.new()
		texture.create_from_image($"../ImageBuilder".parsePatch(patchName,false))
		texture.get_data().save_png(path)

		
		spriteCache[patchName] = texture
		waitForFileToExist(path + ".import")
	
	#print("fetch patch disk wait for ","res://wadFiles/sprites/"+patchName+".png.import")
	
	
	var t = load("res://wadFiles/sprites/"+patchName+".png")
	return  t

func saveSound(name,audio):
	if get_parent().toDisk:
		ResourceSaver.save("res://wadFiles/sounds/" + name +".tres",audio)
	else:
		soundCache[name] = audio

	
func fetchSound(name,diskOverride : bool=false):
	
	if !Engine.editor_hint:
		get_parent().toDisk = false
	
	if get_parent().wadInit == false:
		 get_parent().loadWads()
	
	
	if get_parent().toDisk or diskOverride == true:
		return load("res://wadFiles/sounds/" + name +".tres")
	else:
		if soundCache.has(name):
			return soundCache[name]
	

func createSkyMat(skyDoubleSided : bool =false):

	var texName = $"../ImageBuilder".getSkyboxTextureForMap()
	var matKey = texName+String(skyDoubleSided)
	
	if $"../ResourceManager".materialCache.has(matKey) and !get_parent().toDisk:
		return $"../ResourceManager".materialCache[matKey]
	
	var image : Image# = skyTexture.get_data()

	image = fetchTexture(texName,false).get_data()
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



