extends Control


onready var keyboardBindings = get_node("%keyboardBindings")
onready var controllerBindings = get_node("%controllerBindings")

export var inputParamStr = "res://addons/godotWad/scenes/gameModes/main/options/inputParam.tres"

var inputParam = null

var limitMode = KEYTYPE.KEYBOARD

enum KEYTYPE {
	KEYBOARD,
	MOUSE,
	GAMEPAD,
	GAMEPAD_MOTION,
	ALL
}




func _ready():
	inputParam = load(inputParamStr)
	var dict = inputParam.getAsDict()
	
	
	for i in dict.keys():
		

		
		if !dict[i].has("controllerOnly"):
			if dict[i].has("key"):
				if dict[i]["key"].find("MOUSE") != -1:
					createForAction(i,dict[i]["key"],keyboardBindings,KEYTYPE.MOUSE)
				else:
					createForAction(i,dict[i]["key"],keyboardBindings,KEYTYPE.KEYBOARD)
			else:
				createForAction(i,null,keyboardBindings,KEYTYPE.KEYBOARD)
		
		if dict[i].has("controller"):
			var key = dict[i]["controller"]
			createForAction(i,dict[i]["controller"],controllerBindings,KEYTYPE.GAMEPAD)
		else:
			createForAction(i,null,controllerBindings,KEYTYPE.GAMEPAD)
	
	
	

func createForAction(actionName,boundKey,parent,lMode):
	var label = Label.new()
	label.text = actionName
	parent.add_child(label)
	
	var inputBox : Control = load("res://addons/godotWad/scenes/gameModes/main/options/inputSelector.tscn").instance()
	inputBox.action = actionName
	inputBox.size_flags_horizontal = SIZE_EXPAND_FILL
	
	
	
	if lMode != KEYTYPE.ALL:
		inputBox.curKeytype = lMode
	
	var value = $"%inputEnums".getCodeForString(boundKey,lMode)
	
	if value != null:
		if value.has("isAxis"):
			lMode = KEYTYPE.GAMEPAD_MOTION
	else:
		inputBox.text = ""
		
	inputBox.limitMode = lMode
	
	parent.add_child(inputBox)
	if value !=null:
		inputBox.text = inputBox.getKeyString(value["keycode"],value["value"])
		inputBox.replaceActionScanCode(actionName, value["keycode"],value["value"])
	else:
		
		inputBox.text = ""

	
	inputBox.connect("keySet",self,"inputSet")
	
	
func inputSet(input,caller):
	for i in keyboardBindings.get_children():
		if i == caller:
			continue
				
		if i.text == input:
			i.text = ""
			
	
	for i in controllerBindings.get_children():
		if i == caller:
			continue
				
		if i.text == input:
			i.text = ""


func _on_deviceSelect_item_selected(index):
	var txt = $"%deviceSelect".get_item_text(index)
	
	if txt == "Controller":
		controllerBindings.visible = true
		keyboardBindings.visible = false
	#	limitMode = KEYTYPE.GAMEPAD
	
	if txt == "Keyboard":
		controllerBindings.visible = false
		keyboardBindings.visible = true

		


func _on_restorDefault_pressed():
	for i in $"%keyboardBindings".get_children():
		i.queue_free()
		
	for i in $"%controllerBindings".get_children():
		i.queue_free()
	
	_ready()
