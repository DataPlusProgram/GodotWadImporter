@tool
extends Node3D



@onready var par = $"../"
@export var zoomSens = 1
@export var clickOnly = false
@export var middleMouseZoom = false
@export var hijackParentYaw = false
@export var allowPan = false
@export var current = false
@export var collides = false
@export var yawRange = Vector2(-88,88)
@export var initialRot = Vector2(0,0)
@export var offset = Vector2(0,0)
@export var processInput = true
@export var fov = 70: set = fovChange
@export var dist = 14

var rotH : float = 0.0
var rotV : float = 0.0

@export var sensH = 0.25
@export var sensV = 0.25
@export var controllerSensH = 0.25
@export var controllerSensV = 0.25

var rotationChildrenX = []
var rotationChildrenY = []
var rotationChildrenXprocess = []
var rotationChildrenYprocess = []
var facingDirChildren = []

var pYawTransform : Transform3D= Transform3D.IDENTITY
var pPitchTransform : Transform3D = Transform3D.IDENTITY

var pYaw
var pPitch

var prevTime : int
var nextTime : int



@onready var yaw : Node3D = $h
@onready var pitch : Node3D = $h/v
@onready var cam = $h/v/Camera3D

func _ready():

	position.x = offset.x
	position.y = offset.y
	
	if !InputMap.has_action("lookUp"): InputMap.add_action("lookUp")
	if !InputMap.has_action("lookDown"): InputMap.add_action("lookDown")
	if !InputMap.has_action("lookLeft"): InputMap.add_action("lookLeft")
	if !InputMap.has_action("lookRight"): InputMap.add_action("lookRight")
	


func attachNodeRotation( node : Node):
	pitch.remote_path =pitch.get_path_to(node)
	
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
			position.x += (event.relative.x * sensH)
			position.y += -event.relative.y * sensV 
			

			



func fovChange(ifov):
	if ifov != null and cam != null:
		cam.fov = ifov

func _process(delta):
	
	if Input.is_action_pressed("lookUp"):
		var strength = Input.get_action_strength("lookUp",true)
		rotV += strength * controllerSensV
	
	if Input.is_action_pressed("lookDown"):
		var strength = Input.get_action_strength("lookDown")
		rotV -= strength * controllerSensV
		
	if Input.is_action_pressed("lookLeft"):
		var strength = Input.get_action_strength("lookLeft")
		rotH += strength * controllerSensH
		
	if Input.is_action_pressed("lookRight"):
		var strength = Input.get_action_strength("lookRight")
		rotH -= strength * controllerSensH
	
	yaw.rotation_degrees.y = (rotH * sensH) + initialRot.x
	pitch.rotation_degrees.x = (rotV * sensV) + initialRot.y
	
	for i in rotationChildrenXprocess:
		if is_instance_valid(i):
			i.rotation.x = pitch.rotation.x
			#
	#for i in rotationChildrenYprocess:
	#	if is_instance_valid(i):
	#		i.global_rotation.y = pitch.global_rotation.y
			
	pingTransforms()
 
func _physics_process(delta):
	
	
	sensH = SETTINGS.getSetting(get_tree(),"mouseSens")
	sensV = SETTINGS.getSetting(get_tree(),"mouseSens")
	
	rotV = clamp(rotV,yawRange.x/sensV,yawRange.y/sensV)
	yaw.rotation_degrees.y = (rotH * sensH) + initialRot.x
	pitch.rotation_degrees.x = (rotV * sensV) + initialRot.y
	
	cam.position.z = dist
	cam.current = current
	
	
	for i in facingDirChildren:
		if !is_instance_valid(i):
			facingDirChildren.erase(i)
	
	for i in facingDirChildren:
		i.facingDir = -yaw.basis.z
				
	pingTransforms()
	
	nextTime = Time.get_ticks_msec()
	prevTime = nextTime
	
	pYawTransform = yaw.transform
	pPitchTransform = pitch.transform


func attach(par):
	if get_parent() != null:
		get_parent().remove_child(self)
		
	par.add_child(self)

var pRot = Vector3.ZERO

func pingTransforms():
	if !is_inside_tree():
		return
	
	for i in rotationChildrenX:
		if is_instance_valid(i):
			i.rotation.x = pitch.rotation.x
			
		#
	for i in rotationChildrenY:
		if is_instance_valid(i):
			i.rotation.y = yaw.rotation.y
			
	$h.force_update_transform()
	$h/v.force_update_transform()
	$h/v/Camera3D.force_update_transform()
	
			
	
