@tool
extends StaticBody3D

@export var hp = 20
@export var damage = 128
@export var scaleFactor = 1.0

var dead = false
@onready var soundManager = ENTG.getSoundManager(get_tree())
var nextFrameImpulse = Vector3.ZERO
var mass =100
@export var spawnHeight = 0

var velocity := Vector3.ZERO
@onready var animationPlayer : AnimationPlayer = $AnimationPlayer
var isEditor := Engine.is_editor_hint()
@onready var space : PhysicsDirectSpaceState3D= get_world_3d().direct_space_state

func _physics_process(delta):
	
	if isEditor:
		return

	
	if nextFrameImpulse.length_squared() > 0.1:
		velocity += nextFrameImpulse
		#apply_impulse(nextFrameImpulse*delta)
		nextFrameImpulse = Vector3.ZERO
	

	velocity.y = 0
	if velocity.length() > 0:
		var p : PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
		p.transform = transform
		p.shape = WADG.getCollisionShape(self).shape
		p.motion = velocity
		var result := space.cast_motion(p)
		if result[0] ==1 and result [1] == 1:
			position += velocity*delta
			
		
		
	#move_and_slide()
	velocity *= 0.92
	
	if hp <= 0:
		die()
		
	

func takeDamage(dict):
	#if dict.has("type") and hp > 0:
	#	if dict["type"] == "explosive":
	#		breakpoint
	
	if dict.has("amt"):
		hp -= dict["amt"]
		
	if dict.has("knockback") and dict.has("source"):
		nextFrameImpulse += dict["knockback"]*((global_position - dict["source"].global_position)*50)/(mass*10)

func die():
	if dead:
		return
	
	dead = true
	if soundManager != null:
		soundManager.play($AudioStreamPlayer3D.stream,self,{"deleteOnFinish":true})
	else:
		$AudioStreamPlayer3D.play()
		
	blastDamage(damage)
	animationPlayer.play("explode")
	await animationPlayer.animation_finished
	deleteNonSounds()
	
	if soundManager == null:
		if !$AudioStreamPlayer3D.playing:
			queue_free()
		else:
		#	await get_tree().create_timer($AudioStreamPlayer3D.get_length()).timeout
			queue_free()
	else:
		queue_free()
		



func blastDamage(dmg):
	for i in $BlastZone.get_overlapping_bodies():
		
		if i == self: 
			continue

		
		if i.has_method("takeDamage"):
			#var dist = i.global_position.distance_to(global_position)/scaleFactor.x
			#var diff = abs(global_position -i.global_position)
			var diff = abs(global_position -i.global_position)

			
			var dist = max(diff.x,diff.z)/scaleFactor.x
			var shape : CollisionShape3D = WADG.getCollisionShape(i)
			var thickness = 0
			
			if shape != null:
				thickness = round(WADG.getShapeThickness(shape)/scaleFactor.x)
			#dist -= 16#thickness*0.5
			dist -= thickness
			dmg = max(0,dmg-dist)
			
			if dmg > 0:
				i.takeDamage({"amt":dmg,"type":"explosive","knockback":dmg,"source":self})

func deleteNonSounds():
	for i in get_children():
		if(i.get_class() != "AudioStreamPlayer3D"):
			i.queue_free()
