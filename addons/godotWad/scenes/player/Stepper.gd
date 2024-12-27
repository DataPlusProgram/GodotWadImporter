@tool
extends Node3D

@export var stepHeight = 0.9: set = setRays
@export var radiusExtension = 1.3

@onready var colShape = get_parent().shape
@onready var kneeRay = $"kneeRay"
@onready var footRay = $"footRay"
var grandparent
# Called when the node enters the scene tree for the first time.

func _ready():
	setRays(stepHeight)
	grandparent = $"../.."

func setRays(val):
	if get_node_or_null("..") == null:
		return
	
	if get_parent().shape == null:
		return
	
	colShape = get_parent().shape
	kneeRay = $"kneeRay"
	footRay = $"footRay"
	
	
	stepHeight = val
	var halfHeight = 0.5*-colShape.height
	var kneeHeight = halfHeight+stepHeight*colShape.height
	
	footRay.position = Vector3(0,halfHeight,0)
	footRay.target_position = Vector3(0,0,-colShape.radius*radiusExtension)
	
	kneeRay.position = Vector3(0,kneeHeight,0)
	kneeRay.target_position = Vector3(0,0,-colShape.radius*radiusExtension)
	
	#diffRay.translation = Vector3(0,halfHeight,-colShape.radius*1.1)
	#diffRay.cast_to = Vector3(0,kneeHeight-halfHeight,0)


	
# Called every frame. 'deVector3(0,0,-colShape.radius*1.1)ta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	while footRay.is_colliding() and !kneeRay.is_colliding() and $"../..".inputVelo.length_squared() != 0 and grandparent.is_on_floor(): 
		$"../..".position.y += 0.1
		footRay.force_raycast_update()
		kneeRay.force_raycast_update()
		

	pass
