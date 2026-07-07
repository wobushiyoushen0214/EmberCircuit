extends Control

const CombatStateScript = preload("res://scripts/combat/CombatState.gd")
const DataLoaderScript = preload("res://scripts/core/DataLoader.gd")
const SaveManagerScript = preload("res://scripts/core/SaveManager.gd")
const MapGeneratorScript = preload("res://scripts/map/MapGenerator.gd")
const MapViewScript = preload("res://scripts/map/MapView.gd")

const ENEMY_ART_PATHS := {
	"placeholder_soot_raider": "res://assets/art/enemy_soot_raider.svg",
	"placeholder_ash_hound": "res://assets/art/enemy_ash_hound.svg",
	"placeholder_forge_bishop": "res://assets/art/enemy_forge_bishop.svg"
}
const CARD_FRAME_PATHS := {
	"attack": "res://assets/art/card_attack_frame.svg",
	"skill": "res://assets/art/card_skill_frame.svg",
	"power": "res://assets/art/card_power_frame.svg"
}
const POTION_ART_PATH := "res://assets/art/potion_placeholder.svg"

var combat
var selected_enemy_index: int = 0
var card_data: Dictionary = {}
var enemy_data: Dictionary = {}
var relic_data: Dictionary = {}
var potion_data: Dictionary = {}
var encounter_data: Dictionary = {}
var player_data: Dictionary = {}
var economy_data: Dictionary = {}
var route_data: Dictionary = {}
var event_data: Dictionary = {}
var status_data: Dictionary = {}
var map_generation_data: Dictionary = {}

var run_deck_ids: Array = []
var run_relic_ids: Array = []
var run_potion_ids: Array = []
var run_hp: int = 0
var run_max_hp: int = 0
var run_gold: int = 0
var run_completed: bool = false

var route_nodes: Array = []
var current_node_index: int = 0
var map_graph: Dictionary = {}
var current_node_id: String = ""
var available_node_ids: Array[String] = []
var completed_node_ids: Dictionary = {}
var reward_options: Array = []
var relic_reward_options: Array = []
var potion_reward_options: Array = []
var shop_card_options: Array = []
var shop_potion_options: Array = []
var reward_generated_for: String = ""
var shop_generated_for: int = -1
var card_reward_done: bool = false
var relic_reward_done: bool = true
var potion_reward_done: bool = true
var deck_view_open: bool = false

var root_box: VBoxContainer
var run_label: Label
var status_label: Label
var feedback_label: Label
var map_view: Control
var potion_row: HBoxContainer
var enemy_row: HBoxContainer
var hand_row: HBoxContainer
var reward_row: HBoxContainer
var log_label: RichTextLabel
var end_turn_button: Button
var restart_button: Button
var save_button: Button
var load_button: Button
var deck_button: Button
var last_feedback_events: Array = []

func _ready() -> void:
	_build_layout()
	_start_new_run()

func _build_layout() -> void:
	root_box = VBoxContainer.new()
	root_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_box.add_theme_constant_override("separation", 10)
	add_child(root_box)

	var title := Label.new()
	title.text = "EmberCircuit / 余烬回路 - MVP 跑团"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	root_box.add_child(title)

	run_label = Label.new()
	run_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	run_label.add_theme_font_size_override("font_size", 16)
	root_box.add_child(run_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 18)
	root_box.add_child(status_label)

	feedback_label = Label.new()
	feedback_label.text = ""
	feedback_label.visible = false
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.custom_minimum_size = Vector2(0, 38)
	feedback_label.add_theme_font_size_override("font_size", 20)
	feedback_label.add_theme_stylebox_override("normal", _button_style(Color(0.15, 0.16, 0.18), Color(0.44, 0.48, 0.54), 1, 6))
	root_box.add_child(feedback_label)

	map_view = MapViewScript.new()
	map_view.visible = false
	map_view.custom_minimum_size = Vector2(0, 330)
	map_view.node_selected.connect(_on_map_node_pressed)
	root_box.add_child(map_view)

	potion_row = HBoxContainer.new()
	potion_row.custom_minimum_size = Vector2(0, 68)
	potion_row.add_theme_constant_override("separation", 8)
	root_box.add_child(potion_row)

	enemy_row = HBoxContainer.new()
	enemy_row.custom_minimum_size = Vector2(0, 150)
	enemy_row.add_theme_constant_override("separation", 12)
	root_box.add_child(enemy_row)

	log_label = RichTextLabel.new()
	log_label.custom_minimum_size = Vector2(0, 210)
	log_label.fit_content = false
	log_label.scroll_following = true
	root_box.add_child(log_label)

	hand_row = HBoxContainer.new()
	hand_row.custom_minimum_size = Vector2(0, 190)
	hand_row.add_theme_constant_override("separation", 8)
	root_box.add_child(hand_row)

	reward_row = HBoxContainer.new()
	reward_row.custom_minimum_size = Vector2(0, 112)
	reward_row.add_theme_constant_override("separation", 8)
	root_box.add_child(reward_row)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	root_box.add_child(controls)

	end_turn_button = Button.new()
	end_turn_button.text = "结束回合"
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	controls.add_child(end_turn_button)

	restart_button = Button.new()
	restart_button.text = "重开跑团"
	restart_button.pressed.connect(_start_new_run)
	controls.add_child(restart_button)

	save_button = Button.new()
	save_button.text = "保存跑团"
	save_button.pressed.connect(_on_save_pressed)
	controls.add_child(save_button)

	load_button = Button.new()
	load_button.text = "读取跑团"
	load_button.pressed.connect(_on_load_pressed)
	controls.add_child(load_button)

	deck_button = Button.new()
	deck_button.text = "查看牌组"
	deck_button.pressed.connect(_on_deck_view_pressed)
	controls.add_child(deck_button)

func _start_new_run() -> void:
	_load_all_data()

	var player_config: Dictionary = player_data.get("player", {})
	run_deck_ids = card_data.get("starter_deck", {}).get("cards", []).duplicate(true)
	run_relic_ids = relic_data.get("starter_relics", []).duplicate(true)
	run_potion_ids = player_config.get("starting_potions", []).duplicate(true)
	run_max_hp = int(player_config.get("max_hp", 72))
	run_hp = int(player_config.get("starting_hp", run_max_hp))
	run_gold = int(player_config.get("starting_gold", 0))
	run_completed = false
	current_node_index = 0
	current_node_id = ""
	available_node_ids.clear()
	completed_node_ids.clear()
	reward_options.clear()
	relic_reward_options.clear()
	potion_reward_options.clear()
	shop_card_options.clear()
	shop_potion_options.clear()
	reward_generated_for = ""
	shop_generated_for = -1
	card_reward_done = false
	relic_reward_done = true
	potion_reward_done = true
	_build_route()
	_start_current_node()

func _load_all_data() -> void:
	card_data = DataLoaderScript.load_json("res://data/cards/cards.json")
	enemy_data = DataLoaderScript.load_json("res://data/enemies/enemies.json")
	relic_data = DataLoaderScript.load_json("res://data/relics/relics.json")
	potion_data = DataLoaderScript.load_json("res://data/potions/potions.json")
	encounter_data = DataLoaderScript.load_json("res://data/encounters/encounters.json")
	player_data = DataLoaderScript.load_json("res://data/config/player.json")
	economy_data = DataLoaderScript.load_json("res://data/config/economy.json")
	route_data = DataLoaderScript.load_json("res://data/config/chapter_one_route.json")
	event_data = DataLoaderScript.load_json("res://data/events/events.json")
	status_data = DataLoaderScript.load_json("res://data/statuses/statuses.json")
	map_generation_data = DataLoaderScript.load_json("res://data/config/map_generation.json")

func _build_route() -> void:
	var map_config: Dictionary = map_generation_data.get("chapter_one", {})
	map_graph = MapGeneratorScript.generate(map_config)
	route_nodes = _flatten_map_nodes(map_graph)
	if route_nodes.is_empty():
		route_nodes = route_data.get("nodes", []).duplicate(true)
		map_graph = {}
	if route_nodes.is_empty():
		route_nodes = [
			{"id": "fallback_0", "type": "combat", "name": "煤烟巡逻队", "encounter_id": "intro_patrol"},
			{"id": "fallback_1", "type": "campfire", "name": "裂炉营地"},
			{"id": "fallback_2", "type": "shop", "name": "灰市商人"},
			{"id": "fallback_3", "type": "boss", "name": "炉心礼拜堂", "encounter_id": "chapter_one_boss"}
		]
	current_node_id = str(map_graph.get("start_node_id", ""))
	if current_node_id.is_empty() and not route_nodes.is_empty():
		current_node_id = str(route_nodes[0].get("id", "fallback_0"))
	current_node_index = _node_index_by_id(current_node_id)
	available_node_ids = [current_node_id]

func _start_current_node() -> void:
	if current_node_id.is_empty() and not available_node_ids.is_empty():
		combat = null
		_refresh()
		return
	if current_node_id.is_empty() or current_node_index >= route_nodes.size():
		run_completed = true
		combat = null
		_refresh()
		return

	var node: Dictionary = _current_node()
	var node_type: String = str(node.get("type", ""))
	reward_options.clear()
	relic_reward_options.clear()
	potion_reward_options.clear()
	reward_generated_for = ""
	card_reward_done = false
	relic_reward_done = true
	potion_reward_done = true
	selected_enemy_index = 0
	current_node_index = _node_index_by_id(current_node_id)
	available_node_ids.clear()

	if _is_battle_node(node_type):
		var encounter_id: String = str(node.get("encounter_id", "intro_patrol"))
		combat = CombatStateScript.new()
		combat.setup(card_data, enemy_data, relic_data, encounter_data, player_data, encounter_id, run_deck_ids, run_relic_ids, run_hp)
		combat.changed.connect(_refresh)
	else:
		combat = null
	_refresh()

func _refresh() -> void:
	if deck_view_open:
		_refresh_deck_view()
		return

	if run_completed:
		run_label.text = "跑团完成 | 金币：%d | 牌组：%d 张 | 遗物：%s | 药水：%s" % [run_gold, run_deck_ids.size(), ", ".join(run_relic_ids), _potion_summary()]
		status_label.text = "你击败了第一章 Boss。当前实现已完成战斗、奖励、篝火、商店和 Boss 的 MVP 跑团闭环。"
		feedback_label.visible = false
		map_view.visible = false
		_clear_container(potion_row)
		_clear_container(enemy_row)
		_clear_container(hand_row)
		_clear_container(reward_row)
		log_label.text = "胜利结算：下一阶段将加入分叉地图、正式事件、音效、美术资源和更完整的平衡测试。"
		end_turn_button.disabled = true
		return

	if current_node_id.is_empty() and not available_node_ids.is_empty():
		_refresh_map_choices()
		return

	var node: Dictionary = _current_node()
	var node_type: String = str(node.get("type", ""))
	_refresh_run_header(node)

	if _is_battle_node(node_type):
		_refresh_combat()
	elif node_type == "campfire":
		_refresh_campfire(node)
	elif node_type == "shop":
		_refresh_shop(node)
	elif node_type == "event":
		_refresh_event(node)
	else:
		_refresh_unknown_node(node)

func _refresh_run_header(node: Dictionary) -> void:
	run_label.text = "路线 %d/%d：%s [%s] | 金币：%d | 生命：%d/%d | 牌组：%d 张 | 遗物：%s | 药水：%s" % [
		current_node_index + 1,
		route_nodes.size(),
		node.get("name", "节点"),
		node.get("type", ""),
		run_gold,
		run_hp,
		run_max_hp,
		run_deck_ids.size(),
		", ".join(run_relic_ids),
		_potion_summary()
	]

func _refresh_map_choices() -> void:
	run_label.text = "地图选择 | 金币：%d | 生命：%d/%d | 牌组：%d 张 | 遗物：%s | 药水：%s" % [
		run_gold,
		run_hp,
		run_max_hp,
		run_deck_ids.size(),
		", ".join(run_relic_ids),
		_potion_summary()
	]
	status_label.text = "选择下一处节点。当前是分叉地图后端生成的路线；按钮只显示从当前节点可到达的下一层。"
	feedback_label.visible = false
	map_view.visible = true
	map_view.set_map_state(_map_graph_for_view(), available_node_ids, completed_node_ids, current_node_id)
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	log_label.text = _map_legend_text()
	end_turn_button.disabled = true

func _refresh_deck_view() -> void:
	run_label.text = "牌组查看 | 金币：%d | 生命：%d/%d | 牌组：%d 张 | 遗物：%s | 药水：%s" % [
		run_gold,
		run_hp,
		run_max_hp,
		run_deck_ids.size(),
		", ".join(run_relic_ids),
		_potion_summary()
	]
	status_label.text = "当前牌组。升级牌以 + 标记；后续会升级为可悬停详情和排序筛选。"
	feedback_label.visible = false
	map_view.visible = false
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	end_turn_button.disabled = true

	var summary: Dictionary = _deck_summary()
	log_label.text = "牌组统计\n攻击：%d\n技能：%d\n能力：%d\n状态/诅咒：%d\n升级牌：%d\n\n%s" % [
		int(summary.get("attack", 0)),
		int(summary.get("skill", 0)),
		int(summary.get("power", 0)),
		int(summary.get("other", 0)),
		int(summary.get("upgraded", 0)),
		_deck_list_text()
	]

	var close_button := Button.new()
	close_button.custom_minimum_size = Vector2(140, 88)
	close_button.text = "关闭牌组"
	close_button.pressed.connect(_on_close_deck_view_pressed)
	reward_row.add_child(close_button)

func _refresh_combat() -> void:
	if combat == null:
		return
	map_view.visible = false
	status_label.text = "回合 %d | 阶段：%s | 生命：%d/%d | 护甲：%d | 能量：%d/%d | 势能：%d/%d | 抽牌：%d | 弃牌：%d | 消耗：%d" % [
		combat.turn,
		combat.phase,
		int(combat.player.get("hp", 0)),
		int(combat.player.get("max_hp", 0)),
		int(combat.player.get("block", 0)),
		int(combat.player.get("energy", 0)),
		int(combat.player.get("max_energy", 0)),
		int(combat.player.get("momentum", 0)),
		int(combat.player.get("momentum_max", 0)),
		combat.draw_pile.size(),
		combat.discard_pile.size(),
		combat.exhaust_pile.size()
	]
	_refresh_potions()
	_refresh_enemies()
	_refresh_hand()
	_refresh_rewards()
	_refresh_log()
	_refresh_feedback()
	end_turn_button.disabled = combat.phase != "player"

func _refresh_campfire(node: Dictionary) -> void:
	status_label.text = "篝火：选择恢复生命或升级一张牌。升级后的牌会在名称后显示 +。"
	feedback_label.visible = false
	map_view.visible = false
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	log_label.text = _route_preview()
	end_turn_button.disabled = true

	var heal_button := Button.new()
	heal_button.custom_minimum_size = Vector2(180, 92)
	heal_button.text = "休息\n恢复 %d%% 最大生命" % _campfire_heal_percent()
	heal_button.pressed.connect(_on_campfire_heal_pressed)
	reward_row.add_child(heal_button)

	var upgrade_label := Label.new()
	upgrade_label.text = "可升级："
	upgrade_label.custom_minimum_size = Vector2(90, 0)
	reward_row.add_child(upgrade_label)

	var shown: int = 0
	for i in range(run_deck_ids.size()):
		var entry: String = str(run_deck_ids[i])
		if entry.ends_with("+"):
			continue
		var card: Dictionary = _card_by_id(entry)
		if card.is_empty() or not card.has("upgrade"):
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(220, 120)
		button.text = _upgrade_preview_text(card)
		button.pressed.connect(_on_upgrade_card_pressed.bind(i))
		reward_row.add_child(button)
		shown += 1
		if shown >= 4:
			break

	if shown == 0:
		var no_upgrade := Label.new()
		no_upgrade.text = "没有可升级卡牌。"
		reward_row.add_child(no_upgrade)

func _refresh_shop(node: Dictionary) -> void:
	if shop_generated_for != current_node_index:
		shop_card_options = _generate_card_rewards(3)
		shop_potion_options = _generate_potion_rewards(2)
		shop_generated_for = current_node_index

	status_label.text = "商店：购买卡牌或移除牌组中的一张牌。"
	feedback_label.visible = false
	map_view.visible = false
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	log_label.text = _route_preview()
	end_turn_button.disabled = true

	for card in shop_card_options:
		var card_dict: Dictionary = card
		var price: int = _card_price(card_dict)
		var button := Button.new()
		button.custom_minimum_size = Vector2(180, 104)
		button.text = "购买 %s\n%d 金币\n%s" % [card_dict.get("name", "卡牌"), price, card_dict.get("description", "")]
		button.disabled = run_gold < price
		button.pressed.connect(_on_shop_buy_card_pressed.bind(str(card_dict.get("id", "")), price))
		reward_row.add_child(button)

	for potion in shop_potion_options:
		var potion_dict: Dictionary = potion
		var potion_price: int = _potion_price(potion_dict)
		var potion_button := Button.new()
		potion_button.custom_minimum_size = Vector2(180, 104)
		potion_button.text = "药水 %s\n%d 金币\n%s" % [potion_dict.get("name", "药水"), potion_price, potion_dict.get("description", "")]
		potion_button.disabled = run_gold < potion_price or not _has_empty_potion_slot()
		potion_button.pressed.connect(_on_shop_buy_potion_pressed.bind(str(potion_dict.get("id", "")), potion_price))
		reward_row.add_child(potion_button)

	var remove_button := Button.new()
	remove_button.custom_minimum_size = Vector2(160, 104)
	var remove_price: int = _remove_card_price()
	remove_button.text = "删卡\n%d 金币\n移除第一张非基础升级牌优先" % remove_price
	remove_button.disabled = run_gold < remove_price or run_deck_ids.is_empty()
	remove_button.pressed.connect(_on_shop_remove_card_pressed)
	reward_row.add_child(remove_button)

	var leave_button := Button.new()
	leave_button.custom_minimum_size = Vector2(120, 104)
	leave_button.text = "离开商店"
	leave_button.pressed.connect(_advance_to_next_node)
	reward_row.add_child(leave_button)

func _refresh_event(node: Dictionary) -> void:
	var event: Dictionary = _event_by_id(str(node.get("event_id", "")))
	status_label.text = "%s：%s" % [event.get("name", node.get("name", "事件")), event.get("body", "你遇到了一个未知事件。")]
	feedback_label.visible = false
	map_view.visible = false
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	log_label.text = _route_preview()
	end_turn_button.disabled = true

	for choice in event.get("choices", []):
		var choice_dict: Dictionary = choice
		var button := Button.new()
		button.custom_minimum_size = Vector2(210, 104)
		button.text = "%s\n%s" % [choice_dict.get("label", "选择"), choice_dict.get("description", "")]
		button.pressed.connect(_on_event_choice_pressed.bind(choice_dict))
		reward_row.add_child(button)

	if event.get("choices", []).is_empty():
		var continue_button := Button.new()
		continue_button.text = "继续"
		continue_button.pressed.connect(_advance_to_next_node)
		reward_row.add_child(continue_button)

func _refresh_unknown_node(node: Dictionary) -> void:
	status_label.text = "未知节点，自动前进。"
	feedback_label.visible = false
	map_view.visible = false
	_clear_container(potion_row)
	_clear_container(enemy_row)
	_clear_container(hand_row)
	_clear_container(reward_row)
	log_label.text = _route_preview()
	end_turn_button.disabled = true
	var button := Button.new()
	button.text = "继续"
	button.pressed.connect(_advance_to_next_node)
	reward_row.add_child(button)

func _refresh_potions() -> void:
	_clear_container(potion_row)
	var label := Label.new()
	label.text = "药水"
	label.custom_minimum_size = Vector2(54, 0)
	potion_row.add_child(label)

	var max_slots: int = _max_potion_slots()
	for i in range(max_slots):
		var button := Button.new()
		button.custom_minimum_size = Vector2(190, 62)
		button.add_theme_stylebox_override("normal", _button_style(Color(0.19, 0.21, 0.24), Color(0.89, 0.53, 0.25)))
		button.add_theme_stylebox_override("hover", _button_style(Color(0.24, 0.27, 0.31), Color(0.98, 0.70, 0.32)))
		button.add_theme_stylebox_override("pressed", _button_style(Color(0.14, 0.16, 0.18), Color(0.98, 0.70, 0.32)))
		button.add_theme_stylebox_override("disabled", _button_style(Color(0.12, 0.13, 0.15), Color(0.35, 0.36, 0.38)))
		button.icon = _load_texture(POTION_ART_PATH)
		button.expand_icon = true
		if i < run_potion_ids.size():
			var potion: Dictionary = _potion_by_id(str(run_potion_ids[i]))
			button.text = "%s\n%s" % [potion.get("name", run_potion_ids[i]), potion.get("description", "")]
			button.tooltip_text = "%s\n%s" % [potion.get("name", run_potion_ids[i]), potion.get("description", "")]
			button.disabled = combat == null or combat.phase != "player"
			button.pressed.connect(_on_potion_pressed.bind(i))
		else:
			button.text = "空药水槽"
			button.disabled = true
		potion_row.add_child(button)

func _refresh_enemies() -> void:
	_clear_container(enemy_row)
	for i in range(combat.enemies.size()):
		var enemy: Dictionary = combat.enemies[i]
		var panel := VBoxContainer.new()
		panel.custom_minimum_size = Vector2(246, 176)
		panel.add_theme_constant_override("separation", 4)
		enemy_row.add_child(panel)

		var art := TextureRect.new()
		art.custom_minimum_size = Vector2(246, 72)
		art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture = _enemy_texture(enemy)
		panel.add_child(art)

		var button := Button.new()
		button.custom_minimum_size = Vector2(246, 100)
		button.disabled = int(enemy.get("hp", 0)) <= 0
		button.text = _enemy_button_text(enemy, i == selected_enemy_index)
		button.tooltip_text = _enemy_tooltip_text(enemy)
		button.add_theme_stylebox_override("normal", _enemy_button_style(enemy, i == selected_enemy_index, false))
		button.add_theme_stylebox_override("hover", _enemy_button_style(enemy, true, false))
		button.add_theme_stylebox_override("pressed", _enemy_button_style(enemy, true, true))
		button.add_theme_stylebox_override("disabled", _button_style(Color(0.13, 0.13, 0.14), Color(0.34, 0.34, 0.36)))
		button.pressed.connect(_on_enemy_pressed.bind(i))
		panel.add_child(button)

func _enemy_button_text(enemy: Dictionary, selected: bool) -> String:
	var action: Dictionary = enemy.get("current_action", {})
	var intent: Dictionary = action.get("intent", {})
	var prefix := ">> " if selected else ""
	var phase_name: String = str(enemy.get("phase_name", ""))
	var phase_text: String = " [%s]" % phase_name if not phase_name.is_empty() else ""
	var status_text: String = _status_text(enemy.get("statuses", {}))
	return "%s%s%s\nHP %d/%d  护甲 %d\n意图：%s\n状态：%s" % [
		prefix,
		enemy.get("name", "敌人"),
		phase_text,
		int(enemy.get("hp", 0)),
		int(enemy.get("max_hp", 0)),
		int(enemy.get("block", 0)),
		_intent_text(intent),
		status_text
	]

func _enemy_tooltip_text(enemy: Dictionary) -> String:
	var data: Dictionary = enemy.get("data", {})
	var phase_name: String = str(enemy.get("phase_name", ""))
	var phase_line: String = "阶段：%s\n" % phase_name if not phase_name.is_empty() else ""
	return "%s\n%s类型：%s\n%s" % [
		enemy.get("name", "敌人"),
		phase_line,
		data.get("tier", "normal"),
		data.get("intent_note", "")
	]

func _intent_text(intent: Dictionary) -> String:
	var intent_type: String = str(intent.get("type", "none"))
	match intent_type:
		"attack":
			return "攻击 %d x%d" % [int(intent.get("amount", 0)), int(intent.get("hits", 1))]
		"block":
			return "获得护甲 %d" % int(intent.get("amount", 0))
		"debuff":
			return "施加 %s x%d" % [intent.get("status", ""), int(intent.get("amount", 0))]
		"attack_debuff":
			return "攻击 %d 并施加 %s" % [int(intent.get("amount", 0)), intent.get("status", "")]
		"status_card":
			return "加入状态牌 %s" % intent.get("card_id", "")
		"buff":
			return "强化 %s x%d" % [intent.get("status", ""), int(intent.get("amount", 0))]
		"block_buff":
			return "护甲 %d 并强化" % int(intent.get("amount", 0))
		_:
			return intent_type

func _refresh_hand() -> void:
	_clear_container(hand_row)
	if combat.phase == "won" or combat.phase == "lost":
		return

	for i in range(combat.hand.size()):
		var card: Dictionary = combat.hand[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 172)
		button.text = "%s [%d]\n%s\n\n%s" % [
			card.get("name", "卡牌"),
			int(card.get("cost", 0)),
			card.get("type", ""),
			card.get("description", "")
		]
		button.tooltip_text = "%s [%d]\n%s\n%s" % [
			card.get("name", "卡牌"),
			int(card.get("cost", 0)),
			card.get("type", ""),
			card.get("description", "")
		]
		button.icon = _card_frame_texture(str(card.get("type", "")))
		button.expand_icon = false
		button.add_theme_stylebox_override("normal", _card_button_style(str(card.get("type", "")), false, false))
		button.add_theme_stylebox_override("hover", _card_button_style(str(card.get("type", "")), true, false))
		button.add_theme_stylebox_override("pressed", _card_button_style(str(card.get("type", "")), true, true))
		button.add_theme_stylebox_override("disabled", _button_style(Color(0.13, 0.13, 0.15), Color(0.34, 0.34, 0.38)))
		button.disabled = not combat.can_play_card(i)
		button.pressed.connect(_on_card_pressed.bind(i))
		hand_row.add_child(button)

func _refresh_log() -> void:
	var lines: Array = combat.log_entries.slice(max(0, combat.log_entries.size() - 16), combat.log_entries.size())
	log_label.text = "\n".join(lines)

func _refresh_feedback() -> void:
	if combat == null:
		return
	var events: Array = combat.consume_feedback_events()
	if events.is_empty():
		return
	last_feedback_events = events
	var event: Dictionary = _primary_feedback_event(events)
	var message: String = str(event.get("message", ""))
	if message.is_empty():
		return
	feedback_label.text = message
	feedback_label.visible = true
	feedback_label.add_theme_stylebox_override("normal", _feedback_style(str(event.get("severity", "info"))))
	feedback_label.modulate = Color(1, 1, 1, 1)
	if is_inside_tree() and DisplayServer.get_name() != "headless":
		var tween := create_tween()
		feedback_label.scale = Vector2(1.04, 1.04)
		tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.12)
		tween.parallel().tween_property(feedback_label, "modulate", Color(1, 1, 1, 0.88), 0.42)

func _primary_feedback_event(events: Array) -> Dictionary:
	var priority := {
		"lost": 100,
		"won": 95,
		"phase": 90,
		"enemy_defeated": 80,
		"player_hit": 70,
		"enemy_hit": 60,
		"heal": 55,
		"potion": 50,
		"block": 40
	}
	var selected: Dictionary = {}
	var selected_score := -1
	for event in events:
		var event_dict: Dictionary = event
		var score: int = int(priority.get(str(event_dict.get("type", "")), 0))
		if score >= selected_score:
			selected = event_dict
			selected_score = score
	return selected

func _refresh_rewards() -> void:
	_clear_container(reward_row)
	if combat.phase == "lost":
		var lost_label := Label.new()
		lost_label.text = "战败。点击“重开跑团”重新开始。"
		lost_label.add_theme_font_size_override("font_size", 18)
		reward_row.add_child(lost_label)
		return
	if combat.phase != "won":
		return

	var node: Dictionary = _current_node()
	var encounter_id: String = str(node.get("encounter_id", ""))
	if reward_generated_for != encounter_id:
		_grant_encounter_gold(encounter_id)
		reward_options = _generate_card_rewards(3)
		var encounter: Dictionary = _encounter_by_id(encounter_id)
		if bool(encounter.get("relic_reward", false)):
			relic_reward_options = _generate_relic_rewards(3)
			relic_reward_done = relic_reward_options.is_empty()
		else:
			relic_reward_options.clear()
			relic_reward_done = true
		if _has_empty_potion_slot():
			potion_reward_options = _generate_potion_rewards(_potion_reward_count())
			potion_reward_done = potion_reward_options.is_empty()
		else:
			potion_reward_options.clear()
			potion_reward_done = true
		card_reward_done = reward_options.is_empty()
		reward_generated_for = encounter_id

	var label := Label.new()
	label.text = "战斗胜利，选择奖励："
	label.custom_minimum_size = Vector2(180, 0)
	reward_row.add_child(label)

	if not card_reward_done:
		for card in reward_options:
			var card_dict: Dictionary = card
			var button := Button.new()
			button.custom_minimum_size = Vector2(180, 96)
			button.text = "卡牌：%s [%d]\n%s" % [card_dict.get("name", "卡牌"), int(card_dict.get("cost", 0)), card_dict.get("description", "")]
			button.pressed.connect(_on_reward_card_pressed.bind(str(card_dict.get("id", ""))))
			reward_row.add_child(button)

		var skip_button := Button.new()
		skip_button.custom_minimum_size = Vector2(120, 96)
		skip_button.text = "跳过卡牌"
		skip_button.pressed.connect(_on_skip_card_reward_pressed)
		reward_row.add_child(skip_button)
	else:
		var card_done_label := Label.new()
		card_done_label.text = "卡牌奖励已处理。"
		card_done_label.custom_minimum_size = Vector2(130, 0)
		reward_row.add_child(card_done_label)

	if not relic_reward_done:
		for relic in relic_reward_options:
			var relic_dict: Dictionary = relic
			var relic_button := Button.new()
			relic_button.custom_minimum_size = Vector2(180, 96)
			relic_button.text = "遗物：%s\n%s" % [relic_dict.get("name", "遗物"), relic_dict.get("description", "")]
			relic_button.pressed.connect(_on_reward_relic_pressed.bind(str(relic_dict.get("id", ""))))
			reward_row.add_child(relic_button)
	elif not relic_reward_options.is_empty():
		var relic_done_label := Label.new()
		relic_done_label.text = "遗物奖励已处理。"
		relic_done_label.custom_minimum_size = Vector2(130, 0)
		reward_row.add_child(relic_done_label)

	if not potion_reward_done:
		for potion in potion_reward_options:
			var potion_dict: Dictionary = potion
			var potion_button := Button.new()
			potion_button.custom_minimum_size = Vector2(180, 96)
			potion_button.text = "药水：%s\n%s" % [potion_dict.get("name", "药水"), potion_dict.get("description", "")]
			potion_button.pressed.connect(_on_reward_potion_pressed.bind(str(potion_dict.get("id", ""))))
			reward_row.add_child(potion_button)

		var skip_potion_button := Button.new()
		skip_potion_button.custom_minimum_size = Vector2(120, 96)
		skip_potion_button.text = "跳过药水"
		skip_potion_button.pressed.connect(_on_skip_potion_reward_pressed)
		reward_row.add_child(skip_potion_button)
	elif not potion_reward_options.is_empty():
		var potion_done_label := Label.new()
		potion_done_label.text = "药水奖励已处理。"
		potion_done_label.custom_minimum_size = Vector2(130, 0)
		reward_row.add_child(potion_done_label)

	var continue_button := Button.new()
	continue_button.custom_minimum_size = Vector2(120, 96)
	continue_button.text = "继续"
	continue_button.disabled = not (card_reward_done and relic_reward_done and potion_reward_done)
	continue_button.pressed.connect(_advance_to_next_node)
	reward_row.add_child(continue_button)

func _on_enemy_pressed(index: int) -> void:
	selected_enemy_index = index
	_refresh()

func _on_card_pressed(index: int) -> void:
	if combat != null and combat.phase == "player":
		if combat.play_card(index, selected_enemy_index):
			_audio_event("card_play")
		selected_enemy_index = _normalize_selected_enemy()
	_refresh()

func _on_end_turn_pressed() -> void:
	if combat == null:
		return
	_audio_event("turn_end")
	combat.end_player_turn()
	selected_enemy_index = _normalize_selected_enemy()
	_refresh()

func _on_potion_pressed(slot_index: int) -> void:
	if combat == null or slot_index < 0 or slot_index >= run_potion_ids.size():
		return
	var potion: Dictionary = _potion_by_id(str(run_potion_ids[slot_index]))
	if potion.is_empty():
		_audio_event("error")
		return
	if combat.use_potion(potion, selected_enemy_index):
		run_potion_ids.remove_at(slot_index)
		_audio_event("potion")
	selected_enemy_index = _normalize_selected_enemy()
	_refresh()

func _on_reward_card_pressed(card_id: String) -> void:
	if card_id.is_empty():
		return
	run_deck_ids.append(card_id)
	_audio_event("reward")
	var card: Dictionary = _card_by_id(card_id)
	combat.log_entries.append("奖励选择：%s 加入牌组。" % card.get("name", card_id))
	card_reward_done = true
	_refresh()

func _on_skip_card_reward_pressed() -> void:
	combat.log_entries.append("跳过卡牌奖励。")
	_audio_event("ui_click")
	card_reward_done = true
	_refresh()

func _on_reward_relic_pressed(relic_id: String) -> void:
	if relic_id.is_empty():
		return
	run_relic_ids.append(relic_id)
	_audio_event("reward")
	var relic: Dictionary = _relic_by_id(relic_id)
	combat.log_entries.append("遗物获得：%s。" % relic.get("name", relic_id))
	relic_reward_done = true
	_refresh()

func _on_reward_potion_pressed(potion_id: String) -> void:
	if potion_id.is_empty() or not _has_empty_potion_slot():
		_audio_event("error")
		return
	run_potion_ids.append(potion_id)
	_audio_event("reward")
	var potion: Dictionary = _potion_by_id(potion_id)
	combat.log_entries.append("药水获得：%s。" % potion.get("name", potion_id))
	potion_reward_done = true
	_refresh()

func _on_skip_potion_reward_pressed() -> void:
	combat.log_entries.append("跳过药水奖励。")
	_audio_event("ui_click")
	potion_reward_done = true
	_refresh()

func _on_campfire_heal_pressed() -> void:
	var heal_percent: int = _campfire_heal_percent()
	var heal: int = max(1, int(ceil(float(run_max_hp) * float(heal_percent) / 100.0)))
	run_hp = min(run_max_hp, run_hp + heal)
	_audio_event("campfire")
	_advance_to_next_node()

func _on_upgrade_card_pressed(deck_index: int) -> void:
	if deck_index < 0 or deck_index >= run_deck_ids.size():
		return
	var entry: String = str(run_deck_ids[deck_index])
	if not entry.ends_with("+"):
		run_deck_ids[deck_index] = "%s+" % entry
	_audio_event("campfire")
	_advance_to_next_node()

func _on_shop_buy_card_pressed(card_id: String, price: int) -> void:
	if card_id.is_empty() or run_gold < price:
		_audio_event("error")
		return
	run_gold -= price
	run_deck_ids.append(card_id)
	_audio_event("shop")
	for i in range(shop_card_options.size()):
		var card: Dictionary = shop_card_options[i]
		if str(card.get("id", "")) == card_id:
			shop_card_options.remove_at(i)
			break
	_refresh()

func _on_shop_buy_potion_pressed(potion_id: String, price: int) -> void:
	if potion_id.is_empty() or run_gold < price or not _has_empty_potion_slot():
		_audio_event("error")
		return
	run_gold -= price
	run_potion_ids.append(potion_id)
	_audio_event("shop")
	for i in range(shop_potion_options.size()):
		var potion: Dictionary = shop_potion_options[i]
		if str(potion.get("id", "")) == potion_id:
			shop_potion_options.remove_at(i)
			break
	_refresh()

func _on_shop_remove_card_pressed() -> void:
	var remove_price: int = _remove_card_price()
	if run_gold < remove_price or run_deck_ids.is_empty():
		_audio_event("error")
		return
	var remove_index: int = _find_removable_card_index()
	if remove_index < 0:
		return
	run_gold -= remove_price
	run_deck_ids.remove_at(remove_index)
	_audio_event("shop")
	_refresh()

func _on_map_node_pressed(node_id: String) -> void:
	if not available_node_ids.has(node_id):
		_audio_event("error")
		return
	_audio_event("map_select")
	current_node_id = node_id
	current_node_index = _node_index_by_id(current_node_id)
	available_node_ids.clear()
	_start_current_node()

func _on_deck_view_pressed() -> void:
	deck_view_open = true
	_audio_event("ui_click")
	_refresh()

func _on_close_deck_view_pressed() -> void:
	deck_view_open = false
	_audio_event("ui_click")
	_refresh()

func _on_save_pressed() -> void:
	var state := _create_save_state()
	var ok: bool = SaveManagerScript.save_run(state)
	_audio_event("save" if ok else "error")
	if combat != null:
		combat.log_entries.append("跑团已保存。" if ok else "保存失败。")
	_refresh()

func _on_load_pressed() -> void:
	var state: Dictionary = SaveManagerScript.load_run()
	if state.is_empty():
		_audio_event("error")
		if combat != null:
			combat.log_entries.append("没有可读取的存档。")
			_refresh()
		return
	_load_all_data()
	_audio_event("save")
	run_deck_ids = state.get("run_deck_ids", []).duplicate(true)
	run_relic_ids = state.get("run_relic_ids", []).duplicate(true)
	run_potion_ids = state.get("run_potion_ids", []).duplicate(true)
	run_hp = int(state.get("run_hp", 1))
	run_max_hp = int(state.get("run_max_hp", 72))
	run_gold = int(state.get("run_gold", 0))
	current_node_index = int(state.get("current_node_index", 0))
	current_node_id = str(state.get("current_node_id", ""))
	available_node_ids = []
	for node_id in state.get("available_node_ids", []):
		available_node_ids.append(str(node_id))
	completed_node_ids = state.get("completed_node_ids", {})
	map_graph = state.get("map_graph", {})
	run_completed = bool(state.get("run_completed", false))
	reward_options.clear()
	relic_reward_options.clear()
	potion_reward_options.clear()
	shop_card_options.clear()
	shop_potion_options.clear()
	reward_generated_for = ""
	shop_generated_for = -1
	card_reward_done = false
	relic_reward_done = true
	potion_reward_done = true
	if map_graph.is_empty():
		_build_route()
	else:
		route_nodes = _flatten_map_nodes(map_graph)
		current_node_index = _node_index_by_id(current_node_id)
	_start_current_node()

func _on_event_choice_pressed(choice: Dictionary) -> void:
	for effect in choice.get("effects", []):
		var effect_dict: Dictionary = effect
		_apply_event_effect(effect_dict)
	_audio_event("reward")
	_advance_to_next_node()

func _advance_to_next_node() -> void:
	if combat != null:
		if combat.phase == "won":
			run_hp = int(combat.player.get("hp", run_hp))
		elif combat.phase == "lost":
			return
	if not current_node_id.is_empty():
		completed_node_ids[current_node_id] = true
	available_node_ids = _next_node_ids(current_node_id)
	current_node_id = ""
	combat = null
	_audio_event("ui_click")
	if available_node_ids.is_empty():
		run_completed = true
	_refresh()

func _normalize_selected_enemy() -> int:
	if combat == null:
		return 0
	if selected_enemy_index >= 0 and selected_enemy_index < combat.enemies.size() and int(combat.enemies[selected_enemy_index].get("hp", 0)) > 0:
		return selected_enemy_index
	for i in range(combat.enemies.size()):
		if int(combat.enemies[i].get("hp", 0)) > 0:
			return i
	return 0

func _enemy_texture(enemy: Dictionary) -> Texture2D:
	var data: Dictionary = enemy.get("data", {})
	var sprite_key: String = str(data.get("sprite_key", ""))
	var path: String = str(ENEMY_ART_PATHS.get(sprite_key, ""))
	if path.is_empty():
		path = "res://assets/art/enemy_forge_bishop.svg" if str(data.get("tier", "")) == "boss" else "res://assets/art/enemy_soot_raider.svg"
	return _load_texture(path)

func _card_frame_texture(card_type: String) -> Texture2D:
	var path: String = str(CARD_FRAME_PATHS.get(card_type, ""))
	if path.is_empty():
		return null
	return _load_texture(path)

func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var texture = load(path)
	if texture is Texture2D:
		return texture
	return null

func _card_button_style(card_type: String, highlighted: bool, pressed: bool) -> StyleBoxFlat:
	var colors: Dictionary = _card_colors(card_type)
	var bg: Color = colors.get("bg", Color(0.18, 0.19, 0.22))
	var border: Color = colors.get("border", Color(0.58, 0.60, 0.64))
	if highlighted:
		bg = bg.lightened(0.10)
		border = border.lightened(0.16)
	if pressed:
		bg = bg.darkened(0.12)
	return _button_style(bg, border, 2, 6)

func _enemy_button_style(enemy: Dictionary, selected: bool, pressed: bool) -> StyleBoxFlat:
	var data: Dictionary = enemy.get("data", {})
	var tier: String = str(data.get("tier", "normal"))
	var bg := Color(0.17, 0.18, 0.20)
	var border := Color(0.50, 0.55, 0.60)
	if tier == "elite":
		bg = Color(0.21, 0.18, 0.15)
		border = Color(0.80, 0.54, 0.27)
	elif tier == "boss":
		bg = Color(0.23, 0.14, 0.16)
		border = Color(0.86, 0.34, 0.28)
	if selected:
		bg = bg.lightened(0.10)
		border = border.lightened(0.18)
	if pressed:
		bg = bg.darkened(0.12)
	return _button_style(bg, border, 2, 6)

func _card_colors(card_type: String) -> Dictionary:
	match card_type:
		"attack":
			return {"bg": Color(0.24, 0.13, 0.12), "border": Color(0.86, 0.35, 0.25)}
		"skill":
			return {"bg": Color(0.11, 0.19, 0.24), "border": Color(0.32, 0.66, 0.82)}
		"power":
			return {"bg": Color(0.20, 0.16, 0.25), "border": Color(0.70, 0.50, 0.86)}
		"status", "curse":
			return {"bg": Color(0.16, 0.16, 0.16), "border": Color(0.55, 0.55, 0.55)}
		_:
			return {"bg": Color(0.18, 0.19, 0.22), "border": Color(0.58, 0.60, 0.64)}

func _feedback_style(severity: String) -> StyleBoxFlat:
	match severity:
		"danger":
			return _button_style(Color(0.28, 0.09, 0.08), Color(0.95, 0.35, 0.28), 2, 6)
		"hit":
			return _button_style(Color(0.25, 0.14, 0.08), Color(0.95, 0.55, 0.24), 2, 6)
		"success":
			return _button_style(Color(0.10, 0.22, 0.15), Color(0.30, 0.78, 0.45), 2, 6)
		"phase":
			return _button_style(Color(0.22, 0.12, 0.25), Color(0.78, 0.42, 0.92), 2, 6)
		_:
			return _button_style(Color(0.15, 0.16, 0.18), Color(0.44, 0.48, 0.54), 1, 6)

func _button_style(bg: Color, border: Color, border_width: int = 2, radius: int = 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _status_text(statuses: Dictionary) -> String:
	if statuses.is_empty():
		return "无"
	var parts: Array[String] = []
	for key in statuses.keys():
		if int(statuses[key]) > 0:
			parts.append("%s:%d" % [_status_display_name(str(key)), int(statuses[key])])
	if parts.is_empty():
		return "无"
	return ", ".join(parts)

func _status_display_name(status_id: String) -> String:
	for status in status_data.get("statuses", []):
		var status_dict: Dictionary = status
		if str(status_dict.get("id", "")) == status_id:
			return str(status_dict.get("name", status_id))
	return status_id

func _generate_card_rewards(amount: int) -> Array:
	var pool: Array = []
	for card in card_data.get("cards", []):
		var card_dict: Dictionary = card
		var rarity: String = str(card_dict.get("rarity", ""))
		var type: String = str(card_dict.get("type", ""))
		if rarity == "starter" or rarity == "status" or type == "status" or type == "curse":
			continue
		pool.append(card_dict)
	pool.shuffle()
	return pool.slice(0, min(amount, pool.size()))

func _generate_relic_rewards(amount: int) -> Array:
	var pool: Array = []
	for relic in relic_data.get("relics", []):
		var relic_dict: Dictionary = relic
		var relic_id: String = str(relic_dict.get("id", ""))
		if relic_id.is_empty() or run_relic_ids.has(relic_id):
			continue
		if str(relic_dict.get("rarity", "")) == "starter":
			continue
		if str(relic_dict.get("implementation_note", "")).contains("地图系统阶段"):
			continue
		pool.append(relic_dict)
	pool.shuffle()
	return pool.slice(0, min(amount, pool.size()))

func _generate_potion_rewards(amount: int) -> Array:
	var pool: Array = []
	for potion in potion_data.get("potions", []):
		var potion_dict: Dictionary = potion
		if str(potion_dict.get("id", "")).is_empty():
			continue
		pool.append(potion_dict)
	pool.shuffle()
	return pool.slice(0, min(amount, pool.size()))

func _grant_encounter_gold(encounter_id: String) -> void:
	var encounter: Dictionary = _encounter_by_id(encounter_id)
	var gold_reward: int = int(encounter.get("gold_reward", 0))
	run_gold += gold_reward
	combat.log_entries.append("获得金币：%d。" % gold_reward)

func _card_price(card: Dictionary) -> int:
	var rarity: String = str(card.get("rarity", "common"))
	var prices: Dictionary = economy_data.get("shop", {}).get("card_prices", {})
	return int(prices.get(rarity, prices.get("common", 50)))

func _potion_price(potion: Dictionary) -> int:
	var rarity: String = str(potion.get("rarity", "common"))
	var prices: Dictionary = economy_data.get("shop", {}).get("potion_prices", {})
	return int(prices.get(rarity, prices.get("common", 35)))

func _remove_card_price() -> int:
	return int(economy_data.get("shop", {}).get("remove_card_price", 50))

func _campfire_heal_percent() -> int:
	return int(economy_data.get("campfire", {}).get("heal_percent_of_max_hp", 30))

func _potion_reward_count() -> int:
	return int(economy_data.get("potion_reward", {}).get("combat_drop_count", 1))

func _max_potion_slots() -> int:
	return int(player_data.get("player", {}).get("potion_slots", 2))

func _has_empty_potion_slot() -> bool:
	return run_potion_ids.size() < _max_potion_slots()

func _apply_event_effect(effect: Dictionary) -> void:
	var effect_type: String = str(effect.get("type", ""))
	match effect_type:
		"gain_gold":
			run_gold += int(effect.get("amount", 0))
		"lose_hp":
			run_hp = max(1, run_hp - int(effect.get("amount", 0)))
		"heal_percent":
			var amount: int = int(effect.get("amount", 0))
			var heal: int = max(1, int(ceil(float(run_max_hp) * float(amount) / 100.0)))
			run_hp = min(run_max_hp, run_hp + heal)
		"add_card":
			var card_id: String = str(effect.get("card_id", ""))
			if not card_id.is_empty():
				run_deck_ids.append(card_id)
		"gain_relic":
			var relic_id: String = str(effect.get("relic_id", ""))
			if not relic_id.is_empty() and not run_relic_ids.has(relic_id):
				run_relic_ids.append(relic_id)
		"gain_potion":
			var potion_id: String = str(effect.get("potion_id", ""))
			if not potion_id.is_empty() and _has_empty_potion_slot():
				run_potion_ids.append(potion_id)
		"remove_first_non_starter_card":
			var remove_index: int = _find_removable_card_index()
			if remove_index >= 0:
				run_deck_ids.remove_at(remove_index)
		_:
			pass

func _find_removable_card_index() -> int:
	for i in range(run_deck_ids.size()):
		var entry: String = str(run_deck_ids[i])
		if entry.ends_with("+"):
			return i
	for i in range(run_deck_ids.size()):
		var entry: String = str(run_deck_ids[i])
		var card_id: String = entry.substr(0, entry.length() - 1) if entry.ends_with("+") else entry
		var card: Dictionary = _card_by_id(card_id)
		if str(card.get("rarity", "")) != "starter":
			return i
	return run_deck_ids.size() - 1

func _current_node() -> Dictionary:
	if not current_node_id.is_empty():
		return _node_by_id(current_node_id)
	if current_node_index >= 0 and current_node_index < route_nodes.size():
		return route_nodes[current_node_index]
	return {}

func _is_battle_node(node_type: String) -> bool:
	return node_type == "combat" or node_type == "elite" or node_type == "boss"

func _route_preview() -> String:
	var parts: Array[String] = []
	var layers: Array = map_graph.get("layers", [])
	if not layers.is_empty():
		for layer in layers:
			var layer_nodes: Array = layer
			var node_parts: Array[String] = []
			for node in layer_nodes:
				var node_dict: Dictionary = node
				var node_id: String = str(node_dict.get("id", ""))
				var marker: String = "-"
				if completed_node_ids.has(node_id):
					marker = "x"
				elif node_id == current_node_id:
					marker = ">"
				elif available_node_ids.has(node_id):
					marker = "*"
				node_parts.append("%s%s:%s" % [marker, node_dict.get("name", "节点"), node_dict.get("type", "")])
			parts.append(" | ".join(node_parts))
		return "\n".join(parts)

	for i in range(route_nodes.size()):
		var node: Dictionary = route_nodes[i]
		var marker: String = ">"
		if i < current_node_index:
			marker = "x"
		elif i > current_node_index:
			marker = "-"
		parts.append("%s %s [%s]" % [marker, node.get("name", "节点"), node.get("type", "")])
	return "\n".join(parts)

func _map_graph_for_view() -> Dictionary:
	if not map_graph.is_empty():
		return map_graph
	var layers: Array = []
	var edges: Array = []
	for i in range(route_nodes.size()):
		var node: Dictionary = route_nodes[i]
		layers.append([node])
		if i + 1 < route_nodes.size():
			edges.append({"from": str(node.get("id", "")), "to": str(route_nodes[i + 1].get("id", ""))})
	return {
		"layers": layers,
		"edges": edges,
		"start_node_id": str(route_nodes[0].get("id", "")) if not route_nodes.is_empty() else "",
		"boss_node_id": str(route_nodes[route_nodes.size() - 1].get("id", "")) if not route_nodes.is_empty() else ""
	}

func _map_legend_text() -> String:
	var available_names: Array[String] = []
	for node_id in available_node_ids:
		var node: Dictionary = _node_by_id(node_id)
		available_names.append("%s [%s]" % [node.get("name", node_id), node.get("type", "")])
	return "地图图例：> 可前往，x 已完成，灰色为暂不可达。\n当前可选：%s" % ", ".join(available_names)

func _encounter_by_id(encounter_id: String) -> Dictionary:
	for encounter in encounter_data.get("encounters", []):
		var encounter_dict: Dictionary = encounter
		if str(encounter_dict.get("id", "")) == encounter_id:
			return encounter_dict
	return {}

func _card_by_id(card_id: String) -> Dictionary:
	for card in card_data.get("cards", []):
		var card_dict: Dictionary = card
		if str(card_dict.get("id", "")) == card_id:
			return card_dict
	return {}

func _relic_by_id(relic_id: String) -> Dictionary:
	for relic in relic_data.get("relics", []):
		var relic_dict: Dictionary = relic
		if str(relic_dict.get("id", "")) == relic_id:
			return relic_dict
	return {}

func _potion_by_id(potion_id: String) -> Dictionary:
	for potion in potion_data.get("potions", []):
		var potion_dict: Dictionary = potion
		if str(potion_dict.get("id", "")) == potion_id:
			return potion_dict
	return {}

func _event_by_id(event_id: String) -> Dictionary:
	for event in event_data.get("events", []):
		var event_dict: Dictionary = event
		if str(event_dict.get("id", "")) == event_id:
			return event_dict
	return {}

func _flatten_map_nodes(graph: Dictionary) -> Array:
	var result: Array = []
	for layer in graph.get("layers", []):
		var layer_nodes: Array = layer
		for node in layer_nodes:
			result.append(node)
	return result

func _node_by_id(node_id: String) -> Dictionary:
	for node in route_nodes:
		var node_dict: Dictionary = node
		if str(node_dict.get("id", "")) == node_id:
			return node_dict
	return {}

func _node_index_by_id(node_id: String) -> int:
	for i in range(route_nodes.size()):
		var node: Dictionary = route_nodes[i]
		if str(node.get("id", "")) == node_id:
			return i
	return 0

func _next_node_ids(node_id: String) -> Array[String]:
	var result: Array[String] = []
	for edge in map_graph.get("edges", []):
		var edge_dict: Dictionary = edge
		if str(edge_dict.get("from", "")) == node_id:
			var target_id: String = str(edge_dict.get("to", ""))
			if not target_id.is_empty() and not result.has(target_id):
				result.append(target_id)
	if result.is_empty() and map_graph.is_empty():
		var next_index: int = current_node_index + 1
		if next_index >= 0 and next_index < route_nodes.size():
			result.append(str(route_nodes[next_index].get("id", "")))
	return result

func _node_detail_text(node: Dictionary) -> String:
	var node_type: String = str(node.get("type", ""))
	if _is_battle_node(node_type):
		return str(node.get("encounter_id", ""))
	if node_type == "event":
		return str(node.get("event_id", ""))
	if node_type == "shop":
		return "购买/删卡"
	if node_type == "campfire":
		return "恢复/升级"
	return ""

func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.free()

func _create_save_state() -> Dictionary:
	var hp_to_save: int = run_hp
	if combat != null:
		hp_to_save = int(combat.player.get("hp", run_hp))
	return {
		"version": 1,
		"run_deck_ids": run_deck_ids.duplicate(true),
		"run_relic_ids": run_relic_ids.duplicate(true),
		"run_potion_ids": run_potion_ids.duplicate(true),
		"run_hp": hp_to_save,
		"run_max_hp": run_max_hp,
		"run_gold": run_gold,
		"current_node_index": current_node_index,
		"current_node_id": current_node_id,
		"available_node_ids": available_node_ids.duplicate(true),
		"completed_node_ids": completed_node_ids.duplicate(true),
		"map_graph": map_graph.duplicate(true),
		"run_completed": run_completed
	}

func _deck_summary() -> Dictionary:
	var summary := {
		"attack": 0,
		"skill": 0,
		"power": 0,
		"other": 0,
		"upgraded": 0
	}
	for entry_value in run_deck_ids:
		var entry: String = str(entry_value)
		var upgraded: bool = entry.ends_with("+")
		var card_id: String = entry.substr(0, entry.length() - 1) if upgraded else entry
		var card: Dictionary = _card_by_id(card_id)
		var card_type: String = str(card.get("type", "other"))
		if upgraded:
			summary["upgraded"] = int(summary["upgraded"]) + 1
		if summary.has(card_type):
			summary[card_type] = int(summary[card_type]) + 1
		else:
			summary["other"] = int(summary["other"]) + 1
	return summary

func _deck_list_text() -> String:
	var lines: Array[String] = []
	for i in range(run_deck_ids.size()):
		var entry: String = str(run_deck_ids[i])
		var upgraded: bool = entry.ends_with("+")
		var card_id: String = entry.substr(0, entry.length() - 1) if upgraded else entry
		var card: Dictionary = _card_by_id(card_id)
		var name: String = str(card.get("name", card_id))
		var suffix: String = "+" if upgraded else ""
		lines.append("%02d. %s%s [%d] %s" % [i + 1, name, suffix, int(card.get("cost", 0)), card.get("type", "")])
	return "\n".join(lines)

func _potion_summary() -> String:
	if run_potion_ids.is_empty():
		return "无"
	var names: Array[String] = []
	for potion_id in run_potion_ids:
		var potion: Dictionary = _potion_by_id(str(potion_id))
		names.append(str(potion.get("name", potion_id)))
	return ", ".join(names)

func _upgrade_preview_text(card: Dictionary) -> String:
	var upgrade: Dictionary = card.get("upgrade", {})
	var before_cost: int = int(card.get("cost", 0))
	var after_cost: int = int(upgrade.get("cost", before_cost))
	var before_desc: String = str(card.get("description", ""))
	var after_desc: String = str(upgrade.get("description", before_desc))
	return "%s\n费用 %d -> %d\n%s\n=> %s" % [
		card.get("name", "卡牌"),
		before_cost,
		after_cost,
		before_desc,
		after_desc
	]

func _audio_event(event_id: String) -> void:
	if not is_inside_tree():
		return
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play_event"):
		audio.play_event(event_id)
