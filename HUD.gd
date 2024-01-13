extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	self.toggle_in_game_ui


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed('toggle_in_game_ui'):
		self.toggle_in_game_ui()
	if Input.is_action_just_pressed('spawn'):
		pass
		#spawn(Vector3(0,3,0), 0)
	if Input.is_action_just_pressed('self-destruct'):
		get_tree().quit()
	if Input.is_action_just_pressed("toggle_all_chat"):
		self._toggle_all_chat()

func toggle_in_game_ui() -> void:
	var ui = get_node_or_null("in_game_ui")
	if ui:
		ui.exit()
	else:
		ui = preload("res://in_game_ui.tscn")
		ui = ui.instantiate()
		ui.name = "in_game_ui"
		self.add_child(ui)

func _toggle_all_chat() -> void:
	var input_field = %HUD/chat/input_field
	input_field.visible = true
	input_field.grab_focus()
