extends CanvasLayer

var off_screen_position
var position

export(NodePath) onready var price_label = get_node(price_label)
export(NodePath) onready var delta_price_label = get_node(delta_price_label)
export(NodePath) onready var player_loyalty_label = get_node(player_loyalty_label)
export(NodePath) onready var player_image_label = get_node(player_image_label)
export(NodePath) onready var advertising_label = get_node(advertising_label)
export(NodePath) onready var speed_label = get_node(speed_label)
export(NodePath) onready var bandwidth_label = get_node(bandwidth_label)
export(NodePath) onready var reach_label = get_node(reach_label)
export(NodePath) onready var money_label = get_node(money_label)
export(NodePath) onready var reserved_money_label = get_node(reserved_money_label)
export(NodePath) onready var price_change_container = get_node(price_change_container)
export var cyber_attack_button_paths = {"Tedstra":0, "Vodaclone":0, "ElonMask Co":0, "PanCogan Mobile":0}
export(NodePath) onready var share_graphic = get_node(share_graphic)
export(NodePath) onready var player_ISP_info = get_node(player_ISP_info)
export(NodePath) onready var ISP_info_container = get_node(ISP_info_container)
export(NodePath) onready var reach_button = get_node(reach_button)
export(NodePath) onready var speed_button = get_node(speed_button)
export(NodePath) onready var bandwidth_button = get_node(bandwidth_button)
export var tower_button_paths = {"3g":0, "4g":0, "5g":0}
var tower_buttons = {}
var cyber_attack_buttons = {}
export var ISP_info_paths = {"Tedstra":0, "Vodaclone":0, "ElonMask Co":0, "PanCogan Mobile":0}
var ISP_infos = {}
var increasing_price = false
var decreasing_price = false
var hold_time = 0
export var hold_time_threshold = 0.2
var current_query = false
export(NodePath) onready var query = get_node(query)
export(NodePath) onready var query_title_label = get_node(query_title_label)
export(NodePath) onready var query_text_label = get_node(query_text_label)


signal cyber_attack_pressed(target_name)
signal advertising_sell_pressed
signal advertising_buy_pressed
signal buy_tower_pressed(type)
signal price_up_pressed
signal price_down_pressed
signal next_turn_pressed
signal upgrade_tower_pressed(type)
signal accept_bankruptcy
signal accept_sell_tower
# Called when the node enters the scene tree for the first time.
func _ready():
	for ISP in cyber_attack_button_paths.keys():
		cyber_attack_buttons[ISP] = get_node(cyber_attack_button_paths[ISP])
	for ISP in ISP_info_paths.keys():
		ISP_infos[ISP] = get_node(ISP_info_paths[ISP])
	for tower in tower_button_paths.keys():
		tower_buttons[tower] = get_node(tower_button_paths[tower])
	position = $Bottom.rect_position
	off_screen_position = Vector2(position.x, position.y+400)
	$Bottom.rect_position = off_screen_position
	query.hide()

func init_tabs(ISP_logo_dict):
	pass
#	for ISP in ISP_infos.keys():
#		var id = ISP_infos[ISP].get_index()
#		ISP_info_container.set_tab_icon(id, ISP_logo_dict[ISP])
#	var id = player_ISP_info.get_index()
#	ISP_info_container.set_tab_icon(id, ISP_logo_dict["Player"])
	

func _process(delta):
	if Input.is_action_pressed("ui_click"):
		if hold_time >= hold_time_threshold:
			if !current_query:
				if increasing_price: 
					emit_signal("price_up_pressed")
				elif decreasing_price:
					emit_signal("price_down_pressed")
		else:
			hold_time += delta
	else:
		hold_time = 0.0

func show_town_UI(town):
	var curr_position = $Bottom.rect_position 
	$Tween.interpolate_property($Bottom, "rect_position", curr_position, position, 1, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$Tween.start()
	
func hide_town_UI():
	var curr_position = $Bottom.rect_position 
	$Tween.interpolate_property($Bottom, "rect_position", curr_position, off_screen_position, 1, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$Tween.start()

func query_bankruptcy(negative_money):
	start_query("bankruptcy")
	query_title_label.text = "Declare Bankruptcy?"
	var text_template = "You are in a deficit of $%s and cannot end your turn, would you like to declare bankruptcy?"
	query_text_label.text = text_template % negative_money

func query_sell_tower(town, tower):
	start_query("sell_tower")
	query_title_label = "Sell Tower?"
	var text_template = "Are you sure you want to sell your %s Tower in %s? You will recieve its sale price and reduced operation costs."
	query_text_label.text = text_template % [tower, town]

func end_query():
	current_query = false
	query.hide()

func start_query(query_name):
	current_query = query_name
	query.show()

func update_money(money):
	money_label.text = str(money)

func update_reserved_money(money):
	reserved_money_label.text = "(-" + str(money) + ")"

func update_ISP_info(loyalty, image, price, ISP):
	var ISP_info = ISP_infos[ISP]
	ISP_info.update_price(price)
	ISP_info.update_image(image)
	ISP_info.update_loyalty(loyalty)

func update_connections(connections):
	pass
	
func update_tower_upgrade(reach, bandwidth, speed):
	reach_label.text = str(reach)
	bandwidth_label.text = str(bandwidth)
	speed_label.text = str(speed)

func update_reach_upgrade_tooltip(tower, level, curr_value, next_level, next_cost, next_value):
	if !tower: 
		reach_button.set_tooltip("Construct a tower to buy upgrades")
	if next_level:
		var template = "Current Level: %s\nReach: %s towns\nNext Level: %s\nCost: %s\nReach: %s towns"
		reach_button.set_tooltip(template % [level, curr_value, next_level, next_cost, next_value])
	else:
		var template = "Current Level: %s\nReach: %s towns"
		reach_button.set_tooltip(template % [level, curr_value])

func update_speed_upgrade_tooltip(tower, level, curr_value, next_level, next_cost, next_value):
	if !tower: 
		speed_button.set_tooltip("Construct a tower to buy upgrades")
	if next_level:
		var template = "Current Level: %s\nSpeed: %sMb/s\nNext Level: %s\nCost: %s\nSpeed: %sMb/s"
		speed_button.set_tooltip(template % [level, curr_value, next_level, next_cost, next_value])
	else:
		var template = "Current Level: %s\nSpeed: %sMb/s"
		speed_button.set_tooltip(template % [level, curr_value])

func update_bandwidth_upgrade_tooltip(tower, level, curr_value, next_level, next_cost, next_value):
	if !tower: 
		bandwidth_button.set_tooltip("Construct a tower to buy upgrades")
	if next_level:
		var template = "Current Level: %s\nBandwidth: %s people\nNext Level: %s\nCost: %s\nBandwidth: %s people"
		bandwidth_button.set_tooltip(template % [level, curr_value, next_level, next_cost, next_value])
	else:
		var template = "Current Level: %s\nBandwidth: %s people"
		bandwidth_button.set_tooltip(template % [level, curr_value])

func update_tower(tower_type):
	for tower in tower_buttons.keys():
		tower_buttons[tower].texture = tower_buttons[tower].unpressed
	if tower_type:
		tower_buttons[tower_type].texture = tower_buttons[tower_type].pressed

func update_tower_tooltip(tower_type, price, sell_price, operation_cost, bandwidth, reach, speed, bought):
	var template = "%s Tower: $%s\nOperation Cost: $%s\nBandwidth: %s people\nReach: %s towns\nSpeed: %sMb/s"
	if bought:
		 template = "%s Tower: Bought (Sell: $%s)\nOperation Cost: $%s\nBandwidth: %s people\nReach: %s towns\nSpeed: %sMb/s"
	tower_buttons[tower_type].set_tooltip(template % [tower_type, price, sell_price, bandwidth, reach, speed])

func update_shares(share_dict, colour_dict):
	share_graphic.update_graphic(share_dict, colour_dict)

func update_price(price):
	if price:
		price_label.text = "$" + str(price)
		price_change_container.modulate.a = 1
	else:
		price_label.text = str(price)
		price_change_container.modulate.a = 0

func update_delta_price(delta_price):
	if delta_price:
		delta_price_label.text = "(" + str(delta_price) + ")"
	else:
		delta_price_label.text = str(delta_price)

func update_player_loyalty(loyalty):
	player_loyalty_label.text = str(loyalty)

func update_player_image(image):
	player_image_label.text = str(image)
	
func update_cyber_attack(target, value):
	for ISP in cyber_attack_buttons.keys():
		var button = cyber_attack_buttons[ISP]
		if !target:
			button.texture = button.unpressed
		elif target == ISP:
			if value:
				button.texture = button.pressed
			else:
				button.texture = button.unpressed

func update_advertising_tooltip(cost):
	pass

func update_advertising(value):
	advertising_label.text = str(value)

func _on_AdvertisingBuy_pressed():
	if !current_query:
		emit_signal("advertising_buy_pressed")

func _on_AdvertisingSell_pressed():
	if !current_query:
		emit_signal("advertising_sell_pressed")

func _on_PriceUp_pressed():
	if !current_query:
		emit_signal("price_up_pressed")

func _on_PriceDown_pressed():
	if !current_query:
		emit_signal("price_down_pressed")

func _on_Next_Turn_pressed():
	if !current_query:
		emit_signal("next_turn_pressed")

func _on_TedstraAttack_gui_input(event):
	if event.is_action_pressed("ui_click") and !current_query:
		emit_signal("cyber_attack_pressed", "Tedstra")

func _on_VodacloneAttack_gui_input(event):
	if event.is_action_pressed("ui_click") and !current_query:
		emit_signal("cyber_attack_pressed", "Vodaclone")

func _on_ElonMaskCoAttack_gui_input(event):
	if event.is_action_pressed("ui_click") and !current_query:
		emit_signal("cyber_attack_pressed", "ElonMask Co")

func _on_PanCoganMobileAttack_gui_input(event):
	if event.is_action_pressed("ui_click") and !current_query:
		emit_signal("cyber_attack_pressed", "PanCogan Mobile")


func _on_BandwidthUpgradeButton_pressed():
	if !current_query:
		emit_signal("upgrade_tower_pressed", "bandwidth")


func _on_ReachUpgradeButton_pressed():
	if !current_query:
		emit_signal("upgrade_tower_pressed", "reach")


func _on_SpeedUpgradeButton_pressed():
	if !current_query:
		emit_signal("upgrade_tower_pressed", "speed")
	

func _on_PriceUp_mouse_entered():
	increasing_price = true


func _on_PriceDown_mouse_entered():
	decreasing_price = true


func _on_PriceUp_mouse_exited():
	increasing_price = false


func _on_PriceDown_mouse_exited():
	decreasing_price = false


func _on_3gTowerBuy_gui_input(event):
	if event.is_action_pressed("ui_click") and !current_query:
		emit_signal("buy_tower_pressed", "3g")


func _on_4gTowerBuy_gui_input(event):
	if event.is_action_pressed("ui_click") and !current_query:
		emit_signal("buy_tower_pressed", "4g")


func _on_5gTowerBuy_gui_input(event):
	if event.is_action_pressed("ui_click") and !current_query:
		emit_signal("buy_tower_pressed", "5g")

func _on_QueryDeny_pressed():
	if query:
		if current_query == "bankruptcy":
			end_query()
		elif current_query == "sell_tower":
			emit_signal("deny_sell_tower")
			end_query()
			

func _on_QueryAccept_pressed():
	if current_query:
		if current_query == "bankruptcy":
			emit_signal("accept_bankruptcy")
			end_query()
		elif current_query == "sell_tower":
			emit_signal("accept_sell_tower")
			end_query()
			
