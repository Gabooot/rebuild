extends ServerInterface
class_name PlayerControlledServerInterface

@onready var buffer = PlayerInputBuffer.new()
var current_tick = 0

func _ready():
	self.initialize()
	game_manager.simulate.connect(_on_simulate)

func update_state(state_dict : Dictionary) -> void:
	buffer.add(state_dict)

func _on_simulate() -> void:
	#if victim is MovingBlock:
		#print("server state: ", state_manager.get_state())
	var current_input = buffer.take()
	current_tick = current_input.order
	#if current_input.speed_input > 0:
		#print("Server tick: ", current_tick, " input: ", current_input.speed_input)
		#print("Server running client tick: ", current_tick, " position: ", victim.global_position)
	state_manager.set_state(current_input)
	game_manager.queue_for_output(state_manager.get_state())
	victim.simulate()
