extends Node

signal on_create_block_text(unit: Node2D)
signal on_create_damage_text(unit: Node2D, hitbox: HitboxComponent)
signal on_create_heal_text(unit: Node2D, heal: float)

signal on_upgrade_selected
signal on_enemy_died(enemy: Enemy)

const FLASH_MATERIAL = preload("res://effects/flash_material.tres")
const FLOATING_TEXT = preload("res://scenes/ui/floating_text/floating_text.tscn")
const COINS_SCENE = preload("res://scenes/coins/coins.tscn")
const ITEM_CARD_SCENE = preload("res://scenes/ui/item_card/item_card.tscn")
const SELECTION_CARD_SCENE = preload("res://scenes/ui/selection_panel/selection_card.tscn")
const SPAWN_EFFECT_SCENE = preload("res://scenes/effects/enemy_spawn_effect.tscn")

const COMMON_STYLE = preload("res://styles/common_style.tres")
const EPIC_STYLE = preload("res://styles/epic_style.tres")
const LEGENDARY_STYLE = preload("res://styles/legendary_style.tres")
const RARE_STYLE = preload("res://styles/rare_style.tres")

const UPGRADE_PROBABILITY_CONFIG = {
	"rare": { "start_wave": 2, "base_multi": 0.06 },
	"epic": { "start_wave": 4, "base_multi": 0.02 },
	"legendary": { "start_wave": 7, "base_multi": 0.0023 },
}

const SHOP_PROBABILITY_CONFIG = {
	"rare": { "start_wave": 2, "base_multi": 0.10 },
	"epic": { "start_wave": 4, "base_multi": 0.06 },
	"legendary": { "start_wave": 7, "base_multi": 0.01 },
}

const TIER_COLORS: Dictionary[UpgradeTier, Color] = {
	UpgradeTier.RARE: Color(0.0, 0.557, 0.741),
	UpgradeTier.EPIC: Color(0.478, 0.251, 0.71),
	UpgradeTier.LEGENDARY: Color(0.906, 0.212, 0.212),
}

var available_players: Dictionary[String, PackedScene] = {
	"Brawler": preload("res://scenes/unit/players/player_brawler.tscn"),
	"Bunny": preload("res://scenes/unit/players/player_bunny.tscn"),
	"Crazy": preload("res://scenes/unit/players/player_crazy.tscn"),
	"Knight": preload("res://scenes/unit/players/player_knight.tscn"),
	"Well Rounded": preload("res://scenes/unit/players/player_well_rounded.tscn")
}

enum UpgradeTier{
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

var coins: int
var player: Player
var game_paused := false

var main_player_selected: UnitStats
var main_weapon_selected: ItemWeapon

var equipped_weapons: Array[ItemWeapon]

func get_selected_player() -> Player:
	var player_scene := available_players[main_player_selected.name]
	var player_instance := player_scene.instantiate()
	player = player_instance
	return player

func get_harvesting_coins() -> void:
	coins += player.stats.harvesting

func get_chance_success(chance: float) -> bool:
	var random := randf_range(0, 1.0)
	if random < chance:
		return true
	
	return false

func get_tier_style(tier: UpgradeTier) -> StyleBoxFlat:
	match tier:
		UpgradeTier.COMMON:
			return COMMON_STYLE
		UpgradeTier.RARE:
			return RARE_STYLE
		UpgradeTier.EPIC:
			return EPIC_STYLE
		_:
			return LEGENDARY_STYLE

func calculate_tier_probability(current_wave: int, config: Dictionary) -> Array[float]:
	var common_chance := 0.0
	var rare_chance := 0.0
	var epic_chance := 0.0
	var legendary_chance := 0.0
	
	# RARE: Starts increasing from wave 2 (0% at wave 1)
	if current_wave >= config.rare.start_wave:
		rare_chance = min(1.0, (current_wave - 1) * config.rare.base_multi)
	
	# EPIC Starts increasing from wave 4 (0% at wave 3)
	if current_wave >= config.epic.start_wave:
		epic_chance = min(1.0,  (current_wave - 3) * config.epic.base_multi)
	
	# LEGENDARY Starts increasing from wave 7 (0% at wave 6)
	if current_wave >= config.legendary.start_wave:
		legendary_chance = min(1.0,  (current_wave - 6) * config.legendary.base_multi)
	
	# Player luck increases chance of finding higher tiers
	var luck_factor := 1.0 + (Global.player.stats.luck / 100.0)
	rare_chance *= luck_factor
	epic_chance *= luck_factor
	legendary_chance *= luck_factor
	
	# Normalize probability
	var total_non_common_chances := rare_chance + epic_chance + legendary_chance
	if total_non_common_chances > 1.0:
		var scale_down := 1.0 / total_non_common_chances
		rare_chance *= scale_down
		epic_chance *= scale_down
		legendary_chance *= scale_down
		total_non_common_chances = 1.0
	
	# Common takes remaining probability
	common_chance = 1.0 - total_non_common_chances
	
	# Debug print
	print("Wave: %d, Luck: %.1f => Chances: C:%.2f R:%.2f E:%.2f L:%.2f" % 
	[current_wave, Global.player.stats.luck, common_chance, rare_chance, epic_chance, legendary_chance])
	
	return [
		max(0.0, common_chance),
		max(0.0, rare_chance),
		max(0.0, epic_chance),
		max(0.0, legendary_chance),
		]

func select_items_for_offer(item_pool: Array, current_wave: int, config: Dictionary) -> Array:
	var tier_chances := calculate_tier_probability(current_wave, config)
	
	var legendary_limit = tier_chances[3]
	var epic_limit = legendary_limit + tier_chances[2]
	var rare_limit = epic_limit + tier_chances[1]
	
	var offered_items: Array = []
	while offered_items.size() < 4:
		var roll := randf()
		var chosen_tier_index := 0
		if roll < legendary_limit:
			chosen_tier_index = 3 # Legendary
		elif roll < epic_limit:
			chosen_tier_index = 2 # Epic
		elif roll < rare_limit:
			chosen_tier_index = 1 # Rare
		
		var potential_items: Array = []
		var current_search_tier_index = chosen_tier_index
		
		while potential_items.is_empty() and current_search_tier_index >= 0:
			potential_items = item_pool.filter(func(item: ItemBase): return item.item_tier == current_search_tier_index)
			
			if potential_items.is_empty():
				current_search_tier_index -= 1
			else:
				break
		
		if not potential_items.is_empty():
			var selected_item = potential_items.pick_random()
			
			if not offered_items.has(selected_item):
				offered_items.append(selected_item)
	
	return offered_items

func emit_on_create_block_text(unit: Node2D):
	on_create_block_text.emit(unit)

func emit_on_create_damage_text(unit: Node2D, hitbox: HitboxComponent):
	on_create_damage_text.emit(unit, hitbox)

func emit_on_upgrade_selected():
	on_upgrade_selected.emit()

func emit_on_create_heal_text(unit: Node2D, heal: float):
	on_create_heal_text.emit(unit, heal)

func emit_on_enemy_died(enemy: Enemy):
	on_enemy_died.emit(enemy)
