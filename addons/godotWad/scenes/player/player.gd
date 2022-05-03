tool
extends KinematicBody

var curMap

export var acc = 180
export var airSpeed = 1

export var mouseSensitivity = 0.05
var pPos = translation
var hp = 100
var dead = false
export var gravity = 280
export var maxSpeed = 1600
var maxAcc = 0.5*maxSpeed
var dir = Vector2.ZERO
export var keyMove = 0.03
export var friction = 12
export var thickness = 0.5 setget changeThickness
export var height = 2.15 setget changeHeight

export(NodePath) var wadLoader

export var jumpSpeed = 0.5
var velocity = Vector3.ZERO
var curGun = null

var initalGravity = gravity
var gravityVelo = Vector3()
var onGround = false
var jumpSound = false
var interactPressed
var smoothY = false
onready var colShape = $"CollisionShape"
onready var camera = $"Camera"
onready var footCast = $"footCast"
onready var initialShapeDim = Vector2(colShape.shape.radius,colShape.shape.height)
onready var lastStep = translation
onready var lastMat = "-"
onready var footstepSound = $"footstepSound"
var bspNode = null

var footStepDict = {
	"C":["player/pl_step1.wav","player/pl_step2.wav"],
	"M":["player/pl_metal1.wav","player/pl_metal2.wav"],
	"D":["player/pl_dirt1.wav","player/pl_dirt2.wav","player/pl_dirt3.wav"],
	"V":["player/pl_duct1.wav"],
	"G":["player/pl_grate1.wav","player/pl_grate4.wav"],
	"T":["player/pl_tile1.wav","player/pl_tile2.wav","player/pl_tile3.wav","player/pl_tile4.wav"],
	"S":["player/pl_slosh1.wav","player/pl_slosh2.wav","player/pl_slosh3.wav","player/pl_slosh4.wav"],
	"W":["debris/wood1.wav","debris/wood2.wav","debris/wood3.wav"],
	"P":["debris/glass1.wav","debris/glass2.wav","debris/glass3.wav"],
	"Y":["debris/glass1.wav","debris/glass2.wav","debris/glass3.wav"],
	"F":["weapons/bullet_hit1.wav","weapons/bullet_hit1.wav","weapons/bullet_hit1.wav"]
	

}

var categoryToWeaponDict = {}
var weaponNameToCategory = {}
var categoryIndex = []


var cachedSounds = {}
var modelLoaderNode 
var curLevel = 0



func _ready():
	yield(get_parent(), "ready")
	saveToDisk()
	if Engine.editor_hint:
		return
	
	if !InputMap.has_action("shoot"): InputMap.add_action("shoot")
	if !InputMap.has_action("jump"): InputMap.add_action("jump")
	if !InputMap.has_action("interact"): InputMap.add_action("interact")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	set_meta("height",$"CollisionShape".shape.height)
	
	
	if wadLoader == null:
		return
	
	
	
	for level in get_tree().get_nodes_in_group("levels"):
		curMap = level
		var posAndRot = level.get_spawn(0,0)
		
		if posAndRot == null:#no player spawn in map
			teleport(Vector3(0,0,0))
		else:
			var pos = posAndRot["pos"]
			var rot = posAndRot["rot"]
			teleport(pos,rot)
			
	
	
	
func teleport(pos,rot=null):
	translation = pos + Vector3(0,height/2.0,0)
	if rot != null:
		rotation = rot
	

func _input(event):
	var just_pressed = event.is_pressed() and !event.is_echo()
	
	if Input.is_key_pressed(KEY_ALT):
		if Input.is_key_pressed(KEY_ENTER) and just_pressed:
			OS.window_fullscreen = !OS.window_fullscreen

	
	if dead:
		return
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouseSensitivity))
		camera.rotate_x(deg2rad(-event.relative.y * mouseSensitivity))
		camera.rotation.x = clamp(camera.rotation.x, deg2rad(-89),deg2rad(89))
		
		

func _physics_process(delta):
	
	if !is_instance_valid(curMap):
		for level in get_tree().get_nodes_in_group("levels"):
			curMap = level
			var posAndRot = level.get_spawn(0,0)
			if posAndRot == null:
				return
			var pos = posAndRot["pos"]
			var rot = posAndRot["rot"]
			teleport(pos,rot)
	
	if Engine.editor_hint:
		return
		
	
	if hp == 0:
		die()
		
		
	var collider = footCast.get_collider()

	if collider != null:
		onGround = true
	
	footsteps()

	dir = Vector3.ZERO
	
	if Input.is_action_pressed("ui_up"): dir -= transform.basis.z
	if Input.is_action_pressed("ui_down"): dir += transform.basis.z
	if Input.is_action_pressed("ui_right"): dir += transform.basis.x 
	if Input.is_action_pressed("ui_left"): dir -= transform.basis.x
	
	if Input.is_action_pressed("interact"): 
		interactPressed = true
	else:
		interactPressed = false
	
	dir = dir.normalized()
	
	friction(delta)
	velo(dir,delta)
	
	
	velocity.y -= gravity*delta
	if Input.is_action_just_pressed("jump") and onGround:
		velocity.y = jumpSpeed*50
		var mat = getFootMaterial()
		if mat!=null:
			playMatStepSound(mat)
	else:
		if onGround: 
			velocity.y = -0.001
	

	
	move_and_slide(velocity,Vector3.UP,false,4,0.758,false)
	onGround =  is_on_floor()
	
	
	$MeshInstance.translation.y = height/2
	$CollisionShape.translation.y = height/2
	
	for index in get_slide_count():
		var collision = get_slide_collision(index)
	
		if collision.collider.get_class() == "RigidBody":
			collision.collider.apply_central_impulse(-collision.normal * 1)
		pass
	
	
	var pxz = Vector2(pPos.x,pPos.z)
	var xz = Vector2(translation.x,translation.z)

	
	if smoothY:
		var a = translation.y
		var b = height-0.1
		
		var diff = (b-a)
		

	pPos = translation
	
	

	
	
func enterLadder():
	print("player enter ladder")
	gravity = -initalGravity
	
func exitLadder():
	print("player exit ladder")
	gravity = initalGravity

func die():
	if dead:
		return
	camera.rotate_z(deg2rad(90))
	dead = true
	colShape.shape.radius = initialShapeDim.x * 0.01
	colShape.shape.height = initialShapeDim.y * 0.01
	return

func footsteps():
	
	if velocity.length() < 0.1 and jumpSound == false:
		return
		
	var collider = footCast.get_collider()
	if collider == null:
		return
	
	var matType = getFootMaterial()
	
	if matType == null:
		return
	
	
	
	if footStepDict.has(matType):
		if translation.distance_to(lastStep) < 2 and lastMat == matType:  
			lastMat = matType
			return
		
		lastMat = matType
		lastStep = translation
		
		playMatStepSound(matType)


func getFootMaterial():
	return null
	var collider = footCast.get_collider()
	if collider == null:
		return null
	
	if collider.get_parent() != null:
		if collider.get_parent().get_class()!= "MeshInstance":
			return
			
	
	var mesh = collider.get_parent()
	var mat = getMatFromPos(mesh,mesh.mesh,footCast.get_collision_point())
	print(mat.get_class())

func getMatFromPos(meshInstance,mesh,pos):
	var numSurf = mesh.get_surface_count()
	var runningDataArr = []
	
	for surf in numSurf:
		var meshData = MeshDataTool.new()
		meshData.create_from_surface(mesh,surf)
		runningDataArr.append(meshData)
		
	for surfData in runningDataArr:
		for vertIdx in surfData.get_vertex_count():
			for faceIdx in surfData.get_vertex_faces(vertIdx):
				if surfData.get_face_normal(faceIdx).dot(Vector3.UP) < 0.1:#if faces downwards
					continue
				
				var tri = getVertsOfFaceGlobal(surfData,faceIdx,meshInstance)
				if Geometry.ray_intersects_triangle(global_transform.origin,global_transform.origin.direction_to(pos),tri[0],tri[1],tri[2]):
					return surfData.get_material()
					
		


func getVertsOfFaceGlobal(surfData,faceIdx,meshInstance):
	var a = surfData.get_face_vertex(faceIdx,0)
	var b = surfData.get_face_vertex(faceIdx,1)
	var c = surfData.get_face_vertex(faceIdx,2)
	
	a = surfData.get_vertex(a)
	b = surfData.get_vertex(b)
	c = surfData.get_vertex(c)
	
	a = meshInstance.to_global(a)
	b = meshInstance.to_global(b)
	c = meshInstance.to_global(c)
	return [a,b,c]
	
	

func playMatStepSound(mat):
	pass

func cameraStuff():
	var ninety  = deg2rad(90)
	var rotY = rotation.y + ninety
	#LineDraw.drawLine(translation,translation+Vector3(cos(rotY),0,-sin(rotY))*10)#
	
	
	var x = cos(rotY)*cos(camera.rotation.x)
	var y = sin(camera.rotation.x)
	var z = -sin(rotY)*cos(camera.rotation.x)
	
	var origin = translation
	#LineDraw.drawLine(origin,origin+Vector3(x,y,z)*100)#




func friction(delta):
	var speed = velocity.length()
	if speed != 0:
		var drop = speed * friction * delta
		velocity.x *= max(speed-drop,0)/speed
		velocity.z *= max(speed-drop,0)/speed

func velo(dir,delta):
	var proj = velocity.dot(dir)
	var accelVel = acc * delta
	
	if (proj + accelVel )> maxSpeed:
		accelVel = maxSpeed - proj 
	
	velocity += dir * accelVel

func getCurWeaponCategory():
	 return weaponNameToCategory[curGun["model"]]
	
	
func changeHeight(h):
	height= max(0,h)
	
	if has_node("MeshInstance"):
		$MeshInstance.translation.y = h/2
		$MeshInstance.mesh.height = h
		
	if has_node("CollisionShape"):
		$CollisionShape.translation.y = h/2
		$CollisionShape.shape.height = h
	
func changeThickness(t):
	height= max(0,t)
	
	if has_node("MeshInstance"):
		$MeshInstance.mesh.top_radius = t
		$MeshInstance.mesh.bottom_radius = t
		
	if has_node("CollisionShape"):
		$CollisionShape.shape.radius = t

func saveToDisk():
	return
	
	var pack = PackedScene.new()
	pack.pack($"Camera/gunManager")
	ResourceSaver.save("dbg/gunManager.tscn",pack)


func recursiveOwn(node,newOwner):
	for i in node.get_children():
		recursiveOwn(i,newOwner)
