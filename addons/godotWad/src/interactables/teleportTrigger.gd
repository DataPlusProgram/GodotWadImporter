tool
extends Area

var sectorTag = -1


var tracking = {}
var map

func _ready():
	map = get_node_or_null("../../../../")
	var t = get_meta_list()
	sectorTag = get_meta("sectorTag")
	connect("body_entered",self,"_body_entered")
	connect("body_exited",self,"_body_exited")
	
	


func _body_entered(body):
	if body.get_class() != "StaticBody":
		
		var tScale = Vector2(map.scale.x,map.scale.z)
		tracking[body] = false
		
	
		if getDir(body) < 0:
			tracking[body] = true
		


func _physics_process(delta):
	
	for body in tracking:
		var map = get_node_or_null("../../../../")
		if map != null:
			var mySector = get_meta("targeterLineBackSector")

			var info = WADG.getSectorInfoForPoint(map,Vector2(body.global_translation.x,body.global_translation.z))

			if info == null:
				return

			var dir = getDir(body)

			if tracking[body] == true and dir >=0:
					get_parent().body_entered(body,sectorTag)
					tracking.erase(body)
					return
					
			if tracking[body] == false and dir < 0:
				tracking[body] = true
				


func _body_exited(body):
	if !tracking.has(body):
		return

		
	tracking.erase(body)

	

func getDir(body):
	
	var tScale = Vector2(map.scale.x,map.scale.z)
	var a = (get_meta("lineStart"))*tScale
	var b = (get_meta("lineEnd"))*tScale
	
	var playerPos = Vector2(body.global_translation.x,body.global_translation.z)
	var diff = (b-a)
	var norm = Vector2(diff.y,-diff.x)
	var dir = norm.dot(playerPos-a)
	return dir
