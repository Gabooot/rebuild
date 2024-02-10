extends Object
class_name NetworkObjects

static func create(object_name : String, networking_type : String, id : int) -> Array:
	var object : Node
	var state_manager : StateManager
	var network_interface : NetworkInterface
	
	match object_name:
		"tank":
			object = preload("res://tank.tscn").instantiate()
			state_manager = StateManager.new(object, ["is_shooting", "is_jumping", "global_transform", "velocity", "angular_velocity", "speed_input", "steering_input", "engine_speed", "shot_timers", "flag_name","id"])
		"bullet":
			object = preload("res://bullet.tscn").instantiate()
			state_manager = StateManager.new(object, ["velocity", "global_transform", "id"])
		"player":
			object = preload("res://player.tscn").instantiate()
			state_manager = StateManager.new(object, ["is_shooting", "is_jumping", "global_transform", "velocity", "angular_velocity", "speed_input", "steering_input", "engine_speed", "flag_name", "shot_timers"])
		"flagpole":
			object = preload("res://FlagPole.tscn").instantiate()
			state_manager = StateManager.new(object, ["global_transform", "tank_id", "id"])
	match networking_type:
		"server":
			network_interface = PlayerControlledServerInterface.new()
		"simulated client":
			network_interface = SimulatedClient.new()
		"client":
			network_interface = InterpolatedClient.new()
		"player":
			network_interface = PlayerClientInterface.new()
	
	object.id = id
	network_interface.id = id
	object.add_child(state_manager)
	state_manager.add_child(network_interface)
	
	return [object, network_interface]
