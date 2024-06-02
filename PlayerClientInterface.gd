extends NetworkInterface
class_name PlayerClientInterface

var server_tracker : Node
var input_tracker : Node
var unused_states : Dictionary = {}
var input_stream : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	#self.initialize()
	#game_manager.simulate.connect(_on_simulate)
	SynchronizationManager.simulate.connect(_on_simulate)
	self.server_tracker = get_parent()
	self.input_tracker = get_node("../input_tracker")

func update_state(update_dict : Dictionary) -> void:
	#print("Received update: ", update_dict.values())
	self.unused_states[update_dict.order] = update_dict
	self.state_manager.preserve(update_dict.order, update_dict)
	#print("received order: ", update_dict.order)
	SynchronizationManager.request_resimulation(update_dict.order)
	#print("updated state: ", update_dict)
	'''if update_dict.has("velocity"):
		#print(" current tick: ", game_manager.current_tick, " verified shots: ", update_dict.shot_timers, " update tick ", update_dict.order)
		self.unused_states[update_dict.order] = update_dict
		self.state_manager.preserve(update_dict.order, update_dict)
		self.game_manager.request_resimulation(update_dict.order)
	else:
		state_manager.set_state(update_dict)
		self.input_stream[update_dict.order] = update_dict
		if update_dict.has("is_jumping"):
			input_tracker.is_jumping = update_dict.is_jumping
		if update_dict.has("is_dropping_flag"):
			input_tracker.is_dropping_flag = update_dict.is_dropping_flag
		input_tracker.steering_input = update_dict.steering_input
		input_tracker.speed_input = update_dict.speed_input'''
		

func _on_simulate() -> void:
	var active_tick = SynchronizationManager.active_tick
	#if unused_states.has(active_tick + 1):
		#print("verified shots ", unused_states[active_tick + 1].shot_timers, " at tick ", active_tick + 1)
	if active_tick != SynchronizationManager.current_tick:
		self.server_tracker.simulate()
		var next_state = unused_states.get(active_tick + 1)
		if next_state:
			print("verified state: ", next_state)
			state_manager.set_state(next_state)
			victim.force_update_transform()
		else:
			pass
		
		var next_input = input_stream.get(active_tick + 1)
		if next_input:
			state_manager.set_state(next_input)
			#print("Current tick ", game_manager.current_tick, ", active tick ", game_manager.active_tick, " shot timers ", victim.shot_timers)
		else: 
			pass 
	else:
		state_manager.preserve(active_tick, state_manager.get_state(self.input_properties))
		if input_tracker.flag_name != server_tracker.flag_name:
			input_tracker.flag_name = server_tracker.flag_name
		self.server_tracker.simulate()
		self.input_tracker.simulate()
		self._interpolate()

func _interpolate() -> void:
	
	var rotation_diff = input_tracker.global_rotation.y - victim.global_rotation.y
	if rotation_diff > PI:
		rotation_diff -= (2 * PI)
	elif rotation_diff < -PI:
		rotation_diff += (2 * PI)
	
	var position_diff = (input_tracker.global_position - victim.global_position).length()
	
	if (position_diff > 1.0) or (rotation_diff > 0.3):
		input_tracker.global_transform = victim.global_transform
		input_tracker.velocity = victim.velocity
		input_tracker.angular_velocity = victim.angular_velocity
	
	if (rotation_diff >  0.001):#input_tracker.MIN_ANGLE_TO_INTERPOLATE):
		self._correct_transform(0.004, rotation_diff)
	elif (position_diff > 0.001):#self.MIN_DISTANCE_TO_INTERPOLATE):
		self._correct_transform(0.004, position_diff)
	else:
		pass

func _correct_transform(step : float, error : float) -> void:
	if error <= 0:
		print("Warning: stop trying to correct 0 error!")
		return
	var interp_percent = min((step / error), 1)
	#print("Transforms: ", self.global_transform, " ", server_tracker.global_transform)
	input_tracker.global_transform = input_tracker.global_transform.interpolate_with(victim.global_transform, interp_percent)
