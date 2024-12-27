@tool
extends Node3D

@export var height = 0.25: set = setRatio



func _physics_process(delta):
	
	if !"height" in get_parent():
		return
		
	
	$"mid/high".position.y = height
	$"left/high".position.y = height
	$"right/high".position.y = height
	

	if !stepUp($mid,delta):
		if !stepUp($left,delta):
			stepUp($right,delta)
	

func setRatio(r):
	height = r


func stepUp(node,delta):
	var high = node.get_node("high")
	var low = node.get_node("low")
	var diff = node.get_node("diff")
	
	diff.position.z =low.target_position.z
	
	var colHigh = high.get_collider()
	var colLow = low.get_collider()
	
	diff.target_position.y = high.position.y -  low.position.y
	
	if colLow!=null and colHigh == null:
		var xzVelo = Vector3(get_parent().velocity.x,0,get_parent().velocity.z)
		
		if get_parent().dir.length() > 0:
			if diff.get_collider():
				#var otherH = diff.get_collider().global_transform.origin.y
				var otherH = diff.get_collision_point().y
				var diffH = otherH - get_parent().global_transform.origin.y
				
				var dest =  Vector3(0,diffH*1.1,0)

				var test = (get_parent().test_move(get_parent().transform,dest))
				
				if test == false:
					get_parent().position.y += diffH*1.1
					get_parent().position += xzVelo*delta*1.2
					return true
					
					
	return false
