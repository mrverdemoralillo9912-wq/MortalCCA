extends CanvasLayer
class_name ShopUI
##
## Shop.gd
## Tienda del patio: permite desbloquear al Profesor y la Directora,
## y comprar herramientas utiles con las monedas ganadas.
##

signal shop_closed()

func open_shop() -> void:
	layer = 10
	_build_ui()

func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.1, 0.93)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 100)
	margin.add_theme_constant_override("margin_right", 100)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	bg.add_child(margin)

	var scroll := ScrollContainer.new()
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var title := Label.new()
	title.text = "Tienda del Patio  -  Monedas: %d" % GameManager.coins
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)

	var chars_title := Label.new()
	chars_title.text = "Personajes"
	chars_title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(chars_title)

	for id in ["conserje", "profesor", "director"]:
		var data: Dictionary = GameManager.CHARACTERS[id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		vbox.add_child(row)

		var label := Label.new()
		var status := ""
		if GameManager.unlocked_characters.get(id, false):
			status = "(Desbloqueado)"
		else:
			status = "(Costo: %d monedas)" % data["unlock_cost"]
		label.text = "%s  %s\n%s" % [data["display_name"], status, data.get("passive_desc", "")]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.custom_minimum_size = Vector2(400, 0)
		row.add_child(label)

		if GameManager.unlocked_characters.get(id, false):
			var select_btn := Button.new()
			select_btn.text = "Seleccionar" if GameManager.selected_character != id else "Seleccionado"
			select_btn.disabled = GameManager.selected_character == id
			select_btn.pressed.connect(func():
				GameManager.selected_character = id
				var player_node: PlayerChar = get_tree().get_first_node_in_group("player") as PlayerChar
				if player_node:
					player_node.set_character(id)
				_build_ui()
			)
			row.add_child(select_btn)
		else:
			var buy_btn := Button.new()
			buy_btn.text = "Comprar"
			buy_btn.disabled = GameManager.coins < data["unlock_cost"]
			buy_btn.pressed.connect(func():
				if GameManager.unlock_character(id):
					_build_ui()
			)
			row.add_child(buy_btn)

	var tools_title := Label.new()
	tools_title.text = "Herramientas"
	tools_title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(tools_title)

	for id in GameManager.TOOLS.keys():
		var tdata: Dictionary = GameManager.TOOLS[id]
		var trow := HBoxContainer.new()
		trow.add_theme_constant_override("separation", 12)
		vbox.add_child(trow)

		var tlabel := Label.new()
		var tstatus := "(Comprado)" if GameManager.owned_tools.get(id, false) else "(Costo: %d monedas)" % tdata["cost"]
		tlabel.text = "%s - %s  %s" % [tdata["label"], tdata["desc"], tstatus]
		tlabel.custom_minimum_size = Vector2(650, 0)
		tlabel.autowrap_mode = TextServer.AUTOWRAP_WORD
		trow.add_child(tlabel)

		if not GameManager.owned_tools.get(id, false):
			var tbuy_btn := Button.new()
			tbuy_btn.text = "Comprar"
			tbuy_btn.disabled = GameManager.coins < tdata["cost"]
			tbuy_btn.pressed.connect(func():
				if GameManager.buy_tool(id):
					_build_ui()
			)
			trow.add_child(tbuy_btn)

	var potions_title := Label.new()
	potions_title.text = "Pociones (para la Mochila en batalla)"
	potions_title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(potions_title)

	for id in GameManager.POTIONS.keys():
		var pdata: Dictionary = GameManager.POTIONS[id]
		var prow := HBoxContainer.new()
		prow.add_theme_constant_override("separation", 12)
		vbox.add_child(prow)

		var pcount: int = int(GameManager.inventory.get(id, 0))
		var plabel := Label.new()
		plabel.text = "%s - %s  (Tienes: %d, Costo: %d monedas)" % [pdata["label"], pdata["desc"], pcount, pdata["cost"]]
		plabel.custom_minimum_size = Vector2(650, 0)
		plabel.autowrap_mode = TextServer.AUTOWRAP_WORD
		prow.add_child(plabel)

		var pbuy_btn := Button.new()
		pbuy_btn.text = "Comprar"
		pbuy_btn.disabled = GameManager.coins < pdata["cost"]
		pbuy_btn.pressed.connect(func():
			if GameManager.buy_potion(id):
				_build_ui()
		)
		prow.add_child(pbuy_btn)

	var close_btn := Button.new()
	close_btn.text = "Cerrar tienda [E]"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(_close)
	vbox.add_child(close_btn)

func is_open() -> bool:
	return get_children().size() > 0

func try_close() -> void:
	_close()

func _close() -> void:
	for c in get_children():
		c.queue_free()
	emit_signal("shop_closed")
