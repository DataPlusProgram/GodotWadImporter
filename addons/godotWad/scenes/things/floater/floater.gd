extends Area3D


var gravityRestorationDict = {}
var overalappingBodies : Array[Node3D] = []
var height = 0
@export var power = 500

func _physics_process(delta: float) -> void:
	
	for i in overalappingBodies:
		i.velocity.y =  max(i.velocity.y,power*delta)



func _on_body_entered(body: Node3D) -> void:
	if !overalappingBodies.has(body):
		if "velocity" in body:
			overalappingBodies.append(body)


func _on_body_exited(body: Node3D) -> void:
	if overalappingBodies.has(body):
		overalappingBodies.erase(body)

