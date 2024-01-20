extends TankInterface
class_name ServerTrackerTankInterface

func _ready():
	Flag.new(self)
	self.buffer = InputBuffer.new(ServerInput.new(), 1)
	self.add_child(TeleportDevice.new())

func update_from_input(input : OrderedInput=buffer.take()) -> Variant:
	var generated_input = flag.set_client_state(input)
	return null
