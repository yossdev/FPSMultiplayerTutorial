extends Node

# Get References
@onready var main_menu: Node = $CanvasLayer/MainMenu
@onready var address_entry: Node = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry

const PLAYER = preload("res://src/characters/player1/player.tscn")
# Open PORT 
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_button_pressed():
	main_menu.hide()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	# spawn joined player on host
	multiplayer.peer_connected.connect(add_player)
	
	# spawn host player
	add_player(multiplayer.get_unique_id())

func _on_join_button_pressed():
	main_menu.hide()
	
	# localhost for testing locally
	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer

# Spawn player
func add_player(peer_id):
	var player: Node = PLAYER.instantiate()
	player.name = str(peer_id)
	add_child(player)
