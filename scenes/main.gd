class_name MainLauncher
extends Control

func _ready() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	print("[MainLauncher] Viewport initialized: ", vp_size)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		print("[MainLauncher] Touch event: index=", touch.index, " pos=", touch.position, " pressed=", touch.pressed)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		print("[MainLauncher] Drag event: index=", drag.index, " pos=", drag.position, " relative=", drag.relative)
