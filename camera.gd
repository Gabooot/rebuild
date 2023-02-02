extends Camera3D

var player_visual = null
# Called when the node enters the scene tree for the first time.
func _ready():
	player_visual = get_node("../player/collision")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position = player_visual.global_position
	rotation = player_visual.rotation

