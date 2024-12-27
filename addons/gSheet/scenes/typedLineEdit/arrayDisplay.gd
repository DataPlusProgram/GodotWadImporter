@tool
extends Control



var style = null
var serializeThisFrame = false
var hasMouse = false
# Called when the node enters the scene tree for the first time.
func _ready():
	var initialStyle : StyleBoxFlat = Panel.new().get_theme_stylebox("panel").duplicate()
	
	
	if get_tree().has_meta("baseControl"):
		initialStyle = get_tree().get_meta("baseControl").get_theme_stylebox("panel").duplicate()
	
	
	if initialStyle.bg_color.v < 0.5:
		initialStyle.bg_color.v += 0.08
	else:
		initialStyle.bg_color.v -= 0.1
	
	initialStyle.bg_color.a = 1
	$Panel.set("theme_override_styles/panel",initialStyle)
	
func _physics_process(delta):
	
	
	if serializeThisFrame == true:
		seralize()
	
	serializeThisFrame = false

func setArrToList(arr : Array):
	var list = %List
	
	for i in arr:
		var n = load("res://addons/gSheet/scenes/typedLineEdit/typedLineEdit.tscn").instantiate()
		n.focus_exited.connect(_on_focus_exited)
		list.add_child(n)
		
		n._on_typedLineEdit_text_changed(var_to_str(i))
		n.text = var_to_str(i)
		n.update.connect(setFlag)
	
	
	
		
func setFlag(node):
	serializeThisFrame = true

func seralize():
	
	var runningStr : String = "["
	
	for i in  %List.get_children():
		var value : String = var_to_str(i.value)
		value = value.replace("\\\"","")
		runningStr += value +","
	
	if runningStr.right(1) == ",":
		runningStr =runningStr.erase(runningStr.length()-1)
	
	
	runningStr += "]"
	get_parent()._on_typedLineEdit_text_changed(runningStr)
	get_parent().text = runningStr

func _on_button_pressed():
	var list = %List
	var child : Control = load("res://addons/gSheet/scenes/typedLineEdit/typedLineEdit.tscn").instantiate()
	child.focus_exited.connect(_on_focus_exited)
	child.update.connect(setFlag)
	list.add_child(child)
	pass # Replace with function body.


func _on_mouse_entered():
	hasMouse = true



func _on_focus_exited():
	emit_signal("focus_exited")
	pass # Replace with function body.
