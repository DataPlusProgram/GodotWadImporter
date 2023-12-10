extends LineEdit

signal keySet

enum KEYTYPE {
	KEYBOARD,
	MOUSE,
	GAMEPAD,
	GAMEPAD_MOTION,
	ALL
}


export var action = "ui_up"
export var limitMode = KEYTYPE.ALL
var curKeytype = KEYTYPE.KEYBOARD


func _ready():
	
	
	curKeytype = limitMode
	
	
	if InputMap.has_action(action):#if input already exists show it as text
		if InputMap.get_action_list(action).size() > 0:
			
			var event = InputMap.get_action_list(action)[0]
			
			if event is InputEventMouseButton:
				text = "MOUSE" + str(event.button_index)
			else:
				text = event.as_text()
			


func _input(event):

	
	if !has_focus():
		return
	
	if event is InputEventMouseMotion:
		return
	
	
	if event is InputEventKey:
		if limitMode != KEYTYPE.KEYBOARD and limitMode != KEYTYPE.ALL:
			return
		
		
		#if event.scancode == KEY_ESCAPE:
		#	release_focus()
		#	return
		
		curKeytype = KEYTYPE.KEYBOARD
		
		text = getKeyString(event.scancode)
		
		
		replaceActionScanCode(action,event.scancode)
		release_focus()
		
	if event is InputEventMouseButton:
		if !event.pressed:
			return
		
		if limitMode != KEYTYPE.KEYBOARD and limitMode != KEYTYPE.MOUSE and limitMode != KEYTYPE.ALL:
			return
		
		
		
		curKeytype = KEYTYPE.MOUSE
		text = getKeyString(event.button_index)
		
		replaceActionScanCode(action,event.button_index)
		release_focus()
		return
		
	if event is InputEventJoypadButton:
		
		if limitMode != KEYTYPE.GAMEPAD and limitMode != KEYTYPE.ALL:
			return
		
		curKeytype = KEYTYPE.GAMEPAD
		text = getKeyString(event.button_index)
		replaceActionScanCode(action,event.button_index)
		release_focus()
	
	if event is InputEventJoypadMotion:
		
		if limitMode != KEYTYPE.GAMEPAD and limitMode != KEYTYPE.ALL and limitMode != KEYTYPE.GAMEPAD_MOTION:
			return
		
		if abs(event.axis_value) >= 0.35:
			curKeytype = KEYTYPE.GAMEPAD_MOTION
			text = getKeyString(event.axis,event.axis_value)
			replaceActionScanCode(action,event.axis,event.axis_value)
			release_focus()

		
		


func replaceActionScanCode(actionName,scanCode,value = 0):
	eraseActionScanCodes(actionName)
	setActionToScancode(actionName,scanCode,value)
	

func eraseActionScanCodes(actionName,target = null):
	
	var t = InputMap.get_actions()
	
	if InputMap.has_action(action):
		if InputMap.get_action_list(action).size() > 0:
			#if target == null:
			#	InputMap.action_erase_events(action)
			#	return
			
			
			for event in InputMap.get_action_list(action):
				if event is InputEventKey or event is InputEventMouseButton:
					if !limitMode == KEYTYPE.GAMEPAD and !limitMode == KEYTYPE.GAMEPAD_MOTION:
						InputMap.action_erase_event(action,event)
					
				elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
					if !limitMode == KEYTYPE.KEYBOARD and !limitMode == KEYTYPE.MOUSE:
						InputMap.action_erase_event(action,event)
				else:
					pass
				

func setActionToScancode(actionName,keyCode,value):
	
	
	var keyStr = getKeyString(keyCode)# OS.get_scancode_string(keyCode)#keyCode.as_text()
	
	var e
	
	if limitMode == KEYTYPE.KEYBOARD:
		e = InputEventKey.new()
		e.scancode = keyCode
		
	if limitMode == KEYTYPE.MOUSE:
		e = InputEventMouseButton.new()
		e.button_index = keyCode
	
	if limitMode == KEYTYPE.GAMEPAD:
		e = InputEventJoypadButton.new()
		e.button_index = keyCode
	
	if limitMode == KEYTYPE.GAMEPAD_MOTION:
		e = InputEventJoypadMotion.new()
		e.axis = keyCode
		if value >= 0:
			e.axis_value = 1.0
		elif value < 0:
			e.axis_value = -1.0
		
	if !InputMap.has_action(actionName):
		InputMap.add_action(actionName)
	
	if limitMode == KEYTYPE.GAMEPAD_MOTION:
		InputMap.action_set_deadzone(actionName,0.2)
	
	InputMap.action_add_event(actionName,e)
	
	emit_signal("keySet",keyStr,self)
	
	
	
func _on_inputSelector_text_changed(txt):
	if has_focus():
		release_focus()
	
	


func _on_inputSelector_text_change_rejected(reject):
	text = reject
	
	if has_focus():
		release_focus()


func getKeyString(code,value = 0):
	if curKeytype == KEYTYPE.KEYBOARD:
		return OS.get_scancode_string(code)
	elif curKeytype == KEYTYPE.MOUSE:
		return "MOUSE" + str(code)
	elif curKeytype == KEYTYPE.GAMEPAD:
		return "GAMEPAD" + str(code)
	elif curKeytype == KEYTYPE.GAMEPAD_MOTION:
		if value >= 0 :
			return "AXIS" + str(code) + "-"
		if value <0:
			return "AXIS" + str(code) + "+"
