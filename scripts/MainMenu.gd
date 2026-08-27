extends Control
##
## MainMenu.gd
## Menu principal de Mortal CCA. Permite comenzar una partida nueva,
## continuar una guardada, digitalizar el apodo del jugador, y salir.
##

var _nickname_popup: PanelContainer
var _nickname_edit: LineEdit
var _nickname_display: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists("res://assets/ui/title_screen.png"):
		bg.texture = load("res://assets/ui/title_screen.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.28)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.position.y = 90
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 30)
	pad.add_theme_constant_override("margin_right", 30)
	pad.add_theme_constant_override("margin_top", 24)
	pad.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(pad)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	pad.add_child(vbox)

	_nickname_display = Label.new()
	_nickname_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nickname_display.modulate = Color(1, 0.9, 0.5)
	_update_nickname_display()
	vbox.add_child(_nickname_display)

	var start_btn := Button.new()
	start_btn.text = "Comenzar Nuevo Juego"
	start_btn.custom_minimum_size = Vector2(320, 50)
	start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(start_btn)

	if GameManager.has_save():
		var continue_btn := Button.new()
		continue_btn.text = "Continuar"
		continue_btn.custom_minimum_size = Vector2(320, 50)
		continue_btn.pressed.connect(_on_continue_pressed)
		vbox.add_child(continue_btn)

	var nickname_btn := Button.new()
	nickname_btn.text = "Digitaliza tu Apodo"
	nickname_btn.custom_minimum_size = Vector2(320, 50)
	nickname_btn.pressed.connect(_on_nickname_pressed)
	vbox.add_child(nickname_btn)

	var exit_btn := Button.new()
	exit_btn.text = "Salir"
	exit_btn.custom_minimum_size = Vector2(320, 50)
	exit_btn.pressed.connect(_on_exit_pressed)
	vbox.add_child(exit_btn)

	_build_nickname_popup()

func _update_nickname_display() -> void:
	_nickname_display.text = "Apodo actual: %s" % GameManager.nickname

func _build_nickname_popup() -> void:
	_nickname_popup = PanelContainer.new()
	_nickname_popup.visible = false
	_nickname_popup.set_anchors_preset(Control.PRESET_CENTER)
	_nickname_popup.custom_minimum_size = Vector2(420, 160)
	add_child(_nickname_popup)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 20)
	pad.add_theme_constant_override("margin_right", 20)
	pad.add_theme_constant_override("margin_top", 20)
	pad.add_theme_constant_override("margin_bottom", 20)
	_nickname_popup.add_child(pad)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	pad.add_child(vbox)

	var label := Label.new()
	label.text = "Escribe tu apodo:"
	vbox.add_child(label)

	_nickname_edit = LineEdit.new()
	_nickname_edit.placeholder_text = "Tu apodo aqui..."
	_nickname_edit.max_length = 16
	vbox.add_child(_nickname_edit)

	var confirm_btn := Button.new()
	confirm_btn.text = "Confirmar"
	confirm_btn.pressed.connect(_on_confirm_nickname)
	vbox.add_child(confirm_btn)

func _on_nickname_pressed() -> void:
	_nickname_edit.text = GameManager.nickname
	_nickname_popup.visible = true

func _on_confirm_nickname() -> void:
	var text := _nickname_edit.text.strip_edges()
	if text != "":
		GameManager.nickname = text
	_update_nickname_display()
	_nickname_popup.visible = false

func _on_start_pressed() -> void:
	GameManager.reset_new_game()
	GameManager.unlock_achievement("bienvenido")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_continue_pressed() -> void:
	GameManager.load_game()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
