@tool
extends Node

var entityNode
var totalNpcCount = 0
var entityStrToNode = {}
var directoryInitialised = false


var idStrToKey = {}
var entityDirectory : Dictionary = {}
var entitiesOnDisk : Dictionary = {"notInit":true}
var whiteList = ["name","category","sourceScene","depends"]
var thingIdToEntStrId = {}
var categories = []
var thread
@onready var parent = get_parent()
@export var gunSheet = "res://addons/godotWad/resources/weapons.tres"
@export var gunSheetHexen = "res://addons/godotWad/resources/weaponsHexen.tres"

@onready var materialManager : Node = $"../MaterialManager"
@onready var resourceManager : Node=  $"../ResourceManager"
var thingsDictGenerator ={
	
	
	}

func _ready():
	set_meta("hidden",true)
	
	




func createOrphanOrEntityCache(toBeParentNode = null):
	if Engine.is_editor_hint(): 
		if get_parent().toDisk:#if we're to disk then no cache is created
			pass
			
		else:
			var cache = ENTG.fetchRuntimeEntityCacheNode(get_parent().mapNode,self,get_tree(),"Doom")#self will be referenced when creating entities in editor but no runtime.
			return cache
		
		
	else:
		return ENTG.fetchRuntimeOrphanEntityCacheNode(get_tree(),"Doom")





func getSpriteList(things) -> Dictionary:

	#initThingDirectory()
	var spriteList = []
	var animatedSpriteList = {}
	var spritesFOV = []
	var bitmapFonts = []
	var fonts = []
	for thing in things:
		var typeId = thing
		
		
		if !thingIdToEntStrId.has(typeId):
			continue
		var entryName : String = thingIdToEntStrId[typeId].to_lower()
		var entry : Dictionary = entityDirectory[entryName]
		
		
		if entry.has("sprites"):
			for spr in entry["sprites"]:
				if spr != "":
					if !spriteList.has(spr):
						spriteList.append(spr)
						
					
		var a = Time.get_ticks_msec()
		if entry.has("sourceScene"):
			if !entry["sourceScene"].is_empty():
				
				var ret = instanceGeneratorAndGetSprites(entry["sourceScene"])
				if !ret.is_empty():
					var sprites = ret["sprites"]
					
					if !sprites.is_empty():
						spriteList += ret["sprites"]
					
					
					animatedSpriteList.merge(ret["animatedSprites"])
					if ret.has("bitmapFont"):
						bitmapFonts += ["bitmapFont"]
						
					if ret.has("font"):
						fonts += [ret["font"]]
					
		
		if entry.has("depends"):
			var ents = []
			if typeof(entry["depends"]) == TYPE_STRING:
				ents = [entry["depends"]]
				
			if typeof(entry["depends"]) == TYPE_ARRAY:
				ents = entry["depends"]
			
			for entity in ents:
				var xe = generatorDict
				var entityEntry = entityDirectory[entity.to_lower()]

				if entityEntry.has("sourceScene"):
					var ret = instanceGeneratorAndGetSprites(entityEntry["sourceScene"])
					if !ret.is_empty():
						var sprites = ret["sprites"]
						
						for i in sprites:
							if !spriteList.has(i):
								spriteList.append(i)
									
						if !ret["animatedSprites"].is_empty():
							animatedSpriteList.merge(ret["animatedSprites"])
									
						if ret.has("spritesFOV"):
							if !ret["spritesFOV"].is_empty():
								spritesFOV += ret["spritesFOV"]
								
						if ret.has("bitmapFont"):
							bitmapFonts += ["bitmapFont"]
				
	
	for i in generatorDict.values():
		i.queue_free()
	
	generatorDict.clear()
	
	return {"sprites":spriteList,"animatedSprites":animatedSpriteList,"spritesFOV":spritesFOV,"bitmapFont":bitmapFonts,"fonts":fonts}


func getSpritesForEntity(entry):
	
	var spriteList = []
	var animatedSpriteList = {}
	
	if entry.has("sprites"):
		for spr in entry["sprites"]:
			if spr != "":
				if !spriteList.has(spr):
					spriteList.append(spr)
						
					
	var a = Time.get_ticks_msec()
	if entry.has("sourceScene"):
		if !entry["sourceScene"].is_empty():
			var ret = instanceGeneratorAndGetSprites(entry["sourceScene"])
			if !ret.is_empty():
				var sprites = ret["sprites"]
				
				if !sprites.is_empty():
					spriteList += ret["sprites"]
				
				
				
				if !ret["animatedSprites"].is_empty():
					animatedSpriteList.merge(ret["animatedSprites"])
				#	for i in ret["animatedSprites"]:
				#		animatedSpriteList.merge(i)
	
		
	if entry.has("depends"):
		var ents = []
		if typeof(entry["depends"]) == TYPE_STRING:
			ents = [entry["depends"]]
				
		if typeof(entry["depends"]) == TYPE_ARRAY:
			ents = entry["depends"]
		
		for entity in ents:
			var xe = generatorDict
			var entityEntry = entityDirectory[entity.to_lower()]

			if entityEntry.has("sourceScene"):
				var ret = instanceGeneratorAndGetSprites(entityEntry["sourceScene"])
				if !ret.is_empty():
					var sprites = ret["sprites"]
					
					if !sprites.is_empty():
						for i in sprites:
							if !spriteList.has(i):
								spriteList.append(i)
								
						if !ret["animatedSprites"].is_empty():
							animatedSpriteList.merge(ret["animatedSprites"])
							#for i in ret["animatedSprites"]:
							#	animatedSpriteList.merge(i)
								
								
	return {"sprites":spriteList,"animatedSprites":animatedSpriteList}

var generatorDict = {}
func instanceGeneratorAndGetSprites(srcScene : String) -> Dictionary:
	var generator : Node = null
	

	if !generatorDict.has(srcScene):
		var gen = load(srcScene).instantiate()
		
		if gen == null:
			return {}
			
		generatorDict[srcScene] = gen

	generator = generatorDict[srcScene].get_node_or_null("Generator")
	if generator == null:
		return {}
	
	
	if "loader" in generator:
		generator.loader = resourceManager
	
	var spriteList = []
	var animatedSpriteList = {}
	var spritesFOV = []
	var childDepends = []
	var fonts = []
	
	if "dependantChildren" in generator:
		for dc in generator.dependantChildren:
			childDepends.append(instanceGeneratorAndGetSprites(dc))
			
		
	
	if generator.has_method("getSpriteList"):
		var sl = generator.getSpriteList()
		
		if sl.has("sprites"):
			spriteList += sl["sprites"]
		
		if sl.has("spritesFOV"):
			spritesFOV += sl["spritesFOV"]
			
		if sl.has("animatedSprites"):
			animatedSpriteList.merge(sl["animatedSprites"])
		
		if sl.has("fonts"):
			fonts += (sl["fonts"])
		
	
	
	if generator.has_method("getAnimatedSpriteList"):
		animatedSpriteList.append(generator.getAnimatedSpriteList())
	
	if "entityDepends" in generator:
		for dependEntStrId in generator.entityDepends:
			var dependSrcScene : String = entityDirectory[dependEntStrId.to_lower()]["sourceScene"]
			
			var sl = instanceGeneratorAndGetSprites(dependSrcScene)
			spriteList += sl["sprites"]
	
	var ret= {"sprites":spriteList,"animatedSprites":animatedSpriteList,"spritesFOV":spritesFOV,"fonts":fonts}
	for i in childDepends:
		mergeDepends(i,ret)
	
	return ret
	


func initIdStrToKey() -> void:
	var thingSheet : gsheet = get_parent().thingSheet
	for i in thingSheet.getRowKeys():
		var line : Dictionary = thingSheet.getRow(i)
		
		if line.has("name"):
			idStrToKey[str_to_var(i)] = line["name"]
		 


func initThingDirectory(thingSheet : gsheet,entitySheetPaths : Array):

		
	categories = []
		
	var ids = thingSheet.getRowKeys()
	for id in ids:
		var x = thingSheet.getRow(id)
		if x.has("name"):
			thingIdToEntStrId[int(id)] = x["name"].to_lower()
	
	var entitySheets : Array[gsheet] = []
	
	for path : String in entitySheetPaths:
		entitySheets.append(load(path))

	for entitySheet : gsheet in entitySheets:
		var entries : Array[Dictionary] = entitySheet.getRowsAsArray()
		
		for entityEntry : Dictionary in entries:
			var entityName : String = entityEntry["name"].to_lower()
			
			entityDirectory[entityName] = entityEntry
			
			if entityDirectory.has("category"):
				if !categories.has(entityEntry["category"]):
					categories.append(entityEntry["category"])
	#if get_parent().isHexen:
		#t = load(gunSheetHexen)
	#else:
		#t = load(gunSheet)
	
	
	#for entry in t.getRowsAsArray():
		#var gunStr = entry["name"].to_lower()
		#thingDirectory[gunStr] = entry
		#if entry.has("category"):
			#if !categories.has(entry["category"]):
				#categories.append(entry["category"])
		
	
	for entry in thingSheet.getRowsAsArrayExcludeEmptyColumns():
		
		
		
		if entry.has("name"):
			var temp = entry.duplicate()
			
			#for i in temp.keys():
			#	if !whiteList.has(i):
			#		temp.erase(i)
			
			entityDirectory[entry["name"].to_lower()] = temp
			
		if entry.has("category"):
			if !categories.has(entry["category"]):
				categories.append(entry["category"])
			
	

func createThings(things : Array[Dictionary],cachParent = null):
	
	
	entityNode = Node3D.new()
	entityNode.name = "Entities"
	initIdStrToKey()
	var parent : Node = get_parent()
	var mapNode : Node = parent.mapNode
	mapNode.add_child(entityNode)
	
	var tree : SceneTree = get_tree()
	var gameName : String = parent.gameName
	var toDisk : bool = parent.toDisk
	
	var isEditor : bool = Engine.is_editor_hint()
	var difficulty = parent.difficultyFlags
	
	for thing : Dictionary in things:
		var idStr : String
		var thingFlag : int = 0

		
		if thing.has("flags"):
			thingFlag = thing["flags"]
		
		var skip : bool = true
		var thingEasy : bool  = (thingFlag & 0b1) !=0
		var thingMedium : bool= (thingFlag & 0b10) !=0
		var thingHard : bool= (thingFlag & 0b100) !=0
		var ambush : bool= (thingFlag  & 0b1000) != 0
		var thingMutliplayer : bool= (thingFlag & 0b10000) !=0
		
		
		if thing.has("skill1"):
			if thing["skill1"]:
				thingEasy = true
		
		if thing.has("skill2"):
			if thing["skill2"]:
				thingEasy = true
		
		if thing.has("skill3"):
			if thing["skill3"]:
				thingMedium = true
			
		if thing.has("skill4"):
			if thing["skill4"]:
				thingHard = true
		
		if difficulty == parent.DIFFICULTY.easy and thingEasy: skip = false
		if difficulty == parent.DIFFICULTY.medium and thingMedium: skip = false
		if difficulty == parent.DIFFICULTY.hard and thingHard: skip = false
		if thingMutliplayer : skip = true
		
		
		if skip == true and !thing.has("skill1"):
			continue
		

		if thing.has("name"):
			idStr = thing["name"]
		else:
			if idStrToKey.has(thing["type"]):
				idStr = idStrToKey[thing["type"]]
			else:
				continue
		
		var ent : Node
		
		if !thing.has("skill1"):
			#var thread = Thread.new()
			ent = ENTG.spawn(tree,idStr,thing["pos"],Vector3(0,thing["rot"],0),gameName,entityNode,toDisk,false,cachParent)
			#thread.start(ENTG.spawn.bind(tree,idStr,thing["pos"],Vector3(0,thing["rot"],0),gameName,entityNode,toDisk,false))
			#ent = thread.wait_to_finish()
		else:
			var pos : Vector3 = Vector3(thing["x"],-INF,thing["y"])
			ent = ENTG.spawn(tree,idStr,pos,Vector3(0,thing["angle"],0),gameName,entityNode,toDisk,false,cachParent)
			
			if thing.has("invisible"):
				ent.visible = !thing["invisible"]
	
		if ent == null:
			return
	
		if ambush:
			ent.set_meta("ambush",true)
			
		if "isStaticItem" in ent:
				ent.isStaticItem = true
		
		if "mapNode" in ent:
			ent.mapNode = mapNode
			
		if isEditor and toDisk:
			for i in ent.get_children():
				ent.remove_child(i)
				i.queue_free()

 

func hasEntity(idStr):
	#initThingDirectory()
	idStr == idStr.to_lower()
	return entityDirectory.has(idStr)



func getEntityInfo(idString : String):
	#initThingDirectory()
	
	if entityDirectory.has(idString.to_lower()):
		return entityDirectory[idString.to_lower()]
	
	return null
func getEntityDict():
	#initThingDirectory()
	return entityDirectory
	



func setEntityPos(entity : Node3D ,pos : Vector3,rot : Vector3,parentNode : Node) -> void:
	var s = Time.get_ticks_msec()
	var height : float = 0
	var col : CollisionShape3D =  entity.get_node_or_null("CollisionShape3D")

	

	if entity.has_meta("originAtFeet"):
		height = 0.0
	
	elif "spawnHeight" in entity:
		height = entity.spawnHeight
	elif "height" in entity:
		height = entity.height
			
	elif "texture" in entity:
		var t = entity.texture
		if t != null:
			height = entity.texture.get_size().y*get_parent().scaleFactor.y
				
	else:#this will be for origin at center objects
		var t : CollisionShape3D = WADG.getChildOfClass(entity,"CollisionShape3D")
		if t != null:
			height = WADG.getCollisionShapeHeight(t)
		

	var ret = getFloorHeightAtPoint(pos,entityNode)
	
	#if ret.has("height") and ret.has("ceilingHeight"):
		#if ret["height"] ==  ret["ceilingHeight"]:
			#if entity.get_class() == &"CharacterBody3D":
				#entity.axis_lock_motion_y = true
				
			
			
	
	if pos.y == -INF:
		pos.y = ret["height"]
	
	
	pos.y += (height/2.0)
	
	if ret.has("ceilingHeight") and entity.has_meta("float"):#we attach to ceiling
		pos.y = ret["ceilingHeight"]
		var x = entity.get_meta("height")
		pos.y -= entity.get_meta("height")
		#pos.y -= (height/2.0)
	

	if entity.has_meta("spawnOffset"):
		var off = entity.get_meta("spawnOffset")
		pos.x += off.x
		pos.y += off.y

	#if entity.is_inside_tree():this will stop error but break spawns
	if entity.is_inside_tree():
		entity.global_position = pos
	else:
		entity.position = pos
	entity.rotation_degrees = rot
	
	
	
	if entity.has_method("posSet"):
		entity.posSet()
		
	SETTINGS.incTimeLog(get_tree(),"posSetTime",s)

func createPlayerThings(typeInfo) -> Marker3D:
	
	
	
	var spawnLoc = Marker3D.new()
	spawnLoc.name = String(typeInfo["name"])

	var editorSprite = Sprite3D.new()
	
	if Engine.is_editor_hint():
		editorSprite.texture = preload("res://addons/godotWad/sprites/spawnIcon.png")
		editorSprite.script = load("res://addons/godotWad/src/editorOnlySprite.gd")
		editorSprite.pixel_size = 0.5 * get_parent().scaleFactor.x
		editorSprite.name = "editorSprite"
		editorSprite.position.y += (editorSprite.texture.get_height()/2.0) *get_parent().scaleFactor.x
		editorSprite.billboard = StandardMaterial3D.BILLBOARD_FIXED_Y
	
	spawnLoc.add_child(editorSprite)
	spawnLoc.set_meta("spawn",true)
	spawnLoc.set_meta("team",0)
	
	if typeInfo["name"] == "Deathmatch start":
		spawnLoc.set_meta("deathmatch",0)
	
	return spawnLoc
	

func createTeleports(typeInfo):
	
	var destNode = Node3D.new()
	destNode.name = typeInfo["name"]
	
	
	var sectorTagAtPos
	
	
	if typeInfo["sprites"].size() > 1:
		var sprite = createSprite(typeInfo["name"],typeInfo["sprites"][0])
		if sprite != null:
			var aT = resourceManager.fetchAnimatedSimple(typeInfo["sprites"][0]+"_anim",typeInfo["sprites"],5,true)
			if aT != null:
				sprite = Sprite3D.new() #this will need to be converted to a shader
				sprite.texture = aT
				sprite.position.y = (sprite.texture.get_size().y/2.0) * get_parent().scaleFactor.y
				sprite.modulate.a = 0.6
				sprite.visible = false
				destNode.add_child(sprite)
			

	
	#destNode.translation = typeInfo["pos"]
	
	
	#if get_parent().mapNode.has_meta("sectorPolyArr"):
		#var curMap = get_parent().mapNode
		#var t = WADG.getSectorInfoForPoint(curMap.get_meta("sectorPolyArr"),Vector2(typeInfo["pos"].x,typeInfo["pos"].z))
		#sectorTagAtPos = t["tag"]
#
		#if sectorTagAtPos == null:
			#return destNode
#
		#destNode.translation.y = t["floorHeight"]
	#else:
		#sectorTagAtPos = getSectorTagAtPos(typeInfo["pos"])
#
		#if sectorTagAtPos == null:
			#return destNode
#
		#destNode.translation.y = getFloorHeightAtPoint(typeInfo["pos"])["height"]
		
	
	#destNode.name = "Teleport Landing "+String(sectorTagAtPos)
	
	#destNode.add_to_group("destination:"+sectorTagAtPos,true)
	destNode.set_script(load("res://addons/godotWad/src/interactables/teleportDest.gd"))
	
	return destNode
	

func createFloater(typeInfo : Dictionary):
	var inst : Node = load("res://addons/godotWad/scenes/things/floater/floater.tscn").instantiate()
	var generator : Node = inst.get_node("Generator")
	
	generator.worldSprite = typeInfo["sprites"]
	generator.loader = resourceManager
	generator.scaleFactor = get_parent().scaleFactor
	generator.initialize()
	generator.queue_free()
	return inst


func createJumpBoost(typeInfo : Dictionary):
	var inst : Node = load("res://addons/godotWad/scenes/things/jumpBoost/jumpBoost.tscn").instantiate()
	var generator : Node = inst.get_node("Generator")
	inst.angle = typeInfo["persistant"]
	inst.power = typeInfo["give"]
	
	generator.activateSound = typeInfo["sounds"]
	
	if typeInfo.has("baseSprite"):
		var baseSprite : String = typeInfo["baseSprite"] 
		
		if typeInfo.has("frames"):
			
			var animSpeed = 4
			var frameArr = []
			for char in typeInfo["frames"]:
				frameArr.append(char)
				
			var sprArr = []
			
			for i in frameArr:
				sprArr.append(baseSprite + i + "0")
		
			generator.worldSprite = sprArr
			generator.animSpeed = typeInfo["animSpeed"]
			
			if typeInfo.has("autoPlay"):
				generator.autoPlay = typeInfo["autoPlay"]
	
	else:
		generator.worldSprite = typeInfo["sprites"]
	generator.loader = resourceManager
	generator.scaleFactor = get_parent().scaleFactor
	generator.initialize()
	generator.queue_free()
	return inst


func createDeco(typeInfo : Dictionary):
	var sprites = typeInfo["sprites"]
	var sprite  = null 
	
	sprite = createSprite(typeInfo["name"],typeInfo["sprites"][0])
	
	var offset = null
	
	if sprite.has_meta("spriteOffset"):
		offset = sprite.get_meta("spriteOffset") #* Vector2(get_parent().scaleFactor.x,get_parent().scaleFactor.y)
	
	if sprites.size() > 1:
		sprite = Sprite3D.new()#to do convert this to shader
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		materialManager.registerSprite3D(sprite)
		var aT =resourceManager.fetchAnimatedSimple(typeInfo["sprites"][0]+"_anim",sprites)
		
		
		sprite.texture = aT
		
	sprite.scale.y = 1.14

	
	
	#if sprite is Sprite3D:
	#	sprite.scale *= 3
	
	if sprite is Sprite3D:
		sprite.pixel_size = get_parent().scaleFactor.x
		if offset != null:
		
		
		#sprite.mesh.material.
			sprite.centered = false
			sprite.offset.x = -offset.x
			sprite.offset.y = offset.y -sprite.texture.get_size().y
	
	
	var spatial = Node3D.new()
	
	if typeInfo["float"] == WADG.DIR.UP:
		
		if sprite is MeshInstance3D:
			var texture = sprite.mesh.material.get_shader_parameter("texture_albedo")
			if texture != null:
				spatial.set_meta("float",WADG.DIR.UP)
				spatial.set_meta("height",texture.get_size().y*parent.scaleFactor.y)
		elif sprite.texture != null:
				spatial.set_meta("float",WADG.DIR.UP)
				spatial.set_meta("height",sprite.texture.get_size().y*parent.scaleFactor.y)
			
	
	spatial.add_child(sprite)
	

	
	if typeInfo.has("height"):
		if typeInfo.has("radius") and typeInfo["float"] != WADG.DIR.UP:
			spatial.remove_child(sprite)
			
			
			var height = typeInfo["height"]*parent.scaleFactor.y
			var body = createColForDeco(height,typeInfo["radius"]*parent.scaleFactor.x)
			
			var rayCast = RayCast3D.new()
			rayCast.set_script(load("res://addons/godotWad/scenes/dropper.gd"))
			body.add_child(rayCast)
			rayCast.position.y = height/2.0
			
			body.set_meta("height",height)
			#spatial.remove_child(sprite)
			#spatial.add_child(body)
			body.add_child(sprite)
			spatial = body
			
			
			
		
		
		if typeInfo["height"] == 0:
			return spatial
	elif typeInfo["float"] != WADG.DIR.UP:
		var rayCast = RayCast3D.new()
		rayCast.set_script(load("res://addons/godotWad/scenes/dropper.gd"))
		rayCast.height = 1
		spatial.add_child(rayCast)
		return spatial
	
	var x = spatial.get_child(2)
	return spatial
	
	#var staticBody = StaticBody3D.new()
	#var collisionShape = CollisionShape3D.new()
	#
	#collisionShape.shape = BoxShape3D.new()
	#staticBody.add_child(collisionShape)
	#staticBody.add_child(spatial)
	#
#
	#return staticBody


func createAnimated(animName,sprites):
	
	var aSprite = AnimatedSprite3D.new()
	aSprite.frames = SpriteFrames.new()
	
	
	
	
	for i in sprites.size():
		var sprName = sprites[i]
		var spr = createSprite(animName,sprName)
		
		if spr.has_meta("spriteOffset"):
			aSprite.set_meta("spriteOoffset",spr.get_meta("spriteOffset"))
		
		aSprite.frames.add_frame("default",spr.texture,i)
	
	return aSprite
	
	

#func createSprite(nodeName : String,textureName : String) -> Sprite3D:
	#
	#var node : Sprite3D = Sprite3D.new()
	#node.name = nodeName
	#node.pixel_size = get_parent().scaleFactor.x
	#
	#node.texture_filter = SETTINGS.getSetting(get_tree(),"textureFiltering")
#
	#node.texture = get_parent().get_node("ResourceManager").fetchDoomGraphic(textureName)
	#node.billboard = StandardMaterial3D.BILLBOARD_FIXED_Y
	#
	#var spriteOffsetCache = resourceManager.spriteOffsetCache
	#
	#if  spriteOffsetCache.has(textureName):
		#node.set_meta("spriteOffset", resourceManager.spriteOffsetCache[textureName])
	#
	#materialManager.registerSprite3D( node )
	#return node

func createSprite(nodeName : String,textureName : String): #-> Sprite3D:
	
	#var node : Sprite3D = Sprite3D.new()
	var mesh = MeshInstance3D.new()
	var quad = QuadMesh.new()
	var spr =  get_parent().get_node("ResourceManager").fetchDoomGraphic(textureName)
	var mat : Material = materialManager.fetchSpriteMaterial(textureName,spr,Color.WHITE)
	var spriteDim = Vector2.ZERO
	mesh.name = nodeName
	quad.material = mat
	mesh.mesh = quad
	
	
	if spr != null:
		spriteDim.x = spr.get_size().x* parent.scaleFactor.x
		spriteDim.y = spr.get_size().y* parent.scaleFactor.y
		
		
	if spriteDim.x != 0 or spriteDim.y != 0:
		mesh.custom_aabb.position.x = -ceil(spriteDim.x/2.0)
		mesh.custom_aabb.size.x = ceil(spriteDim.x)
		mesh.custom_aabb.size.y = ceil(spriteDim.y)
	
	#node.material.pixel_size = get_parent().scaleFactor.x
	
	#node.texture_filter = SETTINGS.getSetting(get_tree(),"textureFiltering")

	#node.texture = get_parent().get_node("ResourceManager").fetchDoomGraphic(textureName)
	#node.billboard = StandardMaterial3D.BILLBOARD_FIXED_Y
	
	var spriteOffsetCache = resourceManager.spriteOffsetCache
	
	if  spriteOffsetCache.has(textureName):
		mesh.set_meta("spriteOffset", resourceManager.spriteOffsetCache[textureName])
	
	#materialManager.registerSprite3D( node )
	return mesh

func setNodeHeight(node,pos):
	var h = getFloorHeightAtPoint(pos)["height"]
	h = node.to_local(Vector3(0,h,0)).y
	pos.y = h
	node.position = pos


func getFloorHeightAtPoint(point : Vector3, entityNodeI = null) -> Dictionary:
	
	var pointXZ : Vector2 = Vector2(point.x,point.z)
	var mapNode : Node = get_parent().mapNode
	
	if mapNode != null:
		if is_instance_valid(mapNode):
			if mapNode.has_meta("sectorPolyArr"):
				var t = WADG.getSectorInfoForPoint(mapNode,pointXZ)
				if t != null:
					return {"height":t["floorHeight"],"ceilingHeight":t["ceilingHeight"],"sector":t["sectorIdx"]}


	
	var rc : RayCast3D = RayCast3D.new()
	var pos : Vector3 = Vector3(point.x,-5000,point.z)
	
	rc.enabled = true
	rc.position = pos
	rc.target_position.y = -rc.position.y*2
	rc.collision_mask = 0
	rc.collision_mask = 32768

	
	var gameName : String = get_parent().gameName
	
	if entityNode == null and get_parent().mapNode == null:
		if ENTG.getLoader(get_tree(),gameName) == null:
			ENTG.createEntityCacheForGame(get_tree(),false,gameName,get_parent(),null)
		entityNode = ENTG.fetchRuntimeOrphanEntityCacheNode(get_tree(),gameName)
		#ENTG.createOrphanOrEntityCache()
	
	
	
	if entityNode == null:
		if is_instance_valid(entityNode):
			rc.queue_free()
		return {"height":0,"sector":null}
	
	if is_instance_valid(entityNode):
		if entityNode.is_inside_tree():
			if entityNode.get_world_3d() == null:
				rc.queue_free()
				return {"height":0,"sector":null}
		
	entityNode.add_child(rc)
	
	
	if entityNode.is_inside_tree():
		rc.force_raycast_update()
	
	
	
	var colY = rc.get_collision_point().y
	var gp = rc.get_collider()
 
	if rc.get_parent() != null:
		rc.get_parent().remove_child(rc)
		
	rc.queue_free()
	
	if gp == null:
		return {"height":colY,"sector":""}
	
	return {"height":colY,"sector":gp.name}


	

func getSectorTagAtPos(point):

	var rc = RayCast3D.new()
	var pos = Vector3(point.x,5000,point.z)
	rc.enabled = true
	rc.position = pos
	rc.target_position.y = -rc.position.y*2
	rc.set_collision_mask_value(0,0)
	rc.set_collision_mask_value(1,1)#only floors on this bit
	get_parent().mapNode.add_child(rc)
	rc.force_raycast_update()
	rc.queue_free()
	var collider = rc.get_collider()
	
	if collider == null:
		return
		
	if collider.get_parent().has_meta("sector"):
		var sectorNode = collider.get_parent().get_parent()
		var tag = sectorNode.get_meta("tag")
		return tag
	else:
		return null


	
func pickupCreationFunction(pickupScene,typeInfo) -> Node:
	var splitOffset = typeInfo["name"].find(" pickup")
	var gunName = typeInfo["name"].substr(0,splitOffset).to_lower()
	
	
	var gunInfo : Dictionary = entityDirectory[gunName.to_lower()]
	var inst : Node= load(gunInfo["sourceScene"]).instantiate()
	var gunGen : Node = inst.get_node("Generator")
	var worldSprite : Texture2D = resourceManager.fetchDoomGraphic(gunGen.worldSprite)
	var scaleFactor : Vector3 = get_parent().scaleFactor
	
	
	
	inst.queue_free()
	#pickupScene.get_node($MeshInstance3D).texture = worldSprite
	#pickupScene.get_node($MeshInstance3D).scale = scaleFactor.x * 0.8
	
	var mat : Material = materialManager.fetchSpriteMaterial(gunGen.worldSprite,worldSprite,Color.WHITE)
	var mesh : MeshInstance3D = pickupScene.get_node("MeshInstance3D")
	
	mesh.mesh.material = mat
	
	if pickupScene.get_node_or_null("Area3D") != null:
		pickupScene.get_node("Area3D").get_node("CollisionShape3D").shape.extents *= scaleFactor
	
	pickupScene.get_node("AudioStreamPlayer3D").stream = resourceManager.fetchSound(pickupScene.pickupSoundName)
	

	
	pickupScene.pickupEntityPath = WADG.destPath + get_parent().gameName + "/entities/"+gunInfo["category"]+"/"+gunInfo["name"]+".tscn"
	pickupScene.pickupEntityStr = gunName
	
	if get_parent().toDisk:
		pickupScene.pickupEntityPath = WADG.destPath +get_parent().gameName + "/entities/"+gunInfo["category"]+"/"+gunInfo["name"]+".tscn"
		#pickupScene.gunScene = gunInfo["category"]
#	else:
#
#		
#
	var h = WADG.getCollisionShapeHeight(pickupScene.get_node("Area3D/CollisionShape3D"))
	
	
	

	for i in pickupScene.get_children():
		if "position" in i:
			i.position.y = h/2.0
	
	
	return pickupScene


func giveCreationFunction(scene,typeInfo):
	var spr : Texture2D = null
	var sprArr = []
	
	if typeInfo.has("baseSprite"):
		var frames : Array = ["A"]
		var baseSprite : String = typeInfo["baseSprite"] 
		
		
		
		if typeInfo.has("frames"):
			
			var animSpeed = 4
			var frameArr = []
			for char in typeInfo["frames"]:
				frameArr.append(char)
				
			
			
			for i in frameArr:
				sprArr.append(baseSprite + i + "0")
		
			if sprArr.size() == 1:
				spr = resourceManager.fetchDoomGraphic(sprArr[0])
			else:
				if typeInfo.has("animSpeed"):
					animSpeed = typeInfo["animSpeed"]
				spr =resourceManager.fetchAnimatedSimple(sprArr[0],sprArr,animSpeed)
	
	else:
		if typeInfo["sprites"].size() == 1:
			spr = resourceManager.fetchDoomGraphic(typeInfo["sprites"][0])
		else:
			
			spr =resourceManager.fetchAnimatedSimple(typeInfo["sprites"][0],typeInfo["sprites"],)
	
	var mat : Material 
	
	if !typeInfo.has("baseSprite"):
		mat = materialManager.fetchSpriteMaterial(typeInfo["sprites"][0],spr,Color.WHITE)
	else:
		mat = materialManager.fetchSpriteMaterial(sprArr[0],spr,Color.WHITE)
		
	var mesh : MeshInstance3D = scene.get_node("MeshInstance3D")
	mesh.mesh.material = mat

	#mesh.position.y += spr.get_size().y*0.5*get_parent().scaleFactor.x

	
	
	var sound = null
	
	if typeInfo.has("sounds"):
		sound = resourceManager.fetchSound(typeInfo["sounds"])

	else:
		scene.pickupSound =resourceManager.fetchSound("DSITEMUP")
		sound = resourceManager.fetchSound("DSITEMUP")
		

	if typeInfo.has("give"):
		
		var giveEntry = typeInfo["give"]
		
		if typeof(giveEntry[0]) == TYPE_ARRAY:

			for sub in giveEntry:
				scene.giveString.append(sub[0])
				scene.giveAmount.append(sub[1])
				
				if sub.size() >= 3:
					scene.limit.append(sub[2])
				else:
					scene.limit.append(-1)
					
				if sub.size() >= 4:
					scene.uiTextureName.append(sub[3][0])
					scene.uiTarget.append(sub[3][1])
				else:
					scene.uiTextureName.append(null)
					scene.uiTarget.append(null)
				
				if giveEntry.has("persistant"):
					scene.persistant.append(giveEntry["persistant"])
				else:
					scene.persistant.append(true)
		else:
			scene.giveString.append(giveEntry[0])
			scene.giveAmount.append(giveEntry[1])

			if typeInfo["give"].size() >= 3:
				scene.limit.append(giveEntry[2])
			else:
					scene.limit.append(-1)
				
			if typeInfo["give"].size() >= 4:
				scene.uiTextureName.append(giveEntry[3][1])
				scene.uiTarget.append(giveEntry[3][0])
			else:
				scene.uiTextureName.append(null)
				scene.uiTarget.append(null)
				
			if typeInfo.has("persistant"):
				scene.persistant.append(typeInfo["persistant"])
			else:
				scene.persistant.append(true)
	
	if typeInfo.has("oscillationSpeed"):
		var oscSpeed = typeInfo["oscillationSpeed"]
		var oscHeight = typeInfo["oscillationHeight"]
		scene.oscillationHeight = oscHeight
		scene.oscillationSpeed = oscSpeed
	
	if typeInfo.has("%"):
		scene.countsTowardsPercent= typeInfo["%"]
	
	return scene



func createFromCode(typeInfo : Dictionary,function) -> Node3D:

	var destPath = WADG.destPath+get_parent().gameName +"/"+typeInfo["name"]+".tscn"
	var runtimeName =  resourceManager.getSceneRuntimeName(destPath)
	var scene : Node3D = call(function,typeInfo)
	
	scene.set_meta("gameName",get_parent().gameName.to_lower())
	scene.set_meta("entityName",typeInfo["name"].to_lower())
	
	if scene == null:
		return null
		

	
	return scene


func createFromScene(typeInfo : Dictionary,function) -> Node:
	
	var scene : Node
	var funco =function
	var resource =  ResourceLoader.load(typeInfo["sourceScene"],"",0)
	

	scene  = resource.duplicate(true).instantiate()#this fixes fist shooting sounds

	call(function,typeInfo,scene)

	scene.set_meta("gameName",get_parent().gameName.to_lower())
	scene.set_meta("entityName",typeInfo["name"].to_lower())

	return scene



func basicInstance(typeInfo,scene):
	if scene.get_node_or_null("Generator"):
		var generator = scene.get_node("Generator")
		if generator == null:
			print("scene:", "has no generator")
			return scene
		

		
		generator.loader = resourceManager
		if "entityLoader" in generator:
			generator.entityLoader = self
		generator.scaleFactor = get_parent().scaleFactor
		generator.initialize()
		
		
	if typeInfo.has("projectileNode"):
		if "projectile" in scene:
			scene.projectile = typeInfo["projectileNode"]
	

	return scene

func combineThingsDictAndGunsDict(things,guns):
	var gunPre = []#need to process guns first because pickup depends on them
	for gun in guns:
		guns[gun]["name"] = gun
		guns[gun]["pos"] = Vector3.ZERO
		guns[gun]["rot"] = 0
		gunPre.append(guns[gun])
		
	things = gunPre + things
	
	return things


func createEntityResourcesOnDisk(entStr,editorInterface):

	var res : Dictionary = {}
	
	
	res = fetchAllEntityDepends(entStr)
	
	fetchResourcesDisk(res)
	startFileWaitThread(editorInterface,false)

func  createFontResourcesOnDisk(fontName,editorInteface):
	resourceManager.createBitmapFontTextures(fontName,editorInteface)
	startFileWaitThread(editorInteface,false)
	

func startFileWaitThread(editorInterface,subWait):
	if !editorInterface.get_resource_filesystem().is_scanning():
		editorInterface.get_resource_filesystem().scan()
	thread = Thread.new()
	
	thread.start(Callable(resourceManager, "waitForFilesToExist").bind(editorInterface,subWait))


func fetchAllEntityDepends(entStr):
	entStr = entStr.to_lower()
	var entEntry = entityDirectory[entStr]
	var res = getDepends(entEntry["name"])
	

	if entEntry.has("depends"):#these ar ents that it's dependent on.
		if !entEntry["depends"].is_empty():
			if typeof(entEntry["depends"]) == TYPE_STRING:#if it's a single ent get its depends
					res = mergeDepends(res,getDepends(entEntry["depends"]))
						
			if typeof(entEntry["depends"]) == TYPE_ARRAY:#if it's multiple ents get all their depends
				for i in entEntry["depends"]:
					res = mergeDepends(res,getDepends(i))
					
	
	return res
	
func fetchResourcesDisk(res):
	
	if res.has("sprites"):
		for i in res["sprites"]:
			
			if i.find("_flipped") != -1:
				var resName = i.split("_flipped")
				resourceManager.fetchDoomGraphicDisk(resName[0],true,false)
				
			else:
				resourceManager.fetchDoomGraphicDisk(i,false,false)
				
				
	if res.has("animatedSprites"):
		for animName in res["animatedSprites"]:
			for i in res["animatedSprites"][animName]:
				resourceManager.fetchDoomGraphicDisk(i,false,false)
			#$"../ResourceManager".fetchAnimatedSimple(animName,res["animatedSprites"][animName])

	
	if res.has("flats"):
		for textureName in res["flats"]:
			resourceManager.fetchFlat(textureName)
		
	if res.has("patched"):
		for textureName in res["patched"]:
			resourceManager.fetchPatchedTexture(textureName)
	
	if res.has("fonts"):
		for fontName in res["fonts"]:
			for charEntry in get_parent().getFonts()[fontName].values():
				resourceManager.fetchDoomGraphicDisk(charEntry[0],false,false)
				
	if res.has("bitmapFont"):
		resourceManager.fetchBitmapFont(res["bitmapFont"])
	
	
func getDepends(entStr):
	entStr = entStr.to_lower()
	var entEntry = entityDirectory[entStr]
	var res = {}
	
	#spread sheet defined
	if entEntry.has("sprites"):
		for spr in entEntry["sprites"]:
			if spr != "":
				
				if !res.has("sprites"):
					res["sprites"] = []
				
				if !res["sprites"].has(spr):
					res["sprites"].append(spr)
	
	
	if !entEntry.has("sourceScene"):
		return res
		
	if entEntry["sourceScene"].is_empty():
		return res
	
	#generator defined
	var ret = instanceGeneratorAndGetSprites(entEntry["sourceScene"])
	
	if !ret.is_empty():
		for sprite in ret["sprites"]:
			
			if !res.has("sprites"):
				res["sprites"] = []
			
			if !res["sprites"].has(sprite):
				res["sprites"].append(sprite)
						
				
		for animName in ret["animatedSprites"]:
			if !res.has("animatedSprites"):
				res["animatedSprites"] = {}
			
			res["animatedSprites"][animName] = ret["animatedSprites"][animName]
			
		for fontName in ret["fonts"]:
			if !res.has("fonts"):
				res["fonts"] = []
			
			if !res["fonts"].has(fontName):
				res["fonts"].append(fontName)
				
		
	return res
	



func getResouceChunks(mapname,editorInterface,depends):
	
	var chunkSize = 100.0
	
	for key in depends.keys():
		var arr = depends[key]
		var numberOfChunks = ceil(arr.size()/chunkSize)
	
	
		if arr.size() >= chunkSize:
			for i in range(0,numberOfChunks):
				var chunk = arr.slice(i*chunkSize,(i*chunkSize)+chunkSize)
				resourceChunks.append({key:chunk})
				
				
		else:
			resourceChunks.append({key:depends[key]})
			
			
	
	return resourceChunks


var resourceChunks = []

func recursiveChunkLoadCall(editorInterface):
	if resourceChunks.size() > 0:
		#editorInterface.get_resource_filesystem().scan()
		fetchResourcesDisk(resourceChunks.pop_front())
		startFileWaitThread(editorInterface,true)
	else:
		print("file wait is done")
		resourceManager.emit_signal("fileWaitDone")


var emitPrimed = false
var counter = 0


func _physics_process(delta):
	
	counter += delta
	
	if counter <= 0.2:
		return
	
	waitingForFileTick()
	counter = 0
	


func waitingForFileTick():
	
	if !emitPrimed:
		return
	
	var resMan = resourceManager

	if resMan.waitingForFiles.size() > 0:
		while(resMan.waitingForFiles.size() > 0):
			if WADG.doesFileExist(resMan.waitingForFiles[0]):
				resMan.waitingForFiles.pop_front()
			else:
				break

		
	if resourceManager.waitingForFiles.size() == 0:
		resourceManager.emit_signal("fileWaitDone")
		emitPrimed = false
	

var chunkedThread : Thread = null
func createMapResourcesOnDisk(mapname,editorInterface,startFileWaitThread = true):
	

	resourceChunks = []
	if chunkedThread == null:
		chunkedThread = Thread.new()
	
	
	var depends = getMapDepends(mapname)
	
	var chunks = getResouceChunks(mapname,editorInterface,depends)
	resourceChunks = chunks

	
	
	for i in resourceChunks:
		fetchResourcesDisk(i)
	
	
	editorInterface.get_resource_filesystem().scan()
	
	emitPrimed =  true

	
func createColForDeco(height : float, width : float):
	var body = StaticBody3D.new()
	#var rayCast = RayCast3D.new()
	
	#rayCast.set_script(load("res://addons/godotWad/scenes/dropper.gd"))
	#body.add_child(rayCast)
	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.extents.y = height/2.0
	shape.shape.extents.z = width/2.0
	shape.shape.extents.x = width/2.0
	shape.position.y = height/2.0
	#rayCast.position.y = height/2.0
	
	body.add_child(shape)
	
	
	return body
	
func getMapDepends(mapname):
	get_parent().loadWads()
	var targetMap = get_parent().maps[mapname]
	targetMap["name"] = mapname
	var thingSheet : gsheet = get_parent().thingSheet
	
	$"../LumpParser".parseMap(targetMap)
	$"../LumpParser".postProc(targetMap)
	
	var fme = $"../LumpParser".flatMatEntries
	var wme =  $"../LumpParser".wallMatEntries
	
	var depends = {}
	for t in targetMap["thingsParsed"]:
		var type = t["type"]
		var entry = thingSheet.getRow(str(type))
		#var depends = fetchAllDepends(entry["name"].to_lower())
		depends = mergeDepends(depends,fetchAllEntityDepends(entry["name"].to_lower()))
	
	
	
	
	depends["flats"] = []
	
	for i in fme.keys():
		if !depends["flats"].has(i):
			depends["flats"].append(i)
	
	
	
	depends["patched"] = []
	
	
	for i in wme.keys():
		if !depends["patched"].has(i):
			depends["patched"].append(i)
	
	var skys : Array = []
	
	for i in get_parent().maps:
		if !skys.has($"../ImageBuilder".getSkyboxTextureForMap(i)):
			skys.append($"../ImageBuilder".getSkyboxTextureForMap(i))
	
	for i in skys:
		depends["patched"].append(i)
	

	return depends 
	

func mergeDepends(a,b):
	for key in a.keys():#for each key in dict
		
		for j in a[key]:
			if typeof(a[key]) == TYPE_ARRAY:#if the key points to an array
				
				if !b.has(key):#if b doesn't have this key then we create it 
					b[key] = []
				
				if !b[key].has(j):
					b[key].append(j)
					
			if typeof(a[key]) == TYPE_DICTIONARY:#if key ponits to a dict
				
				if !b.has(key):
					b[key] = {}
				
				if !b[key].has(j):
					b[key].merge({j:a[key][j]})
					
					
				
			
	return b
