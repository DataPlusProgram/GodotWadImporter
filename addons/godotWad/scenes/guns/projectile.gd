extends KinematicBody
var velo = Vector3(0,0,1)



func _process(delta):
	var col = move_and_collide(-transform.basis.z*0.1)
	if col != null:
		hit(col.collider)
		queue_free()
		


func hit(collider):
	if collider.has_method("damage"):
		collider.damage(10)
