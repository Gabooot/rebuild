extends Node3D

signal tank_hit(shooter, target)
signal message_received(message, sender)

@export var RADAR_SCALE : int = 5
# Called when the node enters the scene tree for the first time.
func _ready():
	print("starting")
	if "--server" in OS.get_cmdline_args():
		print("starting server")
		get_node("UDPserver").start_server()
		get_node("ENETServer").start_server(5195)
	else:
		self.toggle_in_game_ui()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#print(Engine.get_frames_per_second())
	if Input.is_action_just_pressed('toggle_in_game_ui'):
		self.toggle_in_game_ui()
	if Input.is_action_just_pressed('spawn'):
		pass
		#spawn(Vector3(0,3,0), 0)
	if Input.is_action_just_pressed('self-destruct'):
		get_tree().quit()
	if Input.is_action_just_pressed("toggle_all_chat"):
		self._toggle_all_chat()

func spawn(location, id_number, environment="server"):
	print("id spawned: ", id_number)
	var tank = null
	if environment == "server":
		tank = preload("res://tank.tscn" )
	elif environment == "client":
		tank = preload("res://client_tank.tscn")
	var player = tank.instantiate()
	player.name = str(id_number)
	add_child(player)
	player.global_position = location
	
	if environment == "client":
		var radar_icon = preload("res://radar_tank.tscn")
		radar_icon = radar_icon.instantiate()
		radar_icon.player = player
		%radar/rotater/mover.add_child(radar_icon)

func apoptose(player):
	player.queue_free()
	
func toggle_in_game_ui() -> void:
	var ui = get_node_or_null("in_game_ui")
	if ui:
		ui.exit()
	else:
		ui = preload("res://in_game_ui.tscn")
		ui = ui.instantiate()
		ui.name = "in_game_ui"
		self.add_child(ui)

func _toggle_all_chat() -> void:
	var input_field = %HUD/chat/input_field
	input_field.visible = true
	input_field.grab_focus()
