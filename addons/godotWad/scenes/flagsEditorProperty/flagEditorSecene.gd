tool
extends ScrollContainer
signal valueChange



func setValues(var flag):
	var easy =   flag & 0b1     != 0
	var medium = flag & 0b10    != 0
	var hard =   flag & 0b100   != 0
	var multi =  flag & 0b1000  != 0
	
	
	$hBox/easy.pressed = easy
	$hBox/medium.pressed = medium
	$hBox/hard.pressed  = hard
	$hBox/multiplayer.pressed = multi
	
	print([easy,medium,hard,multi])

func valuesChanged(var dummy):
	
	var easy   = 1 if $hBox/easy.pressed else 0
	var medium = 1 if $hBox/medium.pressed else 0
	var hard   = 1 if $hBox/hard.pressed else 0
	var multi  = 1 if $hBox/multiplayer.pressed else 0
	
	
	
	emit_signal("valueChange",[easy,medium,hard,multi])
	
