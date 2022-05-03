extends Spatial

var disabled = false

func body_entered(body,tag,a,b):
	if disabled:
		return
	if body.get_class() != "StaticBody":
		
		var inFront = isInFront(a,b,body.global_transform.origin)
		
		if !inFront >= 0:
			return
		
		var destNodes = get_tree().get_nodes_in_group("destination:"+String(tag))
		
		if destNodes.size()>0:
			var destNode = destNodes[0]
			var pos = destNode.global_transform.origin
			
			if body.has_method("teleport"):
				
				body.teleport(pos)
				if get_node_or_null("sound")!= null:
					get_node("sound").play()
				
				#disabled = true
				#yield(get_tree().create_timer(5),"timeout")
				#disabled = false

func isInFront(a,b,bodyPos):
	var p = Vector2(bodyPos.x,bodyPos.z)
	var res = (b-a).cross(p-a)
	return res
