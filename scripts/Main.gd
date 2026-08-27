extends Node2D
##
## Main.gd
## Escena principal: el patio de juego. Orquesta al jugador, los ninos,
## la basura, el basurero, la tienda, las batallas y el ciclo de dias.
##

enum Mode { EXPLORE, BATTLE, DIALOGUE, SHOP, SUMMARY, CHAR_SELECT, ACHIEVEMENTS }

const PLAYGROUND_BOUNDS := Rect2(45, 130, 1190, 545)
const RECESS_DURATION := 75.0 # segundos reales por receso

var mode: int = Mode.EXPLORE

var player: PlayerChar
var hud: GameHUD
var battle_overlay: BattleUI
var dialogue_overlay: DialogueUI
var shop_overlay: ShopUI
var pause_overlay: PauseUI
var char_select_overlay: CharacterSelectUI
var ko_overlay: KOUI
var achievements_overlay: AchievementsUI

var kids: Array[Kid] = []
var trash_items: Array[TrashItem] = []

var bin_position: Vector2 = Vector2(1095, 195)
var shop_position: Vector2 = Vector2(115, 180)

var _recess_time_left: float = RECESS_DURATION
var _recess_label: Label
var _cleared_message_shown: bool = false

func _ready() -> void:
	add_to_group("main")
	randomize()
	_build_background()
	_build_bin()
	_build_shop_marker()

	player = PlayerChar.new()
	add_child(player)
	player.position = Vector2(640, 400)
	player.set_bounds(PLAYGROUND_BOUNDS)

	hud = GameHUD.new()
	add_child(hud)
	hud.update_trash(0, GameManager.get_carry_capacity())

	battle_overlay = BattleUI.new()
	add_child(battle_overlay)
	battle_overlay.battle_finished.connect(_on_battle_finished)

	dialogue_overlay = DialogueUI.new()
	add_child(dialogue_overlay)
	dialogue_overlay.dialogue_finished.connect(_on_dialogue_finished)

	shop_overlay = ShopUI.new()
	add_child(shop_overlay)
	shop_overlay.shop_closed.connect(_on_shop_closed)

	pause_overlay = PauseUI.new()
	add_child(pause_overlay)

	char_select_overlay = CharacterSelectUI.new()
	add_child(char_select_overlay)
	char_select_overlay.closed.connect(_on_char_select_closed)

	ko_overlay = KOUI.new()
	add_child(ko_overlay)
	ko_overlay.knockout_finished.connect(_on_knockout_finished)

	achievements_overlay = AchievementsUI.new()
	add_child(achievements_overlay)
	achievements_overlay.closed.connect(_on_achievements_closed)
	hud.achievements_pressed.connect(_on_achievements_pressed)

	_recess_time_left = RECESS_DURATION
	_spawn_kids_for_recess()
	_show_recess_banner()

func _build_background() -> void:
	var bg_tex := TextureRect.new()
	bg_tex.texture = load("res://assets/background/patio_bg.png")
	bg_tex.position = Vector2(0, 0)
	bg_tex.size = Vector2(1280, 720)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg_tex)

	var title_bg := ColorRect.new()
	title_bg.color = Color(0, 0, 0, 0.35)
	title_bg.position = Vector2(415, 14)
	title_bg.size = Vector2(430, 34)
	add_child(title_bg)

	var title := Label.new()
	title.text = "Mortal CCA - Patio del Instituto"
	title.add_theme_font_size_override("font_size", 22)
	title.position = Vector2(430, 20)
	add_child(title)

	var recess_bg := ColorRect.new()
	recess_bg.color = Color(0, 0, 0, 0.35)
	recess_bg.position = Vector2(985, 14)
	recess_bg.size = Vector2(280, 34)
	add_child(recess_bg)

	_recess_label = Label.new()
	_recess_label.add_theme_font_size_override("font_size", 18)
	_recess_label.modulate = Color(1, 0.9, 0.5)
	_recess_label.position = Vector2(1000, 20)
	add_child(_recess_label)

func _build_bin() -> void:
	var bin := Node2D.new()
	bin.position = bin_position
	add_child(bin)
	var sprite := Sprite2D.new()
	var tex_path := "res://assets/trash/trash_044.png"
	if ResourceLoader.exists(tex_path):
		var tex := load(tex_path)
		sprite.texture = tex
		var target_h := 110.0
		var s: float = target_h / tex.get_size().y
		sprite.scale = Vector2(s, s)
		sprite.offset = Vector2(0, -tex.get_size().y / 2.0)
	bin.add_child(sprite)
	var label := Label.new()
	label.text = "Basurero"
	label.position = Vector2(-35, 6)
	bin.add_child(label)

func _build_shop_marker() -> void:
	var kiosk := Node2D.new()
	kiosk.position = shop_position
	add_child(kiosk)
	var sprite := Sprite2D.new()
	var tex_path := "res://assets/ui/tienda_stall.png"
	if ResourceLoader.exists(tex_path):
		var tex := load(tex_path)
		sprite.texture = tex
		var target_h := 135.0
		var s: float = target_h / tex.get_size().y
		sprite.scale = Vector2(s, s)
		sprite.offset = Vector2(0, -tex.get_size().y / 2.0)
	kiosk.add_child(sprite)

# ---------------------------------------------------------------------------
# GENERACION DE NINOS
# ---------------------------------------------------------------------------
func _spawn_kids_for_recess() -> void:
	_cleared_message_shown = false
	for k in kids:
		if is_instance_valid(k):
			k.queue_free()
	kids.clear()

	var params: Dictionary = GameManager.get_difficulty_params()
	var count: int = randi_range(params["min_kids"], params["max_kids"])

	for i in count:
		var type_id := "normal"
		if randf() < params["problematic_chance"]:
			var special_types := ["veloz", "basurero", "fuerte"]
			type_id = special_types[randi() % special_types.size()]
		_spawn_kid(type_id, false)

	# posibilidad de que un nino reformado regrese como aliado
	if GameManager.reformed_kid_memory.size() > 0 and randf() < 0.35:
		var ally_type: String = GameManager.reformed_kid_memory[randi() % GameManager.reformed_kid_memory.size()]
		_spawn_kid(ally_type, true)

func _spawn_kid(type_id: String, reformed: bool) -> void:
	var kid: Kid = Kid.new()
	add_child(kid)
	kid.position = Vector2(
		randf_range(PLAYGROUND_BOUNDS.position.x + 40, PLAYGROUND_BOUNDS.position.x + PLAYGROUND_BOUNDS.size.x - 40),
		randf_range(PLAYGROUND_BOUNDS.position.y + 40, PLAYGROUND_BOUNDS.position.y + PLAYGROUND_BOUNDS.size.y - 40)
	)
	kid.setup(type_id, GameManager.current_day, PLAYGROUND_BOUNDS, reformed)
	kid.wants_battle.connect(_on_kid_wants_battle)
	kids.append(kid)

# ---------------------------------------------------------------------------
# BASURA
# ---------------------------------------------------------------------------
func spawn_trash_at(pos: Vector2) -> void:
	var item: TrashItem = TrashItem.new()
	add_child(item)
	item.position = Vector2(
		clampf(pos.x, PLAYGROUND_BOUNDS.position.x, PLAYGROUND_BOUNDS.position.x + PLAYGROUND_BOUNDS.size.x),
		clampf(pos.y, PLAYGROUND_BOUNDS.position.y, PLAYGROUND_BOUNDS.position.y + PLAYGROUND_BOUNDS.size.y)
	)
	trash_items.append(item)

# ---------------------------------------------------------------------------
# PROCESO PRINCIPAL
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if mode == Mode.EXPLORE:
		_recess_time_left -= delta
		_recess_label.text = "Tiempo de receso: %d s" % int(max(_recess_time_left, 0))
		if _recess_time_left <= 0:
			_end_recess()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if pause_overlay.is_open():
			pause_overlay.close()
		else:
			pause_overlay.open()
		return
	if get_tree().paused:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		if char_select_overlay.is_open():
			char_select_overlay.close()
		elif mode == Mode.EXPLORE:
			mode = Mode.CHAR_SELECT
			char_select_overlay.open()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_handle_interact()

func _handle_interact() -> void:
	match mode:
		Mode.EXPLORE:
			_try_explore_interactions()
		Mode.DIALOGUE:
			dialogue_overlay.try_continue()
		Mode.SHOP:
			shop_overlay.try_close()
			mode = Mode.EXPLORE
		Mode.SUMMARY:
			_advance_summary()
		_:
			pass

func _advance_summary() -> void:
	var cleared := get_node_or_null("ClearedOverlay")
	if cleared:
		cleared.queue_free()
		_end_recess()
		return
	_close_summary()

func _try_explore_interactions() -> void:
	# 1) nino esperando reflexion
	for k in kids:
		if not is_instance_valid(k):
			continue
		if k.state == 2 and player.position.distance_to(k.position) < 70: # AWAITING_REFLECTION
			mode = Mode.DIALOGUE
			dialogue_overlay.show_reflection(k)
			return
		if k.state == 4 and player.position.distance_to(k.position) < 70: # ALLY
			mode = Mode.DIALOGUE
			var bonus: int = k.give_ally_bonus()
			dialogue_overlay.show_ally_greeting(k, bonus)
			return

	# 2) basura cercana para recoger
	var capacity := GameManager.get_carry_capacity()
	if player.carried_trash < capacity:
		for t in trash_items:
			if not is_instance_valid(t):
				continue
			if player.position.distance_to(t.position) < GameManager.get_pickup_radius():
				trash_items.erase(t)
				t.queue_free()
				player.carried_trash += 1
				GameManager.total_trash_collected += 1
				hud.update_trash(player.carried_trash, capacity)
				return

	# 3) basurero cercano para depositar
	if player.position.distance_to(bin_position) < 90 and player.carried_trash > 0:
		var earned := player.carried_trash * 2
		GameManager.add_coins(earned)
		player.carried_trash = 0
		hud.update_trash(0, capacity)
		return

	# 4) tienda cercana
	if player.position.distance_to(shop_position) < 90:
		mode = Mode.SHOP
		shop_overlay.open_shop()
		return

	# 5) retar a un nino a batalla
	for k in kids:
		if not is_instance_valid(k):
			continue
		if k.state == 0 and player.position.distance_to(k.position) < 85: # WANDER
			if k.try_start_battle():
				return

func _on_kid_wants_battle(kid) -> void:
	mode = Mode.BATTLE
	battle_overlay.start_battle(kid)

func _on_battle_finished(_won: bool) -> void:
	mode = Mode.EXPLORE
	_check_kids_cleared()

func _on_dialogue_finished() -> void:
	mode = Mode.EXPLORE
	_check_kids_cleared()

func _on_shop_closed() -> void:
	mode = Mode.EXPLORE

func _on_char_select_closed() -> void:
	mode = Mode.EXPLORE

func _on_achievements_pressed() -> void:
	if mode == Mode.EXPLORE:
		mode = Mode.ACHIEVEMENTS
		achievements_overlay.open()

func _on_achievements_closed() -> void:
	mode = Mode.EXPLORE

func trigger_knockout() -> void:
	ko_overlay.start()

func _on_knockout_finished() -> void:
	if player:
		player.battle_hp = player.battle_max_hp
	mode = Mode.EXPLORE

## Revisa si ya no queda ningun nino disponible para retar ni en batalla.
## Si es asi, muestra el mensaje de felicitaciones una sola vez por receso.
func _check_kids_cleared() -> void:
	if _cleared_message_shown:
		return
	if kids.is_empty():
		return
	var any_active := false
	for k in kids:
		if is_instance_valid(k) and (k.state == 0 or k.state == 1): # WANDER o IN_BATTLE
			any_active = true
			break
	if not any_active:
		_cleared_message_shown = true
		_show_cleared_message()

func _show_cleared_message() -> void:
	mode = Mode.SUMMARY
	var overlay := ColorRect.new()
	overlay.name = "ClearedOverlay"
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	add_child(overlay)

	var label := Label.new()
	label.add_theme_font_size_override("font_size", 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(290, 300)
	label.size = Vector2(700, 120)
	label.text = "Ya no hay ninos en el patio, Felicidades.\n\nPresiona E para continuar."
	overlay.add_child(label)

# ---------------------------------------------------------------------------
# CICLO DE DIA / RECESO
# ---------------------------------------------------------------------------
func _end_recess() -> void:
	mode = Mode.SUMMARY
	var result := GameManager.next_recess_or_day()
	for t in trash_items:
		if is_instance_valid(t):
			t.queue_free()
	trash_items.clear()

	_show_summary(result)

func _show_summary(result: String) -> void:
	var overlay := ColorRect.new()
	overlay.name = "SummaryOverlay"
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	add_child(overlay)

	var label := Label.new()
	label.add_theme_font_size_override("font_size", 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(340, 300)
	label.size = Vector2(600, 120)
	if result == "recess2":
		label.text = "Fin del receso 1.\nMonedas actuales: %d\n\nPresiona E para el receso 2." % GameManager.coins
	else:
		label.text = "Fin del dia %d.\nMonedas actuales: %d\n\nPresiona E para comenzar el dia %d." % [GameManager.current_day - 1, GameManager.coins, GameManager.current_day]
	overlay.add_child(label)
	set_meta("summary_result", result)

func _close_summary() -> void:
	var overlay := get_node_or_null("SummaryOverlay")
	if overlay:
		overlay.queue_free()
	hud.update_day_info()
	_recess_time_left = RECESS_DURATION
	_spawn_kids_for_recess()
	mode = Mode.EXPLORE

func _show_recess_banner() -> void:
	hud.update_day_info()
