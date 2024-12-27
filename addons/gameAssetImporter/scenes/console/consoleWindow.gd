extends Window

signal open
signal close

var isReady = false
var mouseCaptureRestoreMode = Input.MOUSE_MODE_CAPTURED

func _on_close_requested():
	hide()
	


func _ready():
	
	var t = get_parent()
	$Console.get_node("%input").grab_focus()
	isReady = true
	

func _on_visibility_changed():
	
	
	if visible:
		mouseCaptureRestoreMode = Input.mouse_mode
		$Console.get_node("%input").grab_focus()
		emit_signal("open")
	else:
		Input.mouse_mode = mouseCaptureRestoreMode
		emit_signal("close")

func _on_window_input(event):
	if Input.is_action_just_pressed("shoeConsole"):
		breakpoint

func registerScript(script):
	if !isReady:
		await ready
	
	$Console.get_node("%execute").registerScript(script)
