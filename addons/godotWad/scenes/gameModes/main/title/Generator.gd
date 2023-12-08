tool
extends Node
var loader
var scaleFactor

export var titlePick ="TITLEPIC"

func getSpriteList():
	var anim = {"skullIcon":[]}
	return {"sprites":[titlePick,"M_NGAME","M_QUITG","M_OPTION"],"animatedSprites":{"skullIcon":["M_SKULL1","M_SKULL2"]}}
	
	
func initialize():
	$"../TextureRect".texture = loader.fetchDoomGraphic(titlePick)
	$"../v/newGame".texture_normal = loader.fetchDoomGraphic("M_NGAME")
	$"../v/quit".texture_normal =  loader.fetchDoomGraphic("M_QUITG")
	$"../v/options".texture_normal =  loader.fetchDoomGraphic("M_OPTION")
	$"../target".texture = loader.fetchAnimatedSimple("skullIcon",["M_SKULL1","M_SKULL2"],2)
	$"../move".stream = loader.fetchSound("DSPSTOP")
	$"../select".stream = loader.fetchSound("DSPISTOL")
	
