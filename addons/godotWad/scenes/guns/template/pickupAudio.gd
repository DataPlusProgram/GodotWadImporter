extends AudioStreamPlayer3D

func playPickup():
	connect("finished",self,"queue_free")
	play()
	
