extends Spatial

var disabled = false
export(float) var globalScale = 1
export(int) var sectorIdx = -1


func body_entered(body,tag):
	if disabled:
		return
		
	if body.get_class() != "StaticBody":
		var destNodes = get_tree().get_nodes_in_group("destination:"+String(tag))
		
		if destNodes.size()>0:
			var destNode = destNodes[0]
			var c : RayCast = destNode.get_child(0)
			c.force_raycast_update()
			
			var pos = destNode.global_transform.origin
			
			pos.y = c.get_collision_point().y
			if body.has_method("teleport"):
				
				body.teleport(pos,destNode.rotation,200)
				body.velocity = Vector3.ZERO
				if get_node_or_null("sound")!= null:
					get_node("sound").play()


	
