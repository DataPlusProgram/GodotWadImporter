tool
extends MeshInstance

#export(SpriteFrames) var frames : SpriteFrames = null
var frames : Resource
var isReady : bool = false
var latestFrame
var latestAnim = "front"
var modulate = 1
var pModulate = 1
var curFrame = 0
var pFrame = 0
onready var visibility = get_node_or_null("../VisibilityNotifier")

export var frameList : Dictionary
export(String) var curAnimation  = "front"
export(Vector3) var scaleFactor = Vector3.ONE 
export(Vector3) var offset = Vector3.ZERO 
func _ready():
	var pModulate = modulate
	isReady = true
	mesh = mesh.duplicate(true)




func get_frame(animName,frame):
	if !frameList.has(animName):
		return
		
	var f = frameList[animName][frame]
	
	if f == null:
		return null
	
	if f.get_class() == "ShaderMaterial":
		return f.get_shader_param("texture_albedo")
	
	
	
	return frameList[animName][frame].albedo_texture

	
func has_animation(animName) -> bool:
	return frameList.has(animName)
	
func add_animation(animName) -> void:
	if !frameList.has(animName):
		frameList[animName] = []
			
func add_frame(anim : String,frame : Material,position:int):
	frameList[anim].insert(position,frame)

func setMat(args : Array) -> void:
	
	curFrame = args[0]
	
	
	if isPlayerTooFar() == true:
		return

	
	if visibility != null:
		if !visibility.is_on_screen():
			latestFrame = args
			visible =false
			return
		else:
			visible =true
			
	
	if visible == false:
		return
	

#if tooFar:
	#	return
	
	
		
	if frameList[curAnimation].size() <= args[0]:
		print("missing frame:",args[0], "on ",curAnimation)
		return
	var t : Material  = frameList[curAnimation][args[0]]
	
	if t == null:
		return
		
	
	
	if get_surface_material(0) == t:
		latestFrame = args
		return
	
	if t.get_class() == "ShaderMaterial":
		if t.get_shader_param("texture_albedo") != null:
			mesh.size = t.get_shader_param("texture_albedo").get_size() *Vector2(scaleFactor.x,scaleFactor.y)
			translation.y = (t.get_shader_param("texture_albedo").get_size().y/2.0) *scaleFactor.y - 0.035
			translation.x = -offset.x*scaleFactor.x# - 0.088
			
			
	
	elif  t.albedo_texture != null:
		mesh.size = t.albedo_texture.get_size()  *Vector2(scaleFactor.x,scaleFactor.y)
		translation.y = (t.albedo_texture.get_size().y/2.0) *scaleFactor.y
		
		
	
	set_surface_material(0,t)
	latestFrame = args
	


func _on_VisibilityNotifier_camera_entered(camera):
	
	if latestFrame == null:
		return
		
	setMat(latestFrame)

func _physics_process(delta):
	
	
	if Engine.is_editor_hint():
		return
	
	
	
	if modulate != pModulate or pFrame != curFrame:
		var mat = get_surface_material(0)
		
		if mat != null:
			if mat.get_class() == "ShaderMaterial":
				mat.set_shader_param("albedo",Color(modulate,modulate,modulate))
		
			else:
				mat.albedo_color = Color(modulate,modulate,modulate)
	
	pModulate = modulate
	pFrame = curFrame
	
	if !frameList.has(curAnimation):
		return
	
	
	
	if pFrame >= frameList[curAnimation].size():
		return
		
	var t : Material  = frameList[curAnimation][pFrame]
	
	if t == null:
		return
	
	if t.get_class() == "ShaderMaterial":
		translation.y = (t.get_shader_param("texture_albedo").get_size().y/2.0) *scaleFactor.y - 0.035 - offset.y
	



func isPlayerTooFar():
	var skip = true
	
	if get_tree() == null:
		return

	for node in get_tree().get_nodes_in_group("player"):
		var diff : Vector3 = node.global_translation - global_translation

		if diff.length() <= 100:
			skip = false
			
	return skip
