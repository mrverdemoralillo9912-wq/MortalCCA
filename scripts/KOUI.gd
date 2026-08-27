extends CanvasLayer
class_name KOUI
##
## KOUI.gd
## Pantalla de "Te noquearon". Pausa todo el juego (incluido el tiempo)
## durante 3 minutos reales y luego restaura la vida automaticamente.
##

signal knockout_finished()

const WAIT_SECONDS := 180.0

var _time_left: float = WAIT_SECONDS
var _timer_label: Label
var _active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25

func start() -> void:
	_time_left = WAIT_SECONDS
	_active = true
	get_tree().paused = true
	_build_ui()

func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "¡Te noquearon!"
	title.add_theme_font_size_override("font_size", 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1, 0.4, 0.4)
	vbox.add_child(title)

	var msg := Label.new()
	msg.text = "Espera 3 minutos para recuperar vida y seguir jugando."
	msg.add_theme_font_size_override("font_size", 20)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg)

	_timer_label = Label.new()
	_timer_label.add_theme_font_size_override("font_size", 34)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.modulate = Color(1, 0.9, 0.5)
	vbox.add_child(_timer_label)

	_update_label()

func _update_label() -> void:
	var m: int = int(_time_left) / 60
	var s: int = int(_time_left) % 60
	_timer_label.text = "%01d:%02d" % [m, s]

func _process(delta: float) -> void:
	if not _active:
		return
	_time_left = maxf(0.0, _time_left - delta)
	_update_label()
	if _time_left <= 0.0:
		_finish()

func _finish() -> void:
	_active = false
	for c in get_children():
		c.queue_free()
	get_tree().paused = false
	emit_signal("knockout_finished")
