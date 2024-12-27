@tool
extends Node

var sectorTag = -1
var tracking = {}
var trackingSwitch = []
var map
@export var triggerType : int 
func _ready():
	
	if Engine.is_editor_hint():
		return
		
	map = get_node_or_null("../../../../")
	var t = get_meta_list()
	sectorTag = get_meta("sectorTag")



func bin(body):
	if body.get_class() != "StaticBody3D":
		
		if triggerType == WADG.TTYPE.SWITCH1 or triggerType == WADG.TTYPE.SWITCHR:
			if "interactPressed" in body:
			
				if !trackingSwitch.has(body):
					trackingSwitch.append(body)
				
				if body.interactPressed != true:
					return
				
		
		tracking[body] = false
		
		if getDir(body) < 0:
			tracking[body] = true
		


func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	
	for body in tracking:
		if map != null:

			var info = WADG.getSectorInfoForPoint(map,Vector2(body.global_position.x,body.global_position.z))

			if info == null:
				return

			var dir = getDir(body)

			if tracking[body] == true and dir >=0:
					get_parent().body_entered(body,sectorTag)
					tracking.erase(body)
					return
					
			if tracking[body] == false and dir < 0:
				tracking[body] = true
	
	for body in trackingSwitch:
		if body.interactPressed == true:
			get_parent().body_entered(body,sectorTag)


func bout(body):
	if tracking.has(body):
		tracking.erase(body)
		
	if trackingSwitch.has(body):
		trackingSwitch.erase(body)

	

func getDir(body):
	
	var tScale = Vector2(map.scale.x,map.scale.z)
	var a = (get_meta("lineStart"))*tScale
	var b = (get_meta("lineEnd"))*tScale
	
	var playerPos = Vector2(body.global_position.x,body.global_position.z)
	var diff = (b-a)
	var norm = Vector2(diff.y,-diff.x)
	var dir = norm.dot(playerPos-a)
	return dir
