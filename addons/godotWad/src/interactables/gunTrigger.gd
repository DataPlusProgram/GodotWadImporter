extends StaticBody
signal takeDamage

	
func takeDamage(dcit):
	emit_signal("takeDamage")
