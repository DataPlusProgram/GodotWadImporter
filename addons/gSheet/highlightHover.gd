tool
extends TextureButton

export var makeDarkToggleTexture = false
export var amt = .4
export var tint = Color(1,1,1)
var normalTexture
var pressedTexture
var normalDark
var normalBright
var pressedBright
var darkBright

func _ready():
	
	
	var p = self
	while(true):
		
		p = p.get_parent()

		if p.get_parent() == null:
			break
		
		if p.get("videoPath") != null:
			amt=p.iconDarken
	
	normalTexture = texture_normal
	normalBright = brighten(texture_normal,amt)
	normalDark = brighten(texture_normal,-amt)
	darkBright = brighten(texture_normal,-amt/2.0)
	makeDarkToggleTexture
	texture_disabled = normalDark 
	
	if texture_pressed != null:
		pressedBright = brighten(texture_pressed,amt)
		pressedTexture = texture_pressed
	
	if makeDarkToggleTexture:
		pressedTexture = normalDark
		texture_pressed = normalDark
		
	
	connect("mouse_entered",self,"mouseIn")
	connect("mouse_exited",self,"mouseOut")
	



func brighten(texture : Texture,amt : float):
	
	var image = texture.get_data().duplicate()
	
	image.lock()
	
	for x in image.get_width():
		for y in image.get_height():
			var pix = image.get_pixel(x,y)
			pix *= tint
			var post = pix + Color(amt,amt,amt,0)
			image.set_pixel(x,y,post)
			
			
	image.unlock()
	
	var newTexture =  ImageTexture.new()
	newTexture.create_from_image(image)
	
	return newTexture
	

func mouseIn():
	texture_normal = normalBright
	if texture_pressed and !makeDarkToggleTexture:
		texture_pressed = pressedBright
		
	if makeDarkToggleTexture:
		texture_pressed = darkBright
	
	
func mouseOut():
	texture_normal = normalTexture
	if texture_pressed and !makeDarkToggleTexture:
		texture_pressed = pressedTexture
		
	if makeDarkToggleTexture:
		texture_pressed = normalDark
	

