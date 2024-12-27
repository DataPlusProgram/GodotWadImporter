@tool
extends Button




func _ready():
	$".".connect("button_up", Callable(self, "openDialog"))


func openDialog():
	var dialog = load("res://addons/godotWad/scenes/entityDebugDialog.tscn").instantiate()
	$"/root".add_child(dialog)
	dialog.popup_centered_ratio()

