tool
extends Resource
class_name matFrames

export(int) var frame

export(Dictionary) var frames = {}
export var test : String = "erw"
	
func get_frame(animName,frame):
	if !frames.has(animName):
		return
	return frames[frame]
	
	
func has_animation(animName) -> bool:
	return frames.has(animName)
	
func add_animation(animName) -> void:
	if !frames.has(animName):
		frames[animName] = []
			
func add_frame(anim : String,frame : Texture,position:int):
	frames[anim].insert(position,frame)
