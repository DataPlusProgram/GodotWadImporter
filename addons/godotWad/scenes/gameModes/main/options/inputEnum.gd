extends Node

enum KEYTYPE {
	KEYBOARD,
	MOUSE,
	GAMEPAD,
	GAMEPAD_MOTION,
	ALL
}

var scancodeDict = {
	"KEY_NONE": 0,
	"KEY_SPECIAL": 4194304,
	"KEY_ESCAPE": 4194305,
	"KEY_TAB": 4194306,
	"KEY_BACKTAB": 4194307,
	"KEY_BACKSPACE": 4194308,
	"KEY_ENTER": 4194309,
	"KEY_KP_ENTER": 4194310,
	"KEY_INSERT": 4194311,
	"KEY_DELETE": 4194312,
	"KEY_PAUSE": 4194313,
	"KEY_PRINT": 4194314,
	"KEY_SYSREQ": 4194315,
	"KEY_CLEAR": 4194316,
	"KEY_HOME": 4194317,
	"KEY_END": 4194318,
	"KEY_LEFT": 4194319,
	"KEY_UP": 4194320,
	"KEY_RIGHT": 4194321,
	"KEY_DOWN": 4194322,
	"KEY_PAGEUP": 4194323,
	"KEY_PAGEDOWN": 4194324,
	"KEY_SHIFT": 4194325,
	"KEY_CTRL": 4194326,
	"KEY_META": 4194327,
	"KEY_ALT": 4194328,
	"KEY_CAPSLOCK": 4194329,
	"KEY_NUMLOCK": 4194330,
	"KEY_SCROLLLOCK": 4194331,
	"KEY_F1": 4194332,
	"KEY_F2": 4194333,
	"KEY_F3": 4194334,
	"KEY_F4": 4194335,
	"KEY_F5": 4194336,
	"KEY_F6": 4194337,
	"KEY_F7": 4194338,
	"KEY_F8": 4194339,
	"KEY_F9": 4194340,
	"KEY_F10": 4194341,
	"KEY_F11": 4194342,
	"KEY_F12": 4194343,
	"KEY_F13": 4194344,
	"KEY_F14": 4194345,
	"KEY_F15": 4194346,
	"KEY_F16": 4194347,
	"KEY_F17": 4194348,
	"KEY_F18": 4194349,
	"KEY_F19": 4194350,
	"KEY_F20": 4194351,
	"KEY_F21": 4194352,
	"KEY_F22": 4194353,
	"KEY_F23": 4194354,
	"KEY_F24": 4194355,
	"KEY_F25": 4194356,
	"KEY_F26": 4194357,
	"KEY_F27": 4194358,
	"KEY_F28": 4194359,
	"KEY_F29": 4194360,
	"KEY_F30": 4194361,
	"KEY_F31": 4194362,
	"KEY_F32": 4194363,
	"KEY_F33": 4194364,
	"KEY_F34": 4194365,
	"KEY_F35": 4194366,
	"KEY_KP_MULTIPLY": 4194433,
	"KEY_KP_DIVIDE": 4194434,
	"KEY_KP_SUBTRACT": 4194435,
	"KEY_KP_PERIOD": 4194436,
	"KEY_KP_ADD": 4194437,
	"KEY_KP_0": 4194438,
	"KEY_KP_1": 4194439,
	"KEY_KP_2": 4194440,
	"KEY_KP_3": 4194441,
	"KEY_KP_4": 4194442,
	"KEY_KP_5": 4194443,
	"KEY_KP_6": 4194444,
	"KEY_KP_7": 4194445,
	"KEY_KP_8": 4194446,
	"KEY_KP_9": 4194447,
	"KEY_MENU": 4194370,
	"KEY_HYPER": 4194371,
	"KEY_HELP": 4194373,
	"KEY_BACK": 4194376,
	"KEY_FORWARD": 4194377,
	"KEY_STOP": 4194378,
	"KEY_REFRESH": 4194379,
	"KEY_VOLUMEDOWN": 4194380,
	"KEY_VOLUMEMUTE": 4194381,
	"KEY_VOLUMEUP": 4194382,
	"KEY_MEDIAPLAY": 4194388,
	"KEY_MEDIASTOP": 4194389,
	"KEY_MEDIAPREVIOUS": 4194390,
	"KEY_MEDIANEXT": 4194391,
	"KEY_MEDIARECORD": 4194392,
	"KEY_HOMEPAGE": 4194393,
	"KEY_FAVORITES": 4194394,
	"KEY_SEARCH": 4194395,
	"KEY_STANDBY": 4194396,
	"KEY_OPENURL": 4194397,
	"KEY_LAUNCHMAIL": 4194398,
	"KEY_LAUNCHMEDIA": 4194399,
	"KEY_LAUNCH0": 4194400,
	"KEY_LAUNCH1": 4194401,
	"KEY_LAUNCH2": 4194402,
	"KEY_LAUNCH3": 4194403,
	"KEY_LAUNCH4": 4194404,
	"KEY_LAUNCH5": 4194405,
	"KEY_LAUNCH6": 4194406,
	"KEY_LAUNCH7": 4194407,
	"KEY_LAUNCH8": 4194408,
	"KEY_LAUNCH9": 4194409,
	"KEY_LAUNCHA": 4194410,
	"KEY_LAUNCHB": 4194411,
	"KEY_LAUNCHC": 4194412,
	"KEY_LAUNCHD": 4194413,
	"KEY_LAUNCHE": 4194414,
	"KEY_LAUNCHF": 4194415,
	"KEY_GLOBE": 4194416,
	"KEY_KEYBOARD": 4194417,
	"KEY_JIS_EISU": 4194418,
	"KEY_JIS_KANA": 4194419,
	"KEY_UNKNOWN": 8388607,
	"KEY_SPACE": 32,
	"KEY_EXCLAM": 33,
	"KEY_QUOTEDBL": 34,
	"KEY_NUMBERSIGN": 35,
	"KEY_DOLLAR": 36,
	"KEY_PERCENT": 37,
	"KEY_AMPERSAND": 38,
	"KEY_APOSTROPHE": 39,
	"KEY_PARENLEFT": 40,
	"KEY_PARENRIGHT": 41,
	"KEY_ASTERISK": 42,
	"KEY_PLUS": 43,
	"KEY_COMMA": 44,
	"KEY_MINUS": 45,
	"KEY_PERIOD": 46,
	"KEY_SLASH": 47,
	"KEY_0": 48,
	"KEY_1": 49,
	"KEY_2": 50,
	"KEY_3": 51,
	"KEY_4": 52,
	"KEY_5": 53,
	"KEY_6": 54,
	"KEY_7": 55,
	"KEY_8": 56,
	"KEY_9": 57,
	"KEY_COLON": 58,
	"KEY_SEMICOLON": 59,
	"KEY_LESS": 60,
	"KEY_EQUAL": 61,
	"KEY_GREATER": 62,
	"KEY_QUESTION": 63,
	"KEY_AT": 64,
	"KEY_A": 65,
	"KEY_B": 66,
	"KEY_C": 67,
	"KEY_D": 68,
	"KEY_E": 69,
	"KEY_F": 70,
	"KEY_G": 71,
	"KEY_H": 72,
	"KEY_I": 73,
	"KEY_J": 74,
	"KEY_K": 75,
	"KEY_L": 76,
	"KEY_M": 77,
	"KEY_N": 78,
	"KEY_O": 79,
	"KEY_P": 80,
	"KEY_Q": 81,
	"KEY_R": 82,
	"KEY_S": 83,
	"KEY_T": 84,
	"KEY_U": 85,
	"KEY_V": 86,
	"KEY_W": 87,
	"KEY_X": 88,
	"KEY_Y": 89,
	"KEY_Z": 90,
	"KEY_BRACKETLEFT": 91,
	"KEY_BACKSLASH": 92,
	"KEY_BRACKETRIGHT": 93,
	"KEY_ASCIICIRCUM": 94,
	"KEY_UNDERSCORE": 95,
	"KEY_QUOTELEFT": 96,
	"KEY_BRACELEFT": 123,
	"KEY_BAR": 124,
	"KEY_BRACERIGHT": 125,
	"KEY_ASCIITILDE": 126,
	"KEY_YEN": 165,
	"KEY_SECTION": 167
}
var mouseButtonDict = {
	"MOUSE_BUTTON_NONE": 0,
	"MOUSE_BUTTON_LEFT": 1,
	"MOUSE_BUTTON_RIGHT": 2,
	"MOUSE_BUTTON_MIDDLE": 3,
	"MOUSE_BUTTON_WHEEL_UP": 4,
	"MOUSE_BUTTON_WHEEL_DOWN": 5,
	"MOUSE_BUTTON_WHEEL_LEFT": 6,
	"MOUSE_BUTTON_WHEEL_RIGHT": 7,
	"MOUSE_BUTTON_XBUTTON1": 8,
	"MOUSE_BUTTON_XBUTTON2": 9,
}

var joyButtonDict = {
	"JOY_BUTTON_INVALID": -1,
	"JOY_BUTTON_A": 0,
	"JOY_BUTTON_B": 1,
	"JOY_BUTTON_X": 2,
	"JOY_BUTTON_Y": 3,
	"JOY_BUTTON_BACK": 4,
	"JOY_BUTTON_GUIDE": 5,
	"JOY_BUTTON_START": 6,
	"JOY_BUTTON_LEFT_STICK": 7,
	"JOY_BUTTON_RIGHT_STICK": 8,
	"JOY_BUTTON_LEFT_SHOULDER": 9,
	"JOY_BUTTON_RIGHT_SHOULDER": 10,
	"JOY_BUTTON_DPAD_UP": 11,
	"JOY_BUTTON_DPAD_DOWN": 12,
	"JOY_BUTTON_DPAD_LEFT": 13,
	"JOY_BUTTON_DPAD_RIGHT": 14,
	"JOY_BUTTON_MISC1": 15,
	"JOY_BUTTON_PADDLE1": 16,
	"JOY_BUTTON_PADDLE2": 17,
	"JOY_BUTTON_PADDLE3": 18,
	"JOY_BUTTON_PADDLE4": 19,
	"JOY_BUTTON_TOUCHPAD": 20,
	"JOY_BUTTON_SDL_MAX": 21,
	"JOY_BUTTON_MAX": 128,
}


func getCodeForString(enumStr,limitMode = KEYTYPE.ALL):
	
	
	
	if enumStr == null:
		return
	
	var retDict = {"keycode":0,"analogValue":0}
	
	if scancodeDict.has(enumStr):
		retDict["keycode"] = scancodeDict[enumStr]
		return retDict
	
	if enumStr.find("JOY_BUTTON") != -1:
		var number = joyButtonDict[enumStr]
		retDict["keycode"] = number
		return retDict
	
	if enumStr.find("GAMEPAD") != -1:
		var number = extractNumber(enumStr,"GAMEPAD")
		retDict["keycode"] = number
		return retDict
	
	elif enumStr.find("AXIS") != -1:
		var postfix  = enumStr.split("AXIS")
		if postfix.size() < 2:
			return 
		postfix = postfix[1]
		return getNumberAndSign(postfix)
	
	elif mouseButtonDict.has(enumStr):
		retDict["keycode"] = mouseButtonDict[enumStr]
		return retDict
		
	elif enumStr.find("MOUSE") != -1:
		var number = extractNumber(enumStr,"MOUSE")
		retDict["keycode"] = number
		return retDict
		
		
	
	
func extractNumber(string,filter):
	var number  = string.split(filter)
	if number.size() < 2:
		return 
		
	if !number[1].is_valid_int():
		return
		
	number = str_to_var(number[1])
	
	return number
	
func getNumberAndSign(string):



	var pattern := RegEx.new()
	pattern.compile("([+-]?\\d+)\\s*([+-])?")
	
	
	var matchi = pattern.search(string)

	if matchi:
		
		var retDict = {"keycode":0,"analogValue":0}
		retDict["isAxis"] = true
		retDict["keycode"] = matchi.get_string(1).to_int()
		var signi : String = matchi.get_string(2) if matchi.get_string(2) else '+'
		
		if signi == "+":
			retDict["analogValue"] = -1.0
		else:
			retDict["analogValue"] = 1.0
			
		return retDict
