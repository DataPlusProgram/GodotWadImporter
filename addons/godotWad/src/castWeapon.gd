extends Spatial

export var damage = 10

var shootCast : RayCast


func _ready():
	
	shootCast = RayCast.new()
	shootCast.enabled = true
	shootCast.cast_to.z = -100
	shootCast.add_exception(get_parent())
	if "height" in get_parent():
		shootCast.translation.y = get_parent().height/2.0
	
	add_child(shootCast)




func fire():
	var col = shootCast.get_collider()
	
	if col == null:
		return
	if col.has_method("takeDamage"):
		
		col.takeDamage({"source":self,"amt":damage})


func fireCustomDmg(dmg):
	var col = shootCast.get_collider()
	
	if col == null:
		return
	if col.has_method("takeDamage"):
		col.takeDamage({"source":self,"amt":damage})
	
