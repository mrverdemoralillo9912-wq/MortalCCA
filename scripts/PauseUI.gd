extends CanvasLayer
class_name PauseUI
##
## PauseUI.gd
## Menu de pausa (tecla ESC): reanudar, guardar y salir, volumen,
## y reiniciar partida (con confirmacion).
##

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20

func is_open() -> bool:
	return get_children().size() > 0

func open() -> void:
	get_tree().paused = true
	_build_main_panel()

func close() -> void:
	for c in get_children():
		c.queue_free()
	get_tree().paused = false

func _build_main_panel() -> void:
	for c in get_children():
		c.queue_free()

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 340)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Pausa"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var resume_btn := Button.new()
	resume_btn.text = "Reanudar"
	resume_btn.custom_minimum_size = Vector2(0, 42)
	resume_btn.pressed.connect(close)
	vbox.add_child(resume_btn)

	var vol_label := Label.new()
	vol_label.text = "Volumen"
	vbox.add_child(vol_label)

	var vol_slider := HSlider.new()
	vol_slider.min_value = 0
	vol_slider.max_value = 100
	vol_slider.step = 1
	vol_slider.value = _get_current_volume_percent()
	vol_slider.value_changed.connect(_on_volume_changed)
	vbox.add_child(vol_slider)

	var save_exit_btn := Button.new()
	save_exit_btn.text = "Guardar y Salir"
	save_exit_btn.custom_minimum_size = Vector2(0, 42)
	save_exit_btn.pressed.connect(_on_save_and_exit)
	vbox.add_child(save_exit_btn)

	var restart_btn := Button.new()
	restart_btn.text = "Reiniciar Juego"
	restart_btn.custom_minimum_size = Vector2(0, 42)
	restart_btn.pressed.connect(_build_restart_confirm)
	vbox.add_child(restart_btn)

func _get_current_volume_percent() -> float:
	var idx := AudioServer.get_bus_index("Master")
	if AudioServer.is_bus_mute(idx):
		return 0.0
	var db := AudioServer.get_bus_volume_db(idx)
	return clampf(db_to_linear(db) * 100.0, 0.0, 100.0)

func _on_volume_changed(value: float) -> void:
	var idx := AudioServer.get_bus_index("Master")
	if value <= 0.0:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(value / 100.0))

func _on_save_and_exit() -> void:
	GameManager.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _build_restart_confirm() -> void:
	for c in get_children():
		c.queue_free()

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 180)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	var msg := Label.new()
	msg.text = "¿De verdad deseas iniciar de nuevo?"
	msg.add_theme_font_size_override("font_size", 20)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row)

	var yes_btn := Button.new()
	yes_btn.text = "Si"
	yes_btn.custom_minimum_size = Vector2(120, 42)
	yes_btn.pressed.connect(_on_confirm_restart)
	row.add_child(yes_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancelar"
	cancel_btn.custom_minimum_size = Vector2(120, 42)
	cancel_btn.pressed.connect(_build_main_panel)
	row.add_child(cancel_btn)

func _on_confirm_restart() -> void:
	GameManager.reset_new_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
