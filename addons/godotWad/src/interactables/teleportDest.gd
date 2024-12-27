
extends Node3D


var cast : RayCast3D = null
var damageArea : Area3D = null

func _ready():
	add_to_group("teelportDest")
	cast = RayCast3D.new()
	cast.target_position.y = -100
	cast.position.y += 0.01
	cast.enabled = false
	cast.hit_back_faces = false
	add_child(cast)
	
	#var n = Sprite3D.new()
	#n.texture =load("res://addons/godotWad/scenes/guns/icon.png")
	#add_child(n)
	if !$"../../".has_meta("polyIdxToInfo"):
		return
	
	getSectorInfoFromPolyInfo($"../../")
	
	damageArea = Area3D.new()
	var col : CollisionShape3D = CollisionShape3D.new()
	var shape : BoxShape3D = BoxShape3D.new()
	
	shape.size = Vector3(1,3,1)
	damageArea.position.y = 3/2.0
	col.shape = shape
	
	damageArea.add_child(col)
	add_child(damageArea)
	
	for i in get_children():
		if i.get_class() == &"RayCast3D":
			cast = i
			return



func getSectorInfoFromPolyInfo(mapNode):
	
	var info = WADG.getSectorInfoForPoint(mapNode,Vector2(position.x,position.z))
	
	if info == null:
		return
	add_to_group("destination:"+String(info["tag"]),true)
	return


func _physics_process(delta):
	
	if cast == null:
		return
		
	if(cast.is_colliding()):
		global_position.y = cast.get_collision_point().y
