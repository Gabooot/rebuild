extends Object
class_name NetworkObjects

static func create(object_name : String, networking_type : String, id : int) -> Array:
	var object : Node
	var state_manager : StateManager
	var network_interface : NetworkInterface
	
	match object_name:
		"tank":
			object = preload("res://tank.tscn").instantiate()
			state_manager = StateManager.new(object, ["is_shooting", "is_jumping", "global_transform", "velocity", "angular_velocity", "speed_input", "steering_input", "engine_speed", "shot_timers", "id"])
		"bullet":
			object = preload("res://bullet.tscn").instantiate()
			state_manager = StateManager.new(object, ["velocity", "global_transform"])
		"player":
			object = preload("res://player.tscn").instantiate()
			state_manager = StateManager.new(object, ["is_shooting", "is_jumping", "global_transform", "velocity", "angular_velocity", "speed_input", "steering_input", "engine_speed", "shot_timers"])
	
	match networking_type:
		"server":
			network_interface = PlayerControlledServerInterface.new()
		"simulated client":
			network_interface = SimulatedClient.new()
		"client":
			network_interface = InterpolatedClient.new()
		"player":
			network_interface = PlayerClientInterface.new()
	
	network_interface.id = id
	object.add_child(state_manager)
	state_manager.add_child(network_interface)
	
	return [object, network_interface]
