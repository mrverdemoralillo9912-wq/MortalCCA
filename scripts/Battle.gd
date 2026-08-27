extends CanvasLayer
class_name BattleUI
##
## Battle.gd
## Sistema de batalla por turnos estilo Pokemon. El menu principal tiene
## 3 botones: Luchar (abre las 4 habilidades), Mochila (usar pociones) y
## Huir. Si el jugador llega a 0 de vida, dispara el KO de 3 minutos en
## Main.gd.
##

signal battle_finished(won: bool)

var _kid: Kid = null
var _player_data: Dictionary
var _player_hp: int
var _player_max_hp: int
var _kid_hp: int
var _kid_max_hp: int
var _busy: bool = false
var _power_boost_active: bool = false

var _log_label: Label
var _player_hp_bar: ProgressBar
var _kid_hp_bar: ProgressBar
var _menu_area: Control
var _player_name_label: Label
var _kid_name_label: Label

func start_battle(kid: Kid) -> void:
	_kid = kid
	_busy = false
	_power_boost_active = false
	_player_data = GameManager.CHARACTERS[GameManager.selected_character]

	var player_node: PlayerChar = get_tree().get_first_node_in_group("player") as PlayerChar
	_player_max_hp = player_node.battle_max_hp
	_player_hp = player_node.battle_hp
	_kid_max_hp = kid.max_hp
	_kid_hp = kid.hp

	_build_scene()
	_show_main_menu()
	_update_bars()
	_log("Un %s salvaje aparecio." % GameManager.KID_TYPES[kid.kid_type]["label"])

func _build_scene() -> void:
	layer = 10
	for c in get_children():
		c.queue_free()

	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.75, 0.85)
	bg.position = Vector2(0, 0)
	bg.size = Vector2(1280, 400)
	add_child(bg)

	var ground := ColorRect.new()
	ground.color = Color(0.45, 0.6, 0.35)
	ground.position = Vector2(0, 260)
	ground.size = Vector2(1280, 140)
	add_child(ground)

	var lower_bg := ColorRect.new()
	lower_bg.color = Color(0.08, 0.1, 0.13)
	lower_bg.position = Vector2(0, 400)
	lower_bg.size = Vector2(1280, 320)
	add_child(lower_bg)

	# --- plataforma + sprite del oponente (arriba a la derecha, mas chico) ---
	var platform_tex: Texture2D = null
	if ResourceLoader.exists("res://assets/ui/battle_platform.png"):
		platform_tex = load("res://assets/ui/battle_platform.png")

	var kid_platform := TextureRect.new()
	kid_platform.position = Vector2(865, 175)
	kid_platform.size = Vector2(220, 80)
	kid_platform.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	kid_platform.texture = platform_tex
	add_child(kid_platform)

	var kid_sprite := TextureRect.new()
	kid_sprite.position = Vector2(880, 15)
	kid_sprite.size = Vector2(190, 190)
	kid_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var kid_tex_path: String = _kid.texture_path
	if kid_tex_path != "" and ResourceLoader.exists(kid_tex_path):
		kid_sprite.texture = load(kid_tex_path)
	add_child(kid_sprite)

	var kid_panel := PanelContainer.new()
	kid_panel.position = Vector2(40, 20)
	kid_panel.size = Vector2(320, 62)
	add_child(kid_panel)
	var kid_vbox := VBoxContainer.new()
	kid_panel.add_child(kid_vbox)
	_kid_name_label = Label.new()
	_kid_name_label.text = GameManager.KID_TYPES[_kid.kid_type]["label"] + " problematico"
	_kid_name_label.add_theme_font_size_override("font_size", 16)
	kid_vbox.add_child(_kid_name_label)
	_kid_hp_bar = ProgressBar.new()
	_kid_hp_bar.max_value = _kid_max_hp
	kid_vbox.add_child(_kid_hp_bar)

	# --- plataforma + sprite del jugador (abajo a la izquierda, mas grande) ---
	var player_platform := TextureRect.new()
	player_platform.position = Vector2(30, 320)
	player_platform.size = Vector2(300, 100)
	player_platform.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player_platform.texture = platform_tex
	add_child(player_platform)

	var player_sprite := TextureRect.new()
	player_sprite.position = Vector2(50, 130)
	player_sprite.size = Vector2(260, 260)
	player_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(_player_data["texture"]):
		player_sprite.texture = load(_player_data["texture"])
	add_child(player_sprite)

	var player_panel := PanelContainer.new()
	player_panel.position = Vector2(700, 230)
	player_panel.size = Vector2(320, 62)
	add_child(player_panel)
	var player_vbox := VBoxContainer.new()
	player_panel.add_child(player_vbox)
	_player_name_label = Label.new()
	_player_name_label.text = _player_data["display_name"]
	_player_name_label.add_theme_font_size_override("font_size", 16)
	player_vbox.add_child(_player_name_label)
	_player_hp_bar = ProgressBar.new()
	_player_hp_bar.max_value = _player_max_hp
	player_vbox.add_child(_player_hp_bar)

	# --- caja de mensaje ---
	_log_label = Label.new()
	_log_label.position = Vector2(30, 410)
	_log_label.size = Vector2(1220, 70)
	_log_label.add_theme_font_size_override("font_size", 19)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_log_label)

	# --- zona de menus (principal, habilidades o mochila) ---
	_menu_area = Control.new()
	_menu_area.position = Vector2(30, 490)
	_menu_area.size = Vector2(1220, 210)
	add_child(_menu_area)

func _update_bars() -> void:
	_player_hp_bar.value = _player_hp
	_kid_hp_bar.value = _kid_hp

func _log(msg: String) -> void:
	_log_label.text = msg

func _clear_menu() -> void:
	for c in _menu_area.get_children():
		c.queue_free()

## Menu principal: Luchar / Mochila / Huir.
func _show_main_menu() -> void:
	_clear_menu()
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.size = _menu_area.size
	_menu_area.add_child(grid)

	var fight_btn := Button.new()
	fight_btn.text = "Luchar"
	fight_btn.custom_minimum_size = Vector2(385, 90)
	fight_btn.add_theme_font_size_override("font_size", 22)
	fight_btn.pressed.connect(_show_ability_menu)
	grid.add_child(fight_btn)

	var bag_btn := Button.new()
	bag_btn.text = "Mochila"
	bag_btn.custom_minimum_size = Vector2(385, 90)
	bag_btn.add_theme_font_size_override("font_size", 22)
	bag_btn.pressed.connect(_show_bag_menu)
	grid.add_child(bag_btn)

	var flee_btn := Button.new()
	flee_btn.text = "Huir"
	flee_btn.custom_minimum_size = Vector2(385, 90)
	flee_btn.add_theme_font_size_override("font_size", 22)
	flee_btn.pressed.connect(_on_flee_pressed)
	grid.add_child(flee_btn)

## Muestra las 4 habilidades del personaje elegido, mas un boton Volver.
func _show_ability_menu() -> void:
	if _busy:
		return
	_clear_menu()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.size = _menu_area.size
	_menu_area.add_child(grid)

	for ability in _player_data["abilities"]:
		var btn := Button.new()
		var hits: int = int(ability.get("hits", 1))
		var hits_tag := "  (x%d golpes)" % hits if hits > 1 else ""
		btn.text = "%s (Poder %d)%s" % [ability["name"], ability["power"], hits_tag]
		btn.custom_minimum_size = Vector2(590, 44)
		btn.pressed.connect(func(): _on_ability_pressed(ability))
		grid.add_child(btn)

	var back_btn := Button.new()
	back_btn.text = "Volver"
	back_btn.custom_minimum_size = Vector2(590, 44)
	back_btn.pressed.connect(_show_main_menu)
	grid.add_child(back_btn)

## Muestra las pociones disponibles en la mochila.
func _show_bag_menu() -> void:
	if _busy:
		return
	_clear_menu()
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size = _menu_area.size
	_menu_area.add_child(vbox)

	for id in GameManager.POTIONS.keys():
		var data: Dictionary = GameManager.POTIONS[id]
		var count: int = int(GameManager.inventory.get(id, 0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		vbox.add_child(row)

		var label := Label.new()
		label.text = "%s x%d - %s" % [data["label"], count, data["desc"]]
		label.custom_minimum_size = Vector2(850, 0)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		row.add_child(label)

		var use_btn := Button.new()
		use_btn.text = "Usar"
		use_btn.disabled = count <= 0
		use_btn.pressed.connect(func(): _on_use_potion(id))
		row.add_child(use_btn)

	var back_btn := Button.new()
	back_btn.text = "Volver"
	back_btn.custom_minimum_size = Vector2(0, 40)
	back_btn.pressed.connect(_show_main_menu)
	vbox.add_child(back_btn)

func _on_use_potion(id: String) -> void:
	if _busy:
		return
	if not GameManager.use_potion(id):
		return
	var data: Dictionary = GameManager.POTIONS[id]
	_busy = true
	_clear_menu()

	if id == "pocion_curacion":
		var heal: int = int(data["heal"])
		_player_hp = mini(_player_max_hp, _player_hp + heal)
		_log("Usaste una Pocion de Curacion. Recuperaste %d de vida." % heal)
	elif id == "pocion_fuerza":
		_power_boost_active = true
		_log("Usaste una Pocion de Fuerza. Tu proximo ataque sera mas poderoso.")
	_update_bars()
	await get_tree().create_timer(1.0).timeout

	await _kid_turn()
	if _player_hp <= 0:
		_lose_battle()
		return

	_busy = false
	_show_main_menu()

func _on_flee_pressed() -> void:
	if _busy:
		return
	_finish_battle(false, true)

func _on_ability_pressed(ability: Dictionary) -> void:
	if _busy:
		return
	_busy = true
	_clear_menu()

	# el nino veloz tiene prioridad: ataca primero
	if _kid.kid_type == "veloz":
		await _kid_turn()
		if _player_hp <= 0:
			_lose_battle()
			return
		await _player_turn(ability)
		if _kid_hp <= 0:
			_win_battle()
			return
	else:
		await _player_turn(ability)
		if _kid_hp <= 0:
			_win_battle()
			return
		await _kid_turn()
		if _player_hp <= 0:
			_lose_battle()
			return

	_busy = false
	_show_main_menu()

func _player_turn(ability: Dictionary) -> void:
	var hits: int = int(ability.get("hits", 1))
	var accuracy: float = ability.get("accuracy", 0.95)
	var boost: float = 1.6 if _power_boost_active else 1.0
	var total_dmg := 0
	var connected := 0
	for i in hits:
		if randf() <= accuracy:
			var dmg := int(ability["power"] * randf_range(0.85, 1.2) * boost)
			total_dmg += dmg
			connected += 1
	_kid_hp = maxi(0, _kid_hp - total_dmg)
	_power_boost_active = false

	if connected == 0:
		_log("%s uso %s... pero fallo!" % [_player_data["display_name"], ability["name"]])
	elif hits > 1:
		_log("%s uso %s! Conecto %d golpes por %d de dano en total." % [_player_data["display_name"], ability["name"], connected, total_dmg])
	else:
		_log("%s uso %s! Hizo %d de dano." % [_player_data["display_name"], ability["name"], total_dmg])
	_update_bars()
	await get_tree().create_timer(1.0).timeout

func _kid_turn() -> void:
	var kid_ability: Dictionary = _kid.get_random_ability()
	var k_accuracy: float = kid_ability.get("accuracy", 0.9)
	var k_hit: bool = randf() <= k_accuracy
	if k_hit:
		var kdmg := int(kid_ability["power"] * randf_range(0.85, 1.2))
		_player_hp = maxi(0, _player_hp - kdmg)
		_log("El nino uso %s! Recibiste %d de dano." % [kid_ability["name"], kdmg])
	else:
		_log("El nino uso %s... pero fallo!" % kid_ability["name"])
	_update_bars()
	await get_tree().create_timer(1.0).timeout

func _win_battle() -> void:
	_log("¡Ganaste! El nino esta listo para reflexionar. Acercate y presiona E.")
	_kid.hp = 0
	_kid.on_battle_lost_by_kid()
	var player_node: PlayerChar = get_tree().get_first_node_in_group("player") as PlayerChar
	player_node.battle_hp = _player_hp
	await get_tree().create_timer(1.6).timeout
	_finish_battle(true, false)

func _lose_battle() -> void:
	_log("¡Te noquearon!")
	_kid.on_battle_lost_by_player()
	await get_tree().create_timer(1.4).timeout
	var main := get_tree().get_first_node_in_group("main")
	for c in get_children():
		c.queue_free()
	emit_signal("battle_finished", false)
	if main and main.has_method("trigger_knockout"):
		main.trigger_knockout()

func _finish_battle(won: bool, fled: bool) -> void:
	if fled:
		_kid.on_battle_lost_by_player()
	for c in get_children():
		c.queue_free()
	emit_signal("battle_finished", won)
