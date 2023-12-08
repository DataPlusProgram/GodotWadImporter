tool

extends KinematicBody
export var velo = 12
export(AudioStreamSample) var spawnSound
export var dmg = 16
var exceptions = []
var shooter = null
var disabled = false
var ASprite

func _ready():
	
	if Engine.editor_hint: 
		return
	
	if get_parent().is_in_group("entityCache"):
		disabled = true
	
	if disabled:
		set_physics_process(false)
		set_physics_process_internal(false)
		collision_layer = 0
		collision_mask = 0
		visible = false
		return
	
	
	$AudioStreamPlayer3D.playSpawn()
	ASprite = $AnimatedSprite3D
	setSpriteDir()
	

func _physics_process(delta):
	if Engine.editor_hint: 
		return
		
	setSpriteDir()
	var col = move_and_collide(-transform.basis.z*velo)
	
	if col != null:
		#if col.get_parent() != owner:
		hit(col.collider)
		
		return
	
	if get_node_or_null("Area") == null:
		return
	
	for i in $Area.get_overlapping_bodies():
		
		if i!=self and i!= shooter:
			var t = i
			if !exceptions.has(i):
				hit(i)
				return
			


func hit(collider):
	if collider.get_parent() == self:
		breakpoint
		
	if get_node_or_null("customHit") != null:
		
		$customHit.hit(collider)
		
		if $customHit.overrideParentBehaviour:
			return
		
	if collider.has_method("takeDamage"):
		collider.takeDamage({"source":shooter,"amt":dmg})
	elif get_parent().has_method("takeDamage"):
			breakpoint
			
	delete()
			



func setSpriteDir():
	var camera = get_viewport().get_camera()

	if camera == null:
		return
	
	var cameraForward = -camera.global_transform.basis.z
	
	var forward = -global_transform.basis.z
	var left = global_transform.basis.x
	
	var forwardDot = forward.dot(cameraForward)
	var leftDot = left.dot(cameraForward)
	
	var anim = ASprite.animation
	var newAnim  = anim
	if forwardDot < -0.85:
		newAnim = "front"
		
	elif forwardDot > 0.85:
		newAnim = "back"
	else:
		if leftDot > 0:
			if abs(forwardDot) < 0.3:
				newAnim = "left"
			elif forwardDot < 0:
				newAnim = "frontLeft"
			else:
				newAnim = "backLeft"
		else:
			if abs(forwardDot) < 0.3:
				newAnim = "right"
			elif forwardDot < 0:
				newAnim = "frontRight"
			else:
				newAnim = "backRight"
	
	if anim != newAnim:
		ASprite.animation = newAnim
		

func delete():
	
	#for i in get_children():
		#if i.get_class() == "Area":
		#	i.queue_free()
	$CollisionShape.queue_free()
	$Area.queue_free()
	$AudioStreamPlayer3D.playExplode()
	$AnimationPlayer.play("explosion")
	$AnimationPlayer.connect("animation_finished",self,"deleteSprite",[],CONNECT_DEFERRED)
	
	$AudioStreamPlayer3D.connect("finished",self,"queue_free",[],CONNECT_DEFERRED)
#	$AnimationPlayer.connect("finished",self,"queue_free")
	set_physics_process(false)
	
	

func free():
	queue_free()

func deleteSprite(dummy):
	
	$AnimatedSprite3D.queue_free()
	$AnimationPlayer.queue_free()


