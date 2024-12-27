@tool
extends Node
var loader
var scaleFactor

@export var titlePick ="TITLEPIC"
@export var isTitleRaw = false
@export var titleSong : String 
@export var slectorIcon = ["M_SKULL1","M_SKULL2"]


func getSpriteList():
	var anim = {"skullIcon":[]}
	return {"sprites":[titlePick,"M_NGAME","M_QUITG","M_OPTION","M_SAVEG","M_LOADG"],"animatedSprites":{"skullIcon":slectorIcon}}
	
	
func initialize():
	get_parent().titleSong = titleSong
	$"../options".loader = "../../WadLoader"
	
	
	$"../TextureRect".texture = loader.fetchDoomGraphic(titlePick,false,isTitleRaw)

	$"../v/newGame".texture_normal = loader.fetchDoomGraphic("M_NGAME")
	$"../v/quit".texture_normal =  loader.fetchDoomGraphic("M_QUITG")
	$"../v/options".texture_normal =  loader.fetchDoomGraphic("M_OPTION")
	$"../v/saveGame".texture_normal = loader.fetchDoomGraphic("M_SAVEG")
	$"../v/loadGame".texture_normal = loader.fetchDoomGraphic("M_LOADG")
	$"../move".stream = loader.fetchSound("DSPSTOP")
	$"../target".texture = loader.fetchAnimatedSimple("skullIcon",slectorIcon,2)
	$"../select".stream = loader.fetchSound("DSPISTOL")

	$"../SaveLoadUi".customFont = loader.fetchBitmapFont("default")

	
	$"../v/retry".setFont(loader.fetchBitmapFont("default"))
	$"../v/retry"
