extends Spatial


var yeilding = false

export(WADG.TTYPE) var triggerType

func _physics_process(delta):
	if yeilding:
		return
	if get_node_or_null("trigger") != null:# X1 triggers will get deleted after first trigger
		for c in get_children():
			if c.get_class() == "Area":
				for body in c.get_overlapping_bodies():
					bodyIn(body)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func bodyIn(body):
	
	if body.get_class() != "StaticBody":
		if "interactPressed" in body:
			if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR:
				if body.interactPressed == false: return
			

				
			
			set_physics_process(false)
			var curMap = get_node("../../../")
			curMap.nextMap()
		#	var mapName = get_node("../../../").name
		#	var nextMap = WADG.incMap(mapName)
		#	var wadLoader = get_node("../../../../").get_node("WadLoader")
			
			
		#	curMap.setFullscreenImage()
		#	get_parent().remove_child(self)
		#	curMap.get_parent().add_child(self)
		#	curMap.queue_free()
			
		
			
		#	yeilding = true
		#	get_tree().get_root().add_child(self)
		#	yield(get_tree(), "physics_frame")
		#	yeilding = false
			
			
		#	if wadLoader == null:
		#		return
		#	else:
		#		if wadLoader.textureEntries == null:
			#		wadLoader.createMap(nextMap,true)
		#		else:
		#			wadLoader.createMap(nextMap,true)
			
			
			
			#get_parent().remove_child(self)
			#queue_free()
		



func incMap(mapName):
	if mapName[0] == 'E' and mapName[2] == 'M':
		return WADG.incrementDoom1Map(mapName)
	
	if mapName.substr(0,3) == "MAP":
		return WADG.incrementDoom2Map(mapName)

