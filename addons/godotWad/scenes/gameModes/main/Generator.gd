@tool
extends Node

var loader = null
var scaleFactor

@export var dependantChildren : Array[String]
@export var scoreScreenImg : gsheet = load("res://addons/godotWad/resources/intermissionScreensD1.tres")
@export var killsImageStr = "WIOSTK"
@export var itemsImageStr = "WIOSTI"
@export var finishedImageStr = "WIF"
@export var totalImageStr = "WIMSTT"
@export var timeImageStr = "WITIME"
@export var parImageStr = "WIPAR"
@export var secretImageStr = "WISCRT2"


func initialize():
	
	#$"../endScreen".texture = loader.fetchDoomGraphic("ENDOOM")
	var scoreScreen := $"../ScoreScreen"
	
	
	
	
	var data := {}
	
	if scoreScreenImg != null:
		data = scoreScreenImg.getAsDict()
	
	var a = Time.get_ticks_msec()

	
	for i in data:
		scoreScreen.intermissionData[i] =  loader.fetchDoomGraphic(data[i]["0"])

	
	scoreScreen.get_node("%finished").texture = loader.fetchDoomGraphic(finishedImageStr)
	scoreScreen.get_node("%kills").texture = loader.fetchDoomGraphic(killsImageStr)
	scoreScreen.get_node("%items").texture = loader.fetchDoomGraphic(itemsImageStr)
	scoreScreen.get_node("%secret").texture = loader.fetchDoomGraphic(secretImageStr)
	scoreScreen.get_node("%time").texture = loader.fetchDoomGraphic(timeImageStr)
	
	#print("graphic time:",Time.get_ticks_msec()-a)
	
	var font = loader.fetchBitmapFont("numbers")
	var font2 = loader.fetchBitmapFont("default")
	
	scoreScreen.get_node("GridContainer/killsCount/Label").add_theme_font_override("font",font)
	scoreScreen.get_node("GridContainer/itemsCount/Label").add_theme_font_override("font",font)
	scoreScreen.get_node("GridContainer/secretCount/Label").add_theme_font_override("font",font)
	scoreScreen.get_node("GridContainer/timeCount/Label").add_theme_font_override("font",font2)
	
	$"../WadLoader".gameName = loader.get_parent().gameName
	$"..".theme = loader.get_parent().fetchDefaultTheme()
	#theme = loader.get_parent().fetchDefaultTheme()

func getSpriteList():
	return {"sprites":getIntermissionSprites()}
	
func getIntermissionSprites():
	return scoreScreenImg.getColumn("0")
	
