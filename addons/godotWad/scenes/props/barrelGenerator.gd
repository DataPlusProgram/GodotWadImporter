@tool
extends Node


@export var idleSpriteNames = ["BAR1A0","BAR1B0"] # (Array,String)
@export var explodingSpriteNames = ["BEXPC0","BEXPD0","BEXPD0"] # (Array,String)
@export var explodeSound: String = "DSBAREXP"
@export var scaleFactor = 1.0

var animationPlayer 
var animationLibrary : AnimationLibrary
var animatedSprite
var sceneTree
var loader = null


func initialize():
	
	get_parent().scaleFactor = scaleFactor
	if loader == null:
		queue_free()
		return

		
	
	
	animationPlayer =  $"../AnimationPlayer"
	animatedSprite = $"../AnimatedSprite3D"
	
	animationLibrary = animationPlayer.get_animation_library("")
	
	
	animatedSprite.frames = SpriteFrames.new()
	
	addSprites()
	animatedSprite.pixel_size = scaleFactor.x
	
	var height = $"../CollisionShape3D".shape.extents.y * scaleFactor.y
	
	$"../BlastZone/CollisionShape3D".shape.extents *= scaleFactor
	$"../CollisionShape3D".shape.extents *= scaleFactor
	
	for i in get_parent().get_children():
		if "position" in i:
			i.position.y = height
			
	createAnim("idle",0,idleSpriteNames.size(),0.5,true)
	createAnim("explode",idleSpriteNames.size(),explodingSpriteNames.size(),0.5)
	initSounds()
	animationPlayer.autoplay = "idle"
	

func addSprites():
	var allSprites = idleSpriteNames + explodingSpriteNames
	
	for s in allSprites.size():
		var sprite : Texture2D = loader.fetchDoomGraphic(allSprites[s])
	
		if sprite == null:
			print("missing srpite:",allSprites[s])
			sprite = load("res://addons/godotWad/scenes/guns/icon.png")
			
		
		animatedSprite.sprite_frames.add_frame("default",sprite,s)
		
		


func initSounds():
	var arr = []
	var sound = loader.fetchSound(explodeSound)
	$"../AudioStreamPlayer3D".stream = sound
	
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
	
	animationLibrary.add_animation(animName,anim)
	#var e = animationPlayer.add_animation_library(animName,anim)

func getSpriteList():
	return {"sprites":idleSpriteNames + explodingSpriteNames}
