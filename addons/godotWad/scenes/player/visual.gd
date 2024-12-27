extends Node3D
var prev_position : Transform3D
var prev_time : int
var next_time : int
var target : Node3D
var nextCamOffset = 0
var totatCamOffsetY = 0
var pCamOffset = 0
@export var targeting : TARGET = TARGET.PARENT

var camOffset = Vector3(0,0,0)

enum TARGET{
	SELF,
	PARENT,
	DISABLED
}

func _ready() -> void:
	
	get_parent().physicsProc.connect(tick)
	
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

func tick(delta : float , ppos) -> void:
	camOffset.y += nextCamOffset
	nextCamOffset = 0
	nextCamOffset = get_parent().camOffsetY
	get_parent().camOffsetY = 0
	var eyeHeight =  get_parent().height * get_parent().eyeHeightRatio
	var height = get_parent().height
	nextCamOffset = clamp(nextCamOffset,-0.5*eyeHeight,0.9*height)
	
	prev_time = Time.get_ticks_msec()
	next_time = prev_time + (delta  * 1000)
	prev_position = ppos
	

func _process(delta : float) -> void:

	
	
	if next_time == prev_time:
		
		global_transform = prev_position
	else:
		var curtime : int = Time.get_ticks_msec()
		
		global_transform = prev_position.interpolate_with(target.global_transform.translated((Vector3(0.0,nextCamOffset,0.0))), clamp(float(curtime - prev_time) / float(next_time-prev_time), 0.0, 1.0))


	var eyeHeight =  get_parent().height * get_parent().eyeHeightRatio
	var height = get_parent().height
	var bobAngle = get_parent().bobAngle
	

	camOffset.y = clamp(camOffset.y,-0.5*eyeHeight,0.9*height)
	
	if camOffset.y < 0:
		camOffset.y = min(0,camOffset.y+delta*5)
	
	if camOffset.y > 0:
		camOffset.y = max(0,camOffset.y-delta*5)
		
	$cameraAttach.position.y =  eyeHeight + sin(bobAngle*0.75)*0.1 + camOffset.y
	get_parent().weaponManager.position.y = eyeHeight + sin(bobAngle*0.75)*0.1  + camOffset.y
	
