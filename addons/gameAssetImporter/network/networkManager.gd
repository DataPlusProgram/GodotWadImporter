extends Control

signal playerConnectedSignal(peer_id)
signal playerDisconnectedSignal(peer_id)
signal serverDisconnectedSignal

var playersDict : Dictionary = {}

func _ready():
	
	multiplayer.peer_connected.connect(playerConnected)
	#multiplayer.playerConnectedSignal.connect(playerConnected)
	#multiplayer.peer_disconnected.connect(_on_player_disconnected)
	#multiplayer.connected_to_server.connect(_on_connected_ok)
	#multiplayer.connection_failed.connect(_on_connected_fail)
	#multiplayer.server_disconnected.connect(_on_server_disconnected)
	init()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func init():
	var error = NETG.createServer(get_tree(),playersDict,"bob")
	if error != OK:
		return error
	
	

func playerConnected(id : int):
	breakpoint
