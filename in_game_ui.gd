extends Panel

var config = ConfigFile.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	if not ("--server" in OS.get_cmdline_args()):
		self.load_previous_session()

func _process(delta):
	pass

func load_previous_session() -> void:
	var err = config.load("user://saved_state.cfg")
	if err != OK:
		config.save("user://saved_state.cfg")
		config.load("user://saved_state.cfg")
		return
	else:
		get_node("server_edit").text = config.get_value("Last Connection", "server")
		get_node("port_edit").text = config.get_value("Last Connection", "port")
		get_node("name_edit").text = config.get_value("Last Connection", "name")

func exit() -> void:
	config.set_value("Last Connection", "server", get_node("server_edit").text)
	config.set_value("Last Connection", "port", get_node("port_edit").text)
	config.set_value("Last Connection", "name", get_node("name_edit").text)
	config.save("user://saved_state.cfg")
	self.queue_free()
