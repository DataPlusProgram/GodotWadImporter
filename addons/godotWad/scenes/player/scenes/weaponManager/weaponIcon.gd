extends Control

var text = "Weapon" : set = setText
var texture : Texture2D = null : set = setTexture
var iconMinHeight : set = setIconMinHeight
var weaponNode = null


func _ready() -> void:
	pass
	
	#var c = x.bg_color

	
	

func setText(txt : String):
	%Label.text = txt
	
func setTexture(texture : Texture2D):
	%TextureRect.texture = texture

func setIconMinHeight(h):
	%TextureRect.custom_minimum_size.y = h
	
func _on_focus_entered() -> void:
	var borderW = 2
	var style : StyleBoxFlat = Panel.new().get_theme_stylebox("panel").duplicate()
	style.bg_color = Color(0.35531339049339, 0.35531359910965, 0.35531356930733)
	style.border_color = Color(0.1196212247014, 0.03120810911059, 0.0038606938906)
	style.border_width_left = borderW
	style.border_width_right = borderW
	style.border_width_top = borderW
	style.border_width_bottom = borderW
	
	$Panel.set("theme_override_styles/panel/",style)


func _on_focus_exited() -> void:
	var style : StyleBoxFlat = Panel.new().get_theme_stylebox("panel")
	$Panel.set("theme_override_styles/panel/",style)
