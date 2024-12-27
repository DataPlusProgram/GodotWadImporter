@tool
extends Node


@export var sprites: Resource
@export var idle: String = ""
@export var chase: String = ""
@export var attack: String = ""
@export var melee: String = ""
@export var hurt: String = ""
@export var dying: String = ""
@export var gib: String = ""
@export var heal: String = ""


@export var deathSounds = ["DSPODTH1","DSPODTH2","DSPODTH3"] # (Array,String)
@export var gibSounds = []
@export var painSounds = ["DSPOPAIN"] # (Array,String)
@export var attackSounds = ["DSPISTOL"] # (Array,String)
@export var meleeSounds = [] # (Array,String)
@export var alertSounds = ["DSPOSIT1","DSPOSIT2","DSPOSIT3"] # (Array,String)
@export var searchSounds  : Array[StringName]= []
@export var stompSounds : Array[StringName]= []
@export var scaleFactor = Vector3.ONE
@export var entityDepends : PackedStringArray = []
@export var bloodSplatter : Array # (Array,String)

var animationLibrary : AnimationLibrary
var animationPlayer : Node
var animatedSprite 
var seneTree
var loader = null
var entityLoader




func initialize() -> void:
	if loader == null:
		queue_free()
		return
	
	
	var parent : Node = get_parent()
		
	
	animationLibrary = AnimationLibrary.new()
	animationPlayer =  $"../AnimationPlayer"
	animationPlayer.add_animation_library("",animationLibrary)
	animatedSprite = $"../visual/AnimatedSprite3D"
	animatedSprite.frameList = {}
	
	
	$"../movement/footCast".shape = $"../CollisionShape3D".shape.duplicate()
	$"../movement/ShapeCastH".shape = $"../CollisionShape3D".shape.duplicate()
	
	if animationPlayer == null:
		breakpoint
	

	parent.setHeight(parent.height*scaleFactor.y - 0.001)
	parent.setThickness(get_parent().thickness*scaleFactor.x)
	$"../movement/".thicknessSet()
	parent.meleeRange *= scaleFactor.x
	animatedSprite.scaleFactor = scaleFactor

	var ret = WADG.getSpritesAndFrames( load(get_parent().stateDataPath).getRowsAsArray(),loader.get_parent().flatTextureEntries)
	var frames : Dictionary = ret["frames"]

	
	var aabb = Vector2(-INF,-INF)
	
	for frameName in frames:
		var subAABB = addRow(frameName,frames[frameName])
		if subAABB.x > aabb.x: aabb.x =  subAABB.x
		if subAABB.y > aabb.y: aabb.y=  subAABB.y
	
	#animatedSprite.custom_aabb.size.x = 9999
	#animatedSprite.custom_aabb.size.y = 9999

	var dict = {"s":[],"sw":[],"w":[],"nw":[],"n":[],"ne":[],"e":[],"se":[]}


		
	var delta  = (1.0/35.0)

	$"../navigationLogic".height = get_parent().height


	animatedSprite.setMat("A")

		
	for entityStrId : String in entityDepends:
		ENTG.fetchEntity(entityStrId,entityLoader.get_tree(),loader.get_parent().gameName,entityLoader.get_parent().toDisk).queue_free()
		parent.projectile = entityStrId
	
		
	if !bloodSplatter.is_empty():
		parent.hitDecal = loader.fetchAnimatedSimple(bloodSplatter[0]+"_anim",bloodSplatter,4,true)
	
	parent.speed *= scaleFactor.z
	parent.chargeSpeed *= scaleFactor.z
	parent.hitDecalSize = scaleFactor.x
	parent.defaultProjectileHeight*= scaleFactor.y
	parent.projectileRange*= scaleFactor.z

	if get_node_or_null("../rezCheckArea/CollisionShape3D") != null:
		$"../rezCheckArea".position.y = $"../CollisionShape3D".shape.size.y/2.0
		$"../rezCheckArea/CollisionShape3D".shape.size = $"../CollisionShape3D".shape.size
		$"../rezCheckArea/CollisionShape3D".shape.size.x *= 2
		$"../rezCheckArea/CollisionShape3D".shape.size.z *= 2
		#$"../rezCheckArea/CollisionShape3D".shape.radius = 500 * scaleFactor.x

	var stateData = load(parent.stateDataPath).getRowsAsArray()
	for i in stateData:
		if i["Function"] == "chase":
			var chaseDur = i["Dur"]
			parent.speed = (35/chaseDur)*8
			parent.speed *= scaleFactor.z
	
	initSounds()
	

	for i in parent.get_children():
		if i.get_name().find("_") != -1:
			if i.get_name().split("_")[0] == "projectileSpawn":
				i.position *= scaleFactor
				
	
	if get_node_or_null("VisibleOnScreenNotifier3D"):
		$"VisibleOnScreenNotifier3D".h = get_parent().height*scaleFactor.y
		$"VisibleOnScreenNotifier3D".w = get_parent().thickness
		$"VisibleOnScreenNotifier3D".d = get_parent().thickness
		
	queue_free()

	


func getUniqueLetters(allLetters : String) -> Array:
	var firstLetter = "]"
	var lastLetter = "A"
	var uniqueLetters = []
		
	for letter in allLetters:
		if letter > lastLetter:
			lastLetter = letter
				
		if letter < firstLetter:
			firstLetter = letter
		
	for i in range(firstLetter.to_ascii_buffer()[0],lastLetter.to_ascii_buffer()[0]+1):
		var t = sprites.getRow(char(i))
		if !t.is_empty():
			uniqueLetters.append(char(i))
			
	return uniqueLetters

func toIndices(string,uniqueLetters):
	var ret = []
	
	for letter in string:
		var t = uniqueLetters.find(letter)
		ret.append(t)
		#ret.append(ord(letter)-65)
	
	return ret


func addRow(rowName : String,spriteNames : Dictionary) -> Vector2:
	var rowSprite : Array[Texture2D] = []
	var aabb = Vector2(-INF,-INF)
	
	for sprName in spriteNames.values():
		if sprName == null:
			rowSprite.append(null)
		else:
			var tex : Texture2D = loader.fetchDoomGraphic(sprName)
			if tex.get_width()*scaleFactor.x > aabb.x: aabb.x = tex.get_width()*scaleFactor.x
			if tex.get_height()*scaleFactor.y > aabb.y: aabb.y = tex.get_height()*scaleFactor.y
			rowSprite.append(tex)
	
	var mat : Material 
	
	if spriteNames["All"] != null:
		mat = loader.materialManager.fetchSpriteMaterial(spriteNames["All"],rowSprite[0],get_parent().modulate)
	else:
		rowSprite = rowSprite.slice(1)
		mat = loader.materialManager.fetch8wayBillboardMaterial(spriteNames.values()[1],rowSprite,get_parent().modulate)
	animatedSprite.add_frame(rowName,mat)
	
	
	return aabb
	
	
func addSprites(spriteNames,set = "default",modulate = null):
	
	for s in spriteNames.size():
		var sprite : Texture2D = loader.fetchDoomGraphic(spriteNames[s])
		
		if sprite == null:
			
			print("missing sprite (enemyGenerator):",spriteNames[s])
			sprite = load("res://addons/godotWad/scenes/guns/icon.png")
			
		
		
		if !animatedSprite.has_animation(set):
			animatedSprite.add_animation_library(set)
	
		#var mat = loader.fetchSpriteMaterial(spriteNames[s],false,modulate)
		if modulate == null:
			modulate = 1
	
		var mat = loader.materialManager.fetchSpriteMaterial(spriteNames[s],sprite,modulate)
		
		animatedSprite.add_frame(set,mat,s)
		
	
func initSounds():
	
	for i in deathSounds:
		$"../AudioStreamPlayer3D".deathSounds.append(loader.fetchSound(i))
	
	for i in painSounds:
		$"../AudioStreamPlayer3D".painSounds.append(loader.fetchSound(i))
		
	for i in attackSounds:
		$"../AudioStreamPlayer3D".attackSounds.append(loader.fetchSound(i))
		
	for i in alertSounds:
		$"../AudioStreamPlayer3D".alertSounds.append(loader.fetchSound(i))
		
	for i in meleeSounds:
		$"../AudioStreamPlayer3D".meleeSounds.append(loader.fetchSound(i))
		
	for i in searchSounds:
		$"../AudioStreamPlayer3D".searchSounds.append(loader.fetchSound(i))
		
	for i in stompSounds:
		$"../AudioStreamPlayer3D".stompSounds.append(loader.fetchSound(i))

	for i in gibSounds:
		$"../AudioStreamPlayer3D".gibSounds.append(loader.fetchSound(i))
		
func getSpriteList() -> Dictionary:
	
	var list : Array = []

	list = WADG.getSpritesAndFrames( load(get_parent().stateDataPath).getRowsAsArray(),loader.get_parent().flatTextureEntries)["sprites"]
	list += bloodSplatter
	
	var animatedSprites = {}
	
	if !bloodSplatter.is_empty():
		animatedSprites.merge({bloodSplatter[0]+"_anim":bloodSplatter})
	
	
	
	return {"sprites":list,"animatedSprites":animatedSprites}
