@tool
extends MeshInstance3D

#export(SpriteFrames) var frames : SpriteFrames = null
var frames : Resource
var isReady : bool = false
#var modulate : float= 1
#var pModulate : float= 1.0
var curFrame : String = "A"
var pFrame : String = curFrame
var pMeshSize : Vector2 =  Vector2.ZERO
var pPosY : float = 0
var pPosX : float = 0
var matToDim : Dictionary = {}
var previousMat : Material = null
var levelHandlesDisable = true
var mapNode : Node = null
var sectorInfo : Array[Dictionary]
@export var customAABB : Vector2 = Vector2(0,0)
@export var sprToOffset : Array

@onready var visibility = get_node_or_null("../VisibleOnScreenNotifier3D")
@onready var isEditor : bool = Engine.is_editor_hint()
@export var frameList : Dictionary
@export var curAnimation: String  = "A"
@export var scaleFactor: Vector3 = Vector3.ONE
@export var screenSpace: bool = false



var isEnabled : bool = true


func _ready():
	
	custom_aabb.size.x = customAABB.x + 5
	
	custom_aabb.size.y = customAABB.y + 5
	
	#var pModulate = modulate
	isReady = true
	setMat("A")
	mesh = mesh.duplicate(true)
	
	if frameList.is_empty():
		return
	
	if "map" in get_parent():
		mapNode = get_parent().map
	
	if levelHandlesDisable:
		add_to_group("mapCanDisable")
	
	
	#for animName : StringName in frameList.keys():
		#for mat : Material in frameList[animName]:
			#if mat == null:
				#return
			#if mat.get_class() == &"ShaderMaterial":
				#matToDim[mat.get_rid().get_id()] = mat.get_shader_parameter("texture_albedo")
			#else:
				#mat.albedo_texture.get_size()
				
				
	#if  frameList[curAnimation].size() == 0:
		#visible = false
		#return
	#var t : Material  = frameList[curAnimation][0]
	#setScalingAndSize(t)
	#set_surface_override_material(0,t)



func get_frame(animName,frame):
	return
	if !frameList.has(animName):
		return
		
	var f = frameList[animName][frame]
	
	if f == null:
		return null
	
	if f.get_class() == &"ShaderMaterial":
		return f.get_shader_parameter("texture_albedo")
	
	
	
	return frameList[animName][frame].albedo_texture

	
func has_animation(animName) -> bool:
	return frameList.has(animName)
	
func add_animation_library(animName) -> void:
	if !frameList.has(animName):
		frameList[animName] = []
			
func add_frame(anim : String,spriteRow : Material):
	var dirs : Array[String] = ["S","SW","W","NW","N","NE","East","SE"]
	for i in dirs:
		var texture : Texture2D = spriteRow.get_shader_parameter(i)
		if texture == null:
			continue
			
		if texture.get_height() > customAABB.y:
			customAABB.y = texture.get_height() * scaleFactor.y
		
		if texture.get_width() > customAABB.x:
			customAABB.x = texture.get_width() * scaleFactor.x
	
	custom_aabb.size.x = customAABB.x
	custom_aabb.size.y = customAABB.y
	
	frameList[anim] = spriteRow

func setMatStr(sprName : String):
	pass
func disable():
	pass
func enable():
	pass
func setMat(frame : String) -> void:
	
	
	if !isReady:
		return

	#if "weaponName" in get_parent():
	#	breakpoint

	if frame.is_empty():
		return
	
	
	
	
	curFrame = frame
	
	
	if visible == false:
		return
	
	
	

	
	if !frameList.has(curFrame):
		return
	
	#
	#if frameList.size() <= curFrame:
		#print("missing frame:",curFrame, "on ",curAnimation)
		#return
		
	var t : Material  = frameList[curFrame]
	
	if t == null:
		return
	
	if previousMat == t:
		return
	
	if isPlayerTooFar() == true:
		return
	
	
	previousMat = t

	set_surface_override_material(0,t)
	
func _on_VisibilityNotifier_camera_entered():
	
	if curFrame == null:
		return
		
	setMat(curFrame)

var lowestPoint
var topPoint 
var albedo : Texture2D

var pSectorLight = -1

func _physics_process(delta):
	
	
	if  isEditor:
		return
	
	
	
	if visible and  isEnabled and mapNode != null:
		var sectorInfo : Dictionary = WADG.getSectorInfoForPoint(mapNode,Vector2(global_position.x,global_position.z))
		if sectorInfo != null:
			var light : float = sectorInfo["light"]/256.0
			
			if pSectorLight != light:
				var color = Color(light,light,light)
				set("instance_shader_parameters/tint",color)
	
	
	#wpModulate = modulate
	pFrame = curFrame
	
	#if !frameList.has(curAnimation):
		#return
	#
	#
	#if frameList.has(pFrame):
		#return
		
	#var t : Material  = frameList[curAnimation]
	#
	#if t == null:
		#return



func isPlayerTooFar() -> bool:
	var skip : bool = true
	
	if !isReady:
		return false
	
	
	var playersGroup = get_tree().get_nodes_in_group("player")
	
	if playersGroup.is_empty():
		return false

	for node : Node in playersGroup:
		var diff : Vector3 = node.global_position - global_position

		if diff.length_squared() <= 10000:
			skip = false
			
	return skip


func serializeSave():
	var ret : Dictionary = {}
	ret["curAnimation"] = curAnimation
	ret["curFrame"] = curFrame
	
	return ret
	
	
func serializeLoad(data : Dictionary):
	curAnimation = data["curAnimation"]
	curFrame = data["curFrame"]
	setMat(curFrame)
	
