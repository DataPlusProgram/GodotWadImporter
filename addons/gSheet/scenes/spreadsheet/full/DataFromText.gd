@tool
extends ConfirmationDialog
signal confirmSignal

func _ready():
	#connect("confirmed",self,"confirmed")
	connect("confirmed",confirmedS)
	


func confirmedS():
	emit_signal("confirmSignal",self,$TextEdit.text)
	
