extends TankInterface

func _ready():
	#Flag.new(self)
	self.add_child(TeleportDevice.new())
	print("id: ", self.id)
	SynchronizationManager.collect_input.connect(_on_collect_input)


func _on_collect_input() -> void:
	
	self.steering_input = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	%input_tracker.steering_input = self.steering_input
	self.speed_input = -Input.get_action_strength("move_backward") + Input.get_action_strength("move_forward")
	%input_tracker.speed_input = self.speed_input
	self.is_dropping_flag = false
	%input_tracker.is_dropping_flag = false
	
	if Input.is_action_pressed("jump"):
		self.is_jumping = true
		%input_tracker.is_jumping = true
	if Input.is_action_pressed("drop_flag"):
		self.is_dropping_flag = true
		%input_tracker.is_dropping_flag = true
	if Input.is_action_just_pressed("shoot"):
		self.is_shooting = true	
		%input_tracker.is_shooting = true
