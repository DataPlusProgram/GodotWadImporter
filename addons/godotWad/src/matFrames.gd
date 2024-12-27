@tool
extends Resource
class_name matFrames

@export var frame: int

@export var frames: Dictionary = {}
@export var test : String = "erw"
	
func get_frame(animName,frame):
	if !frames.has(animName):
		return
	return frames[frame]
	
	
func has_animation(animName) -> bool:
	return frames.has(animName)
	
func add_animation_library(animName) -> void:
	if !frames.has(animName):
		frames[animName] = []
			
func add_frame(anim : String,frame : Texture2D,position:int):
	frames[anim].insert(position,frame)
