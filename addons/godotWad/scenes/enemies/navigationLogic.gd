extends Node

var par 
var path = []
var pPos = Vector3.ZERO
var target
func _ready():
	par = get_parent()


func tick():
	return

	
	target = par.target
	
	if target == null:
		return null
	
	var pos = target.position
	
	if get_parent().map == null:
		return target.position-par.position
	
	if pPos.distance_to(pos) < 1:
		path = removeClose()
		
		if path.size() > 0:
			return ingoreY(path[0])
		else:
			return null
	
	pPos = pos
	
	
	
	
	var nav = get_node_or_null("../../../")
	
	
	if nav == null:
		return
	
	path = nav.get_simple_path(get_parent().position, target.position)
	path = removeClose()
	
	if path.is_empty():
		path.append(par.position-target.position)
		#print(target.translation.distance_to(par.translation))
	
	#WADG.drawPath(nav,path)
	
	if path.is_empty():
		return null
	
	
	return ingoreY(path[0])

func removeClose():
	var newPath = []
	
	for i in path:
		if i.distance_to(par.position) > 1:
			newPath.append(i)
			
	return newPath


func ingoreY(vec : Vector3) -> Vector3:
	return Vector3(vec.x,target.position.y,vec.z)
