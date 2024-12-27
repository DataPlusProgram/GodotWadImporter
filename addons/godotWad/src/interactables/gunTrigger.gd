extends StaticBody3D
signal takeDamageSignal




func takeDamage(dict):
	emit_signal("takeDamageSignal")
