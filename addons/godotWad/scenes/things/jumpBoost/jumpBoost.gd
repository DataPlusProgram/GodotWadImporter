extends Area3D


var overalappingBodies : Array[Node3D] = []
@export var power = 50
@export var angle = false
@export var activateSound : AudioStream = null



func _physics_process(delta: float) -> void:
	for body : Node3D in overalappingBodies:
		doBoost(body)
		overalappingBodies.erase(body)
	

	if  $Sprite3D.texture.get_class() == "AnimatedTexture":
		if $Sprite3D.texture.frames-1 == $Sprite3D.texture.current_frame:
			$Sprite3D.texture.current_frame = 0
			$Sprite3D.texture.pause = true


func doBoost(body : Node3D):
	
	if activateSound != null:
		ENTG.getSoundManager(get_tree()).play(activateSound,self,{"unique":true})
		$Sprite3D.texture.pause = false
		$Sprite3D.texture.current_frame = 0
	
	if !angle:
		body.velocity.y = max(power,body.velocity.y)
	else:
		body.velocity = (-basis.z + Vector3(0,1,0)).normalized() * power
	
func _on_body_entered(body: Node3D) -> void:
	if !overalappingBodies.has(body):
		if "velocity" in body:
			overalappingBodies.append(body)


func _on_body_exited(body: Node3D) -> void:
	if overalappingBodies.has(body):
		overalappingBodies.erase(body)
