extends RayCast3D


var maxLength : float= 1000
var pColPoint  = null
var stopperGroup : StringName= &"player" 

var targetNode : Node = null :  set = targetSet
var curLen : float= 100
var pRot : float= 0
var pMe : Vector3= Vector3.ZERO
var pTarget :Vector3= Vector3.ZERO
var pDiff : Vector3= Vector3.ZERO

@onready var parent : Node3D = get_parent()

signal physicsFrameSignal



func _physics_process(delta: float) -> void:
	
	if targetNode != null:
		if is_instance_valid(targetNode):
			if pRot != -parent.rotation.y:#if we have rotated since last frame adjust
				rotation.y = -parent.rotation.y
		
			pRot = -parent.rotation.y
			
			towardsTarget()

		if enabled == false:
			enabled = true
	else:
		
		emit_signal("physicsFrameSignal")
		return
	
	
	
	if !is_colliding():
		curLen = min(curLen+1,maxLength)#we increase the length and return so we can see what the next frame says
		return

	var colPoint =  get_collision_point()
	
	
	if pColPoint == null or colPoint.distance_squared_to(pColPoint) > 0.1:#if we didn't collide with something last frame or the distance between the last two collision is > 0.1
		
		if get_collider() != null:
			if get_collider().get_class() == "CharacterBody3D" and !get_collider().is_in_group(stopperGroup) and get_collider() != targetNode:
				add_exception(get_collider())
			else:
				curLen = (global_position- get_collision_point()).length()*1.01

	if get_collider() != null:
		curLen = (global_position- get_collision_point()).length()*1.01
		
	
	emit_signal("physicsFrameSignal")

func towardsTarget() -> void:
	var diff : Vector3 = pDiff
	
	if is_inside_tree() and targetNode.is_inside_tree():
		diff = global_position - targetNode.global_position
	else:
		diff = position - targetNode.position
	
	var h : float = 0
	
	if "height" in targetNode:
		h = targetNode.height
	
	diff.y -= h*0.9
	
	pMe =global_position
	
	if targetNode.is_inside_tree():
		pTarget = targetNode.global_position
	else:
		pTarget = targetNode.position
		

	var toCast : Vector3 = diff.normalized()*-curLen
	
	
	if toCast != target_position:
		if target_position != toCast:#*-curLen:
			target_position = toCast#*-curLen
			
			
	
func targetSet(target):
	if targetNode == target:
		return
	
	if target is CollisionObject3D:
		remove_exception(target)
	
	
	targetNode = target

	
