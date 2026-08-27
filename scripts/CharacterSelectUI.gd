extends CanvasLayer
class_name CharacterSelectUI
##
## CharacterSelectUI.gd
## Menu rapido (tecla M) para elegir entre los personajes ya desbloqueados.
## Los personajes bloqueados aparecen atenuados con su costo, recordando
## que se compran en la tienda.
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
	bg.color = Color(0.05, 0.08, 0.1, 0.88)
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
	title.text = "Elige tu personaje"
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for id in ["conserje", "profesor", "director"]:
		var data: Dictionary = GameManager.CHARACTERS[id]
		var row := PanelContainer.new()
		vbox.add_child(row)

		var row_margin := MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 14)
		row_margin.add_theme_constant_override("margin_right", 14)
		row_margin.add_theme_constant_override("margin_top", 10)
		row_margin.add_theme_constant_override("margin_bottom", 10)
		row.add_child(row_margin)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)
		row_margin.add_child(hbox)

		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(70, 90)
		portrait.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists(data["texture"]):
			portrait.texture = load(data["texture"])
		hbox.add_child(portrait)

		var info_box := VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_box)

		var unlocked: bool = GameManager.unlocked_characters.get(id, false)

		var name_label := Label.new()
		name_label.text = data["display_name"]
		name_label.add_theme_font_size_override("font_size", 20)
		info_box.add_child(name_label)

		var stats_label := Label.new()
		stats_label.text = "HP %d   Poder %d" % [data["max_hp"], data["power"]]
		info_box.add_child(stats_label)

		var passive_label := Label.new()
		passive_label.text = data.get("passive_desc", "")
		passive_label.modulate = Color(0.6, 0.9, 1.0)
		passive_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		info_box.add_child(passive_label)

		if not unlocked:
			var lock_label := Label.new()
			lock_label.text = "Bloqueado - cuesta %d monedas en la Tienda" % data["unlock_cost"]
			lock_label.modulate = Color(1, 0.5, 0.5)
			info_box.add_child(lock_label)
			row.modulate = Color(1, 1, 1, 0.55)
		else:
			var select_btn := Button.new()
			var is_selected: bool = GameManager.selected_character == id
			select_btn.text = "Seleccionado" if is_selected else "Elegir"
			select_btn.disabled = is_selected
			select_btn.pressed.connect(func():
				GameManager.selected_character = id
				var player_node: PlayerChar = get_tree().get_first_node_in_group("player") as PlayerChar
				if player_node:
					player_node.set_character(id)
				_build_ui()
			)
			hbox.add_child(select_btn)

	var close_btn := Button.new()
	close_btn.text = "Cerrar [M]"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(close)
	vbox.add_child(close_btn)
