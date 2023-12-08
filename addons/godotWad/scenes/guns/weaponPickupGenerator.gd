extends Node

var worldSprite
var pickupSound
var loader = null
var targetScene = null
var scaleFactor = 1.0

func initialize(toDisk=true):
	$"../Sprite3D".texture = loader.fetchDoomGraphic(worldSprite)
	$"../AudioStreamPlayer3D".steram = pickupSound
