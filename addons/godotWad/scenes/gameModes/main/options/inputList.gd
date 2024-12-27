extends Control


@onready var keyboardBindings = get_node("%keyboardBindings")
@onready var controllerBindings = get_node("%controllerBindings")

@export var inputParamStr := "res://addons/godotWad/scenes/gameModes/main/options/inputParam.tres"

var inputParam = null


var limitMode = KEYTYPE.KEYBOARD
var customFont : FontFile = null
var curGamepadIndex = 0
enum KEYTYPE {
KEYBOARD,
MOUSE,
GAMEPAD,
GAMEPAD_MOTION,
ALL,
PC,
}
 
 


func _ready():
	if get_node_or_null("../../../../") != null:
		if get_node("../../../../").has_signal("restoreDefault"):
			get_node("../../../../").restoreDefault.connect(_on_defaults_button_pressed)
	inputParam = load(inputParamStr)
	%deviceSelector.get_node("OptionButton").item_selected.connect(gamepadChanged)
	setInput()
	

func setInput():
	for i in %keyboardBindings.get_children():
		i.get_parent().remove_child(i)
		i.queue_free()
		
	for i in %controllerBindings.get_children():
		if i.name == "deviceSelector":
			continue
		i.get_parent().remove_child(i)
		i.queue_free()
	
	var dict = inputParam.getAsDict()
	dict = getAsCategory(dict)
	
	for category in dict:
		procCategory(dict,category)



func procCategory(dict,category):
	var label = load("res://addons/godotWad/scenes/player/scenes/resizableText/resizableText.tscn").instantiate()
		
	var hasKeyboardKeys = hasKeyboardBinds(dict[category])
		
		
		
	label.text = "none" if category == "none" else category
	label.scaleFactor = Vector2(0.17,5.5)
	label.custom_minimum_size = Vector2(0.1,9)
	
	if customFont != null:
		label.setFont(customFont)
		
	if hasKeyboardKeys:
		keyboardBindings.add_child(label)
		
	controllerBindings.add_child(label.duplicate())
	
	var ruler = HSeparator.new()
	ruler.custom_minimum_size.y = 60
	if hasKeyboardKeys:
		keyboardBindings.add_child(ruler)
	controllerBindings.add_child(ruler.duplicate())
	
	var gridContainerPC = createGridContainer()
	var gridContainerController = createGridContainer()
		
	if hasKeyboardKeys:
		keyboardBindings.add_child(gridContainerPC)
	controllerBindings.add_child(gridContainerController)
		
	var vSpacer = Control.new()
	vSpacer.custom_minimum_size.y = 20
	if hasKeyboardBinds:
		keyboardBindings.add_child(vSpacer)
	controllerBindings.add_child(vSpacer.duplicate())
	
	var ret
		
	for i in dict[category].keys():
		
		var allowMultiBinds = false
		var customName = null
		var curDict =  dict[category][i]
		var disallowM1 = false
		
		
		
		if curDict.has("disallowM1"):
			disallowM1 = curDict["disallowM1"]
			
		if curDict.has("displayName"):
			customName = curDict["displayName"]
		
		if curDict.has("allowMultipleBinds"):
			if curDict["allowMultipleBinds"] == true:
				allowMultiBinds = true
			
		var hidden = false
			
		if curDict.has("hidden"):
			if curDict["hidden"] == true:
				hidden = true
			
		if ! curDict.has("controllerOnly"):
			if  curDict.has("key"):
				ret =createForAction(i,curDict["key"],gridContainerPC,KEYTYPE.PC,customName,hidden,allowMultiBinds,disallowM1)
				ret[0].get_child(0).texture.force_type = 1
				ret[0].allowMultibinds = allowMultiBinds
			else:
				ret =createForAction(i,null,gridContainerPC,KEYTYPE.PC,customName,hidden,allowMultiBinds,disallowM1)
				ret[0].get_child(0).texture.force_type = 1
				ret[0].allowMultibinds = allowMultiBinds
			
			
			
		if  curDict.has("controller"):
			var key = curDict["controller"]
			ret =createForAction(i,curDict["controller"],gridContainerController,KEYTYPE.GAMEPAD,customName,hidden,allowMultiBinds,disallowM1)
			ret[0].get_child(0).texture.force_type = 2
			ret[0].allowMultibinds = allowMultiBinds
			
		else:
			ret =createForAction(i,null,gridContainerController,KEYTYPE.GAMEPAD,customName,hidden,allowMultiBinds,disallowM1)
			ret[0].get_child(0).texture.force_type = 2
			ret[0].allowMultibinds = allowMultiBinds
			
		

func createForAction(actionName,boundKey,parent,lMode,customName,hidden,dontReplaceSameKeybinds = false,disallowM1 = false):
	
	var label = Label.new()
	label.text = actionName.to_upper()
	
	if customFont != null:
		label.set("theme_override_fonts/font",customFont)
	
	if customName != null:
		label.text = customName.to_upper()
		label.set_meta("trueName",actionName.to_upper())
	parent.add_child(label)
	
	
	var inputBox : Control = load("res://addons/godotWad/scenes/gameModes/main/options/inputSelector.tscn").instantiate()
	inputBox.action = actionName
	inputBox.size_flags_horizontal = SIZE_EXPAND_FILL
	inputBox.disallowM1 = disallowM1
	
	if lMode != KEYTYPE.ALL:
		inputBox.curKeytype = lMode
	
	#if boundKey != null:
		#if boundKey.find("MOUSE") != -1:
			#inputBox.curKeytype = KEYTYPE.PC
	
	var value = $"%inputEnums".getCodeForString(boundKey,lMode)
	
	if value != null:
		if value.has("isAxis"):
			lMode = KEYTYPE.GAMEPAD_MOTION
	else:
		inputBox.text = ""
		
		
	inputBox.limitMode = lMode
	
	
	parent.add_child(inputBox)
	if value !=null:
		
		if boundKey != null:
			if boundKey.find("MOUSE") != -1:
				inputBox.curKeytype = KEYTYPE.MOUSE
		
		
		inputBox.text = inputBox.getKeyString(value["keycode"],value["analogValue"])
		inputBox.replaceActionScanCode(actionName, value["keycode"],value["analogValue"],dontReplaceSameKeybinds)
		
	else:
		
		inputBox.text = ""

	
	inputBox.connect("keySet", Callable(self, "inputSet"))
	inputBox.incorrectDeviceUsed.connect(gamepadDeviceIndexUsed)
	inputBox.updateIcon()
	
	if hidden:
		inputBox.queue_free()
		label.queue_free()
	
	return [inputBox,label]
	
func getAllControllerKeyNodes():
	return getKeysForInputType(controllerBindings)
	
func getAllKeyboardKeyNodes():
	return getKeysForInputType(keyboardBindings)

func getKeysForInputType(inputBaseNode):
	
	var ret = []
	
	for i in inputBaseNode.get_children():
		if i is GridContainer:
			for j in i.get_children():
				if j is not LineEdit:
					continue
		
				ret.append(j)
	
	return ret
				
func inputSet(input,caller):
	var callerPath = caller.get_child(0).texture.path
	
	var keys = getKeysForInputType(caller.get_node("../../"))
	
	for key in keys:
		if key == caller:
			continue
			
		if key.valueStr != key.valueStr:
			continue
			
		key.text = ""
		key.valueStr = ""
		key.updateIcon()
		
		

		
	if %prompt.visible:
		%prompt.visible = false
	
	
	get_node("../../../../").skipInputThisFrame = true
	#get_tree().get_root().set_process_input(false)
	#get_node("../../").set_process_input(false)
	#await (get_tree().create_timer(0.1)).timeout
	#get_node("../../").set_process(true)


func _on_deviceSelect_item_selected(index):
	var txt = $"%deviceSelect".get_item_text(index)
	
	
	if index == 1:
		controllerBindings.visible = true
		keyboardBindings.visible = false
		
		procDeviceSelector($"%deviceSelector")

	
	if index == 0:
		controllerBindings.visible = false
		keyboardBindings.visible = true
		
		

		

func procDeviceSelector(deviceSelector):
	var inputs = Input.get_connected_joypads()
	var optionButton : OptionButton = deviceSelector.get_node("OptionButton")
	
	optionButton.clear()
	
	if inputs.size() <= 1:
		deviceSelector.visible = false
	else:
		
		for i in inputs.size():
			var inputName = str(i) + ": " + Input.get_joy_name(i) + "\n" 
			optionButton.add_item(inputName)


func gamepadChanged(index : int):
	curGamepadIndex = index
	
	get_tree().get_root().get_node("ControllerIcons").forceControllerId =  index
	get_tree().get_root().get_node("ControllerIcons")._last_controller = index
	var keys = getAllControllerKeyNodes()
	
	for key in keys:
		key.targetDeviceId = curGamepadIndex

func restoreDefault():
	setInput()
	


func _on_defaults_button_pressed():
	restoreDefault()


func getAsCategory(dict : Dictionary) -> Dictionary:
	
	var catDict = {"general":{}}
	
	for key in dict.keys():
		var value = dict[key]
		var curCat = "general"
		
		
		if value.has("category"):
			curCat = value["category"]
		
		if !catDict.has(curCat):
			catDict[curCat] = {}
			
		catDict[curCat][key] = dict[key]
		
	return catDict

func _physics_process(delta):
	if !get_parent().visible:
		%prompt.visible = false
		return
		
	for i in (keyboardBindings.get_children()+controllerBindings.get_children()):
		if !i is GridContainer:
			continue
		
		for j : Control in i.get_children():
			if !j is LineEdit:
				continue
			
			if j.has_focus():
				return
	
	%prompt.visible = false
		

func createGridContainer():
	var gridContainer = GridContainer.new()
	gridContainer.size_flags_horizontal =Control.SIZE_EXPAND_FILL
	gridContainer.columns = 2
	
	return gridContainer

func hasKeyboardBinds(dict):
	for i in dict.values():
		if !i.has("controllerOnly"):
			return true
			
	return false



	


func gamepadDeviceIndexUsed(idx):
	$"%deviceSelector".get_node("OptionButton").selected = idx


func _on_force_ui_button_item_selected(index: int) -> void:
	pass # Replace with function body.
