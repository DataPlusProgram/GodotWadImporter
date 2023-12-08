extends TextureRect


export (Texture) var hp80 = null
export (Texture) var hp60 = null
export (Texture) var hp40 = null
export (Texture) var hp20 = null
export (Texture) var hp1 = null
export (Texture) var dead = null
var time = 0
var hpNode = null

func _ready():
	hpNode = findHpNode()

func findHpNode():
	var n = self
	
	while n.get_parent() != null:
		if "hp" in n:
			return n
		
		n= n.get_parent()
	

func _physics_process(delta):
	
	if hpNode == null:
		return
	
	#if texture == null:
	#	return
	
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
		
	time += delta

	if time > 1:
		if texture != null:
			texture.current_frame =  (texture.current_frame + 1) % min(texture.frames,3)
			time = 0
	
	if texture != null:
		texture.fps = 0
