@tool
extends Node

@onready var materialCache :Dictionary = {}
@onready var materialCacheDisk :Dictionary = {}

@onready var materialCacheGeom : Dictionary = {}

@onready var resourceManager = $"../ResourceManager"
@onready var imageBuilder = $"../ImageBuilder"
@onready var isEditor = Engine.is_editor_hint()
@onready var parent : WAD_Map = get_parent()

#var instancedShaderCache : Array[Shader] = []
var instancedSpriteShaderCache : Array[Shader] = []
var instancedGeomShaderCache : Array[Shader] = []
var instancedSkyShaderCache  : Array[Shader] = []
var instancedFOVShaderCache : Array[Shader] = []
var instancedUISpriteShaderCache : Array[Shader] = []
var instancedUICanvasItemCache : Array = []
var instancedSprite3D : Array[Sprite3D] = []

var allInstancedShaders : Array[Array] = [instancedSpriteShaderCache,instancedGeomShaderCache,instancedSkyShaderCache,instancedFOVShaderCache]

var unshaded = true
var settingsDict : Dictionary
enum SHADER_TYPE {
	GEOMTERY,
	SPRITE,
	SPRITE_FOV,
	SKY
}


var skyMatOneSided = null
var skyMatDoubleSided = null
var lastSkyName : String= ""

var geomShaders : Array[StringName]= ["res://addons/godotWad/shaders/geometry.gdshader","res://addons/godotWad/shaders/geometry_instanced.gdshader"]
var spriteShaders = ["res://addons/godotWad/shaders/8wayBillboard.gdshader"]
var skyboxShaders = ["res://addons/godotWad/shaders/cubemap.gdshader"]



func _ready():
	
	settingsDict = SETTINGS.getSettingsDict(get_tree())
	

var instancedUISpriteShaderCacheHash = 0

func _physics_process(delta):
	if isEditor:
		return
	
	instancedUISpriteShaderCacheHash = instancedUISpriteShaderCache.hash()
		


func fetchGeometryMaterial(textureName : String,texture : Texture2D, sectorLight : Color,scroll : Vector2 ,modulateAlpha : float, alphaDisabled : bool) -> Material:


	if texture == null:
		return null

	var useInstanceShaderParam = parent.useInstanceShaderParam
	var materialKey 

	if useInstanceShaderParam:
		materialKey = str(textureName) +"," + str(alphaDisabled)
	else:
		materialKey = str(useInstanceShaderParam) + "," + str(textureName) +"," + str(sectorLight)+ "," + str(scroll) + "," + str(modulateAlpha) + "," + str(alphaDisabled)
	

	if get_parent().toDisk == false:
		
		if materialCache.has(materialKey):
			return materialCache[materialKey]
		
		var mat = createGeometryMaterial(textureName,texture,sectorLight,scroll,modulateAlpha,alphaDisabled)
		materialCache[materialKey] = mat
		materialCacheGeom[materialKey] = mat
		if !instancedGeomShaderCache.has(mat.shader):
			instancedGeomShaderCache.append(mat.shader)
		return mat
	else:
		
		if materialCache.has(materialCacheDisk):
			return materialCache[materialCacheDisk]
		
		
		var baseMatOnDisk = WADG.destPath+get_parent().gameName+"/materials/" + textureName+".tres"
		if !WADG.doesFileExist(baseMatOnDisk):
			var mat = createGeometryMaterial(textureName,texture,Color(1,1,1),Vector2(0,0),1.0,false)
			if useInstanceShaderParam:
				mat.set_shader_parameter("texture_albedo" , texture)
				mat.set_shader_parameter("sectorLight",sectorLight)
				mat.set_shader_parameter("scroll",sectorLight)
			ResourceSaver.save(mat,baseMatOnDisk)
			
		var mat = load(baseMatOnDisk)#.duplicate()
		
		return mat



func fetchSpriteMaterial(textureName : String,texture : Texture,modulate : Color):
	var materialKey : String = textureName
	
	
	if modulate != Color.WHITE:
		materialKey += str(modulate)
	
	var material : Material
	
	
	if !get_parent().toDisk:
		
		if materialCache.has(materialKey):
			return materialCache[materialKey]
		
		material = createSpriteMaterial(textureName,texture,modulate)
		materialCache[materialKey] = material
		
		if instancedUISpriteShaderCache.has(material.shader):
			instancedUISpriteShaderCache.append(material.shader)
		
		return material
	else:
		var path = WADG.destPath+get_parent().gameName+"/materials/" + materialKey +".tres"
		if !WADG.doesFileExist(path):
			material = createSpriteMaterial(textureName,texture,modulate)
			ResourceSaver.save(material,path)
		
		return ResourceLoader.load(path)
				
	
func createSpriteMaterial(textureName : String,texture : Texture,modulate : Color) -> Material:
		
	var material = ShaderMaterial.new()
	material.shader = load("res://addons/godotWad/shaders/billboardBasic.gdshader")
	material.set_shader_parameter("texture_albedo" , texture)
	material.set_shader_parameter("pixelSize" ,Vector2(get_parent().scaleFactor.x,get_parent().scaleFactor.y) )
	material.set_shader_parameter("albedo" ,modulate)
	
	if !instancedSpriteShaderCache.has(material.shader):
		instancedSpriteShaderCache.append(material.shader)
	
	return material

func createFovMaterial(textureName : String,texture : Texture,offset : Vector2,modulate : Color) -> Material:
		
	var material = ShaderMaterial.new()
	material.shader = load("res://addons/godotWad/shaders/fov.gdshader")
	material.set_shader_parameter("texture_albedo" , texture)
	material.set_shader_parameter("pixelSize" ,Vector2(get_parent().scaleFactor.x,get_parent().scaleFactor.y)*2.5)
	material.set_shader_parameter("offset" ,offset )
	
	
	if !instancedFOVShaderCache.has(material.shader):
		instancedFOVShaderCache.append(material.shader)
		
	return material


func setFilter(shaderCode : String,filter : BaseMaterial3D.TextureFilter):
	
	var types : Array[String] = ["filter_nearest","filter_linear","filter_nearest_mipmap","filter_linear_mipmap","filter_nearest_mipmap_anisotropic","filter_linear_mipmap_anisotropic"]
	
	var targetType = types[filter]
	types.erase(targetType)
	for i in types:
		shaderCode = shaderCode.replace(i+",",targetType+",")
		shaderCode = shaderCode.replace(i+";",targetType+";")
	#if filter == CanvasItem.TEXTURE_FILTER_NEAREST:
		
	
	return shaderCode
	

func modifyShaderCode(shaderCode : String,textureFiltering :BaseMaterial3D.TextureFilter,disableAlpha : bool) -> String:
	shaderCode.find("render_mode")
	#var textureFiltering : BaseMaterial3D.TextureFilter =  
	shaderCode = setFilter(shaderCode,textureFiltering)

	
	var emmisionBasedLighting = parent.emmisionBasedLighting


	if disableAlpha:
		shaderCode = removeAlphaLine(shaderCode)
	
	
	if !emmisionBasedLighting:
		shaderCode = setUnshaded(shaderCode)
		
		shaderCode = shaderCode.replace("EMISSION =  tint * ALBEDO;","//EMISSION =  tint * ALBEDO;")
		shaderCode = shaderCode.replace("ALBEDO = albedo_tex.rgb;","ALBEDO = albedo_tex.rgb*sectorLight.rgb;")
		
	return shaderCode



func fetch8wayBillboardMaterial(spriteName: String,texture : Array[Texture2D],modulate : Color = Color.WHITE) -> Material:
	var materialKey =  spriteName + "-8way"
	if modulate != Color.WHITE:
		materialKey += str(modulate)
	
	if !get_parent().toDisk:
		
		
		
		if materialCache.has(materialKey):
			return materialCache[materialKey]
		
		var mat : Material = create8wayBillboardMaterial(materialKey,texture,modulate)
		materialCache[materialKey] = mat
		return mat
	else:
		var path = WADG.destPath+get_parent().gameName+"/materials/" + materialKey +".tres"
		if !WADG.doesFileExist(path):
			var material : Material = create8wayBillboardMaterial(materialKey,texture,modulate)
			ResourceSaver.save(material,path)

		
		return ResourceLoader.load(path)
	
#func createGeometryMaterial(textureName : String,texture,sectorLight : Color,scroll : Vector2,modulateAlpha : float,alphaDisabled : bool) -> Material:
func create8wayBillboardMaterial(textureName : String,texture : Array[Texture2D],modulate :Color):
	
	var mat : Material 
	
	mat = ShaderMaterial.new()
	
	
	var shader = fetchShader("res://addons/godotWad/shaders/8wayBillboard.gdshader",false)
	mat.shader = shader
	
	if !instancedSpriteShaderCache.has(shader):
		instancedSpriteShaderCache.append(shader)
	
	var dirs : Array[String] = ["S","SW","W","NW","N","NE","East","SE"]
	
	for idx in dirs.size():
		if idx < texture.size():
			mat.set_shader_parameter(dirs[idx],texture[idx])
	
	mat.set_shader_parameter("pixelSize" ,Vector2(get_parent().scaleFactor.x,get_parent().scaleFactor.y) )
	mat.set_shader_parameter("modulate" , modulate)
	return mat
	
	
	
	
func fetchFovSpriteMaterial(textureName : String,texture : Texture,offset : Vector2,modulate : Color):
	var materialKey : String = textureName
	var material : Material
	if materialCache.has(materialKey):
		return materialCache[materialKey]
	
	else:
		material = createFovMaterial(textureName,texture,offset,modulate)
		
	materialCache[materialKey] = material
	return material

func makeVarsInstanced(str : String):
	var targets = ["vec3 sectorLight","float alpha","vec2 scrolling"]
	

	
	for i in targets:
		var test = "instance uniform " +i
		
		if str.find(test) != -1:
			return str
		
		str = str.replace("uniform " + i,"instance uniform " + i)
	
	
	

	
	return str
	
func removeAlphaLine(str : String) -> String:
	

	var a = str.find("ALPHA ")
	var b = str.find("\n",a)
	
	if a== -1 or b == -1:
		return str
	
	str =  str.erase(a,b-a)
	
	a = str.find("ALPHA_SCISSOR_THRESHOLD ")
	b = str.find("\n",a)
	str =  str.erase(a,b-a)
	
	return str
	
	
func setUnshaded(str : String) -> String:
	
	var a = str.find("render_mode")
	var b = str.find(";",a)
	
	
	if str.substr(a,b-a).find("unshaded") != -1:
		return str
	
	str = str.insert(b,",unshaded")
	return str

func fetchShader(basePath : String,alphaDisabled : bool):
	
	var useInstanceShaderParam = parent.useInstanceShaderParam
	
	if basePath == "res://addons/godotWad/shaders/geometry.gdshader" and useInstanceShaderParam:
		basePath = "res://addons/godotWad/shaders/geometry_instanced.gdshader"
	
	if !parent.toDisk:
		
		


		var firstInstance : bool = !ResourceLoader.has_cached(basePath)
		var shader : Shader = load(basePath)
		
		if firstInstance:
			var shaderCode : String = shader.get_code()
			
			shaderCode = modifyShaderCode(shaderCode,SETTINGS.getSetting(get_tree(),"textureFiltering"),alphaDisabled)
			shader.code = shaderCode
			
		return shader
	else:
		var shaderName : String = basePath.get_file().split(".")[0]
		var path = WADG.destPath+get_parent().gameName+"/shaders/" + shaderName + "-" + str(alphaDisabled) +".gdshader"
		if !WADG.doesFileExist(path):
			
			
			var shader : Shader = load(basePath)
			var shaderCode : String = shader.get_code()
			#if is_inside_tree():
			#	shaderCode = SETTINGS.getSetting(get_tree(),"textureFiltering")
			var shaderNew = Shader.new()
			var textureFiltering = 0
			
			if is_inside_tree():
				textureFiltering = SETTINGS.getSetting(get_tree(),"textureFiltering")
				
			shaderCode = modifyShaderCode(shaderCode,textureFiltering,alphaDisabled)
			
			
			shaderNew.code = shaderCode
			
			var err = ResourceSaver.save(shaderNew,path)

			
		return ResourceLoader.load(path)
			

func createGeometryMaterial(textureName : String,texture,sectorLight : Color,scroll : Vector2,modulateAlpha : float,alphaDisabled : bool) -> Material:
	var useInstanceShaderParam = parent.useInstanceShaderParam
	var mat : Material 
	
	mat = ShaderMaterial.new()
	var shader : Shader = fetchShader("res://addons/godotWad/shaders/geometry.gdshader",alphaDisabled)
	mat.shader = shader
	
	mat.set_shader_parameter("texture_albedo" , texture)
	
	if !useInstanceShaderParam and !(isEditor and !parent):
		
		mat.set_shader_parameter("sectorLight",sectorLight)
		mat.set_shader_parameter("scroll",scroll)
		if !alphaDisabled:
			mat.set_shader_parameter("alpha",modulateAlpha)

	return mat



func customResourceSave(outPath:String,path:String,tintR :float,tintG:float,tintB:float,tintA:float,alpha:float,scrollX:float,scrollY:float,uid):
	var file = FileAccess.open("res://addons/godotWad/materialTresSettings.txt", FileAccess.READ)
	var content = file.get_as_text()
	content = content % [ResourceUID.id_to_text(uid),path,uid,str(tintR),str(tintG),str(tintB),str(tintA),str(alpha),str(scrollX),str(scrollY),uid]
	file.close()
	
	
	file = FileAccess.open(outPath,FileAccess.WRITE)
	file.store_string(content)
	file.close()

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

	if !ResourceLoader.exists(path):
		
		var mat = createSkyMat(texName,skyDoubleSided)
		var err = ResourceSaver.save(mat,path)


	var ret = load(path)
	return ret
	
func createSkyMat(texName : String,skyDoubleSided : bool =false):
	var matKey = texName+str(skyDoubleSided)
	if materialCache.has(matKey) and !get_parent().toDisk:
		return materialCache[matKey]
	
	var image : Image
	var txt = resourceManager.fetchPatchedTexture(texName,false)
	if txt == null:
		return
	#image = txt.get_data()
	image = txt.get_image()
	
	var colArr : PackedByteArray = []
	

	var srcRectA = Rect2(Vector2(0,0),Vector2(128,128))
	var srcRectB = Rect2(Vector2(128,0),Vector2(128,128))
	
	
	
	var imageTop =imageBuilder.createTopImage(image)
	var imageBottom = imageBuilder.createBottomImage(image)
	var imageLeft = image.get_region(srcRectA)
	var imageRight = image.get_region(srcRectB)
	var imageFront = imageLeft.duplicate()
	var imageBack = imageRight.duplicate()
	
	
	imageBack.flip_x()
	imageLeft.flip_x()

	var cubemap = imageBuilder.createCubemap(imageLeft,imageRight,imageTop,imageBottom,imageFront,imageBack)
	
	var mat = ShaderMaterial.new()
	

	if skyDoubleSided:
	#	mat.shader = cubeMapShaderOneSided
		mat.shader = fetchShader("res://addons/godotWad/shaders/cubemap.gdshader",false)
	else:
		#mat.shader = cubeMapShaderOneSided
		mat.shader = fetchShader("res://addons/godotWad/shaders/cubemapOneSided.gdshader",false)
		
	
	mat.set_shader_parameter("cube_map",cubemap)
	
	if !get_parent().toDisk:
		materialCache[matKey] = mat
	
	if !instancedSkyShaderCache.has(mat.shader):
		instancedSkyShaderCache.append(mat.shader)
	
	return mat


func updateTextureFiltering():
	
	for i in instancedGeomShaderCache:
		var code = i.get_code()
		i.code = modifyShaderCode(code,SETTINGS.getSetting(get_tree(),"textureFilteringGeometry"),false)
	
	
	for i in instancedSpriteShaderCache:
		var code = i.get_code()
		i.code = modifyShaderCode(code,SETTINGS.getSetting(get_tree(),"textureFilteringSprite"),false)
	
	for i in instancedSkyShaderCache:
		var code = i.get_code()
		i.code = modifyShaderCode(code,SETTINGS.getSetting(get_tree(),"textureFilteringSky"),false)
		
	for i in instancedFOVShaderCache:
		var code = i.get_code()
		i.code = modifyShaderCode(code,SETTINGS.getSetting(get_tree(),"textureFilteringFov"),false)
		
	
	for i in instancedUISpriteShaderCache:
		var code = i.get_code()
		var test = SETTINGS.getSetting(get_tree(),"textureFilteringUI")
		i.code = modifyShaderCode(code,SETTINGS.getSetting(get_tree(),"textureFilteringUI"),false)
		
	for i : Sprite3D in instancedSprite3D:
		i.texture_filter = SETTINGS.getSetting(get_tree(),"textureFilteringSprite")
	
	
	
	
	for i  in instancedUICanvasItemCache:
		if i is CanvasItem:
			
			var value =  SETTINGS.getSetting(get_tree(),"textureFilteringUI")
			if value == BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST : value = CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST
			if value == BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR : value = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR
			
			if value == BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS : value = CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			if value == BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS : value = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			
			if value == BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC : value = CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
			if value == BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC : value = CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			
			i.texture_filter = value
			
			
		elif i is Viewport:
			
			var value = (SETTINGS.getSetting(get_tree(),"textureFilteringUI"))
			
			if value == BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST : value = Viewport.DefaultCanvasItemTextureFilter.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
			elif value == BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR : value = Viewport.DefaultCanvasItemTextureFilter.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
			
			
			elif value == BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS : value = Viewport.DefaultCanvasItemTextureFilter.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			elif value == BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS : value = Viewport.DefaultCanvasItemTextureFilter.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			
			elif value == BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC : value =  Viewport.DefaultCanvasItemTextureFilter.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			elif value == BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC : value = Viewport.DefaultCanvasItemTextureFilter.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			
			i.canvas_item_default_texture_filter = value
		
	
func registerSprite3D( sprite: Sprite3D ):
	if !instancedSprite3D.has(sprite):
		instancedSprite3D.append(sprite)
		
		sprite.texture_filter = SETTINGS.getSetting(get_tree(),"textureFilteringSprite")
	
