tool
extends Node

var entityNode
var totalNpcCount = 0

var thingsDict ={
	0:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	1:{"name":"Player 1 start","sprites":["PLAYA1"],"func":funcref(self,"createPlayerThings"),"script":null,"height":0},
	2:{"name":"Player 2 start","sprites":[""],"func":funcref(self,"createPlayerThings"),"script":null,"height":0},
	3:{"name":"Player 3 start","sprites":[""],"func":funcref(self,""),"script":null,"height":0},
	4:{"name":"Player 4 start","sprites":[""],"func":funcref(self,""),"script":null,"height":0},
	5:{"name":"Blue keycard","sprites":["BKEYA0"],"func":funcref(self,""),"script":null},
	6:{"name":"Yellow keycard","sprites":["YKEYA0"],"func":funcref(self,""),"script":null},
	7:{"name":"Spiderdemon","sprites":["SPIDA1D1"],"func":funcref(self,"createEnemies"),"script":null},
	8:{"name":"Backpack","sprites":["BPAKA0"],"func":funcref(self,""),"script":null},
	9:{"name":"Shotgun guy","sprites":["SPOSA1"],"deathSprites":["SPOSL0"],"func":funcref(self,"createEnemies"),"script":"res://addons/godotWad/interactables/thingScripts/enemy.gd","height":64,"sounds":{"deathSounds":["DSPODTH1","DSPODTH2","DSPODTH3"]}},
	10:{"name":"Bloody mess","sprites":[""],"func":funcref(self,""),"script":null},
	11:{"name":"Deathmatch start","sprites":[""],"func":funcref(self,""),"script":null},
	12:{"name":"Bloody mess","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	13:{"name":"Red keycard","sprites":["RKEYA0"],"func":funcref(self,""),"script":null},
	14:{"name":"Teleport landing","sprites":["none"],"func":funcref(self,"createTeleports"),"script":"res://addons/godotWad/thingScripts/teleportLanding.gd","height":0},
	15:{"name":"Dead player","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	16:{"name":"Cyberdemon","sprites":["CYBRA1"],"deathSprites":["CYBRP0"],"sounds":{"deathSounds":["DSCYBDTH"]},"func":funcref(self,"createEnemies"),"script":null},
	17:{"name":"Energy cell pack","sprites":[""],"func":funcref(self,""),"script":null},
	18:{"name":"Dead former humann","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	19:{"name":"Dead former sargent","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	20:{"name":"Dead imp","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	21:{"name":"Dead demon","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	22:{"name":"Dead cacodemon","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	23:{"name":"Dead lost soul","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	24:{"name":"Pool of blood and flesh","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	25:{"name":"Impaled human","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	26:{"name":"Twitching impared human","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	27:{"name":"Skull on a pole","sprites":["POL4A0"],"func":funcref(self,"createDeco"),"script":null},
	28:{"name":"Five skulls","sprites":["POL2A0"],"func":funcref(self,"createDeco"),"script":null},
	29:{"name":"Pile of skulls and candles","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	30:{"name":"Tall green pillar","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	31:{"name":"Short green pillar","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	32:{"name":"Tall red pillar","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	33:{"name":"Short red pillar","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	34:{"name":"Candle","sprites":["CANDA0"],"func":funcref(self,"createDeco"),"script":null},
	35:{"name":"Candelbra","sprites":["CBRAA0"],"func":funcref(self,"createDeco"),"script":null},
	36:{"name":"Short green pillar bit beating heart","sprites":["createDeco"],"func":funcref(self,""),"script":null},
	37:{"name":"Short red pillar with skull","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	38:{"name":"Red skull key","sprites":[""],"func":funcref(self,""),"script":null},
	39:{"name":"Yellow skull key","sprites":[""],"func":funcref(self,""),"script":null},
	40:{"name":"Blue skull key","sprites":[""],"func":funcref(self,""),"script":null},
	41:{"name":"Evil eye","sprites":[''],"func":funcref(self,"createDeco"),"script":null},
	42:{"name":"Floating skull","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	43:{"name":"Burnt trere","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	44:{"name":"Tall blue firestick","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	45:{"name":"Tall green firestick","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	46:{"name":"Tall red firestick","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	47:{"name":"Brown stump","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	48:{"name":"Tall techno column","sprites":["ELECA0"],"func":funcref(self,"createDeco"),"script":null},
	49:{"name":"Hanging victim twitching","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	50:{"name":"Hanging victim arms out","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	51:{"name":"Hanging victim one-legged","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	52:{"name":"Hanging pair of legs","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	53:{"name":"Hanging leg","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	54:{"name":"Large brown tree","sprites":["TRE2A0"],"func":funcref(self,"createDeco"),"script":null},
	55:{"name":"Short blue firestick","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	56:{"name":"Short green firestick","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	57:{"name":"Short red firestick","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	58:{"name":"Spectre","sprites":["SARGA1"],"func":funcref(self,"createEnemies"),"script":null},
	59:{"name":"Hanging victim arms out","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	60:{"name":"Hanging pair of legs","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	61:{"name":"Hanging victim one-legged","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	62:{"name":"Hanging leg","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	63:{"name":"Hanging victim twitching","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	64:{"name":"Arch-vile","sprites":[""],"func":funcref(self,"createEnemies"),"script":null},
	65:{"name":"Heavy weapon dude","sprites":[""],"func":funcref(self,"createEnemies"),"script":null},
	66:{"name":"Revenant","sprites":["SKELA0"],"func":funcref(self,"createEnemies"),"script":null},
	67:{"name":"Mancubus","sprites":[""],"func":funcref(self,"createEnemies"),"script":null},
	68:{"name":"Arachnotron","sprites":[""],"func":funcref(self,"createEnemies"),"script":null},
	69:{"name":"Hell knight","sprites":[""],"func":funcref(self,"createEnemies"),"script":null},
	70:{"name":"Burning barrel","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	71:{"name":"Pain elemental","sprites":[""],"func":funcref(self,"createEnemies"),"script":null},
	72:{"name":"Commander Keen","sprites":[""],"func":funcref(self,"createDeco"),"script":null},
	73:{"name":"Hanging victim, guts removed","sprites":[ "HDB1A0"],"func":funcref(self,"createDeco"),"script":"","height":null},
	74:{"name":"Hanging victim, guts and brain removed","sprites":[ "HDB2A0"],"func":funcref(self,"createDeco"),"script":"","height":null},
	75:{"name":"Hanging torso, looking down","sprites":[ "HDB3"],"func":funcref(self,"createDeco"),"script":"","height":null},
	76:{"name":"Hanging torso, open skull","sprites":[""],"func":funcref(self,"createDeco"),"script":"","height":null},
	77:{"name":"Hanging torso looking up","sprites":[""],"func":funcref(self,"createDeco"),"script":"","height":null},
	78:{"name":"Hanging torso, brain removed","sprites":[""],"func":funcref(self,"createDeco"),"script":"","height":null},
	79:{"name":"Pool of blood","sprites":["POB1A0"],"func":funcref(self,"createDeco"),"script":null},
	80:{"name":"Pool of blood 2","sprites":["POB2A0"],"func":funcref(self,"createDeco"),"script":null},
	81:{"name":"Pool of brains","sprites":["BRS1A0"],"func":funcref(self,"createDeco"),"script":null},
	82:{"name":"Super shotgun","sprites":["SGN2A0"],"func":funcref(self,""),"script":null},
	83:{"name":"Megasphere","sprites":["MEGAA0"],"func":funcref(self,""),"script":null},
	84:{"name":"Wolfenstein SS","sprites":["SSWVA1"],"func":funcref(self,"createEnemies"),"script":null},
	85:{"name":"Tall techno floor lamp","sprites":["TLMPA0"],"func":funcref(self,"createDeco"),"script":null},
	86:{"name":"Short techno floor lamp","sprites":["TLP2A0"],"func":funcref(self,"createDeco"),"script":null},
	87:{"name":"Spawn spot","sprites":[""],"func":funcref(self,""),"script":null},
	88:{"name":"Romero's head","sprites":["BBRNA0"],"func":funcref(self,""),"script":null},
	89:{"name":"Monster spawner","sprites":[""],"func":funcref(self,""),"script":null},
	
	2001:{"name":"Shotgun","sprites":["SHOTA0"],"func":funcref(self,""),"script":null,"height":0},
	2002:{"name":"Chaingun","sprites":["MGUNA0"],"func":funcref(self,""),"script":null,"height":0},
	2003:{"name":"Rocket launcher","sprites":["LAUNA0"],"func":funcref(self,""),"script":null,"height":0},
	2004:{"name":"Plasma gun","sprites":["PLASA0"],"func":funcref(self,""),"script":null,"height":0},
	2005:{"name":"Chainsaw","sprites":["CSAWA0"],"func":funcref(self,""),"script":null,"height":0},
	2006:{"name":"BFG9000","sprites":["BFUGA0"],"func":funcref(self,""),"script":null,"height":0},
	2007:{"name":"Clip","sprites":["CLIPA0"],"func":funcref(self,""),"script":null,"height":0},
	2008:{"name":"4 shotgun shells","sprites":["SHELA0"],"func":funcref(self,""),"script":null,"height":0},
	2009:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2010:{"name":"Rocket","sprites":["ROCKA0"],"func":funcref(self,""),"script":null,"height":0},
	2011:{"name":"Stimpack","sprites":["STIMA0"],"func":funcref(self,""),"script":null,"height":0},
	2012:{"name":"Medkit","sprites":["MEDIA0"],"func":funcref(self,""),"script":null,"height":0},
	2013:{"name":"Supercharge","sprites":["SOULA0"],"func":funcref(self,""),"script":null,"height":0},
	2014:{"name":"Heatlh bonus","sprites":["BON1A0"],"func":funcref(self,""),"script":"res://addons/godotWad/thingScripts/collectable.gd","height":0},
	2015:{"name":"Armor bonus","sprites":["BON2A0"],"func":funcref(self,""),"script":"res://addons/godotWad/thingScripts/collectable.gd","height":0},
	2016:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2017:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2018:{"name":"Armor","sprites":["ARM1A0"],"func":funcref(self,""),"script":null},
	2019:{"name":"Megarmor","sprites":["ARM2A0"],"func":funcref(self,""),"script":null},
	2020:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2021:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2022:{"name":"Invulnerability","sprites":["PINVA0"],"func":funcref(self,""),"script":null},
	2023:{"name":"Berserk","sprites":["PSTRA0"],"func":funcref(self,""),"script":null},
	2024:{"name":"Partial invisibility","sprites":["PINSA0"],"func":funcref(self,""),"script":null},
	2025:{"name":"Radiation shielding suit","sprites":["SUITA0"],"func":funcref(self,""),"script":null},
	2026:{"name":"Computer area map","sprites":["PMAPA0"],"func":funcref(self,"createDeco"),"script":null},
	2027:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2028:{"name":"Floor lamp","sprites":["COLU"],"func":funcref(self,""),"script":null},
	2029:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2030:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2031:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2032:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2033:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2034:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2035:{"name":"Exploding barrel","sprites":["BAR1A0"],"func":funcref(self,"createDeco"),"script":null},
	2036:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2037:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2038:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2039:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2040:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2041:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2042:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2043:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2044:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2045:{"name":"","sprites":[""],"func":funcref(self,""),"script":null},
	2046:{"name":"Box of rockets","sprites":["BROKA0"],"func":funcref(self,""),"script":null,"height":0},
	2047:{"name":"Energy cell","sprites":["CELLA0"],"func":funcref(self,""),"script":null,"height":0},
	2048:{"name":"Box of bullets","sprites":["AMMOA0"],"func":funcref(self,""),"script":null,"height":0},
	2049:{"name":"Box of shotgun shells","sprites":["SBOXA0"],"func":funcref(self,""),"script":null,"height":0},
	
	3001:{"name":"Imp","sprites":["TROOA1"],"deathSprites":["TROOM0"],"sounds":{"deathSounds":["DSBGDTH1","DSBGDTH2"]},"func":funcref(self,"createEnemies"),"script":"res://addons/godotWad/interactables/thingScripts/enemy.gd","height":64},
	3002:{"name":"Demon","sprites":["SARGA1"],"deathSprites":["SARGN0"],"sounds":{"deathSounds":["DSSGTDTH"]},"func":funcref(self,"createEnemies"),"script":null},
	3003:{"name":"Baron of Hell","sprites":["BOSSA1"],"func":funcref(self,"createEnemies"),"script":null},
	3004:{"name":"Zombieman","sprites":["POSSA1"],"deathSprites":["POSSL0"],"sounds":{"deathSounds":["DSPODTH1","DSPODTH2","DSPODTH3"]},"func":funcref(self,"createEnemies"),"script":null},
	3005:{"name":"Cacodemon","sprites":["HEADA1"],"func":funcref(self,"createEnemies"),"script":null},
	3006:{"name":"Lost soul","sprites":["SKULA1"],"func":funcref(self,"createEnemies"),"script":null},
}

func _ready():
	set_meta("hidden",true)

func createThings(thingsByType):
	entityNode = Spatial.new()
	entityNode.name = "Entities"
	get_parent().mapNode.add_child(entityNode)
	for type in thingsByType.keys():
		
		if !thingsDict.has(type):
			continue
		
		var functionName = thingsDict[type]["func"].function
		if functionName!= "":
			thingsDict[type]["func"].call_func(thingsByType[type],thingsDict[type])
	
	print("NPC Count:"+String(totalNpcCount))
		#createThingsFromArr(thingsByType[type],type)
		#if type == 1: createPlayerThings(thingsByType[type],type)
		

#func createThingsFromArr(thingsOfType,type):
#	for thing in thingsOfType:
			
		#if type == 1:createPlayerThings(thing)
#		var t = thingsDict[type]["func"].function
#		
		#if t!= "":
		#	thingsDict[type]["func"].call_func(thingsDict[type])
			
	
	
	
	
func createPlayerThings(things,typeInfo):
	
	
	if entityNode.get_node_or_null("Player Spawns") == null:
		var node = Spatial.new()
		node.name = "Player Spawns"
		entityNode.add_child(node)
		
	
	var node = Spatial.new()
	node.name = typeInfo["name"]
	entityNode.get_node("Player Spawns").add_child(node)
	
	
	var index = 0 
	
	for thing in things:
		var spawnLoc = Position3D.new()
		var h = getFloorHeightAtPoint(thing["pos"])["height"] #+ 32
		h = node.to_local(Vector3(0,h,0)).y
		
		
		spawnLoc.translation = Vector3(thing["pos"].x,h,thing["pos"].z)
		
		spawnLoc.rotation_degrees = Vector3(0,thing["rot"]-90,0)
		
		
		
		spawnLoc.name = String(typeInfo["name"])
		node.add_child(spawnLoc)
		
		var editorSprite = Sprite3D.new()
		editorSprite.texture = load("res://addons/godotWad/sprites/spawnIcon.png")
		editorSprite.script = load("res://addons/godotWad/src/editorOnlySprite.gd")
		editorSprite.pixel_size = 0.5
		editorSprite.name = "editorSprite"
		editorSprite.translation.y += editorSprite.texture.get_height()/2.0
		editorSprite.billboard = SpatialMaterial.BILLBOARD_FIXED_Y
		spawnLoc.add_child(editorSprite)
		#index +=1
	
		

func createTeleports(things,typeInfo):
	
	var node = Spatial.new()
	node.name = "Teleport Destinations"
	entityNode.add_child(node)
	for thing in things:
		var destNode = Spatial.new()
		destNode.name = typeInfo["name"]
		
		
		#var pos = node.to_global(thing["pos"])
		var pos = thing["pos"]
		var h = getFloorHeightAtPoint(thing["pos"])["height"]
		h = node.to_local(Vector3(0,h,0)).y
		pos.y = h
		

		destNode.translation = pos
	
		
		node.add_child(destNode) 
		var sectorTagAtPos = getSectorTagAtPos(thing["pos"])
		if sectorTagAtPos == null:
			return
		destNode.name = String(sectorTagAtPos)
		destNode.add_to_group("destination:"+destNode.name,true)
		#breakpoint

func createEnemies(things,typeInfo):
	
	if !get_parent().entitiesEnabled:
		return
	var i = 0
	
	for thing in things:
		var node = createSprite(typeInfo["name"],typeInfo["sprites"][0])

		var pos = thing["pos"]
		
		var script = load("res://addons/godotWad/src/npc/npc.gd")
		var kinBody = createCollision(10,45)
		kinBody.add_child(node)
		kinBody.name = node.name + String(i)
		if node.texture!=null:
			kinBody.translation.y-= node.texture.get_height()/2.0
		
		kinBody.set_script(script)
		
		if typeInfo.has("sounds"):
			if typeInfo["sounds"].has("deathSounds"):
				
				var deathSoundParent = Spatial.new()
				deathSoundParent.name = "deathSounds"
				kinBody.add_child(deathSoundParent)
				
				for soundName in typeInfo["sounds"]["deathSounds"]:
					
					var audioStream =  $"../ResourceManager".fetchSound(soundName)
					var audioPlay = AudioStreamPlayer3D.new()
					
					audioPlay.unit_size = 4
					audioPlay.stream = audioStream
					deathSoundParent.add_child(audioPlay)

		
		if typeInfo.has("deathSprites"):
			var sprName = typeInfo["deathSprites"][0]
			kinBody.deathSprites = [get_node("../ResourceManager").fetchPatch(sprName)]
		
		entityNode.add_child(kinBody)
		
		if "npcName" in kinBody:
			kinBody.npcName = typeInfo["name"]
		setNodeHeight(kinBody,thing["pos"])
		i+=1
		
		var mapNode =entityNode.get_parent()
		
		
		if !mapNode.has_meta(typeInfo["name"]):
			mapNode.set_meta(typeInfo["name"],0)
		
		var curCount = mapNode.get_meta(typeInfo["name"])

		mapNode.set_meta(typeInfo["name"],curCount+1)
		
		totalNpcCount += 1
	
	
func createDeco(things,typeInfo):
	
	for thing in things:
		var node = createSprite(typeInfo["name"],typeInfo["sprites"][0])
		entityNode.add_child(node)
		var pos = thing["pos"]
		setNodeHeight(node,thing["pos"])
		if node.texture != null:
			node.translation.y += node.texture.get_height()/2.0

func createSprite(nodeName,textureName):
	
	var node = Sprite3D.new()
	node.name = nodeName	
	node.pixel_size = 1
	var t = get_parent().get_node("ResourceManager").fetchPatch(textureName)

	node.texture = t
	node.billboard = SpatialMaterial.BILLBOARD_FIXED_Y
	return node

func setNodeHeight(node,pos):
	var h = getFloorHeightAtPoint(pos)["height"]
	h = node.to_local(Vector3(0,h,0)).y
	pos.y = h
	node.translation = pos

func getFloorHeightAtPoint(point):
	var rc = RayCast.new()
	var pos = Vector3(point.x,-5000,point.z)
	rc.enabled = true
	rc.translation = pos
	rc.cast_to.y = -rc.translation.y*2
	rc.collision_mask = 0
	rc.collision_mask = 32768
	#rc.set_collision_mask_bit(16,1)
	#rc.collisoin#
	#rc.set_collision_mask_bit(16,1)#only floors on this bit
	#rc.collision_layer = 0
	entityNode.add_child(rc)
	rc.force_raycast_update()
	rc.debug_shape_thickness = 40
	
	
	
	var colY = rc.get_collision_point().y
	var gp = rc.get_collider()
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
	add_child(rc)
	rc.force_raycast_update()
	
	var collider = rc.get_collider()
	rc.queue_free()
	if collider == null:
		return
	if collider.get_parent().has_meta("sector"):
		var sectorNode = collider.get_parent().get_parent()
		var tag = sectorNode.get_meta("tag")
		return tag
	else:
		return -1

func createCollision(radius,height):
	var body = KinematicBody.new()
	var shape = CollisionShape.new()
	#var shapeRes = CylinderShape.new()
#	var shapeRes = CapsuleShape.new()
	#shape.rotation_degrees.x = 90
	#shapeRes.radius = radius
	#shapeRes.height = height
	
	var shapeRes = BoxShape.new()
	shapeRes.extents = Vector3(10,20,10)
	
	body.add_child(shape)
	shape.shape = shapeRes
	return body


func createSphere(pos):
	var sphereInstance = CSGSphere.new()
	
	sphereInstance.radius = 20
	sphereInstance.translation = pos
	get_parent().add_child(sphereInstance)
