extends Control

signal upgrade_selected(upgrade_id: String)

const UPGRADES: Dictionary = {
	"damage": {
		"name": "⚡  레이저 출력 강화",
		"desc": "총알 피해량 +30%",
		"color": Color(0.0, 0.7, 1.0)
	},
	"fire_rate": {
		"name": "🔥  연사 속도 강화",
		"desc": "발사 속도 +25%",
		"color": Color(1.0, 0.5, 0.1)
	},
	"speed": {
		"name": "🚀  추진 엔진 강화",
		"desc": "이동 속도 +20%",
		"color": Color(0.3, 0.85, 1.0)
	},
	"max_hp": {
		"name": "🛡️  함선 실드 강화",
		"desc": "최대 실드 +40  즉시 회복",
		"color": Color(0.1, 0.8, 0.5)
	},
	"bullet_speed": {
		"name": "💨  레이저 속도 강화",
		"desc": "총알 속도 +25%",
		"color": Color(0.6, 0.3, 1.0)
	},
	"multi_shot": {
		"name": "✨  다중 레이저",
		"desc": "동시 발사 수 +1",
		"color": Color(1.0, 0.85, 0.1)
	},
	"magnet": {
		"name": "🧲  에너지 흡수기",
		"desc": "에너지 수집 범위 +60%",
		"color": Color(0.2, 1.0, 0.6)
	}
}

var _pending: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible      = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

func request_show() -> void:
	_pending += 1
	if _pending == 1:
		_build_and_show()

func _build_and_show() -> void:
	_clear_children()
	_build_ui()
	visible = true
	get_tree().paused = true

func _clear_children() -> void:
	for c in get_children():
		c.queue_free()

func _build_ui() -> void:
	# 반투명 우주 배경
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.82)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 제목
	var title := _make_label("⭐  함선 업그레이드  ⭐", 36, Color(0.3, 0.9, 1.0))
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.position              = Vector2(-240, 95)
	title.size                  = Vector2(480, 54)
	title.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var sub := _make_label("업그레이드를 선택하세요", 17, Color(0.65, 0.85, 0.95))
	sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	sub.position             = Vector2(-200, 155)
	sub.size                 = Vector2(400, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	# 카드 3장
	var keys := UPGRADES.keys()
	keys.shuffle()
	var chosen := keys.slice(0, 3)

	var card_w  := 175.0
	var gap     := 17.5
	var total_w := card_w * 3.0 + gap * 2.0
	var start_x := (1280.0 - total_w) / 2.0
	var card_y  := 208.0

	for i in chosen.size():
		var card := _make_card(chosen[i], UPGRADES[chosen[i]], card_w)
		card.position = Vector2(start_x + i * (card_w + gap), card_y)
		add_child(card)

func _make_card(id: String, data: Dictionary, w: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(w, 272)

	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.03, 0.05, 0.13)
	sb.border_color = data.color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.content_margin_left   = 10
	sb.content_margin_right  = 10
	sb.content_margin_top    = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# 색상 아이콘 영역
	var icon := ColorRect.new()
	icon.color               = data.color.darkened(0.52)
	icon.custom_minimum_size = Vector2(w - 20, 68)
	vbox.add_child(icon)

	# 이름
	var n_lbl := _make_label(data.name, 14, Color.WHITE)
	n_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	vbox.add_child(n_lbl)

	# 설명
	var d_lbl := _make_label(data.desc, 13, Color(0.7, 0.85, 0.9))
	d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	vbox.add_child(d_lbl)

	# 선택 버튼
	var btn := Button.new()
	btn.text = "장착"
	btn.add_theme_font_size_override("font_size", 16)
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = data.color.darkened(0.28)
	btn_sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", btn_sb)
	btn.add_theme_stylebox_override("hover",  btn_sb)
	btn.pressed.connect(func() -> void: _on_selected(id))
	vbox.add_child(btn)

	return panel

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _on_selected(id: String) -> void:
	emit_signal("upgrade_selected", id)
	_pending -= 1
	if _pending > 0:
		_build_and_show()
	else:
		visible = false
		get_tree().paused = false
