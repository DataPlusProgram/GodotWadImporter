@tool
extends Node


@export var front = ["MISLA1"] # (Array,String)
@export var frontLeft = [] # (Array,String)
@export var left = [] # (Array,String)
@export var backLeft = [] # (Array,String)
@export var back = ["MISLA5"] # (Array,String)
@export var backRight = ["MISLA6A4"] # (Array,String)
@export var right = ["MISLA7A3"] # (Array,String)
@export var frontRight = ["MISLA8A2"] # (Array,String)
@export var explosion = ["MISLB0","MISLC0","MISLD0"] # (Array,String)

@export var spawnSound: String = ""
@export var idleSound: String = ""
@export var explosionSound: String = "DSBAREXP"
@export var scaleFactor = Vector3(1,1,1)
@export var sizeIncrease = 0.0

var spriteList = []
var animationPlayer 
var animationLibrary
var animatedSprite : AnimatedSprite3D
var loader
var entityLoader






func initialize():
	animationLibrary = AnimationLibrary.new()
	animationPlayer =  $"../AnimationPlayer"
	animationPlayer.add_animation_library("",animationLibrary)
	animatedSprite = $"../AnimatedSprite3D"
	animatedSprite.frames = SpriteFrames.new()
	animatedSprite.pixel_size = (scaleFactor.x * 0.5) + (scaleFactor.x *sizeIncrease)
	
	
	
	get_parent().velo*= scaleFactor.z
	get_parent().splashRadius*= scaleFactor.z
	addSriteCondition(front,[],"front")
	addSriteCondition(frontLeft,frontRight,"frontLeft")
	addSriteCondition(left,right,"left")
	addSriteCondition(backLeft,backRight,"backLeft")
	addSriteCondition(right,left,"right")
	addSriteCondition(frontRight,frontLeft,"frontRight")
	addSriteCondition(backRight,backLeft,"backRight")
	addSriteCondition(back,front,"back")
	
	animatedSprite.animation = "right"
	
	addSprites(explosion,"explosion")
	createAnim("idle",0,2,0.3,true)
	createAnim("explosion",0,explosion.size(),0.3,false)
	initSounds()
	
	
	#var anim = $"../AnimationPlayer".get_animation("explosion")
	var anim = animationLibrary.get_animation("explosion")
	anim.add_track(Animation.TYPE_VALUE,1)
	anim.track_set_path(1,"AnimatedSprite3D:animation")
	anim.track_insert_key(1,0,"explosion")
	
	
	

func addSriteCondition(desired,fallback,sprName):
	if !desired.is_empty(): 
		addSprites(desired,sprName)
		spriteList += desired
	
	if desired.is_empty() and !fallback.is_empty():
		addSprites(flipped(fallback),sprName)
		spriteList += flipped(fallback)
		
	
	


func addSprites(spriteNames,set = "default"):
	for s in spriteNames.size():
		var sprite : Texture2D = loader.fetchDoomGraphic(spriteNames[s])
		
		if sprite == null:
			print("missing srpite:",spriteNames[s])
			sprite = load("res://addons/godotWad/scenes/guns/icon.png")
	
		
		
		if !animatedSprite.sprite_frames.has_animation(set):
			#animatedSprite.sprite_frames.add_animation_library(set)
			animatedSprite.sprite_frames.add_animation(set)

		animatedSprite.sprite_frames.add_frame(set,sprite,s)


func flipped(arr):
	if arr.is_empty():
		return []
	var ret = []
	for i in arr:
		ret.append(i+"_flipped")
	
	return ret

func getSpriteList() -> Dictionary:
	getSpriteCondition(front,[],"front")
	getSpriteCondition(frontLeft,frontRight,"frontLeft")
	getSpriteCondition(left,right,"left")
	getSpriteCondition(backLeft,backRight,"backLeft")
	getSpriteCondition(right,left,"right")
	getSpriteCondition(frontRight,frontLeft,"frontRight")
	getSpriteCondition(backRight,backLeft,"backRight")
	getSpriteCondition(back,front,"back")
	
	for i in explosion:
		if !spriteList.has(i):
			spriteList.append(i)
	
	return {"sprites":spriteList}
	#return spriteList
	
func initSounds():
	if explosionSound != "":
		$"../AudioStreamPlayer3D".explosionSounds=[loader.fetchSound(explosionSound)]
		
	if idleSound != "":
		$"../AudioStreamPlayer3D".idleSounds = [loader.fetchSound(idleSound)]
		
	if spawnSound != "":
		$"../AudioStreamPlayer3D".spawnSounds = [loader.fetchSound(spawnSound)]
		
	

func createAnim(animName,startIndex,numSprites,dur:float,loop=false):
	if numSprites == 0:
		return
	
	
	var anim = Animation.new()
	var id = anim.get_track_count()
	anim.add_track(Animation.TYPE_VALUE,0)
	anim.length = dur
	anim.track_set_path(0,"AnimatedSprite3D:frame")
	#anim.set_loop(loop)
	if loop != false:
		anim.loop_mode = Animation.LOOP_LINEAR
	anim.value_track_set_update_mode(0,anim.UPDATE_DISCRETE)
	var delta = max(dur / numSprites,0.001)
	
	for s in numSprites:
		anim.track_insert_key(0,delta*s,s+startIndex)
	
	
	#var e = animationPlayer.add_animation_library(animName,anim)
	var e = animationLibrary.add_animation(animName,anim)
	
	return anim
	
func getSpriteCondition(desired,fallback,sprNames):
	var ret = []
	
	if !desired.is_empty(): 
		for sprName in desired:
			if !spriteList.has(sprName):
				spriteList.append(sprName)
	
	if desired.is_empty() and !fallback.is_empty():
		for sprName in flipped(fallback):
			if !spriteList.has(sprName):
				spriteList.append(sprName)
