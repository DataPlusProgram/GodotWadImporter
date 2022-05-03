extends Spatial

func _physics_process(delta):
	if get_node_or_null("trigger") != null:# X1 triggers will get deleted after first trigger
		for c in get_children():
			#if c.get_class()
			if c.get_class() == "Area":
				for body in c.get_overlapping_bodies():
					bodyIn(body)



func bodyIn(body):
	if body.get_class() != "StaticBody" and "interactPressed" in body:
		for c in get_parent().get_children():
			if c == self : continue
			
			if "active" in c:
				c.active = false
				
			if c.get_parent().has_meta("owner"):
				c.get_parent().set_meta("owner",false)
					
				
