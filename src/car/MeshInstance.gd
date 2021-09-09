extends MeshInstance

var t = 0.1

func _process(delta):
	translation = $"../RigidBody".translation
	translation.y -= .3
	var ground_normal = Vector3.UP
	if $RayCast.is_colliding():
		ground_normal = $RayCast.get_collision_normal()
	
	transform.basis.y = transform.basis.y.linear_interpolate(ground_normal, t)
	transform.basis.x = transform.basis.x.linear_interpolate(-transform.basis.z.cross(ground_normal), t)
	transform.basis.z = transform.basis.z.linear_interpolate(transform.basis.x.cross(ground_normal), t)
	
	transform.basis = transform.basis.orthonormalized()
	
	pass
