extends Node2D

var RADAR_SCALE = null
var new_position = null
var player = null
# Called when the node enters the scene tree for the first time.
func _ready():
	RADAR_SCALE = get_node("/root/game").RADAR_SCALE
	player = get_node("../radar_player")
	self.position = Vector2(250,250)
	build_radar()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	new_position = player.twod_position
	self.rotation = player.twod_rotation
	get_node("mover").position = -new_position

func build_radar():
	var collision_shapes = get_tree().get_nodes_in_group("visible_on_radar")
	for shape in collision_shapes:
		if shape.shape is BoxShape3D:
			build_radar_block(shape)
		elif shape.shape is ConvexPolygonShape3D:
			build_radar_convex(shape)

func build_radar_convex(mesh):
	var global_points = []
	for point in mesh.shape.points:
		var global_point = mesh.to_global(point)
		global_points.append(Vector2(global_point.x, global_point.z))
	var polygon = preload("res://radar_face.tscn").instantiate()
	polygon.set_polygon(PackedVector2Array(Geometry2D.convex_hull((global_points))))
	polygon.height = mesh.global_position.y
	get_node("mover").add_child(polygon)
	

func build_radar_block(box):
	var radar_faces = Array()
	var box_size = box.shape.size / 2 
	var box_local_vertices = [[box_size.x, box_size.y, box_size.z], [box_size.x, box_size.y, -box_size.z],\
		[box_size.x, -box_size.y, -box_size.z], [box_size.x, -box_size.y, box_size.z],\
		[-box_size.x, box_size.y, box_size.z], [-box_size.x, box_size.y, -box_size.z],\
		[-box_size.x, -box_size.y, box_size.z], [-box_size.x, -box_size.y, -box_size.z]]
	var box_global_vertices = []
	for vertex in box_local_vertices:
		vertex = box.to_global(Vector3(vertex[0],vertex[1],vertex[2]))
		box_global_vertices.append(Vector2(vertex[0],vertex[2]))
			
	if box.global_transform.basis.x.y > 0:
		radar_faces.append([box_global_vertices[1], box_global_vertices[2],\
			box_global_vertices[3], box_global_vertices[0]])
	elif box.global_transform.basis.x.y < 0:
		radar_faces.append([box_global_vertices[7], box_global_vertices[6],\
			box_global_vertices[4], box_global_vertices[5]])
			
	if box.global_transform.basis.y.y > 0:
		radar_faces.append([box_global_vertices[0], box_global_vertices[1],\
			box_global_vertices[5], box_global_vertices[4]])
	elif box.global_transform.basis.y.y < 0:
		radar_faces.append([box_global_vertices[2], box_global_vertices[3],\
			box_global_vertices[6], box_global_vertices[7]])
			
	if box.global_transform.basis.z.y > 0:
		radar_faces.append([box_global_vertices[0], box_global_vertices[3],\
			box_global_vertices[6], box_global_vertices[4]])
	elif box.global_transform.basis.z.y < 0:
		radar_faces.append([box_global_vertices[1], box_global_vertices[2],\
			box_global_vertices[7], box_global_vertices[5]])
			
	for face in radar_faces:
		#print(face)
		var polygon = preload("res://radar_face.tscn").instantiate()
		polygon.set_polygon(PackedVector2Array(face))
		polygon.height = box.global_position.y
		get_node("mover").add_child(polygon)
