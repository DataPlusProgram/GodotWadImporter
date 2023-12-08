tool
extends Node

var entityNode
var totalNpcCount = 0
var entityStrToNode = {}
var directoryInitialised = false
var thingSheet = load("res://addons/godotWad/resources/things.tres")
var hexenThingSheet = load("res://addons/godotWad/resources/hexenThings.tres")

var idStrToKey = {}
var thingDirectory : Dictionary = {}
var entitiesOnDisk : Dictionary = {"notInit":true}

var thingIdToEntStrId = {}
var categories = []
var thread
export var gunSheet = "res://addons/godotWad/resources/weapons.tres"


var thingsDictGenerator ={
	
	
	}

func _ready():
	set_meta("hidden",true)
	
	




func createOrphanOrEntityCache(var toBeParentNode = null):
	if Engine.editor_hint: 
		if get_parent().toDisk:#if we're to disk then no cache is created
			pass
			
		else:
			var cache = ENTG.fetchRuntimeEntityCacheNode(get_parent().mapNode,self,get_tree(),"Doom")#self will be referenced when creating entities in editor but no runtime.
			return cache
		
		
	else:
		return ENTG.fetchRuntimeOrphanEntityCacheNode(get_tree(),"Doom")





func getSpriteList(things) -> Dictionary:
	
	
	
	initThingDirectory()
	var spriteList = []
	var animatedSpriteList = {}
	var spritesFOV = []
	var bitmapFonts = []
	for thing in things:
		var typeId = thing
		
		
		if !thingIdToEntStrId.has(typeId):
			continue
		var entryName : String = thingIdToEntStrId[typeId].to_lower()
		var entry : Dictionary = thingDirectory[entryName]
		
		
		if entry.has("sprites"):
			for spr in entry["sprites"]:
				if spr != "":
					if !spriteList.has(spr):
						spriteList.append(spr)
						
					
		var a = OS.get_system_time_msecs()
		if entry.has("sourceScene"):
			if !entry["sourceScene"].empty():
				
				var ret = instanceGeneratorAndGetSprites(entry["sourceScene"])
				if !ret.empty():
					var sprites = ret["sprites"]
					
					if !sprites.empty():
						spriteList += ret["sprites"]
					
					
					animatedSpriteList.merge(ret["animatedSprites"])
					if ret.has("bitmapFont"):
						bitmapFonts += ["bitmapFont"]
		
		if entry.has("depends"):
			var ents = []
			if typeof(entry["depends"]) == TYPE_STRING:
				ents = [entry["depends"]]
				
			if typeof(entry["depends"]) == TYPE_ARRAY:
				ents = entry["depends"]
			
			for entity in ents:
				var xe = generatorDict
				var entityEntry = thingDirectory[entity.to_lower()]

				if entityEntry.has("sourceScene"):
					var ret = instanceGeneratorAndGetSprites(entityEntry["sourceScene"])
					if !ret.empty():
						var sprites = ret["sprites"]
						
						for i in sprites:
							if !spriteList.has(i):
								spriteList.append(i)
									
						if !ret["animatedSprites"].empty():
							animatedSpriteList.merge(ret["animatedSprites"])
									
						if ret.has("spritesFOV"):
							if !ret["spritesFOV"].empty():
								spritesFOV += ret["spritesFOV"]
								
						if ret.has("bitmapFont"):
							bitmapFonts += ["bitmapFont"]
				
	
	for i in generatorDict.values():
		i.queue_free()
	
	generatorDict.clear()
	
	return {"sprites":spriteList,"animatedSprites":animatedSpriteList,"spritesFOV":spritesFOV,"bitmapFont":bitmapFonts}


func getSpritesForEntity(entry):
	
	var spriteList = []
	var animatedSpriteList = {}
	
	if entry.has("sprites"):
		for spr in entry["sprites"]:
			if spr != "":
				if !spriteList.has(spr):
					spriteList.append(spr)
						
					
	var a = OS.get_system_time_msecs()
	if entry.has("sourceScene"):
		if !entry["sourceScene"].empty():
			var ret = instanceGeneratorAndGetSprites(entry["sourceScene"])
			if !ret.empty():
				var sprites = ret["sprites"]
				
				if !sprites.empty():
					spriteList += ret["sprites"]
				
				
				
				if !ret["animatedSprites"].empty():
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
			var entityEntry = thingDirectory[entity.to_lower()]

			if entityEntry.has("sourceScene"):
				var ret = instanceGeneratorAndGetSprites(entityEntry["sourceScene"])
				if !ret.empty():
					var sprites = ret["sprites"]
					
					if !sprites.empty():
						for i in sprites:
							if !spriteList.has(i):
								spriteList.append(i)
								
						if !ret["animatedSprites"].empty():
							animatedSpriteList.merge(ret["animatedSprites"])
							#for i in ret["animatedSprites"]:
							#	animatedSpriteList.merge(i)
								
								
	return {"sprites":spriteList,"animatedSprites":animatedSpriteList}

var generatorDict = {}
func instanceGeneratorAndGetSprites(var srcScene : String) -> Dictionary:
	var generator : Node = null
	
	
	if !generatorDict.has(srcScene):
		var gen = load(srcScene).instance()
		
		if gen == null:
			return {}
			
		generatorDict[srcScene] = gen

	generator = generatorDict[srcScene].get_node_or_null("Generator")
	if generator == null:
		return {}
	
	var spriteList = []
	var animatedSpriteList = {}
	var spritesFOV = []
	var childDepends = []
	
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
	
	
	if generator.has_method("getAnimatedSpriteList"):
		animatedSpriteList.append(generator.getAnimatedSpriteList())
	
	if "entityDepends" in generator:
		for dependEntStrId in generator.entityDepends:
			var dependSrcScene : String = thingDirectory[dependEntStrId.to_lower()]["sourceScene"]
			
			var sl = instanceGeneratorAndGetSprites(dependSrcScene)
			spriteList += sl["sprites"]
	
	var ret= {"sprites":spriteList,"animatedSprites":animatedSpriteList,"spritesFOV":spritesFOV}
	for i in childDepends:
		mergeDepends(i,ret)
	
	return ret
	


func initIdStrToKey():
	for i in thingSheet.getRowKeys():
		var line : Dictionary = thingSheet.getRow(i)
		
		if line.has("name"):
			idStrToKey[str2var(i)] = line["name"]
		 


func initThingDirectory():
	if directoryInitialised:
		return
		
		
	categories = []
		
	var ids = thingSheet.getRowKeys()
	for id in ids:
		var x = thingSheet.getRow(id)
		if x.has("name"):
			thingIdToEntStrId[int(id)] = x["name"].to_lower()
	
	
	
	var t = load(gunSheet)
	
	
	for entry in t.getRowsAsArray():
		var gunStr = entry["name"].to_lower()
		thingDirectory[gunStr] = entry
		if entry.has("category"):
			if !categories.has(entry["category"]):
				categories.append(entry["category"])
		
	
	for entry in thingSheet.getRowsAsArrayExcludeEmptyColumns():
		
		if entry.has("name"):
			thingDirectory[entry["name"].to_lower()] = entry
			
		if entry.has("category"):
			if !categories.has(entry["category"]):
				categories.append(entry["category"])
			
	directoryInitialised = true
	

func createThings(things):
	
	#fetchEntityCacheNode()
	entityNode = Spatial.new()
	entityNode.name = "Entities"
	initIdStrToKey()
	
	var t = get_parent().mapNode
	t.add_child(entityNode)
	
	
	for thing in things:
		var entry : Dictionary = thing
		var attributes : Dictionary = {}
		var idStr : String
		
		var difficulty = get_parent().difficultyFlags
		var thingFlag = entry["flags"]
		
		var skip = true
		
		
		var thingEasy = (thingFlag & 0b1) !=0
		var thingMedium = (thingFlag & 0b10) !=0
		var thingHard = (thingFlag & 0b100) !=0
		var thingMutliplayer = (thingFlag & 0b10000) !=0
		
		
		if entry.has("category"):
			breakpoint
		if difficulty == get_parent().DIFFICULTY.easy and thingEasy: skip = false
		if difficulty == get_parent().DIFFICULTY.medium and thingMedium: skip = false
		if difficulty == get_parent().DIFFICULTY.hard and thingHard: skip = false
	
		if thingMutliplayer : skip = true
		
		if skip == true:
			continue
		
		if thing.has("name"):
			idStr = thing["name"]
		else:
			if idStrToKey.has(thing["type"]):
				idStr = idStrToKey[thing["type"]]
			else:
				return

		var ent = ENTG.spawn(get_tree(),idStr,thing["pos"],Vector3(0,thing["rot"],0),get_parent().gameName,entityNode,get_parent().toDisk)
		
		if Engine.is_editor_hint() and get_parent().toDisk:
			for i in ent.get_children():
				ent.remove_child(i)
				i.queue_free()

 

func hasEntity(var idStr):
	initThingDirectory()
	idStr == idStr.to_lower()
	var x = thingDirectory.has(idStr)
	return thingDirectory.has(idStr)



func getEntityInfo(idString : String):
	initThingDirectory()
	
	if thingDirectory.has(idString.to_lower()):
		return thingDirectory[idString.to_lower()]
	
	return null
func getEntityDict():
	initThingDirectory()
	return thingDirectory
	
func createEntity(var idString):
	var entry = thingDirectory[idString.to_lower()]
	
	var ent = null
	
	if get_parent().npcsDisabled:
		if entry.has("category"):
			if entry["category"] == "npcs":
				return null
	
	if entry.has("depends"):
		if typeof(entry["depends"]) == TYPE_ARRAY:
			for i in entry["depends"]:
				var t = get_tree()
				ENTG.fetchEntity(i,get_tree(),get_parent().gameName,get_parent().toDisk).queue_free()#look into deleting this
		else:
			var t = get_tree()
			ENTG.fetchEntity(entry["depends"],get_tree(),get_parent().gameName,get_parent().toDisk).queue_free()#look into delteing this

	if entry.has("func"):
		if !entry["func"].empty():
			var function = entry["func"]
			var funco = funcref(self,function)
			var functionName = funco.function

			if functionName!= "":
				ent = createFromCode(entry,funco)
				if ent == null:
					breakpoint



	elif entry.has("creationFunction"):
		if !entry["creationFunction"].empty():
			ent = createFromScene(entry,entry["creationFunction"])
			if ent == null:
				breakpoint
			

	elif entry.has("sourceScene"):
		if !entry["sourceScene"].empty():
			ent = createFromScene(entry,"basicInstance")
			if ent == null:
				breakpoint
	else:
		print("no creation found")
		return
			
	
	ent.name = idString
	
	
	
	return ent



func setEntityPos(entity : Spatial ,pos : Vector3,rot : Vector3,parentNode : Node) -> void:
	var s = OS.get_system_time_msecs()
	var height : float = 0
	var col : CollisionShape =  entity.get_node_or_null("CollisionShape")

	

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
		var t : CollisionShape = WADG.getChildOfClass(entity,"CollisionShape")
		if t != null:
			height = WADG.getCollisionShapeHeight(t)
		

	var ret = getFloorHeightAtPoint(pos,entityNode)

	if ret.has("height") and ret.has("ceilingHeight"):
		if ret["height"] ==  ret["ceilingHeight"]:
			if entity.get_class() == "KinematicBody":
				entity.axis_lock_motion_y = true
				
			
			
	
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

	entity.translation = pos
	
	entity.rotation_degrees = rot
	
	
	if entity.has_method("posSet"):
		entity.posSet()
		
	WADG.incTimeLog(get_tree(),"posSetTime",s)

func createPlayerThings(typeInfo):
	
	
	
	
	var index = 0
	
	
	var spawnLoc = Position3D.new()
	spawnLoc.name = String(typeInfo["name"])

		
	var editorSprite = Sprite3D.new()
	editorSprite.texture = preload("res://addons/godotWad/sprites/spawnIcon.png")
	editorSprite.script = load("res://addons/godotWad/src/editorOnlySprite.gd")
	#editorSprite.spritePath = "res://addons/godotWad/sprites/spawnIcon.png"
	editorSprite.pixel_size = 0.5 * get_parent().scaleFactor.x
	editorSprite.name = "editorSprite"
	editorSprite.translation.y += (editorSprite.texture.get_height()/2.0) *get_parent().scaleFactor.x
	editorSprite.billboard = SpatialMaterial.BILLBOARD_FIXED_Y
	
	spawnLoc.add_child(editorSprite)
	spawnLoc.set_meta("spawn",true)
	spawnLoc.set_meta("team",0)

	return spawnLoc
	

func createTeleports(typeInfo):
	
	var destNode = Spatial.new()
	destNode.name = typeInfo["name"]
	
	
	var sectorTagAtPos
	#destNode.translation = typeInfo["pos"]
	
	
#	if get_parent().mapNode.has_meta("sectorPolyArr"):
#		var curMap = get_parent().mapNode
#		var t = WADG.getSectorInfoForPoint(curMap.get_meta("sectorPolyArr"),curMap.get_meta("polyGrid"),curMap.get_meta("polyIdxToInfo"),curMap.get_meta("polyBB"),Vector2(typeInfo["pos"].x,typeInfo["pos"].z))
#		sectorTagAtPos = t["tag"]
#
#		if sectorTagAtPos == null:
#			return destNode
#
#		destNode.translation.y = t["floorHeight"]
#	else:
#		sectorTagAtPos = getSectorTagAtPos(typeInfo["pos"])
#
#		if sectorTagAtPos == null:
#			return destNode
#
#		destNode.translation.y = getFloorHeightAtPoint(typeInfo["pos"])["height"]
		
	
	#destNode.name = "Teleport Landing "+String(sectorTagAtPos)
	
	#destNode.add_to_group("destination:"+sectorTagAtPos,true)
	destNode.set_script(load("res://addons/godotWad/src/interactables/teleportDest.gd"))

	return destNode
	

func createDeco(typeInfo):
	var sprites = typeInfo["sprites"]
	var sprite : Sprite3D = null 
	
	sprite = createSprite(typeInfo["name"],typeInfo["sprites"][0])
	
	if sprites.size() > 1:
		var anim = AnimatedSprite3D.new()
		var aT = $"../ResourceManager".fetchAnimatedSimple(typeInfo["sprites"][0]+"_anim",sprites)
		sprite.texture = aT
		
	sprite.scale.y = 1.14

	var offset = null
	
	if sprite.has_meta("spriteOffset"):
		offset = sprite.get_meta("spriteOffset") #* Vector2(get_parent().scaleFactor.x,get_parent().scaleFactor.y)
	else:
		print("doesn't have spriteOffset")

	
	if offset != null:
		sprite.centered = false
		sprite.offset.x = -offset.x
		sprite.offset.y = offset.y -sprite.texture.get_size().y
	
	
	var spatial = Spatial.new()
	
	if typeInfo["float"] == WADG.DIR.UP:
		if sprite.texture != null:
			spatial.set_meta("float",WADG.DIR.UP)
			spatial.set_meta("height",sprite.texture.get_size().y*get_parent().scaleFactor.y)
	
	spatial.add_child(sprite)

	
	if typeInfo.has("height"):
		if typeInfo["height"] == 0:
			return spatial
	else:
		return spatial
	
	
	
	return spatial
	
	var staticBody = StaticBody.new()
	var collisionShape = CollisionShape.new()
	collisionShape.shape = BoxShape.new()
	 
	
	

	staticBody.add_child(collisionShape)
	staticBody.add_child(spatial)
	
	
	staticBody
	return staticBody


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
	
	

func createBarrel(typeInfo):
	pass




func npcCreationFunction(typeInfo,pickupScene):
	breakpoint


		
func createSprite(nodeName,textureName) -> Sprite3D:
	
	var node = Sprite3D.new()
	node.name = nodeName
	node.pixel_size = 1*get_parent().scaleFactor.x
	var t = get_parent().get_node("ResourceManager").fetchDoomGraphic(textureName)
	node.texture = t
	node.billboard = SpatialMaterial.BILLBOARD_FIXED_Y
	if  $"../ResourceManager".spriteOffsetCache.has(textureName):
		node.set_meta("spriteOffset", $"../ResourceManager".spriteOffsetCache[textureName])
	return node

func setNodeHeight(node,pos):
	var h = getFloorHeightAtPoint(pos)["height"]
	h = node.to_local(Vector3(0,h,0)).y
	pos.y = h
	node.translation = pos

func getFloorHeightAtPoint2D(point : Vector2):
	
	var d = get_parent().mapNode.get_node("floorPlan").getAt(point)
	#breakpoint
	

func getFloorHeightAtPoint(point : Vector3,var entityNodeI = null) -> Dictionary:
	var pointXZ = Vector2(point.x,point.z)
	
	if get_parent().mapNode != null:
		if is_instance_valid(get_parent().mapNode):
			if get_parent().mapNode.has_meta("sectorPolyArr"):
				var curMap = get_parent().mapNode
				var t = WADG.getSectorInfoForPoint(curMap,pointXZ)
				if t != null:
					return {"height":t["floorHeight"],"ceilingHeight":t["ceilingHeight"],"sector":t["sectorIdx"]}


	
	var rc : RayCast = RayCast.new()
	var pos : Vector3 = Vector3(point.x,-5000,point.z)
	rc.enabled = true
	rc.translation = pos
	rc.cast_to.y = -rc.translation.y*2
	rc.collision_mask = 0
	rc.collision_mask = 32768

	#entityNode.call_deferred("add_child",rc)
	
	var gameName = get_parent().gameName
	
	if entityNode == null and get_parent().mapNode == null:
		if ENTG.getCreatorScript(get_tree(),gameName) == null:
			ENTG.createEntityCacheForGame(get_tree(),false,gameName,self,null)
		entityNode = ENTG.fetchRuntimeOrphanEntityCacheNode(get_tree(),gameName)
		#ENTG.createOrphanOrEntityCache()
	
	
	
	if entityNode == null:
		if is_instance_valid(entityNode):
			rc.queue_free()
			return {"height":0,"sector":null}
	
	if entityNode.get_world() == null:
		rc.queue_free()
		return {"height":0,"sector":null}
		
	entityNode.add_child(rc)
	
	
	
	rc.force_raycast_update()
	rc.debug_shape_thickness = 40
	
	
	
	
	var colY = rc.get_collision_point().y
	var gp = rc.get_collider()
 
	if rc.get_parent() != null:
		rc.get_parent().remove_child(rc)
		
	rc.queue_free()
	
	
	if gp == null:
		return {"height":colY,"sector":""}
	
	
	
	return {"height":colY,"sector":gp.name}


	

func getSectorTagAtPos(point):

	var rc = RayCast.new()
	var pos = Vector3(point.x,5000,point.z)
	rc.enabled = true
	rc.translation = pos
	rc.cast_to.y = -rc.translation.y*2
	rc.set_collision_mask_bit(0,0)
	rc.set_collision_mask_bit(1,1)#only floors on this bit
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
	#	print(collider)
		return null


	
func pickupCreationFunction(typeInfo,pickupScene):
	
	var splitOffset = typeInfo["name"].find(" pickup")
	var gunName = typeInfo["name"].substr(0,splitOffset).to_lower()
	
	
	var gunInfo = thingDirectory[gunName.to_lower()]
	var inst = load(gunInfo["sourceScene"]).instance()
	var gunGen = inst.get_node("Generator")
	var worldSprite = $"../ResourceManager".fetchDoomGraphic(gunGen.worldSprite)
	var s = $"../ResourceManager".fetchSound(pickupScene.pickupSoundName)
	var scaleFactor = get_parent().scaleFactor
	
	inst.queue_free()
	pickupScene.get_node("Sprite3D").texture = worldSprite
	pickupScene.get_node("Sprite3D").pixel_size = scaleFactor.x * 0.8
	pickupScene.get_node("CollisionShape").shape.extents *= scaleFactor
	if pickupScene.get_node_or_null("Area") != null:
		pickupScene.get_node("Area").get_node("CollisionShape").shape.extents *= scaleFactor
	
	pickupScene.get_node("AudioStreamPlayer3D").stream = s
	
	
	var t = pickupScene.get_node("CollisionShape")
	
	pickupScene.pickupEntityPath = WADG.destPath + get_parent().gameName + "/entities/"+gunInfo["category"]+"/"+gunInfo["name"]+".tscn"
	pickupScene.pickupEntityStr = gunName
	
	if get_parent().toDisk:
		pickupScene.pickupEntityPath = WADG.destPath +get_parent().gameName + "/entities/"+gunInfo["category"]+"/"+gunInfo["name"]+".tscn"
		#pickupScene.gunScene = gunInfo["category"]
#	else:
#
#		var cached =  ENTG.fetchEntity(gunName,get_tree(),get_parent().gameName,get_parent().toDisk)
#		if cached == null:
#			var dict : Dictionary = thingDirectory[gunName]
#			var projectile : KinematicBody = null
#
#			dict["name"] = gunName
#
#			if dict.has("projectileSource"):
#				var dict2 = {"name":dict["projectileName"],"sourceScene":dict["projectileSource"],"category":dict["category"]}
#
#				projectile = createFromScene(dict2,"basicInstance")
#
#			var gun : Spatial = createFromScene(dict,"basicInstance")
#			if projectile != null:
#				gun.projectile = projectile
#
#		if is_instance_valid(cached):
#			cached.queue_free()
#
#
	var h = WADG.getCollisionShapeHeight(t)


	for i in pickupScene.get_children():
		if "translation" in i:
			i.translation.y = h/2.0

	
	
	return pickupScene


func giveCreationFunction(typeInfo,scene):
	var spr =  $"../ResourceManager".fetchDoomGraphic(typeInfo["sprites"][0])
	
	scene.get_node("Sprite3D").texture = spr
	scene.get_node("Sprite3D").pixel_size = get_parent().scaleFactor.x * 0.8
	
	var sound = $"../ResourceManager".fetchSound("DSITEMUP")
	var audio = scene.get_node("AudioStreamPlayer3D")
	
	
	audio.unit_size = 4
	audio.stream = sound
	
	if typeInfo.has("give"):
		scene.giveString = typeInfo["give"][0]
		scene.giveAmount = typeInfo["give"][1]
		
		if typeInfo["give"].size() >= 3:
			scene.limit = typeInfo["give"][2]
	
	if typeInfo.has("persistant"):
		scene.persistant = false
	
	return scene



func createFromCode(typeInfo : Dictionary,function) -> Spatial:

	var destPath = WADG.destPath+get_parent().gameName +"/"+typeInfo["name"]+".tscn"
	var runtimeName =  $"../ResourceManager".getSceneRuntimeName(destPath)
	
	var scene : Spatial = function.call_func(typeInfo)
	
	if scene == null:
		return null
		

	
	return scene


func createFromScene(typeInfo : Dictionary,function) -> Node:
	
	var scene : Node
	var funco = funcref(self,function)
			
	#var resource =  ResourceLoader.load( typeInfo["sourceScene"])
	var resource =  ResourceLoader.load(typeInfo["sourceScene"],"",true)

	#scene  = resource.duplicate(true).instance()
	scene  = resource.duplicate(true).instance()#this fixes fist shooting sounds
	
	funco.call_func(typeInfo,scene)
	
	
	
	for i in scene.get_children():
		if i.name == "Generator":
			scene.remove_child(i)
			i.queue_free()
		
	return scene



func basicInstance(typeInfo,scene):
	if scene.get_node_or_null("Generator"):
		var generator = scene.get_node("Generator")
		if generator == null:
			print("scene:", "has no generator")
			return scene
		

		
		generator.loader = $"../ResourceManager"
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
	
	
	res = fetchAllDepends(entStr)
	fetchResourcesDisk(res)
	startFileWaitThread(editorInterface)



func startFileWaitThread(editorInterface):
	thread = Thread.new()
	thread.start($"../ResourceManager","waitForFilesToExist",editorInterface)

func fetchAllDepends(entStr):
	entStr = entStr.to_lower()
	var entEntry = thingDirectory[entStr]
	var res = getDepends(entEntry["name"])
	
	if entEntry.has("depends"):
		if !entEntry["depends"].empty():
			if typeof(entEntry["depends"]) == TYPE_STRING:
					res = mergeDepends(res,getDepends(entEntry["depends"]))
						
			if typeof(entEntry["depends"]) == TYPE_ARRAY:
				for i in entEntry["depends"]:
					res = mergeDepends(res,getDepends(i))
					
	
	return res
	
func fetchResourcesDisk(res):
	if res.has("sprites"):
		for i in res["sprites"]:
			
			if i.find("_flipped") != -1:
				var resName = i.split("_flipped")
				$"../ResourceManager".fetchDoomGraphicDisk(resName[0],true)
				
			else:
				$"../ResourceManager".fetchDoomGraphicDisk(i,false)
				
				
	if res.has("animatedSprites"):
		for animName in res["animatedSprites"]:
			for i in res["animatedSprites"][animName]:
				$"../ResourceManager".fetchDoomGraphicDisk(i,false)
			#$"../ResourceManager".fetchAnimatedSimple(animName,res["animatedSprites"][animName])

	
	if res.has("flats"):
		for textureName in res["flats"]:
			$"../ResourceManager".fetchFlat(textureName)
		
	if res.has("patched"):
		for textureName in res["patched"]:
			$"../ResourceManager".fetchPatchedTexture(textureName)
	
#	if res.has("mat"):
#		for textureName in res["mat"].keys():
#			var texture = $"../ResourceManager".fetchFlat(textureName)
#
#			for textureEntry in res["mat"][textureName]:#each mat param of a given texture
#				var lightLevel = textureEntry[0]
#				var scrollVector = textureEntry[1]
#				var alpha = textureEntry[2]
#				$"../ResourceManager".fetchMaterial(textureName,texture,lightLevel,scrollVector,1.0,0,0)
#
	if res.has("bitmapFont"):
		print("res has bitmapfont ")
		$"../ResourceManager".fetchBitmapFont(res["bitmapFont"])
	
	
func getDepends(entStr):
	entStr = entStr.to_lower()
	var entEntry = thingDirectory[entStr]
	var res = {}
	
	if entEntry.has("sprites"):
		for spr in entEntry["sprites"]:
			if spr != "":
				
				if !res.has("sprites"):
					res["sprites"] = []
				
				if !res["sprites"].has(spr):
					res["sprites"].append(spr)
	
	
	if !entEntry.has("sourceScene"):
		return res
		
	if entEntry["sourceScene"].empty():
		return res
				
	var ret = instanceGeneratorAndGetSprites(entEntry["sourceScene"])
	
	if !ret.empty():
		for sprite in ret["sprites"]:
			
			if !res.has("sprites"):
				res["sprites"] = []
			
			if !res["sprites"].has(sprite):
				res["sprites"].append(sprite)
						
				
		for animName in ret["animatedSprites"]:
			if !res.has("animatedSprites"):
				res["animatedSprites"] = {}
			
			res["animatedSprites"][animName] = ret["animatedSprites"][animName]
	
	return res
	
	


func createMapResourcesOnDisk(mapname,editorInterface,startFileWaitThread = true):
	var depends = getMapDepends(mapname)
	fetchResourcesDisk(depends)

	if startFileWaitThread:
		startFileWaitThread(editorInterface)
	

func getMapDepends(mapname):
	get_parent().loadWads()
	var targetMap = get_parent().maps[mapname]
	targetMap["name"] = mapname
	
	
	$"../LumpParser".parseMap(targetMap)
	$"../LumpParser".postProc(targetMap)
	
	var fme = $"../LumpParser".flatMatEntries
	var wme =  $"../LumpParser".wallMatEntries
	
	var depends = {}
	for t in targetMap["THINGS"]:
		var type = t["type"]
		var entry = thingSheet.getRow(var2str(type))
		#var depends = fetchAllDepends(entry["name"].to_lower())
		depends = mergeDepends(depends,fetchAllDepends(entry["name"].to_lower()))
	
	
	
	
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
	for i in a.keys():
		
			
		for j in a[i]:
			var t = typeof(a[i])
			if typeof(a[i]) == TYPE_ARRAY:
				
				if !b.has(i):
					b[i] = []
				
				if !b[i].has(j):
					b[i].append(j)
					
			if typeof(a[i]) == TYPE_DICTIONARY:
				
				if !b.has(i):
					b[i] = {}
				
				if !b[i].has(j):
					b[i].merge({j:a[i][j]})
					
					
				
			
	return b
#func fetchRuntimeOrphanEntityCacheNode(gameName):
#	gameName = gameName.to_lower()
#
#
#	if !get_tree().has_meta("entityCacheOrphans"):
#		get_tree().set_meta("entityCacheOrphans",[])
#
#
#
#	var cacheArr =  get_tree().get_meta("entityCacheOrphans")
#
#	var cache = null
#
#	for i in cacheArr:
#		if i.name == gameName:
#			return i
#
#
#	if cache == null:#here we create a new entity cache
#		var eCache = Spatial.new()
#		eCache.name = gameName
#
#		get_tree().get_meta("entityCacheOrphans").append(eCache)
#		print("orphan game cache:",eCache, " added")
#
#		return eCache
