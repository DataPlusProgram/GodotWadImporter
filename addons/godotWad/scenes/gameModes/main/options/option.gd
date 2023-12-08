extends Control



func _ready():
	get_node("%FOVslider").value = SETTINGS.getSetting(get_tree(),"fov")
	get_node("%mouseSensSlider").value = SETTINGS.getSetting(get_tree(),"mouseSens")
	_on_mouseSensSlider_value_changed(get_node("%mouseSensSlider").value)

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


func _on_FOVslider_value_changed(value):
	SETTINGS.setSetting(get_tree(),"fov",value)
	get_node("%FOVlabel").text = String(value)



func _on_mouseSensSlider_value_changed(value):
	SETTINGS.setSetting(get_tree(),"mouseSens",value)
	get_node("%senseSliderLabel").text = "%.3f" % value

