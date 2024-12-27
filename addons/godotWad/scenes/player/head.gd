extends TextureRect


@export  var hp80 : Texture2D= null
@export var hp60 : Texture2D= null
@export  var hp40 : Texture2D= null
@export var hp20 : Texture2D= null
@export  var hp1 : Texture2D= null
@export  var dead : Texture2D= null
var time = 0
var hpNode = null

func _ready():
	hpNode = findHpNode()
	
	
	hpNode.weaponPickupSignal.connect(pickupFace)
func findHpNode():
	var n = self
	
	while n.get_parent() != null:
		if "hp" in n:
			return n
		
		n= n.get_parent()


func pickupFace():
	texture.current_frame = 6
	time = 2
	
func _physics_process(delta):
	
	if hpNode == null:
		return
	

	var hp = hpNode.hp
	
	if hp >= 80:
		texture = hp80
	elif hp >= 60:
		texture = hp60
	elif hp >= 40:
		texture = hp40
	elif hp >= 20:
		texture = hp20
	elif hp >= 1:
		texture = hp1
	elif hp <= 0:
		texture = dead
	

	time -= delta

	if time <= 0:
		if texture != null:
			texture.current_frame =  (texture.current_frame + 1) % min(texture.frames,3)
			time = 1
	
	
	
	if texture != null:
		texture.speed_scale = 0
