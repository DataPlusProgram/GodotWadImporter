extends RayCast3D

var velocity : Vector3 = Vector3.ZERO
var snapAmt : float =  0.1

@onready var par : Node3D = get_parent()
@onready var gravity = 0.6
@export var mapHandlesDisable : bool = true
var activationDistance =  150
@export var hideParentOnDisable : bool = true
var forceResourcesUnique

@export var height = 0 : set = setHeight
var touching : Node3D = null
var touchingLastPos : Vector3 = -Vector3.INF
var pPos : Vector3

var isEnabled = true

func disable():
	if hideParentOnDisable:
		par.visible = false
	isEnabled = false
	enabled = false
	set_physics_process(false)

func enable():
	if hideParentOnDisable:
		par.visible = true
	isEnabled = true
	var ptarget = target_position.y
	target_position.y = -100
	enabled = true
	force_raycast_update()
	if get_collider() != null:
		par.position.y = get_collision_point().y
	target_position.y = ptarget
	set_physics_process(true)

func _ready() -> void:
	
	target_position.y = -0.001
	
	#if mapHandlesDisable:
	#	add_to_group("mapCanDisable")
	

	if height != 0:
		return
	
	if get_parent().has_meta("height"):
		height = get_parent().get_meta("height")
	elif "height" in get_parent():
		height = get_parent().height
	elif get_parent().has_node("CollisionShape3D"):
		height = WADG.getCollisionShapeHeight(get_parent().get_node("CollisionShape3D"))
	elif get_parent().has_node("Area3D"):
		if get_parent().get_node("Area3D").has_node("CollisionShape3D"):
			height = WADG.getCollisionShapeHeight($"../Area3D/CollisionShape3D")
		
	position.y = height/2.0

func setHeight(h):
	height = h 
	position.y = height/2.0


func _physics_process(delta):
	

	if global_position == pPos:
		if touching != null:
			if is_instance_valid(touching):
				if touchingLastPos != touching.global_position:
					touching = null
			else:
				touching = null
	else:
		touching = null
	
	
	if touching != null:
		#if "modulate" in get_parent():
			#get_parent().modulate =  Color.GREEN
		#for i in get_parent().get_children():
			#if "modulate" in i:
				#i.modulate = Color.GREEN
		enabled = false
		return
	
	enabled = true
	force_raycast_update()
	#if "modulate" in get_parent():
		#get_parent().modulate =  Color.GREEN
	#for i in get_parent().get_children():
			#if "modulate" in i:
				#if is_instance_valid(i):
					#i.modulate = Color.RED
	
	if !is_colliding():
		velocity.y += gravity
		par.position.y -= velocity.y * gravity * delta
		target_position.y = -max(0.01,velocity.y * gravity * delta) - height/2.0
		if target_position.y < -500:
			target_position.y = -500
		enabled = false
		scale.y = 1
		return
	
	target_position.y = -max(0.1,velocity.y * gravity * delta) - height/2.0
	scale.y = 2
	touching = get_collider()
	
	touchingLastPos = touching.global_position
	pPos = global_position
	enabled = false
	var diff = (global_position.y-get_collision_point().y)-height

	
	if diff < snapAmt and !is_zero_approx(diff):
		par.global_position.y=get_collision_point().y
		return
		
	if diff > 0.1:
		par.global_position.y=get_collision_point().y
	
	
	
	
