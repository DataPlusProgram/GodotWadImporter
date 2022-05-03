class_name WADG
extends Node



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
	ALPHA,
	
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
	NONE,
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


static func getDest(dest,sector):
	if dest == DEST.LOWEST_ADJ_CEILING: 
		return sector["lowestNeighCeilExc"]
	if dest == DEST.NEXT_HIGHEST_FLOOR: 
		return sector["nextHighestFloor"]
		
	if dest == DEST.NEXT_LOWEST_FLOOR: 
		return sector["nextLowestFloor"]
	if dest == DEST.LOWEST_ADJ_FLOOR: 
		return sector["lowestNeighFloorInc"]
	if dest == DEST.up24: 
		return sector["floorHeight"]+24
	if dest == DEST.up32: 
		return sector["floorHeight"]+32
	if dest == DEST.up512: 
		return sector["floorHeight"]+512
	if dest == DEST.LOWEST_ADJ_CEILING_DOWN8: 
		return sector["lowestNeighCeilExc"]-8
	if dest == DEST.up8:
		return sector["floorHeight"]+8
	if dest == DEST.LOWEST_ADJ_CEILING_DOWN8:
		return sector["lowestNeighCeilExc"]-8
	if dest == DEST.NEXT_HIGHEST_FLOOR_up8:
		return sector["nextLowestFloor"]+8
	if dest == DEST.HIGHEST_ADJ_CEILING:
		return sector["highestNeighCeilInc"]
	if dest == DEST.FLOOR:
		return sector["floorHeight"]
	if dest == DEST.HIGHEST_ADJ_FLOOR:
		return sector["highestNeighFloorInc"]
	if dest == DEST.FLOOR_up8:
		return sector["floorHeight"]+8
	

static func getLightLevel(light):
	var lightLevel = max(light-62,0)
	lightLevel = range_lerp(lightLevel,0,255-62,0,15)
	return lightLevel


static func incMap(mapName):
	if mapName[0] == 'E' and mapName[2] == 'M':
		return incrementDoom1Map(mapName)
	
	if mapName.substr(0,3) == "MAP":
		return incrementDoom2Map(mapName)

static func incrementDoom1Map(nameStr):
	var ret = nameStr
	
	var lastDigit = int(nameStr[3])
	if lastDigit < 9:
		lastDigit+= 1
		nameStr[3] = String(lastDigit)
		return(nameStr)
		
	if lastDigit >= 9:
		var firstDigit = int(nameStr[1])
		if firstDigit < 4:
			firstDigit += 1
			ret = "E" + String(firstDigit) + "M1"
		return ret
		
		
static func incrementDoom2Map(nameStr):
	var digitsStr = nameStr[3] + nameStr[4]
	var digits = int(digitsStr)
	digits += 1
	
	if digits < 10:
		digitsStr = "0" + String(digits)
	else:
		digitsStr = String(digits)
	
	return "MAP" + digitsStr
	


