class_name VictoryBurst
extends CanvasLayer

signal burst_finished

@onready var flash_rect: ColorRect = get_node_or_null("FlashRect")
@onready var shockwave_ring: Line2D = get_node_or_null("ShockwaveRing")

var _is_playing: bool = false

func _ready() -> void:
	visible = false
	if flash_rect != null:
		flash_rect.modulate.a = 0.0
		flash_rect.visible = false
	if shockwave_ring != null:
		shockwave_ring.visible = false

func play_burst(duration: float = 0.4) -> void:
	if _is_playing:
		return
	_is_playing = true
	visible = true

	if flash_rect != null:
		flash_rect.visible = true
		flash_rect.modulate = Color(1.0, 1.0, 1.0, 0.6)

	if shockwave_ring != null:
		shockwave_ring.visible = true
		shockwave_ring.scale = Vector2.ZERO
		shockwave_ring.modulate = Color(1.0, 1.0, 1.0, 0.9)

	var tween: Tween = create_tween()
	if tween == null:
		_on_burst_complete()
		return

	tween.set_parallel(true)

	if flash_rect != null:
		tween.tween_property(flash_rect, "modulate:a", 0.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	if shockwave_ring != null:
		var target_scale: float = 40.0
		tween.tween_property(shockwave_ring, "scale", Vector2(target_scale, target_scale), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(shockwave_ring, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN_OUT)

	tween.chain().tween_callback(_on_burst_complete)

func _on_burst_complete() -> void:
	_is_playing = false
	visible = false
	if flash_rect != null:
		flash_rect.visible = false
		flash_rect.modulate.a = 0.0
	if shockwave_ring != null:
		shockwave_ring.visible = false
		shockwave_ring.scale = Vector2.ONE
	burst_finished.emit()
