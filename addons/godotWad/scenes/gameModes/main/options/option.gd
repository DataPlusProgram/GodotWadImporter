extends Control



func _ready():
	get_node("%FOVslider").value = SETTINGS.getSetting(get_tree(),"fov")
	get_node("%mouseSensSlider").value = SETTINGS.getSetting(get_tree(),"mouseSens")
	_on_mouseSensSlider_value_changed(get_node("%mouseSensSlider").value)

	var bus = AudioServer.get_bus_index("Master")
	var vol =  AudioServer.get_bus_volume_db(bus)
	
	$"%masterSlider".value = db2linear(vol)
func _physics_process(delta):
	if OS.window_fullscreen == true:
		get_node("%displayMode").selected = 1
	
	if OS.vsync_enabled == true:
		get_node("%VSync").selected = 1
		
	#print($AudioStreamPlayer.playing)

	
func _on_displayMode_item_selected(index):
	if index == 0:
		OS.window_fullscreen = false
		
	if index == 1:
		OS.window_fullscreen = true



func _on_VSync_item_selected(index):
	if index == 0:
		OS.vsync_enabled = false
		
	if index == 1:
		OS.vsync_enabled = true
	

func _unhandled_input(event):
	if !event is InputEventJoypadButton:
		return
	
	if event.is_pressed() == false:
		return
	
	if event.button_index == 5:
		$TabContainer.current_tab += 1
		
	if event.button_index == 4:
		$TabContainer.current_tab -= 1


func _on_MasterSlider_value_changed(value):
	
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear2db(value))



func _on_MasterSlider_drag_started():
	
	$AnimationPlayer.stop()
	$AnimationPlayer.play("audioFadeIn")


func _on_MasterSlider_drag_ended(value_changed):

	$AnimationPlayer.stop()
	$AnimationPlayer.play("audioFadeOut")


func _on_Button_pressed():
	visible = false
	if get_parent().has_method("grab_focus"):
		get_parent().grab_focus()


func _on_FOVslider_value_changed(value):
	SETTINGS.setSetting(get_tree(),"fov",value)
	get_node("%FOVlabel").text = String(value)



func _on_mouseSensSlider_value_changed(value):
	SETTINGS.setSetting(get_tree(),"mouseSens",value)
	get_node("%senseSliderLabel").text = "%.3f" % value

func relaseFocusOwner():
	get_focus_owner().release_focus()
