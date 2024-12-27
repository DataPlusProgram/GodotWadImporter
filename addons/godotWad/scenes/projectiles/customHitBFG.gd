extends Node

@export var overrideParentBehaviour = false
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func hit(collider):
	var par = get_parent()
	
	par.velocity = Vector3.ZERO
	var entHitsThisY = []
	
	var rc = RayCast3D.new()
	par.add_child(rc)
	entHitsThisY.clear()
	var xcount = 0
	var ycount = 0
	for x in range(-22.5,22.5,1):
		ycount += 1
		for y in range (-22,22,1):
			rc.target_position = Vector3.FORWARD * 300
			rc.enabled = true
			
			rc.rotation_degrees.y = x
			rc.rotation_degrees.x = y
			rc.force_raycast_update()
			
			if rc.is_colliding():
				var col = rc.get_collider()
				if entHitsThisY.has(col):
					continue
				
				entHitsThisY.append(col)
				if col.has_method("takeDamage"):
					col.takeDamage({"amt": 1000})
					if col.dead:
						rc.add_exception(col)
						
						
		
		if ycount % 10 == 0:
			await get_tree().physics_frame
	rc.queue_free()
			

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
