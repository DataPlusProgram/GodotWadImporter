extends Node

var worldSprite
var activateSound
var loader = null
var scaleFactor = Vector3.ONE



func initialize():
	
	
	
	if worldSprite.size() > 1:
		$"../Sprite3D".texture = loader.fetchAnimatedSimple(worldSprite[0]+"_anim",worldSprite)
	else:
		$"../Sprite3D".texture = loader.fetchDoomGraphic(worldSprite[0])
	$"../AudioStreamPlayer3D".stream = activateSound
	
	
	$"../Sprite3D".pixel_size = scaleFactor.x * 0.8
