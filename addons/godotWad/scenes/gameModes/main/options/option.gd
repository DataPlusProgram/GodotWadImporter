extends Control

@export() var fontColor :Color = Color(0.72882199287415, 0.72882199287415, 0.72882199287415)
@export var loader : NodePath = ""
@onready var videoOptions = $VBoxContainer/TabContainer/Video/Video

signal restoreDefault
var skipInputThisFrame = false

func _ready():
	$VBoxContainer/TabContainer/Video/Video/Video/fovSlider
	get_node("VBoxContainer/TabContainer/Video/Video/Video/fovSlider/FOVslider").value = SETTINGS.getSetting(get_tree(),"fov")
	get_node("VBoxContainer/TabContainer/Video/Video/Video/mouseSensSlider/mouseSensSlider").value = SETTINGS.getSetting(get_tree(),"mouseSens")
	_on_mouseSensSlider_value_changed(get_node("VBoxContainer/TabContainer/Video/Video/Video/mouseSensSlider/mouseSensSlider").value)
	var bus = AudioServer.get_bus_index("Master")
	var vol =  AudioServer.get_bus_volume_db(bus)
	%masterSlider.value = db_to_linear(vol)
	
	
	SETTINGS.addMusicBus()
	bus = AudioServer.get_bus_index("Music")
	vol =  AudioServer.get_bus_volume_db(bus)
	%musicSlider.value = db_to_linear(vol)
	
	setFont(self,fontColor)

	
	
func _physics_process(delta):
	#if get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN: #if (= true:) else Window.MODE_WINDOWED
	#	get_node("%displayMode").selected = 1
	
	skipInputThisFrame = false
	
	if %TabContainer.current_tab != 1:
		%DefaultsButton.visible = false
	else:
		%DefaultsButton.visible = true
	
	#if DisplayServer.window_get_vsync_mode(DisplayServer.VSYNC_ENABLED) != 0: #if (= true:) else DisplayServer.VSYNC_DISABLED)
	#	get_node("%VSync").selected = 1
		
	#print($AudioStreamPlayer.playing)


func setFont(node,col):
	if node.get_class() == "Label":
		if !node.has_meta("keepColor"):
			node.set("theme_override_colors/font_color",col)
		
	for i in node.get_children():
		setFont(i,col)
	
func _on_displayMode_item_selected(index):
	if index == 0:
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN 
		
	if index == 1:
		get_window().mode = Window.MODE_WINDOWED



func _on_VSync_item_selected(index):
	if index == 0:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if index == 1:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	if index == 2:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
	if index == 4:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_MAILBOX)
	


func _input(event):
	
	if skipInputThisFrame:
		return
	
	if event.is_action_pressed("menuTabRight"):
		%TabContainer.current_tab = (%TabContainer.current_tab +1)%(%TabContainer.get_tab_count())
	
	if event.is_action_pressed("menuTabLeft"):
		%TabContainer.current_tab = posmod(%TabContainer.current_tab -1,(%TabContainer.get_tab_count()))
		%TabContainer.get_child(0,true).grab_focus()
	
	if !event is InputEventJoypadButton:
		return
	
	if event.is_pressed() == false:
		return
	
	if event.button_index == 5:
		%TabContainer.current_tab += 1
		
	if event.button_index == 4:
		%TabContainer.current_tab -= 1


func _on_MasterSlider_value_changed(value):
	
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))



func _on_MasterSlider_drag_started():
	
	%AnimationPlayer.stop()
	%AnimationPlayer.play("audioFadeIn")


func _on_MasterSlider_drag_ended(value_changed):

	%AnimationPlayer.stop()
	%AnimationPlayer.play("audioFadeOut")


func _on_Button_pressed():
	visible = false
	if get_parent().has_method("grab_focus"):
		get_parent().grab_focus()


func _on_FOVslider_value_changed(value):
	SETTINGS.setSetting(get_tree(),"fov",value)
	get_node("%FOVlabel").text = str(value)



func _on_mouseSensSlider_value_changed(value):
	SETTINGS.setSetting(get_tree(),"mouseSens",value)
	get_node("VBoxContainer/TabContainer/Video/Video/Video/mouseSensSlider/senseSliderLabel").text = "%.3f" % value

func relaseFocusOwner():
	get_viewport().gui_get_focus_owner().release_focus()


func _on_music_slider_value_changed(value):
	var bus = AudioServer.get_bus_index("Music")
	if bus == -1:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))


func _on_button_pressed():
	hide()


func _on_resolucion_scaling_slider_value_changed(value: float) -> void:
	get_tree().get_root().scaling_3d_scale = value
	%resolutionLabel.text = str(value)
	pass # Replace with function body.


func _on_scaling_mode_options_item_selected(index: int) -> void:
	if index == 0:
		get_tree().get_root().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		%resolucionScalingSlider.max_value = 2.0
	if index == 1:
		get_tree().get_root().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
		%resolucionScalingSlider.value = min(%resolucionScalingSlider.value,1.0)
		%resolucionScalingSlider.max_value = 1.0
	if index == 2:
		get_tree().get_root().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
		%resolucionScalingSlider.value = min(%resolucionScalingSlider.value,1.0)
		%resolucionScalingSlider.max_value = 1.0


func _on_option_button_item_selected(index):
	var l = get_parent().mainMode.get_node("WadLoader")
	
	SETTINGS.setSetting(get_tree(),"textureFiltering",index)
	l.materialManager.updateTextureFiltering()


func _on_fps_limited_label_option_item_selected(index: int) -> void:
	var value = %fpsLimitedLabelOption.get_item_text(index).to_lower()
	
	if value == "disabled":
		Engine.max_fps = 0
		%fpsLimitValue.visible = false
	else:
		%fpsLimitValue.visible = true
		Engine.max_fps = %fpsLimitValue.value


func _on_fps_limit_value_value_changed(value: float) -> void:
	Engine.max_fps = int(value)


func _on_defaults_button_pressed() -> void:
	emit_signal("restoreDefault")


func _on_visibility_changed() -> void:
	if visible == false:
		return
	
	
	var curFocus = get_viewport().gui_get_focus_owner()
	
	if curFocus == null:
		return
	var t = %TabContainer.get_child(0)
	if !curFocus.is_ancestor_of(%TabContainer):
		%TabContainer.get_child(0,true).grab_focus()
	
