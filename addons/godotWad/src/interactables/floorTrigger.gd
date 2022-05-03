extends Area



var sectorTag = -1
var sectorInfo
func _ready():
	sectorTag = get_meta("sectorTag")
	sectorInfo = get_meta("sectorIdx")
	

	
	
func _physics_process(delta):
	for body in get_overlapping_bodies():
		bodyIn(body)
		
func bodyIn(body):
	if body.get_class() != "StaticBody":
		var myTexture = null
		if has_meta("fTextureName"):
			myTexture = get_meta("fTextureName")
		get_parent().body_entered(body,myTexture,sectorInfo)
	
	
