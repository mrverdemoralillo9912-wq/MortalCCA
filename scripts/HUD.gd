extends CanvasLayer
class_name GameHUD
##
## HUD.gd
## Interfaz superior: monedas, dia, receso, basura cargada, apodo,
## boton de logros y aviso emergente al desbloquear uno.
##

signal achievements_pressed()

var _coins_label: Label
var _day_label: Label
var _trash_label: Label
var _hint_label: Label
var _sun_icon: TextureRect
var _toast_label: Label
var _toast_bg: ColorRect
var _toast_timer: float = 0.0

func _ready() -> void:
	layer = 5
	var panel := PanelContainer.new()
	panel.position = Vector2(10, 10)
	add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	_coins_label = Label.new()
	_coins_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_coins_label)

	var day_row := HBoxContainer.new()
	day_row.add_theme_constant_override("separation", 6)
	vbox.add_child(day_row)

	_sun_icon = TextureRect.new()
	_sun_icon.custom_minimum_size = Vector2(22, 22)
	_sun_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_sun_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists("res://assets/ui/sun.png"):
		_sun_icon.texture = load("res://assets/ui/sun.png")
	day_row.add_child(_sun_icon)

	_day_label = Label.new()
	_day_label.add_theme_font_size_override("font_size", 16)
	day_row.add_child(_day_label)

	_trash_label = Label.new()
	_trash_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_trash_label)

	var achievements_btn := Button.new()
	achievements_btn.text = "🏆 Logros"
	achievements_btn.position = Vector2(1120, 60)
	achievements_btn.size = Vector2(150, 40)
	achievements_btn.pressed.connect(func(): achievements_pressed.emit())
	add_child(achievements_btn)

	var toast_bg := ColorRect.new()
	toast_bg.color = Color(0, 0, 0, 0.55)
	toast_bg.position = Vector2(290, 75)
	toast_bg.size = Vector2(700, 60)
	toast_bg.visible = false
	add_child(toast_bg)
	_toast_bg = toast_bg

	_toast_label = Label.new()
	_toast_label.add_theme_font_size_override("font_size", 20)
	_toast_label.modulate = Color(1, 0.85, 0.3)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_toast_label.position = Vector2(290, 75)
	_toast_label.size = Vector2(700, 60)
	_toast_label.visible = false
	add_child(_toast_label)

	_hint_label = Label.new()
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.modulate = Color(1, 1, 0.7)
	_hint_label.position = Vector2(10, 690)
	_hint_label.text = "WASD/Flechas: moverse   E: interactuar   M: personaje   F11: pantalla completa   ESC: pausa"
	add_child(_hint_label)

	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.day_changed.connect(_on_day_changed)
	GameManager.achievement_unlocked.connect(_on_achievement_unlocked)
	_refresh()

func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast_label.visible = false
			_toast_bg.visible = false

func _on_achievement_unlocked(id: String) -> void:
	var data: Dictionary = GameManager.ACHIEVEMENTS.get(id, {})
	_toast_label.text = "🏆 Logro desbloqueado: %s\n%s" % [data.get("title", id), data.get("desc", "")]
	_toast_label.visible = true
	_toast_bg.visible = true
	_toast_timer = 5.5

func _refresh() -> void:
	_coins_label.text = "💰 Monedas: %d" % GameManager.coins
	_day_label.text = "Dia %d - Receso %d/2" % [GameManager.current_day, GameManager.recess_index]

func _on_coins_changed(_new_amount: int) -> void:
	_refresh()

func _on_day_changed(_new_day: int) -> void:
	_refresh()

func update_trash(carried: int, max_carry: int) -> void:
	_trash_label.text = "🗑 Basura: %d/%d" % [carried, max_carry]

func update_day_info() -> void:
	_refresh()
