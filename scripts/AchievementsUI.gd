extends CanvasLayer
class_name AchievementsUI
##
## AchievementsUI.gd
## Panel de logros. Muestra todos los logros del juego, marcando cuales
## ya se desbloquearon.
##

signal closed()

func is_open() -> bool:
	return get_children().size() > 0

func open() -> void:
	layer = 15
	_build_ui()

func close() -> void:
	for c in get_children():
		c.queue_free()
	emit_signal("closed")

func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.1, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "🏆 Logros"
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var count_unlocked := 0
	for id in GameManager.ACHIEVEMENTS.keys():
		if GameManager.is_achievement_unlocked(id):
			count_unlocked += 1

	var progress_label := Label.new()
	progress_label.text = "Desbloqueados: %d / %d" % [count_unlocked, GameManager.ACHIEVEMENTS.size()]
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.modulate = Color(1, 0.9, 0.5)
	vbox.add_child(progress_label)

	for id in GameManager.ACHIEVEMENTS.keys():
		var data: Dictionary = GameManager.ACHIEVEMENTS[id]
		var unlocked: bool = GameManager.is_achievement_unlocked(id)

		var row := PanelContainer.new()
		vbox.add_child(row)

		var row_margin := MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 14)
		row_margin.add_theme_constant_override("margin_right", 14)
		row_margin.add_theme_constant_override("margin_top", 10)
		row_margin.add_theme_constant_override("margin_bottom", 10)
		row.add_child(row_margin)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		row_margin.add_child(hbox)

		var icon := Label.new()
		icon.text = "🏆" if unlocked else "🔒"
		icon.add_theme_font_size_override("font_size", 28)
		hbox.add_child(icon)

		var info_box := VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_box)

		var name_label := Label.new()
		name_label.text = data["title"]
		name_label.add_theme_font_size_override("font_size", 19)
		if not unlocked:
			name_label.modulate = Color(0.7, 0.7, 0.7)
		info_box.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = data["desc"]
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.modulate = Color(0.75, 0.8, 0.85) if unlocked else Color(0.55, 0.55, 0.55)
		info_box.add_child(desc_label)

		if not unlocked:
			row.modulate = Color(1, 1, 1, 0.6)

	var close_btn := Button.new()
	close_btn.text = "Cerrar"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(close)
	vbox.add_child(close_btn)
