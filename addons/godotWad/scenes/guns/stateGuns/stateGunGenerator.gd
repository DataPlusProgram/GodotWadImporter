@tool
extends Node

signal SpritesLoaded

@export var spriteList : Array[String] = []
@export var spriteListMuzzleFlash: Array[String] = []
@export var worldSprite: String
@export var distanceFromCamera: float = 0.1
@export var idleAnimDuration: float = 0

@export var fireSounds : Array[String]= [] # (Array,String)
@export var impactSound: String = ""
@export var viewportTranslation: Vector3 = Vector3(-0.317,-0.084,-0.35)
@export var spriteSize: float = 0.25

@export var entityDepends : PackedStringArray= [] 
@export var extraYShift: float = 0
@export var wallHitSprite = ["PUFFA0","PUFFB0","PUFFC0","PUFFD0"] # (Array,String)
@export var pickupSound : String= "DSWPNUP"
@export var reloadSound : String = ""
@export var extraSound1 : String = ""
@export var extraSound2 : String = ""

var weaponSwapDepth = 0.08
var weaponSwapDur = 0.5

var scaleFactor =  Vector3.ONE
var loader
var entityLoader
var animationPlayer : AnimationPlayer
var library : AnimationLibrary
var animatedSprite : Node3D
var animatedSpriteMuzzleFlash : Node3D
var sprToOffset = []
var sprToSize = []
var cacheParent = null


func initialize():
	
	
	
	if loader == null:
		queue_free()
		return
	
	for entityStrId in entityDepends:
		ENTG.fetchEntity(entityStrId,entityLoader.get_tree(),loader.get_parent().gameName,false,false,cacheParent).queue_free()
		get_parent().projectile = entityStrId

		
		
	var fov = 70
	var angle = deg_to_rad(fov/2.0)
	var opp = distanceFromCamera*tan(angle)
			
	get_parent().position.z = -distanceFromCamera
	
	#get_parent().position.y = -opp
	get_parent().scaleFactor = scaleFactor
	
	
	if get_node_or_null("soundAlert") != null:
		$"../soundAlert".get_node("CollisionShape3D").radius *= scaleFactor.x
	
	get_parent().holsterY = weaponSwapDepth
	library = AnimationLibrary.new()
	animationPlayer =  $"../AnimationPlayer"
	
	animationPlayer.add_animation_library("",library)
	
	animatedSprite = $"../AnimatedSprite3D"
	animatedSprite.position.z = -0.000001
	#animatedSprite.scaleFactor = scaleFactor*0.1*spriteSize
	
	var muzzleLibrary = AnimationLibrary.new()
	
	animatedSpriteMuzzleFlash = $"../muzzleFlash"
#	animatedSpriteMuzzleFlash.scaleFactor = scaleFactor*0.1*spriteSize
	
	var ret = WADG.getSpritesAndFrames( load(get_parent().stateResPath).getRowsAsArray(),loader.get_parent().flatTextureEntries)
	var frames : Dictionary = ret["frames"]

	
	var aabb = Vector2(-INF,-INF)
	
	for frameName in frames:
		var subAABB = addRow(frameName,frames[frameName],animatedSprite)
		if subAABB.x > aabb.x: aabb.x =  subAABB.x
		if subAABB.y > aabb.y: aabb.y=  subAABB.y
	
	#if ret["sprites"][0] == "SHT2A0":
	#	breakpoint
	
	var flashFrames : Dictionary = WADG.getFlashSpritesAndFrames( load(get_parent().stateResPath).getRowsAsArray(),loader.get_parent().flatTextureEntries)["frames"]
	
	for flashFrameName in flashFrames:
		
		
		
		var subAABB = addRow(flashFrameName,flashFrames[flashFrameName],animatedSpriteMuzzleFlash)
	
	
	initSounds()

	
	animatedSprite.curAnimation = "default"
	animatedSprite.setMat("A")

	animatedSpriteMuzzleFlash.curAnimation = "default"
	animatedSpriteMuzzleFlash.setMat("A")
	$"../soundAlert".scale = Vector3.ONE
	get_parent().wallHitSprite = loader.fetchAnimatedSimple("puff",wallHitSprite,4,true)

	createBringDown()
	createBringUp()

	get_parent().worldSprite = loader.fetchDoomGraphic(worldSprite)
	get_parent().worldSpriteName = worldSprite
	get_parent().set_meta("worldSprite",worldSprite)
	get_parent().pickupSound = loader.fetchSound(pickupSound)
	
	

func createAnim(animName,startIndex,numSprites,dur:float):
	if numSprites == 0:
		var anim = Animation.new()
		var e = animationPlayer.add_animation_library(animName,anim)
		return
	
	
	var anim = Animation.new()
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
		var sprOffset = sprToOffset[s+startIndex]
		addMethodTrackKey(animName,0,delta*s,{"method":"setMat","args":[s+startIndex]})

func createBringDown():
	
	var anim = Animation.new()
	anim.add_track(Animation.TYPE_VALUE,0)
	anim.length = weaponSwapDur
	anim.track_set_path(0,"AnimatedSprite3D:position")
	
	
	
#	var spr : ImageTexture =animatedSprite.frames.get_frame("default",0)
#var spr : Texture2D =animatedSprite.get_frame("default",0)
		
	anim.track_insert_key(0,0,Vector3(0,0,0))
	anim.track_insert_key(0,weaponSwapDur,Vector3(0,weaponSwapDepth,0))
	

	
	#anim.track_insert_key(0,0,Vector3(-offset.x,-h+offset.y,0))#+Vector2(viewportTranslation.x,viewportTranslation.y))
	#anim.track_insert_key(0,anim.length,Vector3(-offset.x,-h+offset.y-0.5,0))#+Vector2(viewportTranslation.x,viewportTranslation.y))
	
	library.add_animation("bringDown",anim)
	

func createBringUp():
	
	var anim = Animation.new()
	anim.add_track(Animation.TYPE_VALUE,0)
	anim.length = weaponSwapDur
	anim.track_set_path(0,"AnimatedSprite3D:position")
	
	var spr : Texture2D =animatedSprite.get_frame("default",0)
	#var offset = animatedSprite.sprToOffset[0]# * Vector2(scaleFactor.x,scaleFactor.y)
	
	#var h = 0#spr.size.y
	#var w = 9#spr.size.x
	
	anim.track_insert_key(0,0,Vector3(0,weaponSwapDepth,0))
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
		
	if !extraSound1.is_empty():
		$"../AudioStreamPlayer3D".extraSound1 = loader.fetchSound(extraSound1)
		
	if !extraSound2.is_empty():
		$"../AudioStreamPlayer3D".extraSound2 = loader.fetchSound(extraSound2)
		
	if !reloadSound.is_empty():
		$"../AudioStreamPlayer3D".reloadSound = loader.fetchSound(reloadSound)
		
func getSpriteList():
	var ret = []
	ret = WADG.getSpritesAndFrames( load(get_parent().stateResPath).getRowsAsArray(),loader.get_parent().flatTextureEntries)["sprites"]

	#var ret2 = []
	
	#for i in ret:
	#	ret2.append([i,true])
	

	
	if worldSprite != "":
		ret.append(worldSprite)
	
	for i in spriteListMuzzleFlash:
		ret.append(i)
	
	
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


func addRow(rowName : String,spriteNames : Dictionary,mesh : MeshInstance3D) -> Vector2:
	var rowSprite : Array[Texture2D] = []
	var rowOffsets : Array[Vector2] = []
	var aabb = Vector2(-INF,-INF)
	
	for sprName in spriteNames.values():
		if sprName == null:
			rowSprite.append(null)
		else:
			var tex : Texture2D = loader.fetchDoomGraphic(sprName)
			if tex.get_width()*scaleFactor.x > aabb.x: aabb.x = tex.get_width()*scaleFactor.x
			if tex.get_height()*scaleFactor.y > aabb.y: aabb.y = tex.get_height()*scaleFactor.y
			rowSprite.append(tex)
			rowOffsets.append(loader.fetchDoomGraphicOffset(sprName))
	
	var mat : Material 
	
	
	mat = loader.materialManager.fetchFovSpriteMaterial(spriteNames["All"],rowSprite[0],rowOffsets[0],Color.WHITE)
	mesh.add_frame(rowName,mat)
	
	
	return aabb
