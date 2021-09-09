extends Spatial

var debug:bool = true

func _ready():
	var path_parts = $NavParts.get_children()
	for i in range(0, path_parts.size()):
		var points
		if i == path_parts.size() - 1:
			points = $Navigation.\
				get_simple_path(path_parts[i].global_transform.origin, \
								path_parts[0].global_transform.origin)
		else:
			points = $Navigation.\
				get_simple_path(path_parts[i].global_transform.origin, \
								path_parts[i + 1].global_transform.origin)
		
		for point in points:
			var pos_point:Position3D = Position3D.new()
			pos_point.global_transform.origin = point
			$Nav.add_child(pos_point, true)
			if debug:
				var referenceMesh = MeshInstance.new()
				var sphere = SphereMesh.new()
				sphere.radius = .5
				sphere.height = 1
				referenceMesh.mesh = sphere
				referenceMesh.visible = true
				referenceMesh.global_transform.origin = point
				$Scenario.add_child(referenceMesh)
	
	var path_positions = $Waypoints/PathWay
	path_positions.curve.clear_points()
	for path_pos in $Nav.get_children():
		path_positions.curve.add_point(path_pos.global_transform.origin)
	$Players/Car/RigidBody.move_out()
	pass # Replace with function body.

