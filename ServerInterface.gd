extends NetworkInterface
class_name ServerInterface

var sync_interval : int = 1
var _sync_counter : int = 0

#func _ready():
	#self.initialize()

func update_state(state_dict : Dictionary) -> void:
	super(state_dict)
	game_manager.queue_for_output(state_manager.get_state())

func _on_simulate() -> void:
	_send_necessary_output()
	self.victim.simulate()

func _send_properties(data : Dictionary) -> void:
	data.id = self.id
	game_manager.queue_for_output(data)

func _send_necessary_output() -> void:
	_sync_counter += 1
	if _sync_counter == sync_interval:
		_sync_counter = 0 
		_send_properties(state_manager.get_state())
		#game_manager.queue_for_output(state_manager.get_state())
