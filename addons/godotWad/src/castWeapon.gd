extends Node3D

@export var damage = 10
@export var spread = 0
var shootCast : RayCast3D
@onready var audioPlayer = $"../AudioStreamPlayer3D"

func _ready():
	
	shootCast = $RayCast3D
	shootCast.target_position.z = -100
	shootCast.add_exception(get_parent())
	
	if "height" in get_parent():
		shootCast.position.y = get_parent().height/2.0
	
	


func fire(targetPos: Vector3,forceMelee : bool = false):
	
	shootCast.target_position = targetPos -global_position

	#shootCast.target_position.rotated(Vector3.UP,deg_to_rad(randi_range(-spread/2,spread/2)))
	if forceMelee:
		shootCast.target_position = shootCast.target_position.normalized()*get_parent().meleeRange
	
	var distTo : float =  global_position.distance_to(targetPos)
	var pRange = get_parent().projectileRange
	
	if distTo <= get_parent().meleeRange:
		audioPlayer.playMelee()
		runCast({"source":get_parent(),"amt":get_parent().meleeDamage})
		
		return
	
	
	audioPlayer.playAttack()
	
	var angle = atan2(shootCast.target_position.x,shootCast.target_position.z)
	var shootVector = Vector3(0,0,1)
	var curSpread = Vector2(spread,spread)
	var spreX = randfn(0,curSpread.x/3.4641)
			
	spreX = min(curSpread.x,spreX)
			
	var radiusX = tan(deg_to_rad(spreX))
	var spreadAngle = randfn(0,2*PI)
	var spreY = randfn(0,curSpread.y/3.4641)
	var radiusY = tan(deg_to_rad(spreY))
	
	var dest = Vector3(radiusX*cos(spreadAngle),radiusY*sin(spreadAngle),1).rotated(Vector3.UP,angle)

	shootCast.target_position += dest

	shootCast.target_position *= 1000
	
	#print(angle,",",angle+spreadAngle)
	
	runCast({"source":self,"amt":damage})
	
	

func runCast(damageDict : Dictionary,forceMelee  = false):
	shootCast.enabled = true
	
	shootCast.force_raycast_update()
	var col = shootCast.get_collider()
	
	
	if col == null:
		#shootCast.enabled = false
		return
		
		
	if col.has_method("takeDamage"):
		col.takeDamage({"source":get_parent(),"amt":damage})
		
		
	if forceMelee:
		$"../AudioStreamPlayer3D".playMelee()
	#shootCast.enabled = false
	

func fireCustomDmg(dmg):
	var col = shootCast.get_collider()
	
	if col == null:
		return
	if col.has_method("takeDamage"):
		col.takeDamage({"source":self,"amt":damage})
	
