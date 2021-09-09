extends Spatial

func _ready():
	pass

func _process(delta):
	translation = $"../RigidBody".translation
	translation.y += 1.3
