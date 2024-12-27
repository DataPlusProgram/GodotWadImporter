extends LineEdit

signal keySet
signal incorrectDeviceUsed 

enum KEYTYPE {
	KEYBOARD,
	MOUSE,
	GAMEPAD,
	GAMEPAD_MOTION,
	ALL,
	PC
}


@export var action = "ui_up" : set = actionSet
@export var limitMode = KEYTYPE.ALL
@export var allowMultibinds : bool  = false
@export var disallowM1 : bool = false
@onready var prompt = get_node_or_null("../../../../../../prompt")


var ignoreNextFocus = false
var targetDeviceId = 0 : set = deviceIdSet
var valueStr = ""
var curKeytype = KEYTYPE.KEYBOARD
var code = null
var analogCode = 0

func _ready():
	$ControllerTextureRect.texture = $ControllerTextureRect.texture.duplicate()
	$ControllerTextureRect.texture.path = action
	curKeytype = limitMode
	

	updateIcon()
	
	if InputMap.has_action(action):#if input already exists show it as text
		if InputMap.action_get_events(action).size() > 0:
			
			
			
			var event = InputMap.action_get_events(action)[0]
			
			if event is InputEventMouseButton and !disallowM1:
				#text = "MOUSE" + str(event.button_index)
				valueStr =  "MOUSE" + str(event.button_index)
				
			else:
				#text = event.as_text()
				valueStr = event.as_text()
			


func _input(event):

	if !has_focus():
		return
	
	if ignoreNextFocus:
		release_focus()
		ignoreNextFocus = false
		return
	
	if event is InputEventMouseMotion:
		return
	
	
	if event is InputEventKey:
		if limitMode != KEYTYPE.KEYBOARD and limitMode != KEYTYPE.ALL and limitMode != KEYTYPE.PC:
			return
		
		if event.keycode == KEY_ESCAPE:
			release_focus()
			return
		
		curKeytype = KEYTYPE.KEYBOARD
		
		valueStr = getKeyString(event.keycode)
		
		Input.flush_buffered_events()

		replaceActionScanCode(action,event.keycode)
		
		
		release_focus()
		
	if event is InputEventMouseButton:
		if !event.pressed:
			return
		
		if  limitMode != KEYTYPE.MOUSE and limitMode != KEYTYPE.ALL and limitMode != KEYTYPE.PC:
			return
		
		
		
		curKeytype = KEYTYPE.MOUSE
		valueStr = getKeyString(event.button_index)
		
		if valueStr == "MOUSE1" :
			#if ignoreNextFocus == true:
			#	ignoreNextFocus = false
			#	return
			#else:
			ignoreNextFocus = true
				
		
		
		if valueStr.find("MOUSE") != -1 and disallowM1:
			return
			
			
		
	
	
		replaceActionScanCode(action,event.button_index)
		release_focus()
		updateIcon()
		return
	
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event.device != targetDeviceId:
			emit_signal("incorrectDeviceUsed",event.device)
	
	if event is InputEventJoypadButton:
		
		
		if limitMode != KEYTYPE.GAMEPAD and limitMode != KEYTYPE.ALL:
			return
		
		curKeytype = KEYTYPE.GAMEPAD
		valueStr = getKeyString(event.button_index)
		replaceActionScanCode(action,event.button_index)
		release_focus()
	
	if event is InputEventJoypadMotion:
		
		if limitMode != KEYTYPE.GAMEPAD and limitMode != KEYTYPE.ALL and limitMode != KEYTYPE.GAMEPAD_MOTION:
			return
		
		if abs(event.axis_value) >= 0.35:
			curKeytype = KEYTYPE.GAMEPAD_MOTION
			valueStr = getKeyString(event.axis,event.axis_value)
			replaceActionScanCode(action,event.axis,event.axis_value)
			release_focus()
	
	
	$ControllerTextureRect.texture.path = action
	updateIcon()
		
		


func replaceActionScanCode(actionName : StringName,scanCode : int,analogValue = 0,dontEraseSameKeybinds = false):

	code = scanCode
	analogCode = analogValue
	
	if !allowMultibinds and !dontEraseSameKeybinds:
		#if actionName ==  "menuSelect":
		#	breakpoint
		removeActionTiedToKey(scanCode)
		eraseActionScanCodes(actionName)
	setActionToScancode(actionName,scanCode,analogValue)
	

func removeActionTiedToKey(scanCode):
	for action in InputMap.get_actions():
		for event in InputMap.action_get_events(action):
			if curKeytype == KEYTYPE.MOUSE:
				if !event is InputEventMouseButton:
					continue
				
				
				if event.button_index  == scanCode:
					InputMap.action_erase_event(action,event)
			
			if curKeytype == KEYTYPE.KEYBOARD:
				if !event is InputEventKey:
					continue
				
				if scanCode == event.keycode:
					InputMap.action_erase_event(action,event)
			
			elif curKeytype == KEYTYPE.GAMEPAD:
				if !event is InputEventJoypadButton:
					continue
					
				if scanCode == event.button_index:
					InputMap.action_erase_event(action,event)
					
			

func eraseActionScanCodes(actionName,target = null):
	
	
	
	var t = InputMap.get_actions()
	
	if InputMap.has_action(action):
		if InputMap.action_get_events(action).size() > 0:
			#if target == null:
			#	InputMap.action_erase_events(action)
			#	return
			
			
			for event in InputMap.action_get_events(action):
				if event is InputEventKey or event is InputEventMouseButton:
					if !limitMode == KEYTYPE.GAMEPAD and !limitMode == KEYTYPE.GAMEPAD_MOTION:
						InputMap.action_erase_event(action,event)
					
				elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
					if !limitMode == KEYTYPE.KEYBOARD and !limitMode == KEYTYPE.MOUSE:
						InputMap.action_erase_event(action,event)
				else:
					pass
				

func setActionToScancode(actionName,keyCode,analogValue):
	
	
	var keyStr = getKeyString(keyCode)# OS.get_keycode_string(keyCode)#keyCode.as_text()
	var e
	
	if keyStr.find("MOUSE") != -1 and (limitMode == KEYTYPE.PC or limitMode == KEYTYPE.ALL):
		e = InputEventMouseButton.new()
		e.button_index = keyCode
		
	
	elif keyStr.find("GAMEPAD")  != -1 and (limitMode == KEYTYPE.GAMEPAD or limitMode == KEYTYPE.ALL):
		e = InputEventJoypadButton.new()
		e.button_index = keyCode
		e.device = targetDeviceId
	
	elif keyStr.find("AXIS") != -1 and (limitMode == KEYTYPE.GAMEPAD_MOTION  or limitMode == KEYTYPE.ALL):
		e = InputEventJoypadMotion.new()
		e.axis = keyCode
		e.device = targetDeviceId
		if analogValue >= 0:
			e.axis_value = 1.0
		elif analogValue < 0:
			e.axis_value = -1.0
	
	else: #limitMode == KEYTYPE.KEYBOARD and (limitMode == KEYTYPE.PC or limitMode == KEYTYPE.ALL):
		e = InputEventKey.new()
		e.keycode = keyCode
		
	

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
	if curKeytype == KEYTYPE.KEYBOARD or curKeytype == KEYTYPE.PC:

		return OS.get_keycode_string(code)
	elif curKeytype == KEYTYPE.MOUSE or curKeytype == KEYTYPE.PC:
		return "MOUSE" + str(code)
	elif curKeytype == KEYTYPE.GAMEPAD:
		return "GAMEPAD" + str(code)
	elif curKeytype == KEYTYPE.GAMEPAD_MOTION:
		if value >= 0 :
			return "AXIS" + str(code) + "-"
		if value <0:
			return "AXIS" + str(code) + "+"
			
	
	breakpoint

func updateIcon():
	
	
	if limitMode == KEYTYPE.PC:
		$ControllerTextureRect.texture.force_type = 1
	elif curKeytype == KEYTYPE.KEYBOARD or curKeytype==KEYTYPE.MOUSE:
		$ControllerTextureRect.texture.force_type = 1
	elif  curKeytype == KEYTYPE.GAMEPAD  or  curKeytype == KEYTYPE.GAMEPAD_MOTION:
		$ControllerTextureRect.texture.force_type = 2
	
	$ControllerTextureRect.texture.path = action
	
	
func _physics_process(delta):

	if $ControllerTextureRect.texture != null:
		text = ""
	else:
		text = valueStr
		

	custom_minimum_size.y = $ControllerTextureRect.size.y



func _on_mouse_entered():
	self_modulate = Color(2.0,2.0,2.0)


func _on_mouse_exited():
	self_modulate = Color(1.0,1.0,1.0)


func _on_focus_entered():
	if prompt != null:
		prompt.visible = true

func deviceIdSet(deviceIdx):
	
	if code == null:
		return
	
	targetDeviceId = deviceIdx
	replaceActionScanCode(action,code,analogCode)

func actionSet(act):
	action = act
	$ControllerTextureRect.texture.path = action
