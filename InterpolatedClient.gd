extends NetworkInterface
class_name InterpolatedClient

var unused_states : Dictionary = {}
var latest_reliable_state : int = 0

func _ready():
	self.initialize()
	game_manager.simulate.connect("_on_simulate")

func update_state(state_dict : Dictionary) -> void:
	var update_tick = state_dict.tick
	
	if update_tick > self.latest_reliable_state:
		self.latest_reliable_state = update_tick
	else:
		pass
	
	self.unused_states[update_tick] = state_dict
	game_manager.request_resimulation(update_tick)

func _on_simulate() -> void:
	if game_manager.active_tick < self.latest_reliable_state: 
		victim.simulate()
	else:
		pass
	
	var next_state = self.unused_states.get(game_manager.active_tick + 1)
	if next_state:
		self.state_manager.set_state(next_state)
		self.unused_states.erase(game_manager.active_tick + 1)
	else:
		var preserved_inputs = self.state_manager.state_dictionary.get(game_manager.active_tick + 1)
		if preserved_inputs:
			victim.is_shooting = preserved_inputs.is_shooting
			victim.is_jumping = preserved_inputs.is_jumping
