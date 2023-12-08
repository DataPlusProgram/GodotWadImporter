
extends Spatial


var cast : RayCast = null


func _ready():
	
	cast = RayCast.new()
	cast.cast_to.y = -100
	cast.translation.y += 0.01
	cast.enabled = false
	
	add_child(cast)
	
	#var n = Sprite3D.new()
	#n.texture =load("res://addons/godotWad/scenes/guns/icon.png")
	#add_child(n)
	if !$"../../".has_meta("polyIdxToInfo"):
		return
	
	getSectorInfoFromPolyInfo($"../../")
	
	
	for i in get_children():
		if i.get_class() == "RayCast":
			cast = i
			return



func getSectorInfoFromPolyInfo(mapNode):
	
	var info = WADG.getSectorInfoForPoint(mapNode,Vector2(translation.x,translation.z))
	
	if info == null:
		return
	add_to_group("destination:"+String(info["tag"]),true)
	return


func _physics_process(delta):
	if cast == null:
		return
		
	#if(cast.is_colliding()):
	#	global_translation.y = cast.get_collision_point().y
