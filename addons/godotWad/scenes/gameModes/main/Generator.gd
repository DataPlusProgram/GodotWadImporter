tool
extends Node

var loader = null
var scaleFactor

var dependantChildren = ["res://addons/godotWad/scenes/gameModes/main/title/mainMenu_template.tscn"]

func initialize():
	#$"../endScreen".texture = loader.fetchDoomGraphic("ENDOOM")
	pass


func getSpriteList():
	return {}
	#return {"sprites":"ENDOOM"}
	
