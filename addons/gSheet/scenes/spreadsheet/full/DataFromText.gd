tool
extends ConfirmationDialog
signal confirm

func _ready():
	connect("confirmed",self,"confirmed")
	


func confirmed():
	emit_signal("confirm",self,$TextEdit.text)
	
