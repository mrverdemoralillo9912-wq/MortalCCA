extends CanvasLayer
class_name DialogueUI
##
## Dialogue.gd
## Muestra el dialogo de reflexion con un nino luego de derrotarlo,
## y entrega la recompensa en monedas.
##

signal dialogue_finished()

var _continue_cb: Callable = Callable()

func show_reflection(kid: Kid) -> void:
	layer = 10
	_build_box(func(vbox: VBoxContainer):
		var title := Label.new()
		title.text = "Reflexion con el nino"
		title.add_theme_font_size_override("font_size", 18)
		vbox.add_child(title)

		var line: String = GameManager.REFLECTION_LINES[randi() % GameManager.REFLECTION_LINES.size()]
		var body := Label.new()
		body.text = "\"" + line + "\""
		body.add_theme_font_size_override("font_size", 22)
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(body)

		var reward := randi_range(6, 14)
		var reward_label := Label.new()
		reward_label.text = "Recompensa: +%d monedas" % reward
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_label.modulate = Color(1, 0.85, 0.3)
		vbox.add_child(reward_label)

		var continue_btn := Button.new()
		continue_btn.text = "Continuar [E]"
		continue_btn.custom_minimum_size = Vector2(0, 40)
		var finish_cb := func(): _finish(kid, reward)
		continue_btn.pressed.connect(finish_cb)
		vbox.add_child(continue_btn)
		_continue_cb = finish_cb
	)

func is_open() -> bool:
	return get_children().size() > 0

func try_continue() -> void:
	if _continue_cb.is_valid():
		_continue_cb.call()

func _finish(kid: Kid, reward: int) -> void:
	for c in get_children():
		c.queue_free()
	_continue_cb = Callable()
	if is_instance_valid(kid):
		kid.on_reflected(reward)
	emit_signal("dialogue_finished")

func show_ally_greeting(kid: Kid, bonus: int) -> void:
	layer = 10
	_build_box(func(vbox: VBoxContainer):
		var body := Label.new()
		if bonus > 0:
			body.text = "\"Gracias por ayudarme antes. Toma, encontre %d monedas mientras cuidaba el patio! Adios!\"" % bonus
		else:
			body.text = "\"Ya te ayude por hoy. Adios!\""
		body.add_theme_font_size_override("font_size", 20)
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(body)

		var continue_btn := Button.new()
		continue_btn.text = "Continuar [E]"
		continue_btn.custom_minimum_size = Vector2(0, 40)
		var finish_ally := func():
			for c in get_children():
				c.queue_free()
			_continue_cb = Callable()
			if is_instance_valid(kid):
				kid.leave_map()
			emit_signal("dialogue_finished")
		continue_btn.pressed.connect(finish_ally)
		vbox.add_child(continue_btn)
		_continue_cb = finish_ally
	)

## Construye el fondo oscuro + panel centrado, y llama a populate_fn(vbox)
## para que cada tipo de dialogo agregue su propio contenido.
func _build_box(populate_fn: Callable) -> void:
	for c in get_children():
		c.queue_free()

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	populate_fn.call(vbox)
