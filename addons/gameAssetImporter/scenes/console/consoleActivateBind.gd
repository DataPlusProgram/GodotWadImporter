extends Node

var console
func _ready():
	get_tree().set_meta("bindedConsole",self)
	console = EGLO.fetchConsole(get_tree())
	console.visible = false
	if console.is_inside_tree():
		console.get_parent().remove_child(console)
	add_child(console)
	
	var e = InputEventKey.new()
	e.keycode = ENTG.consoleButtonScancode
	
	InputMap.action_add_event(ENTG.consoleShowAction,e)



func _physics_process(delta):
	if Input.is_action_just_pressed(ENTG.consoleShowAction):
		if console.visible == true:
			console.visible = false
			#enableInput()
		else:
			console.popup_centered_ratio()
			#disableInput()
