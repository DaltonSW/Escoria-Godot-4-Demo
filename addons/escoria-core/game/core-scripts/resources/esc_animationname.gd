@tool
# Class defining an animation to use for an angle.
extends Resource
class_name ESCAnimationName

# Name of the animation
@export var animation: String

# Animation mirror (false is no mirror, true is mirrored)
@export var mirrored: bool

func _to_string():
	return "ESCAnimationName {animation: %s, mirrored: %s}" % [animation, str(mirrored)]
