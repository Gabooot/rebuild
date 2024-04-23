extends NetworkInterface
class_name ServerInterface

var sync_interval : int = 10
var _sync_counter : int = 0
@onready var previous_input : Dictionary = state_manager.get_state(input_properties) 

#func _ready():
	#self.initialize()

func update_state(state_dict : Dictionary) -> void:
	super(state_dict)
	game_manager.queue_for_output(state_manager.get_state())

func _on_simulate() -> void:
	_send_necessary_output()
	self.victim.simulate()

func _send_necessary_output() -> void:
	var data : Dictionary = {}
	
	_sync_counter += 1
	if _sync_counter == sync_interval:
		_sync_counter = 0 
		data = state_manager.get_state(state_properties)
	
	var current_input = state_manager.get_state(input_properties)
	if current_input != previous_input:
		self.previous_input = current_input
		#data.merge(current_input)
	if not data.is_empty():
		#print("Sending: ", data)
		_send_properties(data)
		#game_manager.queue_for_output(state_manager.get_state())

func _send_properties(data : Dictionary) -> void:
	data.id = self.id
	game_manager.queue_for_output(data)
