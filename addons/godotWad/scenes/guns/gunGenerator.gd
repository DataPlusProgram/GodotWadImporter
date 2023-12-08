tool
extends Node

signal SpritesLoaded

export(Array,String) var idleSpriteNames
export(Array,String) var shootSpriteNames
export(String) var worldSprite
export(float) var distanceFromCamera = 0.1
export(float) var idleAnimDuration = 0

export(Array,String) var fireSounds = []
export(String) var impactSound = ""
export(Vector3) var viewportTranslation = Vector3(-0.317,-0.084,-0.35)
export(float) var spriteSize = 0.25

export(Array,String) var entityDepends = []
export(float) var extraYShift = 0
export(Array,String) var wallHitSprite = ["PUFFA0","PUFFB0","PUFFC0","PUFFD0"]

var scaleFactor =  Vector3.ONE
var loader
var entityLoader
var animationPlayer 
var animatedSprite : Spatial




func initialize():
	if loader == null:
		queue_free()
		return
	
	for entityStrId in entityDepends:
		ENTG.fetchEntity(entityStrId,entityLoader.get_tree(),loader.get_parent().gameName,false).queue_free()
		get_parent().projectile = entityStrId

		
	#get_parent().translation = viewportTranslation
	#get_parent().translation.y = (0.7*viewportTranslation.z) +  0.334
	#get_parent().translation.y += extraYShift
	
	#var c = get_viewport().get_camera()
	
	#get_parent().translation.y -= -0.0243
	#if get_viewport()!= null:
		#var c = get_viewport().get_camera();
	#if c!= null:
	var fov = 70
	var angle = deg2rad(fov/2.0)
	var opp = distanceFromCamera*tan(angle)
			
	get_parent().translation.z = -distanceFromCamera
	get_parent().translation.y = -opp
	get_parent().scaleFactor = scaleFactor
	
	
	if get_node_or_null("soundAlert") != null:
		$"../soundAlert".get_node("CollisionShape").radius *= scaleFactor.x
	
	
	animationPlayer =  $"../AnimationPlayer"
	animatedSprite = $"../AnimatedSprite3D"
	
	animatedSprite.frames = SpriteFrames.new()
	#animatedSprite.pixel_size = 0.002#*scaleFactor
	animatedSprite.scaleFactor = Vector3(0.0032,0.0032,0.0032)*spriteSize
	
	initSounds()
	initSprites()
	
	
	#var spr : Texture =animatedSprite.frames.get_frame("default",0)
	#var offset = sprToOffset[0]
	#var h = spr.size.y
	#var w = spr.size.x
	
	animatedSprite.curAnimation = "default"
	animatedSprite.setMat([0])

	
	var x = animatedSprite.frameList
	
	createAnim("idle",0,idleSpriteNames.size(),idleAnimDuration)
	createAnim("fire",idleSpriteNames.size(),shootSpriteNames.size(),get_parent().shootDurationMS/1000.0)
	
	get_parent().wallHitSprite = loader.fetchAnimatedSimple("puff",wallHitSprite)


	addMethodTrack("fire","playFire")
	createBringDown()
	createBringUp()

	get_parent().worldSprite = loader.fetchDoomGraphic(worldSprite)
	get_parent().set_meta("worldSprite",worldSprite)
	get_parent().remove_child(self)
	queue_free()
	
	

var sprToOffset = []

func initSprites():
	
	animatedSprite.add_animation("default")
	var allSprites = idleSpriteNames + shootSpriteNames
	
	for s in allSprites.size():
		
		var sprite : Texture = loader.fetchDoomGraphic(allSprites[s])
		
		

		var offset : Vector2 = loader.fetchDoomGraphicOffset(allSprites[s])
		
		if sprite == null:
			print("missing srpite:",allSprites[s]," for weapon ",get_parent().weaponName)
			sprite = load("res://addons/godotWad/scenes/guns/icon.png")
		
		
		
		animatedSprite.frames.add_frame("default",sprite,s)
		
		var mat = loader.fetchSpriteMaterial(allSprites[s],true)
		animatedSprite.add_frame("default",mat,s)
		#animatedSprite.frames.add_frame("default",mat,s)
		
		
		#sprToOffset.append(offset)
		sprToOffset.append(Vector3.ZERO)
		#breakpoint


func createAnim(animName,startIndex,numSprites,dur:float):
	if numSprites == 0:
		var anim = Animation.new()
		var e = animationPlayer.add_animation(animName,anim)
		return
	
	
	var anim = Animation.new()
	#anim.add_track(Animation.TYPE_VALUE,0)
	var e = animationPlayer.add_animation(animName,anim)
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
		var sprOffset = sprToOffset[s+startIndex]
		
		
		#var h = spr.get_size().y
		#var w = spr.get_size().x
		
		var totalOffset = sprOffset#+Vector2(viewportTranslation.x,viewportTranslation.y)
		
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
	var spr : Texture =animatedSprite.get_frame("default",0)
	var offset = sprToOffset[0]
	
	var h = 0
	var w = 0
	
	if spr != null:
		h =spr.get_size().y
		w =spr.get_size().x

		
		
	anim.track_insert_key(0,0,Vector3(0,0,0))
	anim.track_insert_key(0,anim.length,Vector3(0,0.08,0))
	
	#anim.track_insert_key(0,0,Vector3(-offset.x,-h+offset.y,0))#+Vector2(viewportTranslation.x,viewportTranslation.y))
	#anim.track_insert_key(0,anim.length,Vector3(-offset.x,-h+offset.y-0.5,0))#+Vector2(viewportTranslation.x,viewportTranslation.y))
	
	
	var e = animationPlayer.add_animation("bringDown",anim)

func createBringUp():
	
	var anim = Animation.new()
	anim.add_track(Animation.TYPE_VALUE,0)
	anim.length = 0.25
	anim.track_set_path(0,"AnimatedSprite3D:offset")
	
	var spr : Texture =animatedSprite.get_frame("default",0)
	var offset = sprToOffset[0]# * Vector2(scaleFactor.x,scaleFactor.y)
	
	var h = 0#spr.size.y
	var w = 9#spr.size.x
	
	anim.track_insert_key(0,0,Vector3(0,0.08,0))
	anim.track_insert_key(0,anim.length,Vector3(0,0,0))
	
	
	#anim.track_insert_key(0,0,Vector3(-offset.x,-h+offset.y-0.5,0))
	#anim.track_insert_key(0,anim.length,Vector3(-offset.x,-h+offset.y,0))
	
	var e = animationPlayer.add_animation("bringUp",anim)


func initSounds():
	
	$"../AudioStreamPlayer3D".fireSounds = []
	#$"../AudioStreamPlayer3D".impactSound = null
	for i in fireSounds:
		var t  = loader.fetchSound(i)
		var y = $"../AudioStreamPlayer3D"
		var x =  $"../AudioStreamPlayer3D".fireSounds
		
		$"../AudioStreamPlayer3D".fireSounds.append(t)
	
	if !impactSound.empty():
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
	var anim = animationPlayer.get_animation(animName)
	anim.add_track(Animation.TYPE_METHOD,1)
	anim.track_set_path(1,"AudioStreamPlayer3D")
	anim.track_insert_key(1,0,{"method":methodName,"args":[]})


func addMethodTrackOnly(nodeName : String,animName: String,methodName: String,args : Array = []) -> void:
	var anim : Animation = animationPlayer.get_animation(animName)
	anim.add_track(Animation.TYPE_METHOD,0)
	anim.track_set_path(0,nodeName)

func addMethodTrackKey(var animName , var trackIdx,var time,var funcDict) -> void:
	var anim : Animation = animationPlayer.get_animation(animName)
	anim.track_insert_key(trackIdx,time,{"method":funcDict["method"],"args":[funcDict["args"]]})

