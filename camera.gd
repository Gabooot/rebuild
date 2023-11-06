extends Camera3D

@onready var player = get_node("../player")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#player = get_node("../player")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position = player.global_position
	rotation = player.rotation

