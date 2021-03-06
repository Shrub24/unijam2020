extends Polygon2D
class_name Town

export var population = 0
export(Array, String) var neighbours
export var shares = {"Tedstra":0, "Vodaclone":0, "ElonMask Co":0, "PanCogan Mobile":0}
export(Dictionary) var sprites = {"Tedstra": {"3g": 0, "4g": 0, "5g": 0}, "Vodaclone": {"3g": 0, "4g": 0, "5g":0}, "ElonMask Co":{"3g": 0, "4g": 0, "5g":0}, "PanCogan Mobile":{"3g": 0, "4g": 0, "5g":0}, "Who-awei":{"3g": 0, "4g": 0, "5g":0}, "Xiaomy":{"3g": 0, "4g": 0, "5g":0}, "Alidada":{"3g": 0, "4g": 0, "5g":0}, "Knockia":{"3g": 0, "4g": 0, "5g":0}}
export var starter_town = false
export(String) var town_name
export(PackedScene) var ISPTownInfo_scene
var neighbour_towns = []
var ISPs = {}
var Player_ISPTownInfo
export(float) var affluency
export(NodePath) onready var bound
export(NodePath) onready var border
var unselected_opacity
var hover_opacity
export var selected_opacity = 0.8
export var player_opacity = 0.2
export var base_unselected_opacity = 0.4
export var base_hover_opacity = 0.7
var selected = false

signal clicked(town)
signal town_mouse_entered
signal town_mouse_exited

var no_ISP_pop = 0
var affluency_connection_delta = {}
var hovered = false

export(NodePath) onready var tower_sprite = get_node(tower_sprite) if tower_sprite else null

export var tower_loc = [0, 0] 

#put this somewhere else?
export var base_aoe_image = 0.05

export var min_no_ISP = 2
export var max_no_ISP = 10
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	
	population /= 10

	hover_opacity = base_hover_opacity
	unselected_opacity = base_unselected_opacity
	get_node(bound).set_polygon(polygon)
	border = get_node(border)
	selected_opacity = border.modulate.a
	border.set_polygon(polygon)
	self_modulate.a = 0

	# set initial pop with no ISP
	rng.randomize()
	randomize()
	
	if check_ISPs_exist() or starter_town:
		no_ISP_pop = int(rng.randf_range(min_no_ISP, max_no_ISP) * population/100)
	else:
		no_ISP_pop = population
		
	randomise_shares()
	
func randomise_shares():
	var ISPs = []
	var share_vals = []
	for ISP in shares.keys():
		var val = shares[ISP]
		if val != 0:
			ISPs.append(ISP)
			share_vals.append(val)
	share_vals.shuffle()
	for i in range(0, len(ISPs)):
		shares[ISPs[i]] = share_vals[i]

func check_ISPs_exist():
	for val in shares.values():
		if val != 0:
			return true
	return false
	
func init_starter_town(player):
	create_ISPTownInfo(player.ISP)
	Player_ISPTownInfo.generate_starter(no_ISP_pop)
	var tower = Player_ISPTownInfo.tower
	propagate_brand_image(tower, Player_ISPTownInfo.ISP, tower.get_reach())
	
	get_tree().call_group("tower_sprite_changers", "add_tower_sprite", player.ISP.ISP_name, tower.tower_type, tower_loc)

# population - noISPs in generates
func init_town_ISPs(AIs):
	for AI in AIs:
		var ISP = AI.ISP
		if shares[ISP.ISP_name] != 0:
			var ISPTownInfo = create_ISPTownInfo(ISP)
			ISPTownInfo.generate(shares[ISP.ISP_name], no_ISP_pop, affluency)
			var tower = ISPTownInfo.tower
			propagate_brand_image(tower, ISPTownInfo.ISP, tower.get_reach())
			
#	if town_name == "Berwick":
#		for isp in ISPs.keys():
#			print(isp.ISP_name + ": " + str(ISPs[isp].connections))
#		print("No ISPpop: " + str(no_ISP_pop))
#		print("\n")

func set_town_colour():
	hover_opacity = base_hover_opacity
	unselected_opacity = base_unselected_opacity
	var ashares = get_ISP_shares()
	var max_ISP = null
	for ISP in ashares.keys():
		if !max_ISP:
			max_ISP = ISP
		elif ashares[ISP] > ashares[max_ISP]:
			max_ISP = ISP
	if max_ISP:
		border.set_color(max_ISP.primary_colour)
		border.border_color = max_ISP.secondary_colour
		if max_ISP.is_player:
			unselected_opacity = base_unselected_opacity + player_opacity
			hover_opacity = base_hover_opacity + player_opacity
	if selected:
		select()
	else:
		deselect()

func get_ISP_town_info(ISP):
	if ISPs.keys().has(ISP):
		return ISPs[ISP]
	return false

func get_ISP_shares():
	var ISP_shares = {}
	for ISP in get_ISPs():
		var share = get_share(ISP)
		if share:
			ISP_shares[ISP] = get_share(ISP)
		
	return ISP_shares


func get_ISP_town_infos():
	var town_infos = ISPs.values()
	return town_infos

func get_ISPs():
	var ISP_list = ISPs.keys()
	return ISP_list

func get_max_speed():
	var max_speed = 0
	for town_info in get_ISP_town_infos():
		if town_info.tower:
			var speed = town_info.tower.get_speed()
			if  speed > max_speed:
				max_speed = speed
	return max_speed

func get_max_tower_type():
	var max_type = ""
	for town_info in get_ISP_town_infos():
		if town_info.tower:
			var type = town_info.tower.tower_type
			if max_type in ["", "3g"]:
				if type in ["3g", "4g", "5g"]:
					max_type = type
			elif max_type == "4g":
				if type == "5g":
					max_type = "5g"
	return max_type

func get_share(ISP):
	return float(ISPs[ISP].connections)/population
	
func update_turn():
#	if town_name == "Juliest":
#		var pop = 0
#		for town_info in ISPs.values():
#			pop += town_info.connections
#		pop += no_ISP_pop
#		print(pop)
	var ISPTownInfos = get_ISP_town_infos()
	for town_info in ISPTownInfos:
		if town_info.tower:
			town_info.get_connections_loss(ISPTownInfos)
			affluency_connection_delta[town_info] = town_info.get_affluency_delta(affluency)
	
	
	normalise_affluency_delta()
	affluency_convert_pos_share_to_pop()

	for town_info in ISPTownInfos:
		if town_info.tower:
			town_info.get_connections_delta()
	for town_info in ISPTownInfos:
		town_info.update_turn(get_max_speed())
		if town_info.tower:
			no_ISP_pop -= town_info.update_affluency_conns(affluency_connection_delta[town_info])
	set_town_colour()

func create_ISPTownInfo(ISP):
	var ISPTownInfo = ISPTownInfo_scene.instance()
	ISPTownInfo.initialise(ISP, self, population)
	ISPs[ISP] = ISPTownInfo
	if ISP.is_player:
		Player_ISPTownInfo = ISPTownInfo
	return ISPTownInfo
	
func propagate_brand_image(tower, ISP, dist):
	var town_info = get_ISP_town_info(ISP)
	if !town_info:
		town_info = create_ISPTownInfo(ISP)
	town_info.update_aoe_image(tower, base_aoe_image * (dist + 1))
	if dist > 0:
		# neighbours list of town objects
		for town in neighbour_towns:
			town.propagate_brand_image(tower, ISP, dist - 1)

func depropagate_brand_image(tower, ISP, dist):
	var town_info = get_ISP_town_info(ISP)
	if town_info:
		ISPs[ISP].remove_aoe_image(tower)
	if dist > 0:
		for town in neighbour_towns:
			town.depropagate_brand_image(tower, ISP, dist - 1)

func normalise_affluency_delta():
	var pos_sum = 0.0
	for delta in affluency_connection_delta.values():
		if delta > 0:
			pos_sum += delta
	for ISP in affluency_connection_delta.keys():
		if pos_sum > 100:
			affluency_connection_delta[ISP] /= (pos_sum/100)

func build_tower(ISP, tower):
	get_ISP_town_info(ISP).build_tower(tower)
	propagate_brand_image(tower, ISP, tower.get_reach())
	#todo sprite changing
	#var sprite = sprites[ISP][tower.type()]
	get_tree().call_group("tower_sprite_changers", "add_tower_sprite", ISP.ISP_name, tower.tower_type, tower_loc)
	
func sell_tower(ISP):
	var town_info = get_ISP_town_info(ISP)
	var tower = town_info.tower
	depropagate_brand_image(tower, ISP, tower.get_reach())
	get_ISP_town_info(ISP).remove_tower()
	# remove all remaining pops from player ISP
	no_ISP_pop += town_info.update_affluency_conns(-100)
	
	get_tree().call_group("tower_sprite_changers", "remove_tower_sprite", tower_loc)

# converts pos shares in get_affluency_delta to pops
func affluency_convert_pos_share_to_pop():
	var pop_sum = 0
	for ISP in affluency_connection_delta.keys():
		var share_delta = affluency_connection_delta[ISP]
		if share_delta > 0:
			affluency_connection_delta[ISP] = int(no_ISP_pop * share_delta/100)

func upgrade_tower(ISP, type):
	get_ISP_town_info(ISP).upgrade_tower(type)
	var tower = get_ISP_town_info(ISP).tower
	if type == "reach":
		propagate_brand_image(tower, ISP, tower.get_reach())

func deselect():
	hovered = true
	selected = false
	border.modulate.a = unselected_opacity
	border.update_color_and_opacity()
		
func select():
	hovered = false
	selected = true
	border.modulate.a = selected_opacity
	border.update_color_and_opacity()

func _on_Collider_mouse_entered():
	if !selected and !hovered:
		hovered = true
		border.modulate.a = hover_opacity
		border.update_color_and_opacity()

func _on_Collider_mouse_exited():
	if hovered:
		hovered = false
		border.modulate.a = unselected_opacity
		border.update_color_and_opacity()

func _on_Collider_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("ui_click"):
		emit_signal("clicked", self)

