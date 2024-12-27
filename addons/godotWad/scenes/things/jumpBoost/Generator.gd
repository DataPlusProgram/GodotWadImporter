@tool
extends Node

var worldSprite
var activateSound = ""
var loader = null
var scaleFactor = Vector3.ONE
var animSpeed = 4
var autoPlay = true
func initialize():
	

	if !activateSound.is_empty():
		get_parent().activateSound = loader.fetchSound(activateSound)
	
	
	
	if worldSprite.size() > 1:
		$"../Sprite3D".texture = loader.fetchAnimatedSimple(worldSprite[0]+"_anim",worldSprite,animSpeed,autoPlay)
		if autoPlay == false:
			$"../Sprite3D".texture.pause = true
			$"../Sprite3D".texture.one_shot = true
			$"../Sprite3D".texture.current_frame = 0
			
	else:
		$"../Sprite3D".texture = loader.fetchDoomGraphic(worldSprite[0])
	
	
	$"../Sprite3D".pixel_size = scaleFactor.x * 0.8
