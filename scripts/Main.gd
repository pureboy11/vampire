extends Node2D

const PLAYER_SCENE         = preload("res://scenes/Player.tscn")
const ENEMY_SCENE          = preload("res://scenes/Enemy.tscn")
const LEVEL_UP_POPUP_SCENE = preload("res://scenes/LevelUpPopup.tscn")

var player: Node2D       = null
var game_time: float     = 0.0
var spawn_timer: float   = 0.0
var spawn_interval: float = 2.0
var is_game_over: bool   = false

var hp_bar:       ProgressBar
var xp_bar:       ProgressBar
var level_label:  Label
var time_label:   Label
var level_up_popup: Node

const GRID_SIZE  := 64
const GRID_COLOR := Color(0.18, 0.18, 0.22, 1.0)

func _ready() -> void:
	_setup_ui()
	_spawn_player()
	_setup_popup()

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Node2D
	player.global_position = Vector2.ZERO
	add_child(player)
	player.connect("xp_updated",        _on_xp_updated)
	player.connect("level_up_triggered", _on_level_up)
	player.connect("hp_updated",        _on_hp_updated)
	player.connect("player_died",       _on_player_died)
	_on_hp_updated(player.get("current_hp"), player.get("max_hp"))
	_on_xp_updated(player.get("current_xp"), player.get("xp_to_level"))

func _setup_popup() -> void:
	level_up_popup = LEVEL_UP_POPUP_SCENE.instantiate()
	$UILayer.add_child(level_up_popup)
	level_up_popup.connect("upgrade_selected", _on_upgrade_selected)

func _setup_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UILayer"
	add_child(layer)

	# HP 배경
	layer.add_child(_colored_rect(Vector2(10, 12), Vector2(220, 22), Color(0.15, 0.15, 0.15)))

	hp_bar = ProgressBar.new()
	hp_bar.position        = Vector2(10, 12)
	hp_bar.size            = Vector2(220, 22)
	hp_bar.min_value       = 0
	hp_bar.max_value       = 100
	hp_bar.value           = 100
	hp_bar.show_percentage = false
	var hp_sb := StyleBoxFlat.new()
	hp_sb.bg_color = Color(0.9, 0.15, 0.15)
	hp_bar.add_theme_stylebox_override("fill", hp_sb)
	layer.add_child(hp_bar)

	var hp_lbl := _make_label("❤ HP", 13, Color.WHITE)
	hp_lbl.position = Vector2(14, 13)
	layer.add_child(hp_lbl)

	# XP 배경
	layer.add_child(_colored_rect(Vector2(10, 40), Vector2(220, 16), Color(0.15, 0.15, 0.15)))

	xp_bar = ProgressBar.new()
	xp_bar.position        = Vector2(10, 40)
	xp_bar.size            = Vector2(220, 16)
	xp_bar.min_value       = 0
	xp_bar.max_value       = 10
	xp_bar.value           = 0
	xp_bar.show_percentage = false
	var xp_sb := StyleBoxFlat.new()
	xp_sb.bg_color = Color(0.3, 0.6, 1.0)
	xp_bar.add_theme_stylebox_override("fill", xp_sb)
	layer.add_child(xp_bar)

	level_label = _make_label("Lv. 1", 16, Color(1.0, 0.9, 0.2))
	level_label.position = Vector2(238, 36)
	layer.add_child(level_label)

	time_label = _make_label("00:00", 26, Color.WHITE)
	time_label.position = Vector2(590, 10)
	layer.add_child(time_label)

func _physics_process(delta: float) -> void:
	if is_game_over:
		return

	game_time   += delta
	spawn_timer += delta

	var m: int = int(game_time / 60.0)
	var s: int = int(fmod(game_time, 60.0))
	time_label.text = "%02d:%02d" % [m, s]

	if spawn_timer >= spawn_interval:
		spawn_timer    = 0.0
		_spawn_enemies()
		spawn_interval = max(0.25, spawn_interval - 0.015)

func _spawn_enemies() -> void:
	if player == null or not is_instance_valid(player):
		return
	var count: int = 1 + int(game_time / 30.0)
	for _i in range(count):
		_spawn_one_enemy()

func _spawn_one_enemy() -> void:
	var vp: Vector2     = get_viewport().get_visible_rect().size
	var center: Vector2 = player.global_position
	var margin: float   = 120.0
	var hw: float       = vp.x / 2.0 + margin
	var hh: float       = vp.y / 2.0 + margin

	var pos: Vector2
	match randi() % 4:
		0: pos = center + Vector2(randf_range(-hw, hw), -hh)
		1: pos = center + Vector2(randf_range(-hw, hw),  hh)
		2: pos = center + Vector2(-hw, randf_range(-hh, hh))
		_: pos = center + Vector2( hw, randf_range(-hh, hh))

	var enemy := ENEMY_SCENE.instantiate()
	add_child(enemy)
	enemy.global_position = pos

	var scale_f: float = 1.0 + game_time / 60.0
	enemy.set("max_hp",    enemy.get("max_hp")    * scale_f)
	enemy.set("current_hp", enemy.get("max_hp"))
	enemy.set("damage",    enemy.get("damage")    * scale_f)
	enemy.set("speed",     min(160.0, enemy.get("speed") + game_time * 0.4))
	enemy.set("xp_value",  max(1, int(scale_f)))

func _on_xp_updated(current: int, required: int) -> void:
	xp_bar.max_value = required
	xp_bar.value     = current

func _on_level_up() -> void:
	level_label.text = "Lv. %d" % player.get("level")
	level_up_popup.request_show()

func _on_hp_updated(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value     = current

func _on_upgrade_selected(id: String) -> void:
	if player and is_instance_valid(player):
		player.call("apply_upgrade", id)

func _on_player_died() -> void:
	is_game_over = true
	_show_game_over()

func _show_game_over() -> void:
	var layer: Node = $UILayer

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)

	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(390, 240)
	panel.size     = Vector2(500, 240)
	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.08, 0.08, 0.12)
	sb.border_color = Color(0.9, 0.1, 0.1)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	var title := _make_label("게 임  오 버", 40, Color(1.0, 0.2, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var t_lbl := _make_label("생존 시간: %s" % time_label.text, 22, Color.WHITE)
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(t_lbl)

	var lv_lbl := _make_label("도달 레벨: %d" % player.get("level"), 20, Color(1.0, 0.9, 0.3))
	lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lv_lbl)

	var btn := Button.new()
	btn.text = "다시 시작"
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(func() -> void: get_tree().reload_current_scene())
	vbox.add_child(btn)

# ── 배경 격자 ─────────────────────────────────────────
func _draw() -> void:
	if player == null or not is_instance_valid(player):
		return

	var vp: Vector2      = get_viewport().get_visible_rect().size
	var cam_pos: Vector2 = player.global_position
	var half_w: float    = vp.x / 2.0 + float(GRID_SIZE)
	var half_h: float    = vp.y / 2.0 + float(GRID_SIZE)
	var left: float      = cam_pos.x - half_w
	var top: float       = cam_pos.y - half_h
	var right: float     = cam_pos.x + half_w
	var bottom: float    = cam_pos.y + half_h

	var x_start: float = floor(left  / float(GRID_SIZE)) * float(GRID_SIZE)
	var y_start: float = floor(top   / float(GRID_SIZE)) * float(GRID_SIZE)

	var x: float = x_start
	while x <= right:
		draw_line(Vector2(x, top), Vector2(x, bottom), GRID_COLOR, 1.0)
		x += float(GRID_SIZE)

	var y: float = y_start
	while y <= bottom:
		draw_line(Vector2(left, y), Vector2(right, y), GRID_COLOR, 1.0)
		y += float(GRID_SIZE)

func _process(_delta: float) -> void:
	queue_redraw()

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _colored_rect(pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size     = sz
	r.color    = col
	return r
