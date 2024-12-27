extends Node3D
var prev_position : Transform3D
var prev_time : int
var next_time : int
var target : Node3D

@export var targeting : TARGET = TARGET.PARENT


enum TARGET{
	SELF,
	PARENT,
	DISABLED
}

func _ready() -> void:
	
	if targeting == TARGET.DISABLED:
		return
	
	if targeting == TARGET.SELF:
		target = self
	else:
		target = get_parent()
		
	prev_position = target.global_transform
	target.global_transform = prev_position
	next_time = Time.get_ticks_msec()
	prev_time =next_time

func _physics_process(delta : float) -> void:
	
	
	
	
	prev_time = Time.get_ticks_msec()
	next_time = prev_time + (delta  * 1000)
	prev_position = target.global_transform

func _process(_delta : float) -> void:
	
	if next_time == prev_time:
		global_transform = prev_position
	else:
		var curtime : int = Time.get_ticks_msec()
		global_transform = prev_position.interpolate_with(target.global_transform, clamp(float(curtime - prev_time) / float(next_time-prev_time), 0.0, 1.0))
		
	$"../cameraAttach/remoteTransform"
