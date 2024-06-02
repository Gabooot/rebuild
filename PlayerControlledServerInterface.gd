extends ServerInterface
class_name PlayerControlledServerInterface

@onready var buffer = PlayerInputBuffer.new()
var current_tick = 0

func _ready():
	game_manager.simulate.connect(_on_simulate)
	SynchronizationManager.simulate.connect(_on_simulate)
	SynchronizationManager.collect_input.connect(_on_collect_input)

func update_state(state_dict : Dictionary) -> void:
	#print("Received client update: ", state_dict)
	buffer.add(state_dict)


func _on_collect_input() -> void:
	var current_input = buffer.take()
	#print("Current input: ", current_input)
	state_manager.set_state(current_input)

#func _on_simulate() -> void:
	#var current_input = buffer.take()
	#current_tick = current_input.order
	#print("Current input: ", current_input)
	#state_manager.set_state(current_input)
	#super()

func get_delta_state(compare_with : int) -> Dictionary:
	var out := super(compare_with)
	#print("Got delta state: ", out.values(), " Compared with #", compare_with)
	return out
