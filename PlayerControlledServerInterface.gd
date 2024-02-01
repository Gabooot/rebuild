extends ServerInterface
class_name PlayerControlledServerInterface

@onready var buffer = PlayerInputBuffer.new()

func _ready():
	self.initialize()

func update_state(state_dict : Dictionary) -> void:
	buffer.add(state_dict)
	super(buffer.take())
