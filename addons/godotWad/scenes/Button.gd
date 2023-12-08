tool
extends Button




func _ready():
	$".".connect("button_up",self,"openDialog")


func openDialog():
	var dialog = load("res://addons/godotWad/scenes/entityDebugDialog.tscn").instance()
	$"/root".add_child(dialog)
	dialog.popup_centered_ratio()

