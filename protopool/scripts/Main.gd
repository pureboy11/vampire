extends Node2D

const PLAYER_SCENE         = preload("res://scenes/Player.tscn")
const ENEMY_SCENE          = preload("res://scenes/Enemy.tscn")
const LEVEL_UP_POPUP_SCENE = preload("res://scenes/LevelUpPopup.tscn")

# ── 게임 상태 ────────────────────────────────────────
var player: Node2D        = null
var game_time: float      = 0.0
var spawn_timer: float    = 0.0
var spawn_interval: float = 2.0
var is_game_over: bool    = false
var kill_count: int       = 0

# ── UI 참조 ──────────────────────────────────────────
var hp_bar:      ProgressBar
var xp_bar:      ProgressBar
var level_label: Label
var time_label:  Label
var kill_label:  Label
var level_up_popup: Node

# ── 별 배경 데이터 ────────────────────────────────────
var _stars: Array[Dictionary] = []
const STAR_COUNT := 280

func _ready() -> void:
	randomize()
	_init_stars()
	_setup_ui()
	_spawn_player()
	_setup_popup()

# ── 별 초기화 ─────────────────────────────────────────
func _init_stars() -> void:
	var vp := get_viewport().get_visible_rect().size
	for i in STAR_COUNT:
		_stars.append({
			"pos":    Vector2(randf_range(0.0, vp.x), randf_range(0.0, vp.y)),
			"size":   randf_range(0.5, 2.8),
			"bright": randf_range(0.25, 1.0),
			"phase":  randf() * TAU,
			"spd":    randf_range(0.8, 2.5),
		})

# ── 플레이어 스폰 ─────────────────────────────────────
func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.global_position = Vector2.ZERO
	add_child(player)

	player.xp_updated.connect(_on_xp_updated)
	player.level_up_triggered.connect(_on_level_up)
	player.hp_updated.connect(_on_hp_updated)
	player.player_died.connect(_on_player_died)

	_on_hp_updated(player.current_hp, player.max_hp)
	_on_xp_updated(player.current_xp, player.xp_to_level)

func _setup_popup() -> void:
	level_up_popup = LEVEL_UP_POPUP_SCENE.instantiate()
	$UILayer.add_child(level_up_popup)
	level_up_popup.upgrade_selected.connect(_on_upgrade_selected)

# ── UI 생성 ───────────────────────────────────────────
func _setup_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UILayer"
	add_child(layer)

	# ─ 실드 바 (HP) ─
	layer.add_child(_colored_rect(Vector2(10, 12), Vector2(220, 22), Color(0.06, 0.06, 0.14)))
	hp_bar = _make_bar(Vector2(10, 12), Vector2(220, 22), 100.0, Color(0.1, 0.7, 1.0))
	layer.add_child(hp_bar)
	var hp_lbl := _make_label("SHIELD", 11, Color(0.5, 0.85, 1.0))
	hp_lbl.position = Vector2(14, 15)
	layer.add_child(hp_lbl)

	# ─ 에너지 바 (XP) ─
	layer.add_child(_colored_rect(Vector2(10, 40), Vector2(220, 14), Color(0.06, 0.06, 0.14)))
	xp_bar = _make_bar(Vector2(10, 40), Vector2(220, 14), 10.0, Color(0.0, 0.85, 0.55))
	layer.add_child(xp_bar)

	# ─ 등급 ─
	level_label = _make_label("등급  I", 15, Color(0.3, 1.0, 0.7))
	level_label.position = Vector2(238, 35)
	layer.add_child(level_label)

	# ─ 생존 시간 (상단 중앙) ─
	time_label = _make_label("00:00", 26, Color.WHITE)
	time_label.position = Vector2(590, 10)
	layer.add_child(time_label)

	# ─ 격파 수 ─
	kill_label = _make_label("격파: 0", 17, Color(1.0, 0.78, 0.2))
	kill_label.position = Vector2(593, 44)
	layer.add_child(kill_label)

# ── 게임 루프 ────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if is_game_over:
		return

	game_time   += delta
	spawn_timer += delta

	var m := int(game_time / 60.0)
	var s := int(fmod(game_time, 60.0))
	time_label.text = "%02d:%02d" % [m, s]
	kill_label.text = "격파: %d" % kill_count

	if spawn_timer >= spawn_interval:
		spawn_timer    = 0.0
		_spawn_enemies()
		spawn_interval = max(0.25, spawn_interval - 0.012)

# ── 적 스폰 ──────────────────────────────────────────
func _spawn_enemies() -> void:
	if player == null or not is_instance_valid(player):
		return
	var count := 1 + int(game_time / 30.0)
	for _i in range(count):
		_spawn_one_enemy()

func _spawn_one_enemy() -> void:
	var vp     := get_viewport().get_visible_rect().size
	var center := player.global_position
	var hw     := vp.x / 2.0 + 130.0
	var hh     := vp.y / 2.0 + 130.0

	var side := randi() % 4
	var pos: Vector2
	match side:
		0: pos = center + Vector2(randf_range(-hw, hw), -hh)
		1: pos = center + Vector2(randf_range(-hw, hw),  hh)
		2: pos = center + Vector2(-hw, randf_range(-hh, hh))
		3: pos = center + Vector2( hw, randf_range(-hh, hh))

	var enemy = ENEMY_SCENE.instantiate()

	# 시간에 따른 적 타입 확률
	var roll := randf()
	if   game_time > 120.0 and roll < 0.20:
		enemy.enemy_type = "ufo"
	elif game_time > 45.0  and roll < 0.40:
		enemy.enemy_type = "dart"
	else:
		enemy.enemy_type = "alien"

	add_child(enemy)
	enemy.global_position = pos

	# 난이도 스케일링
	var sf := 1.0 + game_time / 60.0
	enemy.max_hp     = enemy.max_hp * sf
	enemy.current_hp = enemy.max_hp
	enemy.damage     = enemy.damage * sf
	enemy.speed      = min(enemy.speed + game_time * 0.3, enemy.speed * 1.5)
	# kill_count 연결
	enemy.tree_exited.connect(func() -> void: kill_count += 1)

# ── 신호 처리 ────────────────────────────────────────
func _on_xp_updated(current: int, required: int) -> void:
	xp_bar.max_value = required
	xp_bar.value     = current

func _on_level_up() -> void:
	level_label.text = "등급  %s" % _roman(player.level)
	level_up_popup.request_show()

func _on_hp_updated(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value     = current

func _on_upgrade_selected(id: String) -> void:
	if player and is_instance_valid(player):
		player.apply_upgrade(id)

func _on_player_died() -> void:
	is_game_over = true
	_show_game_over()

# ── 게임 오버 ─────────────────────────────────────────
func _show_game_over() -> void:
	var layer  := $UILayer
	var final_level: int = 1
	if is_instance_valid(player):
		final_level = int(player.level)


	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)

	var panel := Panel.new()
	panel.position = Vector2(390, 210)
	panel.size     = Vector2(500, 300)
	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.02, 0.03, 0.10)
	sb.border_color = Color(0.1, 0.55, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", sb)
	layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	for pair in [
		["함선 격파됨", 36, Color(0.2, 0.7, 1.0)],
		["생존 시간: %s" % time_label.text,   20, Color.WHITE],
		["격파 수: %d"   % kill_count,         18, Color(1.0, 0.85, 0.25)],
		["최종 등급: %s" % _roman(final_level), 18, Color(0.3, 1.0, 0.7)],
	]:
		var lbl := _make_label(pair[0], pair[1], pair[2])
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl)

	var btn := Button.new()
	btn.text = "재출격"
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(func() -> void: get_tree().reload_current_scene())
	vbox.add_child(btn)

# ── 우주 배경 드로잉 ──────────────────────────────────
func _draw() -> void:
	if player == null or not is_instance_valid(player):
		return

	var t    := Time.get_ticks_msec() * 0.001
	var vp   := get_viewport().get_visible_rect().size
	var cam  := player.global_position
	var half := vp * 0.5

	# 심우주 배경
	draw_rect(Rect2(cam - half, vp), Color(0.01, 0.01, 0.05))

	# 성운 (세계 고정 위치)
	draw_circle(Vector2(600,  400), 320, Color(0.04, 0.0,  0.12, 0.14))
	draw_circle(Vector2(-800,-300), 260, Color(0.0,  0.04, 0.15, 0.11))
	draw_circle(Vector2(200, -700), 200, Color(0.03, 0.02, 0.10, 0.09))

	# 별 (시차 타일링)
	for s in _stars:
		var px := fposmod(s.pos.x - cam.x * 0.06, vp.x)
		var py := fposmod(s.pos.y - cam.y * 0.06, vp.y)
		var world := cam - half + Vector2(px, py)
		var b: float = s["bright"] * (0.55 + 0.45 * sin(t * s["spd"] + s["phase"]))
		draw_circle(world, s.size, Color(b, b, b + 0.05))

func _process(_delta: float) -> void:
	queue_redraw()

# ── 헬퍼 ─────────────────────────────────────────────
func _make_label(text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _colored_rect(pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos;  r.size = sz;  r.color = col
	return r

func _make_bar(pos: Vector2, sz: Vector2, max_val: float, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position        = pos
	bar.size            = sz
	bar.min_value       = 0
	bar.max_value       = max_val
	bar.value           = max_val
	bar.show_percentage = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.corner_radius_top_left     = 3
	sb.corner_radius_top_right    = 3
	sb.corner_radius_bottom_left  = 3
	sb.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", sb)
	return bar

func _roman(n: int) -> String:
	var vals := [10, 9, 5, 4, 1]
	var syms := ["X", "IX", "V", "IV", "I"]
	var res  := ""
	var num  := clampi(n, 1, 39)
	for i in vals.size():
		while num >= vals[i]:
			res += syms[i];  num -= vals[i]
	return res
