tool
extends Node

enum LINDEF_FLAG{
	BLOCK_CHARACTERS = 0x01,
	BLOCK_MONSTERS = 0x02,
	TWO_SIDED = 0x4
	UPPER_UNPEGGED= 0x08,
	LOWER_UNPEGGED = 0x10,
	SECRET = 0x20,
	BLOCKS_SOUND = 0x40,
	NEVER_ON_AUTOMA = 0x80,
	ALWAYS_ON_AUTOMAP = 0x100,
	PASS_THROUGH = 0x200
}

enum TEXTUREDRAW{
	BOTTOMTOP,
	TOPBOTTOM,
	GRID,
}

enum DIR{
	UP,
	DOWN
}

enum KEY{
	RED,
	GREEN,
	BLUE,
	YELLOW,
}

enum LTYPE {
	DOOR,
	FLOOR,
	LIFT,
	CRUSHER,
	STAIR,
	EXIT,
	LIGHT,
	SCROLL,
	TELEPORT,
	CEILING,
	DUMMY,
	STOPPER,
	ALPHA
}

enum TTYPE{
	DOOR,
	DOOR1,
	SWITCH1,
	SWITCHR,
	WALK1,
	WALKR,
	GUN1,
	GUNR,
	NONE
}

enum DEST{
	LOWEST_ADJ_CEILING,
	LOWEST_ADJ_FLOOR,
	NEXT_HIGHEST_FLOOR,
	NEXT_LOWEST_FLOOR,
	up8,
	up24,
	up32,
	up512,
	NEXT_HIGHEST_FLOOR_up8,
	LOWEST_ADJ_CEILING_DOWN8,
	HIGHEST_ADJ_CEILING,
	FLOOR,
	FLOOR_up8,
	HIGHEST_ADJ_FLOOR
	
}


class interactionSectorSort:
	static func sort_asc(a,b):
		if a["type"] < b["type"]:
			return true
		return false

var sectorLightType = {
	1:{"interval":1.0},
	2:{"interval":0.5},
	3:{"interval":1.0},
	4:{"interval":1.0},
	12:{"interval":0.5},
	13:{"interval":1.0},
	17:{"interval":1.0},
}




var typeDict =  {
	-2:{"type":LTYPE.FLOOR,"str":"stair"},
	
	0:{"type":LTYPE.DUMMY,"str":"dummy"},
	1:{"type":LTYPE.DOOR,"str":"DR Door Open Wait Close","trigger":TTYPE.DOOR,"wait":4,"direction":DIR.UP},
	2:{"type":LTYPE.DOOR,"str":"W1 Door Stay Open","trigger":TTYPE.WALK1,"direction":DIR.UP},
	3:{"type":LTYPE.DOOR,"str":"W1 Door Close","trigger":TTYPE.WALK1,"direction":DIR.DOWN},
	4:{"type":LTYPE.DOOR,"str":"W1 Door","trigger":TTYPE.WALK1,"wait":4,"direction":DIR.UP},
	5:{"type":LTYPE.FLOOR,"str":"W1 Floor Raise To Lowest Adjacent Ceiling","trigger":TTYPE.WALK1,"direction":DIR.UP,"dest":DEST.LOWEST_ADJ_CEILING},
	6:{"type":LTYPE.CRUSHER,"str":"W1 Start Crusher, Fast Damage","trigger":TTYPE.WALK1,"direction":DIR.DOWN},
	7:{"type":LTYPE.STAIR,"str":"S1 Build Stairs 8 Up","trigger":TTYPE.SWITCH1,"inc":8},
	8:{"type":LTYPE.STAIR,"str":"W1 Build Stairs 8 Up","trigger":TTYPE.WALK1,"inc":8},
	9:{"type":LTYPE.FLOOR,"str":"S1 Floor Donut","trigger":TTYPE.SWITCH1,"dest":DEST.LOWEST_ADJ_FLOOR,"direction":DIR.DOWN},
	10:{"type":LTYPE.LIFT,"str":"W1 Lift","trigger":TTYPE.WALK1},
	
	11:{"type":LTYPE.EXIT,"str":"S1 Exit (Normal)","trigger":TTYPE.SWITCH1},
	12:{"type":LTYPE.LIGHT,"str":"W1 Light to Highest Adjacent","trigger":TTYPE.WALK1},
	13:{"type":LTYPE.LIGHT,"str":"W1 Light to 255","trigger":TTYPE.WALK1},
	14:{"type":LTYPE.FLOOR,"str":"S1 Floor Up 32 Change Texture","trigger":TTYPE.SWITCH1,"direction":DIR.UP,"dest":DEST.up32},
	15:{"type":LTYPE.FLOOR,"str":"S1 Floor Up 24 Change Texture","trigger":TTYPE.SWITCH1,"direction":DIR.UP,"dest":DEST.up24},
	16:{"type":LTYPE.DOOR,"str":"W1 Door Close Wait Open","trigger":TTYPE.WALK1,"direction":DIR.DOWN},
	17:{"type":LTYPE.LIGHT,"str":"W1 Light Blink 1 Sec","trigger":TTYPE.WALK1},
	18:{"type":LTYPE.FLOOR,"str":"S1 Floor Raise To Next Highest Floor","trigger":TTYPE.SWITCH1,"direction":DIR.UP,"dest":DEST.NEXT_HIGHEST_FLOOR},
	19:{"type":LTYPE.FLOOR,"str":"W1 Floor Lower To Next Lowest Floor Fast","trigger":TTYPE.WALK1,"direction":DIR.DOWN,"dest":DEST.NEXT_LOWEST_FLOOR},
	
	20:{"type":LTYPE.FLOOR,"str":"S1 Floor To Higher Floor Change Texture","trigger":TTYPE.SWITCH1,"direction":DIR.UP,"dest":DEST.NEXT_HIGHEST_FLOOR,"changeTexture":true},
	21:{"type":LTYPE.FLOOR,"str":"S1 Floor To Lowest Floor Wait Raise","trigger":TTYPE.SWITCH1,"direction":DIR.DOWN,"dest":DEST.LOWEST_ADJ_FLOOR},
	22:{"type":LTYPE.FLOOR,"str":"W1 Riase Floor To Next Highest Floor CT","trigger":TTYPE.WALK1,"direction":DIR.UP,"dest":DEST.NEXT_HIGHEST_FLOOR,"changeTexture":true},
	23:{"type":LTYPE.FLOOR,"str":"S1 FLoor Lower To Lowest Floor","trigger":TTYPE.SWITCHR,"direction":DIR.DOWN,"dest":DEST.LOWEST_ADJ_FLOOR},
	24:{"type":LTYPE.FLOOR,"str":"G1 FLoor Raise To Lowest Ceiling","trigger":TTYPE.GUN1,"direction":DIR.UP,"dest":DEST.LOWEST_ADJ_CEILING},
	25:{"type":LTYPE.CRUSHER,"str":"W1 Crusher Start With Slow Damage","trigger":TTYPE.WALK1,"direction":DIR.DOWN},
	26:{"type":LTYPE.DOOR,"str":"DR Blue Door Open Wait Close","trigger":TTYPE.DOOR,"key":KEY.BLUE,"direction":DIR.UP},
	27:{"type":LTYPE.DOOR,"str":"DR Yellow Door Open Wait Close","trigger":TTYPE.DOOR,"key":KEY.BLUE,"direction":DIR.UP},
	28:{"type":LTYPE.DOOR,"str":"DR Red Door Open Wait Close ","trigger":TTYPE.DOOR,"key":KEY.YELLOW,"direction":DIR.UP},
	29:{"type":LTYPE.DOOR,"str":"S1 Door Open Wait Close","trigger":TTYPE.DOOR,"wait":4,"direction":DIR.UP},
	
	30:{"type":LTYPE.LIFT,"str":"S1 Floor Up Shortest Lower Texture","trigger":TTYPE.WALK1,"direction":DIR.UP,"dest":DEST.up24},
	31:{"type":LTYPE.DOOR,"str":"D1 Door Open Stay","trigger":TTYPE.DOOR,"direction":DIR.UP},
	32:{"type":LTYPE.DOOR,"str":"D1 Blue Door Open Stay","trigger":TTYPE.DOOR1,"key":KEY.BLUE,"direction":DIR.UP},
	33:{"type":LTYPE.DOOR,"str":"D1 Red Door Open Stay","trigger":TTYPE.DOOR1,"key":KEY.RED,"direction":DIR.UP},
	34:{"type":LTYPE.DOOR,"str":"DR Yellow Door Open Stay","trigger":TTYPE.DOOR,"key":KEY.YELLOW,"direction":DIR.UP},
	35:{"type":LTYPE.LIGHT,"str":"W1 Light Change To 35","trigger":TTYPE.WALK1},
	36:{"type":LTYPE.FLOOR,"str":"W1 Floor To 8 Above Higher Adjacent Floor Fast","trigger":TTYPE.WALK1,"direction":DIR.DOWN,"dest":DEST.NEXT_HIGHEST_FLOOR_up8},
	37:{"type":LTYPE.FLOOR,"str":"W1 Floor Lower to Lowest Floor (changes texture)","trigger":TTYPE.WALK1,"direction":DIR.DOWN,"changeTexture":true,"dest":DEST.LOWEST_ADJ_FLOOR},
	38:{"type":LTYPE.FLOOR,"str":"W1 Floor To Lowest Adjacent Floor","trigger":TTYPE.WALK1,"direction":DIR.DOWN,"dest":DEST.LOWEST_ADJ_FLOOR},
	39:{"type":LTYPE.TELEPORT,"str":"W1 Teleport","trigger":TTYPE.WALK1},
	
	40:{"type":LTYPE.CEILING,"str":"W1 Ceiling Raise To Highest Ceiling","trigger":TTYPE.WALK1,"dest":DEST.HIGHEST_ADJ_CEILING,"direction":DIR.UP},
	41:{"type":LTYPE.CEILING,"str":"S1 Ceiling Lower To Floor","trigger":TTYPE.SWITCH1,"dest":DEST.FLOOR,"direction":DIR.DOWN},  
	42:{"type":LTYPE.DOOR,"str":"SR Door Close Stay","trigger":TTYPE.SWITCHR,"direction":DIR.DOWN},
	43:{"type":LTYPE.CEILING,"str":"S1 Ceiling Lower To Floor","trigger":TTYPE.SWITCHR,"dest":DEST.FLOOR,"direction":DIR.DOWN},  
	44:{"type":LTYPE.CEILING,"str":"W1 Ceiling Lower To 8 Above Floor","trigger":TTYPE.WALK1,"direction":DIR.DOWN,"dest":DEST.FLOOR_up8}, 
	45:{"type":LTYPE.FLOOR,"str":"W1 Floor To Highest Adjacent Floor","trigger":TTYPE.WALK1,"direction":DIR.DOWN,"dest":DEST.NEXT_LOWEST_FLOOR},
	46:{"type":LTYPE.DOOR,"str":"GR Door Also Monsters","trigger":TTYPE.GUNR,"direction":DIR.UP},
	47:{"type":LTYPE.FLOOR,"str":"G1 Floor Raise To Next Higher Floor","trigger":TTYPE.GUN1,"direction":DIR.UP,"dest":DEST.NEXT_HIGHEST_FLOOR},
	48:{"type":LTYPE.SCROLL,"str":"Scrolling Wall Left","trigger":TTYPE.NONE,"vector":Vector2(-1,0)},
	49:{"type":LTYPE.CEILING,"str":"S1 Ceiling Lower to 8 above Floor(slow crusher damage)","trigger":TTYPE.SWITCH1,"direction":DIR.DOWN,"dest":DEST.FLOOR_up8}, 
	
	50:{"type":LTYPE.DOOR,"str":"S1 Door Close Stay","trigger":TTYPE.SWITCH1,"direction":DIR.DOWN},
	51:{"type":LTYPE.EXIT,"str":"S1 Exit Level to Secret","trigger":TTYPE.SWITCH1},
	52:{"type":LTYPE.EXIT,"str":"W1 EXIT","trigger":TTYPE.WALK1},
	53:{"type":LTYPE.FLOOR,"str":"W1 Floor Start Moving Up And Down","trigger":TTYPE.WALK1,"direction":DIR.UP,"loop":true,"dest":DEST.HIGHEST_ADJ_FLOOR},
	54:{"type":LTYPE.STOPPER,"str":"W1 Floor Stop Moving","trigger":TTYPE.WALK1},
	55:{"type":LTYPE.FLOOR,"str":"S1 Floor Raise to 8 below Lowest Ceil","trigger":TTYPE.SWITCH1,"direction":DIR.UP,"dest":DEST.LOWEST_ADJ_CEILING_DOWN8},
	56:{"type":LTYPE.FLOOR,"str":"W1 Floor Raise to 8 below Lowest Ceil","trigger":TTYPE.WALK1,"direction":DIR.UP,"dest":DEST.LOWEST_ADJ_CEILING_DOWN8},
	57:{"type":LTYPE.STOPPER,"str":"W1 Crusher Stop","trigger":TTYPE.WALK1,"direction":DIR.UP},
	58:{"type":LTYPE.FLOOR,"str":"W1 Floor Up 24","trigger":TTYPE.WALK1,"direction":DIR.UP,"dest":DEST.up24},
	59:{"type":LTYPE.FLOOR,"str":"W1 Floor Up 24 Change Texture and Type","trigger":TTYPE.WALK1,"direction":DIR.UP,"dest":DEST.up24,"changeTexture":true},###############################################change type 
	
	60:{"type":LTYPE.FLOOR,"str":"SR Floor Lower to Lowest Floor ","trigger":TTYPE.SWITCHR,"direction":DIR.DOWN,"dest":DEST.LOWEST_ADJ_FLOOR},
	61:{"type":LTYPE.DOOR,"str":"SR Door Stay Open","trigger":TTYPE.SWITCHR,"direction":DIR.UP},
	62:{"type":LTYPE.LIFT,"str":"SR Lift Lower Wait Raise","trigger":TTYPE.SWITCHR,"direction":DIR.DOWN},
	63:{"type":LTYPE.DOOR,"str":"SR Door Open Wait Close","trigger":TTYPE.SWITCHR,"direction":DIR.UP,"wait":4},
	64:{"type":LTYPE.FLOOR,"str":"SR Floor Raise to Lowest Ceiling","trigger":TTYPE.SWITCHR,"direction":DIR.UP,"dest":DEST.LOWEST_ADJ_CEILING},
	65:{"type":LTYPE.FLOOR,"str":"SR Floor Raise to 8 below Lowest Ceiling","trigger":TTYPE.SWITCHR,"direction":DIR.UP,"dest":DEST.LOWEST_ADJ_CEILING_DOWN8},
	66:{"type":LTYPE.FLOOR,"str":"SR Floor Raise by 24 (changes texture)","trigger":TTYPE.SWITCHR,"direction":DIR.UP,"dest":DEST.up24,"changeTexture":true},
	67:{"type":LTYPE.FLOOR,"str":"SR Floor Raise by 32 (changes texture)","trigger":TTYPE.SWITCHR,"direction":DIR.UP,"dest":DEST.up32,"changeTexture":true},
	68:{"type":LTYPE.FLOOR,"str":"SR Floor Raise to Next Higer Floor (changes texture)","trigger":TTYPE.SWITCHR,"direction":DIR.UP,"dest":DEST.NEXT_HIGHEST_FLOOR,"changeTexture":true},
	69:{"type":LTYPE.FLOOR,"str":"SR Floor Raise to Next Higer Floor","trigger":TTYPE.SWITCHR,"direction":DIR.UP,"dest":DEST.NEXT_HIGHEST_FLOOR},
	
	70:{"type":LTYPE.FLOOR,"str":"SR Floor Lower to 8 above Highest Floor","trigger":TTYPE.SWITCHR,"direction":DIR.DOWN,"dest":DEST.NEXT_HIGHEST_FLOOR_up8},
	71:{"type":LTYPE.FLOOR,"str":"S1 Floor Lower to 8 above Highest Floor","trigger":TTYPE.SWITCH1,"direction":DIR.DOWN,"dest":DEST.NEXT_HIGHEST_FLOOR_up8},
	72:{"type":LTYPE.CEILING,"str":"WR Ceiling Lower To 8 above Floor","trigger":TTYPE.WALKR,"dest":DEST.up8,"direction":DIR.DOWN},  
	73:{"type":LTYPE.CRUSHER,"str":"WR Start Crusher, Slow Damage","trigger":TTYPE.WALKR,"direction":DIR.DOWN},
	74:{"type":LTYPE.STOPPER,"str":"W1 Crusher Stop","trigger":TTYPE.WALK1,"direction":DIR.DOWN},
	75:{"type":LTYPE.DOOR,"str":"WR Door Close Stay","trigger":TTYPE.WALKR,"direction":DIR.UP},
	76:{"type":LTYPE.DOOR,"str":"WR Door Close Stay Open","trigger":TTYPE.WALKR,"direction":DIR.DOWN},#What
	77:{"type":LTYPE.CRUSHER,"str":"WR Start Crusher Fast Damage","trigger":TTYPE.WALKR,"direction":DIR.DOWN},
	78:{"type":LTYPE.DUMMY,"str":"dummy","trigger":TTYPE.WALKR},#dummy for now
	79:{"type":LTYPE.LIGHT,"str":"WR Light to 35","trigger":TTYPE.WALKR},
	
	80:{"type":LTYPE.LIGHT,"str":"WR Light Change to Brightest Adjacent","trigger":TTYPE.WALKR},
	81:{"type":LTYPE.LIGHT,"str":"WR Light Change to 255","trigger":TTYPE.WALKR},
	82:{"type":LTYPE.FLOOR,"str":"WR Floor Lower To Lowest Floor","trigger":TTYPE.WALKR,"direction":DIR.DOWN,"dest":DEST.LOWEST_ADJ_FLOOR},
	83:{"type":LTYPE.FLOOR,"str":"WR Floor Lower To Highest Floor","trigger":TTYPE.WALKR,"direction":DIR.DOWN,"dest":DEST.NEXT_LOWEST_FLOOR},
	84:{"type":LTYPE.FLOOR,"str":"WR Floor Lower To Lowest Floor (changes texture)","trigger":TTYPE.WALKR,"direction":DIR.DOWN,"dest":DEST.LOWEST_ADJ_FLOOR,"changeTexture":true},
	85:{"type":LTYPE.SCROLL,"str":"Scrolling Wall Right","trigger":TTYPE.NONE,"vector":Vector2(1,0)},
	86:{"type":LTYPE.DOOR,"str":"WR Door Open Stay","trigger":TTYPE.WALKR,"direction":DIR.UP},
	87:{"type":LTYPE.FLOOR,"str":"WR Floor Start Moving Up And Down","trigger":TTYPE.WALKR,"direction":DIR.UP,"loop":true,"dest":DEST.HIGHEST_ADJ_FLOOR},
	88:{"type":LTYPE.LIFT,"str":"WR Lift Lower Wait Raise","trigger":TTYPE.WALKR,"direction":DIR.DOWN},
	89:{"type":LTYPE.STOPPER,"str":"WR Floor Stop Moving","trigger":TTYPE.WALKR},#----------------------------------------------
	
	90:{"type":LTYPE.DOOR,"str":"WR Door Open Wait Close","trigger":TTYPE.WALKR,"wait":4,"direction":DIR.UP},
	91:{"type":LTYPE.FLOOR,"str":"WR Floor Raise To Lowest Ceiling","trigger":TTYPE.WALKR,"direction":DIR.UP,"dest":DEST.LOWEST_ADJ_CEILING},
	92:{"type":LTYPE.FLOOR,"str":"WR Floor Up 24","trigger":TTYPE.WALK1,"direction":DIR.UP,"dest":DEST.up24,"inc":24},
	93:{"type":LTYPE.FLOOR,"str":"WR Floor Up 24 (changes texture)","trigger":TTYPE.WALK1,"direction":DIR.UP,"dest":DEST.up24,"inc":24,"changeTexture":true},
	94:{"type":LTYPE.FLOOR,"str":"WR Floor Raise to 8 below Lowest Ceil","trigger":TTYPE.WALKR,"direction":DIR.UP,"dest":DEST.LOWEST_ADJ_CEILING_DOWN8},
	95:{"type":LTYPE.FLOOR,"str":"WR Floor Raise to Next Higher Floor","trigger":TTYPE.WALKR,"direction":DIR.UP,"dest":DEST.NEXT_HIGHEST_FLOOR},
	96:{"type":LTYPE.FLOOR,"str":"WR Floor Raise to Next Shortest Lower Texture","trigger":TTYPE.WALKR,"direction":DIR.UP,"dest":DEST.NEXT_HIGHEST_FLOOR},
	98:{"type":LTYPE.FLOOR,"str":"WR Floor Lower to 8 above Highest Floor","trigger":TTYPE.WALKR,"direction":DIR.DOWN,"dest":DEST.NEXT_HIGHEST_FLOOR_up8},
	97:{"type":LTYPE.TELEPORT,"str":"WR Teleport","trigger":TTYPE.WALKR},
	99:{"type":LTYPE.DOOR,"str":"SR Blue Door Open Stay (fast)","trigger":TTYPE.SWITCHR,"KEY":KEY.BLUE,"direction":DIR.UP},
	
	100:{"type":LTYPE.STAIR,"str":"S1 Stairs Raise by 16 fast","trigger":TTYPE.WALK1,"inc":16},
	101:{"type":LTYPE.FLOOR,"str":"S1 Floor Raise To Lowest Ceil","trigger":TTYPE.SWITCH1,"direction":DIR.UP,"dest":DEST.LOWEST_ADJ_CEILING},
	102:{"type":LTYPE.FLOOR,"str":"S1 Floor Lower to Highest Adjacent Floor","trigger":TTYPE.SWITCH1,"direction":DIR.DOWN,"dest":DEST.NEXT_LOWEST_FLOOR},
	103:{"type":LTYPE.DOOR,"str":"S1 Door Open Stay","trigger":TTYPE.SWITCH1,"direction":DIR.UP},
	104:{"type":LTYPE.LIGHT,"str":"W1 Light Change to Darkest Adjacent","trigger":TTYPE.WALK1},
	105:{"type":LTYPE.DOOR,"str":"WR Door Open Wait Close Fast","trigger":TTYPE.WALKR,"wait":4,"direction":DIR.UP},
	106:{"type":LTYPE.DOOR,"str":"WR Door Stay Open Stay Fast","trigger":TTYPE.WALKR,"direction":DIR.UP},
	107:{"type":LTYPE.DOOR,"str":"WR Door Stay Close Stay Fast","trigger":TTYPE.WALKR,"direction":DIR.UP},
	108:{"type":LTYPE.DOOR,"str":"W1 Door Open Wait Close Fast","trigger":TTYPE.WALK1,"direction":DIR.UP},
	109:{"type":LTYPE.DOOR,"str":"W1 Door Stay Open Fast","trigger":TTYPE.WALK1,"direction":DIR.UP},
	
	110:{"type":LTYPE.DOOR,"str":"W1 Door Close (fast)","trigger":TTYPE.WALK1,"direction":DIR.DOWN},
	111:{"type":LTYPE.DOOR,"str":"S1 Door Open Wait Close (fast)","trigger":TTYPE.SWITCH1,"direction":DIR.UP},
	112:{"type":LTYPE.DOOR,"str":"SR Door Open Stay (fast)","trigger":TTYPE.SWITCH1,"direction":DIR.UP},
	113:{"type":LTYPE.DOOR,"str":"S1 Door Close Stay (fast)","trigger":TTYPE.SWITCH1,"direction":DIR.DOWN},
	114:{"type":LTYPE.DOOR,"str":"SR Door Open Wait Close (fast)","trigger":TTYPE.SWITCHR,"direction":DIR.UP},
	115:{"type":LTYPE.DOOR,"str":"SR Door Open Stay Fast","trigger":TTYPE.SWITCHR,"direction":DIR.UP},
	116:{"type":LTYPE.DOOR,"str":"SR Door Close Stay Fast","trigger":TTYPE.SWITCHR,"direction":DIR.DOWN},
	117:{"type":LTYPE.DOOR,"str":"DR Door Open Wait Close (fast)","trigger":TTYPE.DOOR,"direction":DIR.UP},
	118:{"type":LTYPE.DOOR,"str":"D1 Door Open Wait Close (fast)","trigger":TTYPE.DOOR1,"direction":DIR.UP},
	119:{"type":LTYPE.FLOOR,"str":"W1 Floor Raise to Next Higher Floor","trigger":TTYPE.WALK1,"direction":DIR.UP,"dest":DEST.NEXT_HIGHEST_FLOOR},
	
	120:{"type":LTYPE.LIFT,"str":"WR Lift Lower Wait Raise fast","trigger":TTYPE.WALKR,"direction":DIR.DOWN},
	121:{"type":LTYPE.LIFT,"str":"W1 Lift Lower Wait Raise fast","trigger":TTYPE.WALK1,"direction":DIR.DOWN},
	122:{"type":LTYPE.LIFT,"str":"S1 Lift Lower Wait Raise fast","trigger":TTYPE.WALK1,"direction":DIR.DOWN},
	123:{"type":LTYPE.LIFT,"str":"SR Lift Lower Wait Raise fast","trigger":TTYPE.SWITCHR,"direction":DIR.DOWN},
	124:{"type":LTYPE.EXIT,"str":"W1 Exit Level (secret)","trigger":TTYPE.SWITCH1},
	125:{"type":LTYPE.TELEPORT,"str":"W1 Monster Teleport","trigger":TTYPE.WALK1},
	126:{"type":LTYPE.TELEPORT,"str":"WR Monster Teleport","trigger":TTYPE.WALKR},
	127:{"type":LTYPE.STAIR,"str":"S1 Stairs Raise by 16 fast","trigger":TTYPE.SWITCH1,"inc":16},
	128:{"type":LTYPE.FLOOR,"str":"WR Floor Raise to Next Higher Floor","trigger":TTYPE.WALKR,"direction":DIR.UP,"dest":DEST.NEXT_HIGHEST_FLOOR},
	129:{"type":LTYPE.TELEPORT,"str":"W1 Teleport (Monsters Only)","trigger":TTYPE.WALK1},
	
	130:{"type":LTYPE.FLOOR,"str":"W1 Floor Raise to Next High Floor fast","trigger":TTYPE.WALK1,"dest":DEST.NEXT_HIGHEST_FLOOR,"direction":DIR.UP},
	131:{"type":LTYPE.FLOOR,"str":"S1 Floor Raise to Next Higher Floor fast","trigger":TTYPE.WALKR,"direction":DIR.UP,"dest":DEST.NEXT_HIGHEST_FLOOR},
	132:{"type":LTYPE.FLOOR,"str":"SR Floor Raise to Next Higher Floor fast","trigger":TTYPE.SWITCHR,"direction":DIR.UP,"dest":DEST.NEXT_HIGHEST_FLOOR},
	133:{"type":LTYPE.DOOR,"str":"S1 Blue Door Open Stay (fast)","trigger":TTYPE.DOOR1,"KEY":KEY.BLUE,"direction":DIR.UP},
	134:{"type":LTYPE.DOOR,"str":"SR Red Door Open Stay (fast)","trigger":TTYPE.SWITCHR,"KEY":KEY.RED,"direction":DIR.UP},
	135:{"type":LTYPE.DOOR,"str":"S1 Red Door Open Stay (fast)","trigger":TTYPE.SWITCH1,"KEY":KEY.RED,"direction":DIR.UP},
	136:{"type":LTYPE.DOOR,"str":"SR Yellow Door Open Stay (fast)","trigger":TTYPE.SWITCHR,"KEY":KEY.YELLOW,"direction":DIR.UP},
	137:{"type":LTYPE.DOOR,"str":"S1 Yellow Door Open Stay (fast)","trigger":TTYPE.SWITCH1,"KEY":KEY.YELLOW,"direction":DIR.UP},
	138:{"type":LTYPE.LIGHT,"str":"SR Light to 255","trigger":TTYPE.SWITCHR},
	139:{"type":LTYPE.LIGHT,"str":"SR Light to 35","trigger":TTYPE.SWITCHR},
	
	140:{"type":LTYPE.FLOOR,"str":"SR Floor Raise by 512","trigger":TTYPE.SWITCHR,"direction":DIR.UP,"dest":DEST.up512},
	141:{"type":LTYPE.CRUSHER,"str":"W1 Start Crusher Slow Damage silent","trigger":TTYPE.WALK1,"direction":DIR.DOWN},
	
	159:{"type":LTYPE.FLOOR,"str":"S1 Floor Down To Adjacent Floor","trigger":TTYPE.SWITCH1,"direction":DIR.DOWN,"dest":DEST.LOWEST_ADJ_FLOOR},
	195:{"type":LTYPE.TELEPORT,"str":"SR Teleport","trigger":TTYPE.SWITCHR},
	221:{"type":LTYPE.FLOOR,"str":"S1 Floor Down To Adjacent Floor","trigger":TTYPE.SWITCH1,"direction":DIR.DOWN,"dest":DEST.NEXT_LOWEST_FLOOR},
	260:{"type":LTYPE.ALPHA,"str":"Translucent Line","alpha":0.5},
}
	
	
var mapTo666 = {
	"E1M8":{"type":23,"npcName":"Baron of Hell"},
	"E2M8":{"type":11,"npcName":"Baron of Hell"},
	"E3M8":{"type":11,"npcName":"Baron of Hell"},

}


var sideDefs
var sectors
var verts 
var lineToSide
var lines
var sides 
var geomNode = null
var sideNodePath = {}
var preInstancedMeshes = {}

var mapName 
var mapNode 
var mapDict
func _ready():
	set_meta("hidden",true)
	

func createLevel(mapDict,mapname):
	self.mapDict =mapDict
	print("level create start")
	mapName = mapname
	mapNode = Spatial.new()
	mapNode.name = mapname
	mapNode.set_meta("map",true)
	
	get_parent().mapNode = mapNode
	mapNode.set_script(load("res://addons/godotWad/src/mapNode.gd"))
	
	mapNode.transform = get_parent().transform
	
	
	geomNode = Spatial.new()
	geomNode.name = "Geometry"
	mapNode.add_child(geomNode)
	
	var specialNode = Node.new()
	specialNode.name = "SectorSpecials"
	mapNode.add_child(specialNode)
	
		
	var ineteractablesNode = Spatial.new()
	ineteractablesNode.name = "Interactables"
	mapNode.add_child(ineteractablesNode)
	
	
	
	preInstancedMeshes = {}
	sideNodePath = {}

	sideDefs = mapDict["SIDEDEFS"]
	sectors = mapDict["SECTORS"]
	verts = mapDict["VERTEXES"]
	lines = mapDict["LINEDEFS"]
	sides = mapDict["SIDEDEFS"]
	
	print("floor start")
	$"../FloorBuilder".instance(mapDict,geomNode,specialNode)
	print("floor done")
	
	
	for r in mapDict["staticRenderables"]:
		createStaticSide(r)
	
	var count = 0

	for r in mapDict["dynamicRenderables"]:
		createDynamicSide(r)
		count +=1
		
	
	
	print("start mesh combiner")
	if get_parent().mergeMesh != get_parent().MERGE.DISABLED:
		$"../MeshCombiner".merge(preInstancedMeshes,geomNode)
	
	print("mesh combiner done")
	print("creating interactables....")
	createInteractables(mapDict["sectorToInteraction"],mapDict)
	print("create interactables done")
	print("creating skybox...")
	if mapDict["createSurroundingSkybox"]:
		createSurroundingSkybox(mapDict["BB"],mapDict["minDim"])
	
	#get_parent().get_parent().add_child(mapNode) #add map node last so it dosen't show up while being constructed
	
	

	print("map made")
	return mapNode
	
	



func createStaticSide(renderable):
	var start = verts[renderable["startVertIdx"]]
	var end =  verts[renderable["endVertIdx"]]
	var sector = sectors[renderable["sector"]]
	var oSectorIdx = renderable["oSector"]
	var type = renderable["type"]
	var fFloor = sector["floorHeight"]
	var fCeil = sector["ceilingHeight"]
	var textureName = renderable["texture"]
	var flags = renderable["flags"]
	var textureOffset = renderable["textureOffset"]
	var lowerUnpegged = (flags &  LINDEF_FLAG.LOWER_UNPEGGED) != 0
	var upperUnpegged = (flags &  LINDEF_FLAG.UPPER_UNPEGGED) != 0
	var doubleSided = (flags & LINDEF_FLAG.TWO_SIDED) != 0
	
	
	var hasCollision = flags & LINDEF_FLAG.BLOCK_CHARACTERS == 1
	
	if type != "middle": hasCollision = true
	
	
	var floorDraw = TEXTUREDRAW.TOPBOTTOM
	var midDraw = TEXTUREDRAW.TOPBOTTOM
	var ceilDraw = TEXTUREDRAW.BOTTOMTOP
	var lineIndex = renderable["lineIndex"]

	
	if lowerUnpegged: 
		floorDraw = TEXTUREDRAW.GRID
		midDraw = TEXTUREDRAW.BOTTOMTOP
	
	if upperUnpegged:
		ceilDraw = TEXTUREDRAW.GRID
	
	
	if type == "trigger":return
	

	var texture
	

	
	if textureName != "F_SKY1":
		texture = $"../ResourceManager".fetchTexture(textureName,!get_parent().dontUseShader)
	
	
	#if texture == null:
	#	breakpoint
	
	var oSectorSky = false
	if oSectorIdx != null:
		if sectors[oSectorIdx]["ceilingTexture"] == "F_SKY1":
			oSectorSky = true
	
		
	if type == "skyUpper" and oSectorIdx == null:
		if fCeil < sector["highestNeighCeilInc"]:
			createMeshAndCol(start,end,fCeil,sector["highestNeighCeilInc"],sector["highestNeighCeilInc"],texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"])
			return
		else:
			return

	
	if sector["ceilingTexture"] == "F_SKY1" and type!="lower" and oSectorSky and renderable["oSide"]["upperName"] == "-" and oSectorIdx and type == "upper" :#if my ceiling is sky and I'm not lower and oSector is also sky then I'm sky 
		return

	
	#hasCollision =true# hasCollision or doubleSided
	
	
	if oSectorIdx == null:
		if type == "middle":
			createMeshAndCol(start,end,fFloor,fCeil,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"])
			return
		else:
			return
		
	
	var oSector = sectors[oSectorIdx]
	var oFloor = oSector["floorHeight"]
	var oCeil = oSector["ceilingHeight"]
	
	var lowFloor = min(fFloor,oFloor)
	var highFloor = max(fFloor,oFloor)
	var lowCeil = min(fCeil,oCeil)
	var highCeil = max(fCeil,oCeil)
	
	

	if type == "middle" and !doubleSided:
		
		
		
		createMeshAndCol(start,end,fFloor,fCeil,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],false)
		return 
		
	if type == "middle" and doubleSided and texture != null:#floating mid
		var h = texture.get_height()
		var shootThrough = false
		
		if oSector != null and doubleSided != false: shootThrough = true
		
		if lowerUnpegged:
			
			createMeshAndCol(start,end,highFloor+textureOffset.y,highFloor+textureOffset.y+h,fCeil,texture,midDraw,Vector2(textureOffset.x,0),renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],shootThrough)
			return
			#var wallNode = createWall(startVert,endVert,start,end,midDraw,Vector2(offset.x,0),hasCollision,texture,fCeil,String(lineIndex)+" mid",type,sectorLight)
		
		else:#lower unpegged and no pegged seems to be the same
			
			#createMeshAndCol(start,end,fCeil+textureOffset.y-h,fCeil+textureOffset.y,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,true,renderable["sType"])
			
			var a = lowCeil+textureOffset.y-h
			var b = highFloor
			createMeshAndCol(start,end,max(a,b),lowCeil+textureOffset.y,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],shootThrough)
			return
		return
	
	if type == "upper" and fCeil > oCeil:#upper section
		createMeshAndCol(start,end,lowCeil,highCeil,fCeil,texture,ceilDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"])
	
	if type == "lower" and fFloor < oFloor:#lower section
		createMeshAndCol(start,end,lowFloor,highFloor,fCeil,texture,floorDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"])
	



func createDynamicSide(renderable):
	
	var sectorIdx = renderable["sector"]#
	var oSectorIdx = renderable["oSector"]
	var textureName = renderable["texture"]

	
	var sTypes = []
	if mapDict["sectorToInteraction"].has(sectorIdx): sTypes += mapDict["sectorToInteraction"][sectorIdx]
	
	
	var start = verts[renderable["startVertIdx"]]
	var end =  verts[renderable["endVertIdx"]]
	var sector = sectors[sectorIdx]

	var type = renderable["type"]
	var fFloor = sectors[sectorIdx]["floorHeight"]
	var fCeil = sectors[sectorIdx]["ceilingHeight"]

	var flags = renderable["flags"]
	var textureOffset = renderable["textureOffset"]
	
	
	var hasCollision = (flags & LINDEF_FLAG.BLOCK_CHARACTERS) == 1
	var lowerUnpegged = (flags &  LINDEF_FLAG.LOWER_UNPEGGED) != 0
	var upperUnpegged = (flags &  LINDEF_FLAG.UPPER_UNPEGGED) != 0
	var doubleSided = (flags & LINDEF_FLAG.TWO_SIDED) != 0
	var floorDraw = TEXTUREDRAW.TOPBOTTOM
	var midDraw = TEXTUREDRAW.TOPBOTTOM
	var ceilDraw = TEXTUREDRAW.BOTTOMTOP
	var lineIndex = renderable["lineIndex"]
	var oSide = renderable["oSide"]
	var oSideHasTexture = false

	if lowerUnpegged: 
		floorDraw = TEXTUREDRAW.GRID
		midDraw = TEXTUREDRAW.BOTTOMTOP
	
	if upperUnpegged:
		ceilDraw = TEXTUREDRAW.GRID
	
	hasCollision = hasCollision or doubleSided
	


	if type == "trigger":
		return
	


	var texture = $"../ResourceManager".fetchTexture(textureName,!get_parent().dontUseShader)
	

	var oSectorSky = false
	if oSectorIdx != null:
		if sectors[oSectorIdx]["ceilingTexture"] == "F_SKY1":
			oSectorSky = true
	
	if sector["ceilingTexture"] == "F_SKY1" and type!="lower" and oSectorSky:
		if get_parent().skyWall!= get_parent().SKYVIS.DISABLED:
			textureName = "F_SKY1"

	
	var dest = fFloor
	var minDest = INF
	var maxDest = -INF
	var destH = fFloor
	

	for t in sTypes:
		
		var ty = t["type"]
		
		if ty == -2 and renderable.has("stairInfo"):
			destH = sector["floorHeight"]+16*renderable["stairInfo"]["stairNum"]
		
		if typeDict[ty].has("dest"):
			var destType = typeDict[ty]["dest"]
			destH = WADG.getDest(destType,sector)
		
		elif typeDict[ty]["type"] == WADG.LTYPE.LIFT: destH = sector["lowestNeighFloorExc"]
		elif typeDict[ty]["type"] == WADG.LTYPE.DOOR: destH = sector["lowestNeighCeilExc"]
		elif typeDict[ty]["type"] == WADG.LTYPE.CRUSHER: destH = sector["floorHeight"]+8

		
		minDest = min(minDest,destH)
		maxDest = max(maxDest,destH)
		
	

	if oSectorIdx == null:
		if type == "middle":
			createMeshAndCol(start,end,min(fFloor,minDest),max(fCeil,maxDest),fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,true,renderable["sType"])
			return
		return
		
		

	var oSector = sectors[oSectorIdx]
	var oFloor = oSector["floorHeight"]
	var oCeil = oSector["ceilingHeight"]
	
	var minOdest = INF
	var maxOdest = -INF
	var odestH = oFloor
	
	if mapDict["sectorToInteraction"].has(oSectorIdx):
		var allTypes = mapDict["sectorToInteraction"][oSectorIdx]
		for t in allTypes:
			var ty = t["type"]
			
			if ty == -2 and renderable.has("stairInfo"):
				destH = sector["floorHeight"]+16*renderable["stairInfo"]["stairNum"]
			
			if typeDict[ty].has("dest"):
				var destType = typeDict[ty]["dest"]
				odestH = WADG.getDest(destType,oSector)
				
			elif typeDict[ty]["type"] == WADG.LTYPE.LIFT: destH = sector["lowestNeighFloorExc"]
			elif typeDict[ty]["type"] == WADG.LTYPE.DOOR: destH = sector["lowestNeighCeilExc"]
			elif typeDict[ty]["type"] == WADG.LTYPE.CRUSHER: destH = sector["floorHeight"]

			minOdest = min(minOdest,odestH)
			maxOdest = max(maxOdest,odestH)
	

	
	var lowestLocalFloor = min(fFloor,minDest)
	var lowestLocalCeil = min(fCeil,minDest)
	var highestLocalCeil = max(fCeil,maxDest)
	var highestOFloor = max(oFloor,maxOdest)
	var lowestOCeil = min(oCeil,minOdest)
	
	
	var lowestCeil = min(fCeil,min(oCeil,minDest))
	var highestCeil = max(fCeil,max(oCeil,maxDest))
	
	var lowFloor = min(fFloor,oFloor)
	var highFloor = max(fFloor,oFloor)
	var lowCeil = min(fCeil,oCeil)
	var highCeil = max(fCeil,oCeil)
	

	
	if type == "middle" and !doubleSided:
		createMeshAndCol(start,end,lowestLocalFloor,highestOFloor,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,true,renderable["sType"],false)
		return 
	
	if type == "middle" and doubleSided and texture != null:#floating mid
		var h = texture.get_height()
		var shootThrough = false
		
		if oSector != null and doubleSided != false: shootThrough = true
		
		if lowerUnpegged:
			
			createMeshAndCol(start,end,highFloor+textureOffset.y,highFloor+textureOffset.y+h,fCeil,texture,midDraw,Vector2(textureOffset.x,0),renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],shootThrough)
			return
			#var wallNode = createWall(startVert,endVert,start,end,midDraw,Vector2(offset.x,0),hasCollision,texture,fCeil,String(lineIndex)+" mid",type,sectorLight)
		
		else:#lower unpegged and no pegged seems to be the same
			
			#createMeshAndCol(start,end,fCeil+textureOffset.y-h,fCeil+textureOffset.y,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,true,renderable["sType"])
			
			var a = lowCeil+textureOffset.y-h
			var b = highFloor
			createMeshAndCol(start,end,max(a,b),lowCeil+textureOffset.y,fCeil,texture,midDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,false,renderable["sType"],shootThrough)
			return
		return
	

		
	if type == "lower":
		
		if renderable.has("stairIdx"):
			highestOFloor = highestOFloor + renderable["stairIdx"]*renderable["stairInc"]
		
		
		
		var wallBot = oFloor-(highestOFloor-lowestLocalFloor)
		var wallTop = oFloor
		
		if renderable.has("stairIdx"):
			wallBot =  lowestLocalFloor-(renderable["stairIdx"]*renderable["stairInc"])


		if lowestLocalFloor < highestOFloor:

			createMeshAndCol(start,end,wallBot,wallTop,fCeil,texture,floorDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,true,renderable["sType"])


	if type == "upper":
		var bottom = min(minDest,minOdest)
		
		var wallBottom = oCeil
		var wallTop = oCeil + (highestLocalCeil-lowestOCeil)
		
	
		if wallBottom < wallTop: 
			createMeshAndCol(start,end,wallBottom,wallTop,fCeil,texture,ceilDraw,textureOffset,renderable["sideIndex"],lineIndex,renderable["sector"],type,hasCollision,textureName,true,renderable["sType"])
	return
	
	
func makeSideMesh(start,end,floorZ,ceilZ,fCeil,texture,uvType,textureOffset,sideIndex,sector,textureName,sType):
	var origin = Vector3(start.x,ceilZ,start.y)
	var height = ceilZ-floorZ 
	var startUVy = 0
	var startUVx = 0
	var endUVy= 0
	var endUVx = 0
	#var origin = Vector3(start.x,floorZ,start.y) -  Vector3(end.x,ceilZ,end.y)/2.0


	if texture != null:
		var textureDim = texture.get_size()
		endUVx = ((start-end).length()/textureDim.x)
		if uvType == TEXTUREDRAW.TOPBOTTOM:
			endUVy = height
			startUVy/=textureDim.y
			endUVy/=textureDim.y
		
		elif uvType == TEXTUREDRAW.BOTTOMTOP:
			startUVy = floorZ-ceilZ
			endUVy = 0
			startUVy/=textureDim.y
			endUVy/=textureDim.y
			
		elif uvType == TEXTUREDRAW.GRID:
			startUVy = (fCeil - ceilZ)/textureDim.y
			endUVy = startUVy+(ceilZ-floorZ)/textureDim.y
	
	 
		startUVy += textureOffset.y / texture.get_height() 
		endUVy += textureOffset.y / texture.get_height() 
	
		startUVx += textureOffset.x / texture.get_width() 
		endUVx += textureOffset.x / texture.get_width() 
	
	var TL = Vector3(start.x,ceilZ,start.y) - origin
	var BL = Vector3(start.x,floorZ,start.y) -origin
	var TR = Vector3(end.x,ceilZ,end.y) - origin
	var BR = Vector3(end.x,floorZ,end.y) - origin
	
	var line1 = TL - TR
	var line2 = TL - BL
	var normal = -line1.cross(line2).normalized()

	var surf = SurfaceTool.new()
	var mesh = Mesh.new()
	var mat
	
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)



	if texture!=null and textureName != "F_SKY1":
		var inc = 0
		if start.y == end.y: inc = -1
		elif start.x == end.x: inc = 1
		
		var scroll = Vector2(0,0)
		var alpha = 1.0
		
		if typeDict[sType]["type"] == LTYPE.SCROLL:
			scroll = typeDict[sType]["vector"]
		
		if typeDict[sType].has("alpha"):
			alpha = typeDict[sType]["alpha"]
		
		mat =  $"../ResourceManager".fetchMaterial(textureName,texture,sector["lightLevel"],scroll,alpha,inc,true)
		
	
	if textureName == "F_SKY1":
		#mat = $"../ResourceManager".createSkyMat()
		mat = $"../ResourceManager".fetchSkyMat(true)
	
	surf.set_material(mat)
		

	surf.add_normal(normal)
	surf.add_uv(Vector2(startUVx,startUVy))
	surf.add_vertex(TL)
	
	surf.add_normal(normal)
	surf.add_uv((Vector2(endUVx,startUVy)))
	surf.add_vertex(TR)
	
	surf.add_normal(normal)
	surf.add_uv(Vector2(endUVx,endUVy))
	surf.add_vertex(BR)
	
	
	surf.add_normal(normal)
	surf.add_uv(Vector2(startUVx,startUVy))
	surf.add_vertex(TL)
	
	surf.add_normal(normal)
	surf.add_uv(Vector2(endUVx,endUVy))
	surf.add_vertex(BR)
	
	surf.add_normal(normal)
	surf.add_uv(Vector2(startUVx,endUVy))
	surf.add_vertex(BL)
	
	
	surf.commit(mesh)
	mesh.surface_set_name(mesh.get_surface_count()-1,textureName)
	if get_parent().unwrapLightmap:
		mesh.lightmap_unwrap(Transform.IDENTITY,1)
	var meshNode = MeshInstance.new()
	meshNode.translation = origin
	meshNode.mesh = mesh
	
	if texture == null and textureName !="F_SKY1" and !get_parent().renderNullTextures:
		meshNode.visible = false
	
	meshNode.name = "sidedef " + sideIndex
	return meshNode

func createMeshAndCol(start,end,floorZ,ceilZ,fCeil,texture,uvType,textureOffset,sideIndex,lineIndex,sectorIdx,nameStr,hasCollision,textureName,isDynamic,sType,shootThrough = false):
	var side = sides[int(sideIndex)]
	var oSectorIdx = side["backSector"]
	var sector = sectors[sectorIdx]
	var sectorIdxPre = sectorIdx
	sectorIdx = "sector " + String(sectorIdx)
	var sectorNode = geomNode.get_node(sectorIdx)
	
	#if textureName == "F_SKY1":
	#	breakpoint
	#var center =  start+((start-end)/2.0)
	
	
	#start = (start-center)*-1.1 + center
	#end = (end-center)*1.1 + center
	
	
	if sectorNode == null:
		print("couldn't find sector node for line:",String(lineIndex))
		sectorNode = Spatial.new()
		get_parent().add_child(sectorNode)
		
	
	if sectorNode.get_node_or_null(String(lineIndex)) == null:
		var lineNode = Spatial.new()
		lineNode.name =  "linenode " + String(lineIndex)
		sectorNode.add_child(lineNode)
	
	var lineNode = sectorNode.get_node("linenode " + String(lineIndex))
	
	
	
	var diff = (end-start).normalized()
	start -= diff*0.00001
	end += diff*0.00001
	
	
	if get_parent().mergeMesh != get_parent().MERGE.DISABLED and !isDynamic:# and textureName != "F_SKY1" :
		if !preInstancedMeshes.has(sectorIdxPre):
			preInstancedMeshes[sectorIdxPre] = []
		 
		var colMask = 1
		
		if shootThrough: colMask = 0
		if textureName == "F_SKY1": colMask = 0
		preInstancedMeshes[sectorIdxPre].append({"start":start,"end":end,"floorZ":floorZ,"ceilZ":ceilZ,"fCeil":fCeil,"uvType":uvType,"textureOffset":textureOffset,"sideIndex":sideIndex,"textureName":textureName,"texture":texture,"lineNode":lineNode,"sector":sector,"sectorNode":sectorNode,"colMask":colMask})
		preInstancedMeshes[sectorIdxPre].append({"start":start,"end":end,"floorZ":floorZ,"ceilZ":ceilZ,"fCeil":fCeil,"uvType":uvType,"textureOffset":textureOffset,"sideIndex":sideIndex,"textureName":textureName,"texture":texture,"lineNode":lineNode,"sector":sector,"sectorNode":sectorNode,"colMask":colMask})
		return
	
	

	
	var mesh = makeSideMesh(start,end,floorZ,ceilZ,fCeil,texture,uvType,textureOffset,sideIndex,sector,textureName,sType)
	mesh.create_trimesh_collision()
	#mesh.create_convex_collision()
	
	
	if hasCollision == false:
		mesh.get_child(0).collision_mask = 0
		mesh.get_child(0).collision_layer = 0
	
	if shootThrough or textureName == "F_SKY1":
		mesh.get_child(0).collision_layer = 0
	
	
	if isDynamic:# and false:
		var colShape = mesh.get_child(0).get_child(0)
		var staticCol = mesh.get_child(0)

		mesh.name = "sidedef " + sideIndex
		mesh.set_meta("type",nameStr)

		lineNode.add_child(mesh)
		sideNodePath[sideIndex] = mesh
		
	else:
		mesh.name = "sidedef " + sideIndex
		mesh.set_meta("type",nameStr)
		lineNode.add_child(mesh)
	
	
	if isDynamic:
		sideNodePath[sideIndex] = mesh
	
	if textureName != "F_SKY":
		mesh.cast_shadow = MeshInstance.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		mesh.use_in_baked_light = true
	



func createInteractables(sectorToInteraction,mapDict):
	
	for secIndex in sectorToInteraction.keys():#for every sector#

		var sectorInteraction = {}
		
		for i in sectorToInteraction[secIndex]:
			if !sectorInteraction.has(i["type"]):
				sectorInteraction[i["type"]] = []
			
			sectorInteraction[i["type"]].append(i)
		
		sectorToInteraction[secIndex].sort_custom(interactionSectorSort,"sort_asc")
		var originSectorIdx
		var animMeshPath = []
		for type in sectorInteraction.keys():
			var lineType
			var triggerNodes = []
			
			for i in sectorInteraction[type]:#for every line that belongs to the target sectro
				
				lineType = i["type"]#we assumne every linetype is the same
				var line = i["line"]
				
				originSectorIdx = line["frontSector"]
				var pathPost = "Geometry/sector " +String(originSectorIdx) + "/linenode " + String(line["index"])
				var path = "../../../" + pathPost
				
				var frontSideDefIndex = mapDict["SIDEDEFS"][line["frontSideDef"]]
				if isSideAnimatedSwitch(frontSideDefIndex):
					if mapNode.get_node_or_null(pathPost)!= null:
						for c in mapNode.get_node(pathPost).get_children():
							animMeshPath.append(path + "/" + c.name)
				
				
				
				if lineType == -2:
					continue
					
				var category = typeDict[lineType]["type"]
				if category == LTYPE.SCROLL:
					continue
				
				var interactionAreaNode
				
				
				if typeDict[lineType].has("trigger"):
					
					if typeDict[lineType]["type"] == LTYPE.TELEPORT:
						interactionAreaNode = createInteractionAreaNode(line,Vector3(1,1,1))
						interactionAreaNode.set_meta("lineStart",verts[line["startVert"]])
						interactionAreaNode.set_meta("lineEnd",verts[line["endVert"]])
					
					elif typeDict[lineType]["trigger"] == TTYPE.SWITCH1 or typeDict[lineType]["trigger"] == TTYPE.SWITCHR:
						interactionAreaNode = createInteractionAreaNode(line,Vector3(1,1,20))
					else:
						interactionAreaNode = createInteractionAreaNode(line,Vector3(0,0,10))
				
				else:
					interactionAreaNode = createInteractionAreaNode(line,Vector3(0,0,10))
				
				if i.has("npcTrigger"):
					interactionAreaNode.set_meta("npcTrigger",i["npcTrigger"])
				
				if i["line"].has("sectorTag"):
					interactionAreaNode.set_meta("sectorTag",i["line"]["sectorTag"])#for teleports the destination sector is set as a sector tag
				
				interactionAreaNode.set_meta("sectorIdx",sectors[secIndex])
				
				if line["frontSector"] != null:
					var sector = sectors[line["frontSector"]]
					interactionAreaNode.set_meta("fTextureName",sector["floorTexture"])#some types need to know the floor texture the line is facing
				
				triggerNodes.append(interactionAreaNode)

			if lineType > 256 :
				continue
				
			if lineType == -2:
				continue
			
			
			var typeInfo = typeDict[lineType]
			var category = typeDict[lineType]["type"]
			
			if geomNode.get_node_or_null("sector " + String(secIndex)) == null:
				#print("interaction sector " + String(secIndex)," not found")
				continue
			
			var sectorNode = geomNode.get_node("sector " + String(secIndex))
			
			
			var ceilings = []
			var floorings = []
			
			var allSectorSides   = mapDict["sectorToSides"][secIndex]
			var sectorFrontSides = mapDict["sectorToFrontSides"][secIndex]
			var sectorBackSides  = mapDict["sectorToBackSides"][secIndex]
			
			var sector = sectors[secIndex]
			
			
			var frontSidesNodes  = getSideNodePaths(secIndex,sectorFrontSides)
			var backSideLinedefNodes  = getSideNodePaths(secIndex,sectorBackSides)
			var backSideSideDefNodes = []
			for c in backSideLinedefNodes:
				backSideSideDefNodes.append(c)
			
			for c in sectorNode.get_children():
				var path = "Geometry/" + c.get_parent().name + "/" + c.name
				
				if c.has_meta("floor"): 
					floorings.append(path)
					
				elif c.has_meta("ceil"): 
					makeAreaForCeilFloor(c)
					ceilings.append("Geometry/" + c.get_parent().name + "/" + c.name)
			
				
			
			var mid =  sectors[secIndex]["center"]
			
			mid.y = sectors[secIndex]["ceilingHeight"] - sectors[secIndex]["floorHeight"]

			var script
			var sectorGroup = []
			
			
			
			var node = Spatial.new()
			
			
			if typeDict[lineType]["trigger"] == WADG.TTYPE.SWITCH1 or typeDict[lineType]["trigger"] == WADG.TTYPE.SWITCHR:#buttom press sound
				var buttonSound = createAudioPlayback("DSSWTCHN")
				buttonSound.name="buttonSound"
				
				if node.has_node("trigger"):
					node.get_node("trigger").add_child(buttonSound)
				else:
					node.add_child(buttonSound)
			
			if category == LTYPE.DOOR: 
				sectorGroup = {"targets":backSideSideDefNodes+ceilings,"sectorInfo":sector}

				var open = createAudioPlayback("DSDOROPN")

				open.name="openSound"
				
				
				var close = createAudioPlayback("DSDORCLS")
				close.name="closeSound"
				node.add_child(open)
				node.add_child(close)
				script = load("res://addons/godotWad/src/interactables/door.gd")
				
			
			if category == LTYPE.CEILING:
				sectorGroup = {"targets":backSideSideDefNodes+ceilings,"sectorInfo":sector}
				script = load("res://addons/godotWad/src/interactables/ceiling.gd")
				
			if category == LTYPE.CRUSHER:
				sectorGroup = {"targets":backSideSideDefNodes+ceilings,"sectorInfo":sector}
				script = load("res://addons/godotWad/src/interactables/crusher.gd")
				
			
			if category == LTYPE.FLOOR: 
				var start : AudioStreamPlayer3D= createAudioPlayback("DSSTNMOV")
				
				start.name="openSound"
				var stop = createAudioPlayback("DSBDCLS")
				stop.name="closeSound"
				node.add_child(start)
				node.add_child(stop)
				
				sectorGroup = ({"targets":backSideSideDefNodes+floorings,"sectorInfo":sector})
				script = load("res://addons/godotWad/src/interactables/floor.gd")
			
			if category == LTYPE.LIFT: 
				sectorGroup = ({"targets":backSideSideDefNodes+floorings,"sectorInfo":sector})
				
				var start = createAudioPlayback("DSPSTART")
				start.name="startSound"
				var stop = createAudioPlayback("DSPSTOP")
				stop.name="stopSound"
				node.add_child(start)
				node.add_child(stop)
				script = load("res://addons/godotWad/src/interactables/lift.gd")
			
			if category == LTYPE.TELEPORT:
				var teleportSound = createAudioPlayback("DSTELEPT")
				teleportSound.name="sound"
				node.add_child(teleportSound)
				script = load("res://addons/godotWad/src/interactables/teleport.gd")
			
			if category == LTYPE.STOPPER:
				script = load("res://addons/godotWad/src/interactables/stopper.gd")
				pass
				
			
			if category == LTYPE.EXIT:
				script =load("res://addons/godotWad/src/interactables/levelChange.gd")
			
			if category == LTYPE.STAIR:
				
				script = load("res://addons/godotWad/src/interactables/stairs.gd")
				var targetStairs = []
				var stairSectorDict = mapDict["stairLookup"][secIndex]

				for stairSectorIdx in stairSectorDict.keys():
					
					
					sectorBackSides  = mapDict["sectorToBackSides"][stairSectorIdx]
					backSideLinedefNodes  = getSideNodePaths(stairSectorIdx,sectorBackSides)
					sectorNode = geomNode.get_node("sector " + String(stairSectorIdx))
					var sectorFloor
					var sectorCeiling
					sector = sectors[stairSectorIdx]
					

					var sidesForStair = sectorBackSides
					var sidePath = null

					for c in sectorNode.get_children():
						if c.has_meta("floor"): 
							sectorFloor = [("Geometry/" + c.get_parent().name + "/" + c.name)]
						elif c.has_meta("ceil"): 
							sectorCeiling = [("Geometry/" + c.get_parent().name + "/" + c.name)]
					

					if sectorFloor == null: continue
						
					targetStairs.append({"targets":sectorFloor+backSideLinedefNodes,"sectorInfo":sector})
				sectorGroup = targetStairs

			node.set_script(script)

			if "info" in node :node.info = sectorGroup
			if "type" in node: node.type = lineType
			if "triggerType" in node: node.triggerType = typeInfo["trigger"]
			if "dir" in node: node.dir = typeInfo["direction"]
			if "inc" in node: node.inc  = typeInfo["inc"]
			if "dest" in node: node.dest = typeInfo["dest"]
			if "animMeshPath" in node: node.animMeshPath = animMeshPath
			#if "npcType" in node: 
			#	breakpoint
			if "category" in node: node.category = typeInfo["type"]
			if floorings.size()!= 0:
				if "floorPath" in node:node.floorPath = floorings[0]
			if typeInfo.has("wait") and "waitClose" in node: node.waitClose = typeInfo["wait"]
			
			if typeInfo.has("changeTexture"):
				if "textureChange" in node:
					node.textureChange = true
			

			node.name = typeDict[lineType]["str"]
			#node.translation = mid
			
			var sectorInteractionParent 
			var sectorNodeName = "Sector "+String(secIndex)
			
			
			var t = null
			
			if mapNode.get_node("Interactables").has_node(sectorNodeName):
				t = mapNode.get_node("Interactables").get_node(sectorNodeName)
			
			if t==null:
				sectorInteractionParent = Spatial.new()
				sectorInteractionParent.translation = mid
				sectorInteractionParent.name = sectorNodeName
				sectorInteractionParent.set_meta("owner",false)
				mapNode.get_node("Interactables").add_child(sectorInteractionParent)
			else:
				sectorInteractionParent = mapNode.get_node("Interactables").get_node(sectorNodeName)
			
			for i in triggerNodes:
				node.add_child(i)
				i.owner = node
				i.translation -= mid
				if i.has_meta("npcTrigger"):
					i.set_script(load("res://addons/godotWad/src/interactables/npcTrigger.gd"))
					i.add_to_group("counter_"+i.get_meta("npcTrigger"),true)
				elif category == LTYPE.TELEPORT: i.set_script(load("res://addons/godotWad/src/interactables/teleportTrigger.gd"))
				elif category == LTYPE.FLOOR: i.set_script(load("res://addons/godotWad/src/interactables/floorTrigger.gd"))
			
				
			sectorInteractionParent.add_child(node)




func getSideNodePaths(sector,sideIdxArr):
	var sideNodes = []
	
	for idx in sideIdxArr:
		if sideNodePath.has(String(idx)):
			var node = sideNodePath[String(idx)]#get mesh node for sideIdx
			var p = node.get_parent()
			var path
			
			
			if p.get_class() == "KinematicBody":#a kinemtatic body with mesh as child
				path = "Geometry/" + p.get_parent().get_parent().name + "/" + p.get_parent().name + "/" + p.name
			else:#a mesh with a static body as child
				path = ("Geometry/" + node.get_parent().get_parent().name + "/" + node.get_parent().name)
			#path = Gerometry/sector/linenode
			
			var lineNode = mapNode.get_node(path)
			if lineNode == null:
				continue
			for c in lineNode.get_children():
				var sidePath = path + "/" + c.name
				sideNodes.append(sidePath)

	return sideNodes
	
func createAudioPlayback(soundName):
	

	var audioStream =  $"../ResourceManager".fetchSound(soundName)
	var audioPlay = AudioStreamPlayer3D.new()

	audioPlay.stream = audioStream
	
	return audioPlay
	



func createInteractionAreaNode(line,growMargin= Vector3(1,1,5),nameStr ="interactionBox"):
	var areaNode = Area.new()
	var collisionNode = CollisionShape.new()
	var shapeNode = BoxShape.new()
	
	var startVert  = verts[line["startVert"]]
	var endVert = verts[line["endVert"]]
	var length =  endVert-startVert
	var sector = sectors[line["frontSector"]]
	var height = sector["ceilingHeight"] - sector["floorHeight"]
	

	
	var dim = Vector3(length.length()/2.0,height/2,1)
	var angle = length.angle_to(Vector2.UP) + deg2rad(90)
	var normal = Vector3(cos(angle - deg2rad(90)),0, sin(angle- deg2rad(90)))
	
	
	dim = Vector3(abs(dim.x),abs(dim.y),abs(dim.z))
	dim += Vector3(1,1,1)*growMargin#box will be x units larger than object in all dimensions
	
	
	var origin = Vector3(startVert.x+length.x/2,sector["floorHeight"]+height/2,startVert.y+length.y/2)
	#origin -= normal#*Vector3(di.x,0,dim.z) #- Vector3(0,0,growMargin)
	#areaNode.translation.z -= growMargin.z/2.0
	areaNode.rotation.y = angle
	areaNode.translation = origin
	
	shapeNode.extents = dim
	collisionNode.shape = shapeNode
	areaNode.add_child(collisionNode)
	areaNode.name = nameStr
	areaNode.name = "trigger"
	return areaNode


func createSurroundingSkybox(dim,minDim):
	var meshInstance = MeshInstance.new()
	var cubeMesh = CubeMesh.new()
	cubeMesh.size = dim+Vector3(20,20,20)#add a small buffer to prevent z-fighing
	cubeMesh.flip_faces = true
	meshInstance.mesh = cubeMesh 
	meshInstance.translation = minDim + (dim/2)
	
	cubeMesh.material = $"../ResourceManager".fetchSkyMat()
	meshInstance.name = "Surrounding Skybox"
	mapNode.add_child(meshInstance)
	meshInstance.set_owner(mapNode)

		
	

func getStairSectors(mapDict,frontSides,sectorIdx):
	var stairSectors = [sectorIdx]
	var nextSector = getNextStairSector(frontSides,stairSectors)
	
	while nextSector != null:
		stairSectors.append(nextSector)
		frontSides = mapDict["sectorToFrontSides"][nextSector]
		nextSector = getNextStairSector(frontSides,stairSectors)
		
	return stairSectors
	

func getNextStairSector(frontSides,curStairs):
	for sideIdx in frontSides:
		var side = sides[sideIdx]
		if side["backSector"] != null: 
			if !curStairs.has(side["backSector"]):
				return side["backSector"]
			
	return null

func recursiveOwn(node,newOwner):
	for i in node.get_children():
		recursiveOwn(i,newOwner)
	
	node.owner = newOwner

func makeFloorKinematic(flr):
	
	var flrParent = flr.get_parent()
	var colNode = flr.get_child(0)
	flr.get_parent().remove_child(flr)
	#flr.remove_child(colNode)
	var floorKine = KinematicBody.new()
	
	flrParent.add_child(floorKine)
	floorKine.add_child(flr)
	
	
func makeAreaForCeilFloor(cf):
	return
	var colNode = cf.get_child(0).duplicate()
	var shapeNode = colNode.get_child(0)
	
	var area = Area.new()
	area.translation.y -= 1
	colNode.remove_child(shapeNode)
	area.add_child(shapeNode)
	colNode.queue_free()
	area.name = "area"
	cf.add_child(area)
	
	

func isSideAnimatedSwitch(side):
	if $"../ImageBuilder".switchTextures.has(side["lowerName"]): return true
	if $"../ImageBuilder".switchTextures.has(side["middleName"]): return true
	if $"../ImageBuilder".switchTextures.has(side["upperName"]): return true
	return false
