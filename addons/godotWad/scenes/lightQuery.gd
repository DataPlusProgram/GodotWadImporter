extends RayCast3D


var ppos : Vector3 = Vector3.ZERO
var pLL : int = 0

func tick() -> void:
	if ppos != global_transform.origin:
		
		ppos = global_transform.origin
		var ll = queryLightLevel()
		if ll != pLL:
			if ll != null:
				setLightLevel(ll)
		
			pLL = ll
			
	
	
	
	


func queryLightLevel() -> int:
	var col = get_collider()
	if col != null:
		if col.has_meta("light"):
			var lightLevel = WADG.getLightLevel(col.get_meta("light"))
			lightLevel = remap(lightLevel,0,16,0.0,1.0)
			return lightLevel
			
	return 0


func setLightLevel(lightLevel) -> void:
	for i in get_parent().get_children():
		if "modulate" in i:
			i.modulate = Color(lightLevel,lightLevel,lightLevel,1)
