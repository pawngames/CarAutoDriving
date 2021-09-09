extends RigidBody

var BASE_DEF:float = 7.0

var MULT_DEF:float = BASE_DEF
var MULT_MAX:float = MULT_DEF*1.4
var DEG_TURN:float = MULT_DEF/2000
var PATH_TURN_THRES:float = MULT_DEF*4.5
var TURN_PRECISION:float = DEG_TURN
var RAND_THRES:float = 1.8
var ANG_DRIFT:float = 30.0

var forcemult = MULT_DEF
var accel:bool = false
var brake:bool = false

var enabled = true

var positionPath:PathFollow
var pathRef:Path

var player = true
var referenceMesh:MeshInstance

var last_offset = 1
var correct_direction:bool

var path = []
var pathMain = []
var pathAlt = []
var path_index = 0

var left_check:RayCast
var front_check:RayCast
var right_check:RayCast
var body_check:RayCast

var body
var driver_body
var nav
var vel

var stuck = false
var stuck_time:int = 0

var ang_global = 0

var debug = false
var mesh_dbg:CylinderMesh

var debounce = 0

var joystick_mult:float = 1.0

func _ready():
	move_out()
	left_check = $"../CarBody/RayCastLeft"
	front_check = $"../CarBody/RayCastFront"
	right_check = $"../CarBody/RayCastRight"
	body_check = $"../CarBody/RayCast"
	body = $"../CarBody"
	nav = $"../NavRef"
	vel = $"../VelRef"
	mesh_dbg = $"../CarBody/NAV_DEBUG".mesh
	pass

func _initialize_race_positioning():
	pathRef = $"../../../Waypoints/PathWay"
	#Adds position reference path
	positionPath = PathFollow.new()
	positionPath.loop = true
	pathRef.add_child(positionPath)
	
	#Creates reference mesh (for debug purposes)
	if debug:
		referenceMesh = MeshInstance.new()
		var material:SpatialMaterial = SpatialMaterial.new()
		randomize()
		var color = Color(randf(), randf(), randf())
		material.albedo_color = color
		#body.material_override = material
		referenceMesh.set_surface_material(0, material)
		var sphere = SphereMesh.new()
		sphere.radius = 1
		sphere.height = 2
		sphere.material = material
		referenceMesh.mesh = sphere
		referenceMesh.visible = true
		positionPath.add_child(referenceMesh)
	pass

func _process(delta):
	pass

func _physics_process(delta):
	#$"../Camera/UI".visible = player
	
	if not enabled:
		return
	
	var left = false
	var right = false
	
	var direction:Vector3 = body.transform.basis.z
	
	var linear_xz = Vector2(linear_velocity.x, linear_velocity.z)
	var dir_xz = Vector2(direction.x, direction.z)
	ang_global = -rad2deg(linear_xz.angle_to(dir_xz))
	if ang_global > 0:
		ang_global -= 180
	elif ang_global < 0:
		ang_global += 180
	
	vel.rotation_degrees.y = ang_global
	
	var vel_l = linear_velocity.length()
	
	#AUTONAV---------------------------------
	#Ponto de ajuste de dificuldade
	#forcemult += 1
	#Ponto de ajuste de dificuldade
	TURN_PRECISION = DEG_TURN*4
	
	if path.size() > 0 and path_index < path.size():
		accel = true
		#Referencias
		var nav = $"../NavRef"

		var path_next = path[path_index]
		# Precisamos somente da diferença em XY
		var distV:Vector3 = (path_next - global_transform.origin)
		distV.y = 0;
		var dist = distV.length()
		
		#Olha para o vetor e pega só a dif em y
		nav.look_at(path_next, Vector3.UP)
		nav.rotation.x = 0
		nav.rotation.z = 0
		
		if abs(nav.rotation.y) > deg2rad(ANG_DRIFT):
			nav.rotation.y += deg2rad(ang_global)/1.8
		else:
			nav.rotation.y += deg2rad(ang_global)/2.8
		
		var ang_vec = nav.rotation - body.rotation
		ang_vec = nav.rotation - body.rotation
		
		var ang_dir = rad2deg(ang_vec.y)
		if ang_dir > 300:
			ang_dir -= 360
		if ang_dir < -300:
			ang_dir += 360
		
		#Turned beyond threshold
		#if ang_dir > PATH_TURN_THRES or ang_dir < -PATH_TURN_THRES:
		#	accel = false
		
		#Adjusts course as necessary
		if ang_dir > 1:
			left = true
		elif ang_dir < -1:
			right = true
		else:
			right = false
			left = false
		
		#Collision avoidance code
		#Prioritized over path finding
		#Adjusts raycasts angle and lenght according to speed
		#thumb rule applies big time
		var angle_ray = 45 - vel_l*1.6
		var lenght_ray = -2.2 - vel_l
		left_check.rotation_degrees.y = angle_ray
		right_check.rotation_degrees.y = -angle_ray
		front_check.cast_to.y = lenght_ray
		left_check.cast_to.y = lenght_ray
		right_check.cast_to.y = lenght_ray
		
		
		#Selects only one to avoid deadlock
		if left_check.is_colliding():
			left = false# and correct_direction
			right = true# and not correct_direction
			accel = true
		elif right_check.is_colliding():
			left = true and correct_direction
			right = false and not correct_direction
			accel = true
		
		#if stuck, goes back to clear path and continue
		if  (front_check.is_colliding() and vel_l < 2) or \
			(left_check.is_colliding() and right_check.is_colliding() \
			 and vel_l < 2):
			if stuck_time == 0:
				stuck_time = OS.get_ticks_msec()
				print("preso")
			if OS.get_ticks_msec() - stuck_time > 3000:
				reset_position()
			accel = false
			brake = true
		
		#Adjusting path
		var trhes = 3 + vel_l/2
		
		if debug:
			mesh_dbg.top_radius = trhes
			mesh_dbg.bottom_radius = trhes
	
		#Next point in path
		if dist < trhes:
			path_index += 1
			if path_index < path.size():
				randomize()
				var xRand = randf()*RAND_THRES*2 - RAND_THRES
				var zRand = randf()*RAND_THRES*2 - RAND_THRES
				path[path_index] = path[path_index] + Vector3(xRand, 0.0, zRand)
		#Back to the beginning for another lap
		if path_index >= path.size():
			path_index = 0
	else:
		print("Parar")

	var turn_base = TURN_PRECISION
	
	if left:
		var amount = turn_base*abs(joystick_mult)
		body.rotation.y += amount
	elif right:
		var amount = turn_base*abs(joystick_mult)
		body.rotation.y -= amount
	
func _integrate_forces(state):
	if body_check.is_colliding():
		var position = Vector3(0,0,0)
		var direction = body.transform.basis.z
		if accel:
			state.apply_central_impulse(-direction * forcemult)
		elif brake:
			state.apply_central_impulse(direction * forcemult/2)
		else:
			linear_velocity = linear_velocity.linear_interpolate(Vector3(0,0,0), 0.001)
		
		if linear_velocity.length() > 10:
			#Resistencia lateral
			var direction_side = body.transform.basis.x
			state.apply_central_impulse(direction * (-abs(ang_global)/10))
			#Mantem momento dentro da curva
			state.apply_central_impulse(direction_side * (-ang_global/12))
	pass

func process_bot():
	var vel_l = linear_velocity.length()

func move_out():
	if $"../../../Nav" == null:
		return
	#Initialization of grid paths
	#Path origin has to match Gridmap origin, sorry
	$"../NavMeshes".global_transform.origin = Vector3(50.0, 0.0, 86.6)
	var path_positions = $"../../../Nav".get_children()
	for pos in path_positions:
		var path_next = pos.global_transform.origin
		pathMain.append(path_next)
	
	path = pathMain

func reset_position():
	if not player:
		joystick_mult == 1
	var reset_pos = pathRef.curve.get_closest_point(global_transform.origin)
	reset_pos.y += 3
	global_transform.origin = reset_pos
	pass

func _on_Area_area_entered(area:Area):
	if area.has_method("collided_with_player"):
		if player:
			Input.start_joy_vibration(0, 0.5, 0, 0.1)
		print("collided")
		var dir = area.global_transform.origin.direction_to(global_transform.origin)
		dir.y = 0
		apply_central_impulse(dir*600)
	pass # Replace with function body.
