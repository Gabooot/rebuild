extends Node3D

@export var RADAR_SCALE : int = 5
# Called when the node enters the scene tree for the first time.
func _ready():
	print("starting")
	if "--server" in OS.get_cmdline_args():
		print("starting server")
		get_node("UDPserver").start_server()
		get_node("ENETServer").start_server(5194)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#print(Engine.get_frames_per_second())
	if Input.is_action_just_pressed('spawn'):
		spawn(Vector3(0,3,0), 0)
	if Input.is_action_just_pressed('self-destruct'):
		get_tree().quit()

func spawn(location, id_number):
	print("id spawned: ", id_number)
	var tank = preload("res://tank.tscn" )
	var player = tank.instantiate()
	player.name = str(id_number)
	add_child(player)
	player.global_position = location

func apoptose(player):
	player.queue_free()
	


