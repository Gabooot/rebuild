extends ServerInterface
class_name PlayerControlledServerInterface

@onready var buffer = PlayerInputBuffer.new()
var current_input_tick : int = 0

func _ready():
	#game_manager.simulate.connect(_on_simulate)
	SynchronizationManager.simulate.connect(_on_simulate)
	SynchronizationManager.collect_input.connect(_on_collect_input)

func update_state(state_dict : Dictionary) -> void:
	#print("Received client update: ", state_dict)
	for key in state_dict.keys():
		if (key not in input_properties) and (key != "order"):
			state_dict.erase(key)
	buffer.add(state_dict)


func _on_collect_input() -> void:
	var current_input = buffer.take()
	if current_input.order > self.current_input_tick:
		self.current_input_tick = current_input.order
	#print("Current input: ", current_input)
	state_manager.set_state(current_input)

func get_delta_state(compare_with : int) -> Dictionary:
	var out := super(compare_with)
	out["last_input_received"] = current_input_tick
	#print("Got delta state: ", out.values(), " Compared with #", compare_with)
	return out
