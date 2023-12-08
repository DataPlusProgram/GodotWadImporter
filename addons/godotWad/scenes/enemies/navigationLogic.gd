extends Node

var par 
var path = []
var pPos = Vector3.ZERO
var target
func _ready():
	par = get_parent()


func tick():
	

	
	target = par.target
	
	if target == null:
		return null
	
	var pos = target.translation
	
	if get_parent().map == null:
		return target.translation-par.translation
	
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
	
	path = nav.get_simple_path(get_parent().translation, target.translation)
	path = removeClose()
	
	if path.empty():
		path.append(par.translation-target.translation)
		#print(target.translation.distance_to(par.translation))
	
	#WADG.drawPath(nav,path)
	
	if path.empty():
		return null
	
	
	return ingoreY(path[0])

func removeClose():
	var newPath = []
	
	for i in path:
		if i.distance_to(par.translation) > 1:
			newPath.append(i)
			
	return newPath


func ingoreY(vec : Vector3) -> Vector3:
	return Vector3(vec.x,target.translation.y,vec.z)
