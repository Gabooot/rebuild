extends Object
class_name NetworkObjects

static func create(object_name : String, networking_type : String, id : int) -> Array:
	var object : Node
	#var state_manager : StateManager
	var state_properties : Array[StringName]
	var input_properties : Array[StringName]
	var network_interface : NetworkInterface
	
	match object_name:
		"tank":
			object = preload("res://tank.tscn").instantiate()
			state_properties = ["global_transform", "velocity", "angular_velocity", "engine_speed", "shot_timers", "flag_name"]
			input_properties = ["is_shooting", "is_jumping", "speed_input", "steering_input"]
		"bullet":
			object = preload("res://bullet.tscn").instantiate()
			state_properties = ["velocity", "global_transform"]
			input_properties = []
			#state_manager = StateManager.new(object, ["velocity", "global_transform", "id"])
		"player":
			object = preload("res://player.tscn").instantiate()
			state_properties = ["global_transform", "velocity", "angular_velocity", "engine_speed", "shot_timers", "flag_name"]
			input_properties = ["is_shooting", "is_jumping", "speed_input", "steering_input"]
		"flagpole":
			object = preload("res://FlagPole.tscn").instantiate()
			state_properties = ["global_transform",]
			input_properties = ["tank_id"]
			#state_manager = StateManager.new(object, ["global_transform", "tank_id", "id"])
	match networking_type:
		"server":
			network_interface = PlayerControlledServerInterface.new(object, state_properties, input_properties)
		"simulated client":
			network_interface = SimulatedClient.new(object, state_properties, input_properties)
		"client":
			network_interface = InterpolatedClient.new(object, state_properties, input_properties)
		"player":
			network_interface = PlayerClientInterface.new(object, state_properties, input_properties)
	
	object.id = id
	network_interface.id = id
	#object.add_child(network_interface)
	#state_manager.add_child(network_interface)
	
	return [object, network_interface]
