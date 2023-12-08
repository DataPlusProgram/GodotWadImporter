tool
extends Node

signal SpritesLoaded

export(NodePath) var loaderPath
export(Array,String) var idleSpriteNames
export(Array,String) var shootSpriteNames

export(float) var idleAnimDuration = 0
export(float) var shootAnimDurationMS = 300

export(Array,String) var shootSounds = []

var loader
var initialized = false
var animationPlayer : AnimationPlayer
var animatedSprite : AnimatedSprite3D
var scaleFactor = 1

func _ready():
	
	
	if !Engine.editor_hint:
		yield(get_parent(), "ready")
		
		initialize(false)


func initialize(toDisk=true):
	
	loader = get_node_or_null(loaderPath)
	
	if toDisk:
		loader.get_parent().createDirectories()
	
	
	if loader == null:
		queue_free()
		return
	
	animationPlayer =  AnimationPlayer.new()
	animatedSprite = AnimatedSprite3D.new()
	animatedSprite.frames = SpriteFrames.new()
	
	animatedSprite.pixel_size = 0.002 * scaleFactor
	
	animatedSprite.name = "AnimatedSprite"
	animationPlayer.name = "AnimationPlayer"
	
	
	get_parent().add_child(animatedSprite)
	get_parent().add_child(animationPlayer)
	
	animationPlayer.set_owner(get_parent())
	animatedSprite.set_owner(get_parent())
	
	initSounds()
	
	initSprites()
	initTail()



func initTail():
	createAnim("idle",0,idleSpriteNames.size(),idleAnimDuration)
	createAnim("fire",idleSpriteNames.size(),shootSpriteNames.size(),shootAnimDurationMS/1000.0)
	
	createBringDown()
	createBringUp()
	
	var pack = PackedScene.new()
	pack.pack(get_parent())
	

	initialized = true

func initSprites():
	var allSprites = idleSpriteNames + shootSpriteNames
	
	for s in allSprites.size():
		
		var sprite : Texture = loader.fetchDoomGraphic(allSprites[s])
	
		if sprite == null:
			print("missing srpite:",allSprites[s]," for weapon ",get_parent().weaponName)
			sprite = load("res://addons/godotWad/scenes/guns/icon.png")
		
		
		
		if loader.get_parent().textureFiltering == false: 
			sprite.flags -= Texture.FLAG_FILTER

		if loader.get_parent().mipMaps == loader.get_parent().MIP.OFF:
			sprite.flags -= Texture.FLAG_MIPMAPS
	
		
		animatedSprite.frames.add_frame("default",sprite,s)
	emit_signal("SpritesLoaded")
		


func createAnim(animName,startIndex,numSprites,dur:float):
	if numSprites == 0:
		return
	
	
	var anim = Animation.new()
	anim.add_track(Animation.TYPE_VALUE,0)
	anim.length = dur
	anim.track_set_path(0,"AnimatedSprite:frame")
	
	var delta = max(dur / numSprites,0.001)
	
	for s in numSprites:
		anim.track_insert_key(0,delta*s,s+startIndex)
	
	
	var e = animationPlayer.add_animation(animName,anim)

func createBringDown():
	
	var anim = Animation.new()
	anim.add_track(Animation.TYPE_VALUE,0)
	anim.length = 0.25
	anim.track_set_path(0,"AnimatedSprite:offset")
	
	anim.track_insert_key(0,0,Vector3.ZERO)
	anim.track_insert_key(0,anim.length,Vector3(0,-50,0))
	
	var e = animationPlayer.add_animation("bringDown",anim)

func createBringUp():
	
	var anim = Animation.new()
	anim.add_track(Animation.TYPE_VALUE,0)
	anim.length = 0.25
	anim.track_set_path(0,"AnimatedSprite:offset")
	
	anim.track_insert_key(0,0,Vector3(0,-50,0))
	anim.track_insert_key(0,anim.length,Vector3.ZERO)
	
	var e = animationPlayer.add_animation("bringUp",anim)


func initSounds():
	
	var arr = []
	
	for s in shootSounds:
		var sound = loader.fetchSound(s)
		var p = get_parent()
		arr.append(sound)
		
	get_parent().shootSounds = arr
