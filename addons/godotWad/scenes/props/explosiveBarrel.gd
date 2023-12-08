tool
extends RigidBody

export var hp = 3
export var damage = 25
export var scaleFactor = 1.0

var dead = false
export var spawnHeight = 0


func _physics_process(delta):
	
	if Engine.editor_hint: 
		return
	
	if hp < 0:
		die()

func takeDamage(dict):
	
	if dict.has("amt"):
		hp -= dict["amt"]

func die():
	if dead:
		return
	
	dead = true
	$"AudioStreamPlayer3D".play()
	blastDamage(damage)
	$AnimationPlayer.play("explode")
	yield($AnimationPlayer,"animation_finished")
	deleteNonSounds()
	
	if !$AudioStreamPlayer3D.playing:
		queue_free()
	else:
		yield($AudioStreamPlayer3D, "finished")
		queue_free()



func blastDamage(dmg):
	for i in $BlastZone.get_overlapping_bodies():
		
		if i == self: 
			continue

		
		if i.has_method("takeDamage"):
			var dist = i.global_translation.distance_to(global_translation)/scaleFactor.x
			i.takeDamage({"amt":max(0,dmg-dist),"type":"explosive"})

func deleteNonSounds():
	for i in get_children():
		if(i.get_class() != "AudioStreamPlayer3D"):
			i.queue_free()
