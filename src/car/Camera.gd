tool
extends Camera

var t = 0.18
var roam = false

var look_back:bool = false

func _ready():
	pass

func _process(delta):
	var ref = $"../CarBody/CameraPivot/CameraRef".global_transform.origin
	var lookref = $"../CarBody/CameraLookRef".global_transform.origin
	global_transform.origin = global_transform.origin.linear_interpolate(ref, t)
	look_at(lookref, Vector3.UP)
	pass
