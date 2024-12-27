@tool
extends Node

var loader : Node
var scaleFactor : Vector3
@export var sprites : Array[String]
@export var sounds : Array[String]


@onready var soundPlayer = $"../AudioStreamPlayer3D"


func getSpriteList():
	return sprites

func initialize():
	var spri = $"../Sprite3D"
	spri.texture = loader.fetchAnimatedSimple("arcvhileFire",sprites)
	
	$"../BlastZone/CollisionShape3D".shape.size *= scaleFactor
	$"../Sprite3D".pixel_size = scaleFactor.x * 2.0
	get_parent().spawnSound = loader.fetchSound(sounds[0])
	get_parent().fireStartSound = loader.fetchSound(sounds[1])
	get_parent().crackleSound = loader.fetchSound(sounds[2])
	get_parent().explosionSound = loader.fetchSound(sounds[3])
	get_parent().scaleFactor = scaleFactor
	#add_child(animatedSprite)
		
		



