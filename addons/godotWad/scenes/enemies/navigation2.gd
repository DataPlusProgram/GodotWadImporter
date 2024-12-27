extends NavigationAgent3D


var target : Node3D

func _ready():
	pass



func tick():
	
	
	target = get_parent().target
	
	if target == null:
		return

	set_target_position(target.global_position)

	var n = get_next_path_position()
	return n
	
	
func isReachable(pos):
	set_target_position(pos)
	
	if get_parent().map == null:
		return true
	
	return is_target_reachable()
