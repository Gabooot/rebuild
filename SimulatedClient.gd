extends NetworkInterface
class_name SimulatedClient

var unused_states : Dictionary = {}
var inputs : Array[String] = []

func _ready():
	game_manager.simulate.connect(_on_simulate)

func update_state(state_dict : Dictionary) -> void:
	var update_tick = state_dict.order
	self.unused_states[update_tick] = state_dict
	self.state_manager.preserve(update_tick, state_dict)
	if update_tick < game_manager.current_tick:
		game_manager.request_resimulation(self, update_tick)
	
	var ticks = unused_states.keys()
	for tick in ticks:
		if (game_manager.current_tick - tick) > Shared.num_states_stored:
			unused_states.erase(tick)


func _on_simulate() -> void:
	victim.simulate()
	var future_state = self.unused_states.get(game_manager.active_tick + 1)
	if future_state:
		self.state_manager.set_state(future_state)
	
	#if (victim is MovingBlock) and (game_manager.active_tick == game_manager.current_tick):
		#print("Moving position: ", victim.global_position)
