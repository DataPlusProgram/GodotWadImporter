extends Control

var history : Array[String] = []
var historyMaxSize = 3
var historyOffset = 0

func _ready():
	if !InputMap.has_action("showConsole"):
		InputMap.add_action("showConsole")


func _on_input_send_pressed():
	
	
	history.append(%input.text)
	
	if history.size() > historyMaxSize:
		history.pop_front()
	
	%logText.text += "[color=yellow]" +%input.text +"[/color]" + "\n"
	
	
	var retText : String = %execute.execute(%input.text)
	
	%input.text = ""
	
	
	
	if !retText.is_empty():#will return non empty for errors
		%logText.text += retText + "\n"
		return
	

func _on_input_gui_input(event):
	if !event is InputEventKey:
		return
	
	if event.keycode == KEY_ENTER and !event.echo and event.pressed:
		historyOffset = 0
		_on_input_send_pressed()
		
	if Input.is_action_just_pressed("ui_up"):
		if history.is_empty():
			%input.caret_column = %input.text.length()

			return
			
		if historyOffset > historyMaxSize:
			historyOffset = history.size()
		
		%input.text = history[history.size()-1-(historyOffset%history.size())]
		%input.caret_column = %input.text.length()-1
		historyOffset += 1
		
	
	if Input.is_action_just_pressed("ui_down"):
		if history.is_empty():
			return
			
			
		
		%input.text = history[history.size()-1-(historyOffset%history.size())]
		%input.caret_column = %input.text.length()-1

		historyOffset -= 1
		
		if historyOffset < 0:
			historyOffset = 0 
		
	if Input.is_action_just_pressed("ui_cancel"):
		if !%input.has_focus():
			visible = false


func _on_visibility_changed():
	if !%input.is_inside_tree():
		return
	if visible:
		%input.text = ""
		%input.grab_focus()
	
	
