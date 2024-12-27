extends Node

class_name NETG

const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 20

func createNetworkManager():
	var node = load("res://addons/gameAssetImporter/network/networkManager.tscn").instantiate()
	return node

static func createServer(tree:SceneTree,playerInfo : Dictionary, creatorName = "player0",maxConnections = MAX_CONNECTIONS) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	
	if error:
		return error
		
	tree.get_root().multiplayer.multiplayer_peer = peer
	playerInfo[0] = {"name":creatorName}
	
	
	return OK

static func joinServer(tree,ip,port):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip,port)
	tree.get_root().multiplayer.multiplayer_peer = peer
