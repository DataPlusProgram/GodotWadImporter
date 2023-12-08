extends Spatial


var yeilding = false

export(WADG.TTYPE) var triggerType
export(bool) var secret = false

func _physics_process(delta):
	
	if yeilding:
		return
	if get_node_or_null("trigger") != null:# X1 triggers will get deleted after first trigger
		for c in get_children():
			if c.get_class() == "Area":
				for body in c.get_overlapping_bodies():
					bodyIn(body)



func bodyIn(body):
	
	if body.get_class() != "StaticBody":
		if "interactPressed" in body:
			if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR:
				if body.interactPressed == false: return
			

				
			
			set_physics_process(false)
			var curMap = get_node("../../../")
			curMap.nextMap()
			




func incMap(mapName):
	if mapName[0] == 'E' and mapName[2] == 'M':
		return WADG.incrementDoom1Map(mapName,secret)
	
	if mapName.substr(0,3) == "MAP":
		return WADG.incrementDoom2Map(mapName,secret)

