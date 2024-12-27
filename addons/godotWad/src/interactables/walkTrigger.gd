@tool
extends Area3D

var sectorTag = -1

signal walkOverSignal 
signal walkOverSignalTextureChange
var tracking = {}
var map
@export var lineStart : Vector2
@export var lineEnd : Vector2
@export var W1 : bool = false

var colShape : CollisionShape3D = null

var diff = null
var normal = Vector2.ZERO
var allPlayerPos : PackedVector3Array = []
var disabled = false
var triggerLastFrame = []

@export var mapHandlesDisable : bool = true
var activationDistance := 17
var isEnabled := true

func _ready():
	add_to_group("levelObject",true)
	
	
	
	if Engine.is_editor_hint():
		return
	
	if get_child_count() > 0:
		colShape = get_child(0)
	
	map = get_node_or_null("../../../")
	sectorTag = get_meta("sectorTag")
	var tScale = Vector2(map.scale.x,map.scale.z)
	lineStart = lineStart * tScale
	lineEnd = lineEnd * tScale
	
	if "allPlayersPos" in map:
		allPlayerPos = map.allPlayersPos
		
		
	
	

func bin(body):
	if disabled:
		return
	if body.get_class() != "StaticBody3D":
		tracking[body] = getDir(body)
		
		#if getDir(body) < 0:
		#	tracking[body] = true
		


func _physics_process(delta):

	for body in tracking:
		if map != null:
			if !is_instance_valid(body):
				tracking.erase(body)
				continue
			var info = WADG.getSectorInfoForPoint(map,Vector2(body.global_position.x,body.global_position.z))
		
			if info == null:
				return

			var dir = getDir(body)
			
			var texture = null
			var sectorTypeInfo = {}
			
			if has_meta("fTextureName"):
				texture = get_meta("fTextureName")
		
			if (tracking[body] >0  and dir <=0) or (tracking[body] <0  and dir >=0):
				emit_signal("walkOverSignal",body)
				emit_signal("walkOverSignalTextureChange",body,texture,info["sectorIdx"] ,sectorTypeInfo)
				
				tracking[body] = dir
				if W1:
					disabled = true
				continue
			

	
	if colShape == null:
		return
	
	#var anyPlayerNear : = false
	#
#
	#if allPlayerPos.size() == 0:
		#anyPlayerNear = true
	#
	#for i in allPlayerPos:
		#if( (global_position - i).length_squared() < 300):
			#anyPlayerNear = true
			#break
		
		
	#if anyPlayerNear:
		#if colShape.disabled:
			#colShape.disabled = false
#
	#else:
		#if !colShape.disabled:
			#colShape.disabled = true

func disable():
	colShape.disabled = true
	
func enable():
	colShape.disabled = false

func bout(body):
	if !tracking.has(body):
		return
		
	tracking.erase(body)

func getDir(body):
	
	
	var tScale = Vector2(map.scale.x,map.scale.z)

	if diff == null:
		diff = lineEnd -lineStart
		normal = Vector2(diff.y,-diff.x)

	var playerPos = Vector2(body.global_position.x,body.global_position.z)
	var dir = normal.dot(playerPos-lineStart)
	
	return dir

func serializeSave():
	var dict : Dictionary = {}
	dict["disabled"] = disabled
	
	return dict

func serializeLoad(dict : Dictionary):
	disabled = dict["disabled"]
