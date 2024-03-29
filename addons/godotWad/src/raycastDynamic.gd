extends RayCast


var maxLength = 1000
var pColPoint = null
var stopperGroup = "player"

var targetNode  = null
var curLen = 100
var pRot = 0
var pMe = Vector3.ZERO
var pTarget = Vector3.ZERO
var pDiff = Vector3.ZERO

func _physics_process(delta):
	
	
	
	if targetNode != null:
		if is_instance_valid(targetNode):
			if pRot != -get_parent().rotation.y:#if we have rotated since last frame adjust
				rotation.y = -get_parent().rotation.y
		
			pRot = -get_parent().rotation.y
			
			towardsTarget()
		
		
		
		if enabled == false:
			enabled = true
	else:
		enabled = false
		return
	
	
	
	if !is_colliding():
		curLen = min(curLen+1,maxLength)#we increase the length and return so we can see what the next frame says
		return

	var colPoint =  get_collision_point()
	
	
	if pColPoint == null or colPoint.distance_squared_to(pColPoint) > 0.1:#if we didn't collide with something last frame or the distance between the last two collision is > 0.1
		
		if get_collider() != null:
			if get_collider().get_class() == "KinematicBody" and !get_collider().is_in_group(stopperGroup):
				add_exception(get_collider())
			else:
				curLen = (global_translation- get_collision_point()).length()*1.01

	if get_collider() != null:
		curLen = (global_translation- get_collision_point()).length()*1.01

func towardsTarget():
	var diff = pDiff
	
	diff = global_translation - targetNode.global_translation
	
	var h = 0
	
	if "height" in targetNode:
		h = targetNode.height
	
	diff.y -= h*0.9
	
	pMe =global_translation
	pTarget = targetNode.global_translation
	
	var toCast = diff.normalized()*-curLen
	
	
	if toCast != cast_to:
		if cast_to != toCast:#*-curLen:
			cast_to = toCast#*-curLen
			
			
	
