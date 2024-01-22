extends TankInterface
class_name ClientTankInterface

func _ready():
	Flag.new(self)
	self.buffer = InputBuffer.new(ServerInput.new(), 4)
	self.add_child(TeleportDevice.new())
	var radar_icon = preload("res://radar_tank.tscn")
	radar_icon = radar_icon.instantiate()
	radar_icon.player = self
	get_node("/root/game/radar/rotater/mover").add_child(radar_icon)

func update_from_input(input : OrderedInput=buffer.take()) -> Variant:
	var extrapolation_factor = self._get_extrapolation_factor()
	var generated_input = flag.set_client_state(input, extrapolation_factor)
	return null

func _get_extrapolation_factor() -> int:
	return 5
