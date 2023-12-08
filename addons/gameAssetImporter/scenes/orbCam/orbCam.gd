tool
extends Spatial



onready var par = $"../"
export var zoomSens = 1
export var clickOnly = false
export var middleMouseZoom = false
export var hijackParentYaw = false
export var allowPan = false
export var current = false
export var collides = false
export var yawRange = Vector2(-90,90)
export var initialRot = Vector2(0,0)
export var offset = Vector2(0,0)
export var processInput = true
export var fov = 70 setget fovChange
export var dist = 14

var rotH = 0
var rotV = 0

export var sensH = 0.25
export var sensV = 0.25
var rotationChildrenX = []
var rotationChildrenY = []


func _ready():

	translation.x = offset.x
	translation.y = offset.y
	
	if get_parent()!= null:
		if get_parent().has_method("get_shape_owners"):
			$h/v/ClippedCamera.add_exception(get_parent())
	
	$h/v/ClippedCamera.clip_to_bodies = collides

	

func _input(event):
	if processInput == false:
		return
	if !(event is InputEventMouseButton) and !(event is InputEventMouseMotion):
		return
	
	
	if event is InputEventMouseButton:
		
		if event.button_index == 4:
			dist = max(0,dist-zoomSens)
		
		if event.button_index == 5:
			dist += zoomSens
		
			
	if event is InputEventMouseMotion:
		
		if (clickOnly and Input.is_mouse_button_pressed(2)) or !clickOnly:
			rotH += -event.relative.x * sensH
			rotV += -event.relative.y * sensV
		
		if allowPan and Input.is_mouse_button_pressed(3):
			translation.x += (event.relative.x * sensH)
			translation.y += -event.relative.y * sensV 
			
	
		#_physics_process(0)
		
	

func fovChange(ifov):
	if ifov != null:
		$h/v/ClippedCamera.fov = ifov

func _process(delta):
	pingTransforms()

		

func _physics_process(delta):
	
	
	sensH = SETTINGS.getSetting(get_tree(),"mouseSens")
	sensV = SETTINGS.getSetting(get_tree(),"mouseSens")
	
	rotV = clamp(rotV,yawRange.x/sensV,yawRange.y/sensV)
	$h.rotation_degrees.y = (rotH * sensH) + initialRot.x
	$h/v.rotation_degrees.x = (rotV * sensV) + initialRot.y
	
	$h/v/ClippedCamera.translation.z = dist
	$h/v/ClippedCamera.current = current
	
	if hijackParentYaw:
		if get_parent() != null:
			if "rotation_degrees" in get_parent():
				get_parent().rotation_degrees.y = $h.rotation_degrees.y
				
	pingTransforms()
				

func attach(par):
	if get_parent() != null:
		get_parent().remove_child(self)
		
	par.add_child(self)

func pingTransforms():
	for i in rotationChildrenX:
		if is_instance_valid(i):
			i.rotation.x = $h/v.rotation.x
		
	for i in rotationChildrenY:
		if is_instance_valid(i):
			i.rotation.y = $h.rotation.y
