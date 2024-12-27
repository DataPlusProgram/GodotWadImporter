@tool

extends CharacterBody3D
@export var velo : float = 12
@export var spawnSound: AudioStreamWAV
@export var dmg = 16
@export var splashDmg = 0
@export var canSlpashOwner = false
@export var splashRadius = 0
@onready var isEditor = Engine.is_editor_hint()

var exceptions = []
var shooter = null
var enabled = false
var ASprite
var splashArea = null
var animFinished = false
var soundFinished = false
var exploded = false
@onready var pCol = collision_layer
@onready var pMask = collision_mask

func _ready():
	
	if Engine.is_editor_hint(): 
		return
	

	if get_parent().is_in_group("entityCache"):
		disable()
	else:
		enable()
	
	if splashDmg != 0:
		splashArea = Area3D.new()
		splashArea.name = "splashArea"
		var shapeInstance = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = splashRadius
		shapeInstance.shape = shape
		splashArea.add_child(shapeInstance)
		add_child(splashArea)
		
	
	$AudioStreamPlayer3D.playSpawn()
	ASprite = $AnimatedSprite3D
	
	$AnimationPlayer.play("idle")
	
	setSpriteDir()
	

func disable():
	
	if !enabled:
		return
	
	enabled = true
	
	set_physics_process(false)
	set_physics_process_internal(false)
	
	
	
	
	pCol = collision_layer
	pMask = collision_mask
	
	collision_layer = 0
	collision_mask = 0
	visible = false
	return


func enable():
	
	if enabled:
		return
	
	enabled = true
	
	set_physics_process(true)
	set_physics_process_internal(true)
	
	
	collision_layer = pCol
	collision_mask = pMask
	visible = true
	return

func _physics_process(delta):
	if isEditor:
		return
		
	if exploded:
		return
	setSpriteDir()
	
	var col = move_and_collide(-transform.basis.z*velo*delta,false,0.001,true,3)


	if col != null:
		#if col.get_parent() != owner:
		hit(col.get_collider())
		
		return
	
	if get_node_or_null("Area3D") == null:
		return
	
	#for i in $Area3D.get_overlapping_bodies():
		
	#	if i!=self and (i!= shooter):
	#		var t = i
	#		if !exceptions.has(i):
	#			hit(i)
	#			return


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
		
	
	if splashArea != null:
		for i in splashArea.get_overlapping_bodies():
			if i!=self and (i!= shooter or canSlpashOwner):
				if i.has_method("takeDamage"):
					i.takeDamage({"source":shooter,"amt":splashDmg})
	delete()
	
			



func setSpriteDir():
	var camera = get_viewport().get_camera_3d()

	if camera == null:
		return
	
	
	
	var diff : Vector3 = (global_position -camera.global_position).normalized()
	var cameraForward = -camera.global_transform.basis.z
	
	var forward = -global_transform.basis.z
	var left = global_transform.basis.x
	
	if camera.global_rotation.x > 0.541 or camera.global_rotation.x < -0.541:
		cameraForward = diff
	
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
	

	$CollisionShape3D.queue_free()
	$Area3D.queue_free()
	var length = $AudioStreamPlayer3D.playExplode()
	$AnimationPlayer.play("explosion")
	$AnimationPlayer.connect("animation_finished", Callable(self, "deleteSprite").bind(), CONNECT_DEFERRED)
	#$AudioStreamPlayer3D.connect("finished", Callable(self, "queue_free").bind(), CONNECT_DEFERRED)
	
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 1
	timer.autostart = true
	timer.timeout.connect(f)
	
	add_child(timer)
	exploded = true
	#set_physics_process(false)
	
	

func f():
	if animFinished == true:
		queue_free()
		
	soundFinished = true

func deleteSprite(dummy):
	
	animFinished = true
	$AnimatedSprite3D.queue_free()
	$AnimationPlayer.queue_free()
	
	if soundFinished:
		queue_free()


func serializeSave():
	var ret : Dictionary = {}
	var exceptionsPaths = []
	
	for i in exceptions:
		exceptionsPaths.append(get_path_to(i))
	
	ret["velo"] = velo
	ret["zBasisx"] = global_basis.z.x
	ret["zBasisy"] = global_basis.z.y
	ret["zBasisz"] = global_basis.z.z
	ret["exceptions"] = exceptionsPaths
	return ret
	
func serializeLoad(data):
	
	if $AudioStreamPlayer3D.is_playing():
		$AudioStreamPlayer3D.stop()
	velo = data["velo"]
	global_basis.z.x = data["zBasisx"]
	global_basis.z.y = data["zBasisy"]
	global_basis.z.z = data["zBasisz"]
	
	if !data["exceptions"].is_empty():
		for i : NodePath in data["exceptions"]:
			if get_node_or_null(i)!= null:
				add_collision_exception_with(get_node(i))
	
