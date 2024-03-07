extends ServerInterface
class_name PlayerControlledServerInterface

@onready var buffer = PlayerInputBuffer.new()
var current_tick = 0

func _ready():
	game_manager.simulate.connect(_on_simulate)

func update_state(state_dict : Dictionary) -> void:
	buffer.add(state_dict)

func _on_simulate() -> void:
	var current_input = buffer.take()
	current_tick = current_input.order
	state_manager.set_state(current_input)
	super()


