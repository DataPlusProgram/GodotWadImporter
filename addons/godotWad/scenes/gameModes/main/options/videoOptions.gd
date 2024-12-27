extends VBoxContainer

var materialManager : set = materialManagerSet


func _ready():
	var mipMapsOn = %mipMaps.button_pressed
	%ansiotropicLabel.visible = mipMapsOn
	%ansiotropic.visible = mipMapsOn
	
	if get_node_or_null("../../../../") != null:
		if get_node("../../../../").has_signal("restoreDefault"):
			get_node("../../../../").restoreDefault.connect(restoreDefaults)
			
	if %textureFilteringOption.selected != 2:
		%AdvancedFiltering.visible = false
	
	%VSync.selected = DisplayServer.window_get_vsync_mode(0)


func materialManagerSet(matMan):
	materialManager = matMan
	setFilteringOptionsToUIselected()
	materialManager.updateTextureFiltering()

	

func restoreDefaults():
	breakpoint

func _on_display_mode_item_selected(index):
	if index == 0:
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN 
		
	if index == 1:
		get_window().mode = Window.MODE_WINDOWED



func _on_fps_limited_label_option_item_selected(index):
	var value = %fpsLimitedLabelOption.get_item_text(index).to_lower()
	
	if value == "disabled":
		Engine.max_fps = 0
		%fpsLimitValue.visible = false
	else:
		%fpsLimitValue.visible = true
		Engine.max_fps = %fpsLimitValue.value


func _on_fps_limit_value_value_changed(value):
	Engine.max_fps = %fpsLimitValue.value


func _on_v_sync_item_selected(index):
	if index == 0:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if index == 1:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	if index == 2:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
	if index == 4:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_MAILBOX)
	


func _on_scaling_mode_options_item_selected(index):
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


func _on_resolucion_scaling_slider_value_changed(value):
	get_tree().get_root().scaling_3d_scale = value
	%resolutionLabel.text = str(value)


func _on_mouse_sens_slider_value_changed(value):
	SETTINGS.setSetting(get_tree(),"mouseSens",value)
	%senseSliderLabel.text = "%.3f" % value


func _on_fo_vslider_value_changed(value):
	SETTINGS.setSetting(get_tree(),"fov",value)
	get_node("%FOVlabel").text = str(value)


func _on_option_button_item_selected(index):
	var all = %textureFilteringOption.selected
	
	setFilteringOptionsToUIselected()
	if all == 2:
		%AdvancedFiltering.visible = true
	else:
		%AdvancedFiltering.visible = false
	#
	setFilteringOptionsToUIselected()
	materialManager.updateTextureFiltering()

 
func setTextureFilteringAll(value):
	SETTINGS.setSetting(get_tree(),"textureFiltering",value)
	SETTINGS.setSetting(get_tree(),"textureFilteringGeometry",value)
	SETTINGS.setSetting(get_tree(),"textureFilteringSprite",value)
	SETTINGS.setSetting(get_tree(),"textureFilteringFov",value)
	SETTINGS.setSetting(get_tree(),"textureFilteringSky",value)
	SETTINGS.setSetting(get_tree(),"textureFilteringUI",value)
	



func _on_mip_maps_toggled(toggled_on):
	
	
	%ansiotropicLabel.visible = toggled_on
	%ansiotropic.visible = toggled_on

	setFilteringOptionsToUIselected()
	materialManager.updateTextureFiltering()


func _on_ansiotropic_toggled(toggled_on):
	
	setFilteringOptionsToUIselected()
	materialManager.updateTextureFiltering()
	
func setFilteringOptionsToUIselected():
	var all = %textureFilteringOption.selected
	var textureFilteringAll = optionIndexToFilterIndex(%textureFilteringOption.selected)
	var textureFilteringGeometry = optionIndexToFilterIndex(%GFilterOption.selected)
	var textureFilteringSprite = optionIndexToFilterIndex(%SpriteFilterOption.selected)
	var textureFilteringSky = optionIndexToFilterIndex(%SkyOption.selected)
	var textureFilteringUI=	optionIndexToFilterIndex(%UIFilterOption.selected)
	
	if all == 0 or all == 1:
		setTextureFilteringAll(textureFilteringAll)
	
	if all == 2:
	
	#	SETTINGS.setSetting(get_tree(),"textureFiltering",value)
		SETTINGS.setSetting(get_tree(),"textureFilteringGeometry",textureFilteringGeometry)
		SETTINGS.setSetting(get_tree(),"textureFilteringSprite",textureFilteringSprite)
		#SETTINGS.setSetting(get_tree(),"textureFilteringFov",value)
		SETTINGS.setSetting(get_tree(),"textureFilteringSky",textureFilteringSky)
		SETTINGS.setSetting(get_tree(),"textureFilteringUI",textureFilteringUI)
	
	
func _on_g_filter_option_item_selected(index: int) -> void:
	setFilteringOptionsToUIselected()
	#SETTINGS.setSetting(get_tree(),"textureFilteringGeometry",index+1)
	materialManager.updateTextureFiltering()


func _on_sprite_filter_option_item_selected(index: int) -> void:
	setFilteringOptionsToUIselected()
	#SETTINGS.setSetting(get_tree(),"textureFilteringSprite",index+1)
	materialManager.updateTextureFiltering()

func _on_sky_option_item_selected(index: int) -> void:
	#SETTINGS.setSetting(get_tree(),"textureFilteringSky",index+1)
	setFilteringOptionsToUIselected()
	materialManager.updateTextureFiltering()
	


func _on_ui_filter_option_item_selected(index: int) -> void:
	#SETTINGS.setSetting(get_tree(),"textureFilteringUI",index+1)
	setFilteringOptionsToUIselected()
	materialManager.updateTextureFiltering()

func optionIndexToFilterIndex(index):
	if index == 0:
		return getCurrentNearest()
	else:
		return getCurrentLinear()
	

func getCurrentLinear() -> BaseMaterial3D.TextureFilter:
	var mips = %mipMaps.button_pressed
	var ansio = %ansiotropic.button_pressed
	
	if mips and !ansio: return BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if mips and ansio: return BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	 
	return BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR
	
func getCurrentNearest() -> BaseMaterial3D.TextureFilter:
	var mips = %mipMaps.button_pressed
	var ansio = %ansiotropic.button_pressed
	
	if mips and !ansio: return BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
	if mips and ansio: return BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
	 
	return BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST

func printDbg():
	
	print("textureFiltering:",SETTINGS.getSetting(get_tree(),"textureFiltering"))
	print("textureFilteringGeometry:",SETTINGS.getSetting(get_tree(),"textureFilteringGeometry"))
	print("textureFilteringSprite:",SETTINGS.getSetting(get_tree(),"textureFilteringSprite"))
	print("textureFilteringUI:",SETTINGS.getSetting(get_tree(),"textureFilteringUI"))
	
