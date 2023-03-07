extends Node

# Get References
@onready var main_menu: Node = $CanvasLayer/MainMenu
@onready var address_entry: Node = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar

const PLAYER = preload("res://src/characters/player1/player.tscn")
# Open PORT 
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_button_pressed():
	main_menu.hide()
	hud.show()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	# spawn joined player on host (client join to server)
	multiplayer.peer_connected.connect(add_player)
	
	# spawn host player (server)
	add_player(multiplayer.get_unique_id())

# Client
func _on_join_button_pressed():
	main_menu.hide()
	hud.show()
	
	# localhost for testing locally
	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer

# Spawn player (Server)
func add_player(peer_id):
	var player: Node = PLAYER.instantiate()
	player.name = str(peer_id)
	add_child(player)
	
	# connect signal emitting from player after receiving damage
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)

# update health_bar for host player
# for client is done from the MultiplayerSpawner Node
func update_health_bar(health_value):
	health_bar.value = health_value

# update health_bar for client
# dont need to check if node is a player because
# MultiplayerSpawner only used on player
func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)
