extends Node
class_name NetworkInterface

@onready var game_manager = get_node("/root/game")

var state_manager : StateManager 
var victim : Node
var state_properties : Array[StringName]
var input_properties : Array[StringName]
var is_active : bool = true
var id : int = -1
var initial_state : Dictionary = {}

func _init(victim : Node, state_properties : Array[StringName], input_properties : Array[StringName]) -> void:
	self.victim = victim
	self.state_properties = state_properties
	self.input_properties = input_properties
	self.state_manager = StateManager.new(victim, (state_properties + input_properties))
	self.add_child(state_manager)
	victim.add_child(self)

func _ready():
	pass
	#print("Grabbing initial state")
	#self.initial_state = state_manager.get_state()


func update_state(state_dict : Dictionary) -> void:
	if multiplayer.is_server():
		print("Update: ", state_dict)
	state_manager.set_state(state_dict)
	var current_state = state_manager.get_state()

func get_state() -> Variant:
	return state_manager.get_state()

func get_delta_state(compare_with : int) -> Dictionary:
	var current_state = state_manager.get_state()
	var comparison_state = state_manager.state_dictionary.get(compare_with)
	if not comparison_state:
		comparison_state = self.initial_state
	else:
		pass
	
	var delta_state = {}
	for key in current_state.keys():
		var current_var = current_state[key]
		if current_var != comparison_state.get(key):
			delta_state[key] = current_var
	
	#delta_state.id = self.id
	if not multiplayer.is_server():
		#print(delta_state)
		pass
	return delta_state


func preserve():
	state_manager.preserve(SynchronizationManager.active_tick)


func serialize_state(state : Dictionary) -> PackedByteArray:
	return var_to_bytes(state)


func simulate():
	victim.simulate()

func deserialize_state(serialized_state : PackedByteArray) -> Dictionary:
	return bytes_to_var(serialized_state)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		SynchronizationManager.deregister_network_interface(self)
