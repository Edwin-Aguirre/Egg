extends Node

signal on_create_block_text(unit: Node2D)
signal on_create_damage_text(unit: Node2D, hitbox: HitboxComponent)

const FLASH_MATERIAL = preload("res://effects/flash_material.tres")
const FLOATING_TEXT = preload("res://scenes/ui/floating_text/floating_text.tscn")

enum UpgradeTier{
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

var player: Player

func get_chance_success(chance: float) -> bool:
	var random := randf_range(0, 1.0)
	if random < chance:
		return true
	
	return false

func emit_on_create_block_text(unit: Node2D):
	on_create_block_text.emit(unit)

func emit_on_create_damage_text(unit: Node2D, hitbox: HitboxComponent):
	on_create_damage_text.emit(unit, hitbox)
