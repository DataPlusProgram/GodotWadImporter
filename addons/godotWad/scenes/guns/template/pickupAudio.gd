extends AudioStreamPlayer3D

func playPickup():
	connect("finished", Callable(self, "queue_free"))
	play()
	
