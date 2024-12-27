@tool
extends Node

signal SpritesLoaded

@export var idleSpriteNames :Array # (Array,String)
@export var shootSpriteNames :  Array# (Array,String)
@export var worldSprite: String
@export var distanceFromCamera: float = 0.1
@export var idleAnimDuration: float = 0

@export var fireSounds = [] # (Array,String)
@export var impactSound: String = ""
@export var spriteSize: float = 0.25
@export var entityDepends : PackedStringArray = []
@export var extraYShift: float = 0
@export var wallHitSprite = ["PUFFA0","PUFFB0","PUFFC0","PUFFD0"] # (Array,String)
@export var pickupSound : String= "DSWPNUP"

var cacheParent = null
var scaleFactor =  Vector3.ONE
var loader
var entityLoader
var animationPlayer : AnimationPlayer
var library : AnimationLibrary
var animatedSprite : Node3D
var sprToOffset = []
var sprToSize = []



func initialize():
	if loader == null:
		queue_free()
		return
	
	for entityStrId in entityDepends:
		ENTG.fetchEntity(entityStrId,entityLoader.get_tree(),loader.get_parent().gameName,false,false,cacheParent).queue_free()
		get_parent().projectile = entityStrId

	
#	var fov = 70
	#var angle = deg_to_rad(fov/2.0)
	#var opp = distanceFromCamera*tan(angle)
			
	get_parent().position.z = -distanceFromCamera
	get_parent().scaleFactor = scaleFactor
	
	
	if get_node_or_null("soundAlert") != null:
		$"../soundAlert".get_node("CollisionShape3D").radius *= scaleFactor.x
	
	
	library = AnimationLibrary.new()
	animationPlayer =  $"../AnimationPlayer"
	
	animationPlayer.add_animation_library("",library)
	
	animatedSprite = $"../AnimatedSprite3D"
	
	animatedSprite.frames = SpriteFrames.new()
	animatedSprite.scaleFactor = scaleFactor*0.1*spriteSize
	animatedSprite.screenSpace = true
	initSounds()
	
	var ret = WADG.getSpritesAndFrames( load(get_parent().stateDataPath).getRowsAsArray(),loader.get_parent().flatTextureEntries)
	var frames : Dictionary = ret["frames"]

	
	var aabb = Vector2(-INF,-INF)
	
	for frameName in frames:
		var subAABB = addRow(frameName,frames[frameName])
		if subAABB.x > aabb.x: aabb.x =  subAABB.x
		if subAABB.y > aabb.y: aabb.y=  subAABB.y
	
	
	#initSprites()
	
	animatedSprite.curAnimation = "default"
	animatedSprite.setMat([0])
	
	
	createAnim("idle",0,idleSpriteNames.size(),idleAnimDuration)
	createAnim("fire",idleSpriteNames.size(),shootSpriteNames.size(),get_parent().shootDurationMS/1000.0)
	
	get_parent().wallHitSprite = loader.fetchAnimatedSimple("puff",wallHitSprite,4,true)


	addMethodTrack("fire","playFire")
	createBringDown()
	createBringUp()

	get_parent().worldSprite = loader.fetchDoomGraphic(worldSprite)
	get_parent().set_meta("worldSprite",worldSprite)
	get_parent().pickupSound = loader.fetchSound(pickupSound)
	
	get_parent().remove_child(self)
	queue_free()
	
	


func initSprites():
	
	animatedSprite.add_animation_library("default")
	var allSprites = idleSpriteNames + shootSpriteNames
	
	for s in allSprites.size():
		
		var sprite : Texture2D = loader.fetchDoomGraphic(allSprites[s])
		var offset : Vector2 = loader.fetchDoomGraphicOffset(allSprites[s])
		
		animatedSprite.sprToOffset.append(offset)
		sprToSize.append(sprite.get_size())

		
		
		if sprite == null:
			print("missing srpite:",allSprites[s]," for weapon ",get_parent().weaponName)
			sprite = load("res://addons/godotWad/scenes/guns/icon.png")
		
		
		
		animatedSprite.frames.add_frame("default",sprite,s)
		
		var mat = loader.fetchSpriteMaterial(allSprites[s],true)
		animatedSprite.add_frame("default",mat,s)
		#animatedSprite.frames.add_frame("default",mat,s)
		
		
		#sprToOffset.append(offset)
		#get_parent().sprToOffset.append(Vector3.ZERO)
		#breakpoint


func createAnim(animName,startIndex,numSprites,dur:float):
	if numSprites == 0:
		var anim = Animation.new()
		var e = animationPlayer.add_animation_library(animName,anim)
		return
	
	
	var anim = Animation.new()
	#anim.add_track(Animation.TYPE_VALUE,0)
	var e = library.add_animation(animName,anim)
	
	addMethodTrackOnly("AnimatedSprite3D",animName,"setMat")
	anim.length = dur
	anim.track_set_path(0,"AnimatedSprite3D:frame")
	
	
	
	anim.add_track(Animation.TYPE_VALUE,1)
	anim.length = dur
	anim.track_set_path(1,"AnimatedSprite3D:offset")
	anim.value_track_set_update_mode(1,Animation.UPDATE_DISCRETE)
	
	var delta = max(dur / numSprites,0.001)
	
	
	
	for s in numSprites:
		
		
		#var spr : Texture =animatedSprite.frames.get_frame("default",s+startIndex)
		var sprOffset = animatedSprite.sprToOffset[s+startIndex]
		
		
		#var h = spr.get_size().y
		#var w = spr.get_size().x
		
		var w = sprOffset#+Vector2(viewportTranslation.x,viewportTranslation.y)
		
		addMethodTrackKey(animName,0,delta*s,{"method":"setMat","args":[s+startIndex]})
		#anim.track_insert_key(0,delta*s,s+startIndex)
		#anim.track_insert_key(1,0,sprOffset)
		
	#	var diff = -offset.x
		#print(diff)
		
		

		
	
	
	#var e = animationPlayer.add_animation(animName,anim)
	

func createBringDown():
	
	var anim = Animation.new()
	anim.add_track(Animation.TYPE_VALUE,0)
	anim.length = 0.25
	anim.track_set_path(0,"AnimatedSprite3D:offset")
	
	
	
#	var spr : ImageTexture =animatedSprite.frames.get_frame("default",0)
	var spr : Texture2D =animatedSprite.get_frame("default",0)
	var offset = animatedSprite.sprToOffset[0]
	
	var h = 0
	var w = 0
	
	if spr != null:
		h =spr.get_size().y
		w =spr.get_size().x

		
		
	anim.track_insert_key(0,0,Vector3(0,0,0))
	anim.track_insert_key(0,anim.length,Vector3(0,0.08,0))
	
	#anim.track_insert_key(0,0,Vector3(-offset.x,-h+offset.y,0))#+Vector2(viewportTranslation.x,viewportTranslation.y))
	#anim.track_insert_key(0,anim.length,Vector3(-offset.x,-h+offset.y-0.5,0))#+Vector2(viewportTranslation.x,viewportTranslation.y))
	
	library.add_animation("bringDown",anim)
	

func createBringUp():
	
	var anim = Animation.new()
	anim.add_track(Animation.TYPE_VALUE,0)
	anim.length = 0.25
	anim.track_set_path(0,"AnimatedSprite3D:offset")
	
	var spr : Texture2D =animatedSprite.get_frame("default",0)
	var offset = animatedSprite.sprToOffset[0]# * Vector2(scaleFactor.x,scaleFactor.y)
	
	var h = 0#spr.size.y
	var w = 9#spr.size.x
	
	anim.track_insert_key(0,0,Vector3(0,0.08,0))
	anim.track_insert_key(0,anim.length,Vector3(0,0,0))
	
	
	#anim.track_insert_key(0,0,Vector3(-offset.x,-h+offset.y-0.5,0))
	#anim.track_insert_key(0,anim.length,Vector3(-offset.x,-h+offset.y,0))
	library.add_animation("bringUp",anim)
	#var e = animationPlayer.add_animation_library("bringUp",anim)


func initSounds():
	
	$"../AudioStreamPlayer3D".fireSounds = []
	#$"../AudioStreamPlayer3D".impactSound = null
	for i in fireSounds:
		var t  = loader.fetchSound(i)
		
		$"../AudioStreamPlayer3D".fireSounds.append(t)
	
	if !impactSound.is_empty():
		$"../AudioStreamPlayer3D".impactSound =  loader.fetchSound(impactSound)
		
func getSpriteList():
	var ret = []
	ret = idleSpriteNames + shootSpriteNames 
	ret = idleSpriteNames + shootSpriteNames 
	
	var ret2 = []
	
	for i in ret:
		ret2.append([i,true])
	
	if worldSprite != "":
		ret.append(worldSprite)
	
	
	
	
	
	return {"sprites":ret,"spritesFOV":ret,"animatedSprites":{"puff":wallHitSprite}}




func addMethodTrack(animName,methodName):
	var anim = library.get_animation(animName)
	anim.add_track(Animation.TYPE_METHOD,1)
	anim.track_set_path(1,"AudioStreamPlayer3D")
	anim.track_insert_key(1,0,{"method":methodName,"args":[]})


func addMethodTrackOnly(nodeName : String,animName: String,methodName: String,args : Array = []) -> void:
	var anim : Animation = library.get_animation(animName)
	anim.add_track(Animation.TYPE_METHOD,0)
	anim.track_set_path(0,nodeName)

func addMethodTrackKey(animName, trackIdx, time, funcDict) -> void:
	var anim : Animation = library.get_animation(animName)
	anim.track_insert_key(trackIdx,time,{"method":funcDict["method"],"args":[funcDict["args"]]})


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
	

	mat = loader.materialManager.fetchFovSpriteMaterial(spriteNames["All"],rowSprite[0],Color.WHITE)

	ResourceSaver.save(mat,"res://dbg/gun.tres")
	animatedSprite.add_frame(rowName,mat)
	
	
	return aabb
