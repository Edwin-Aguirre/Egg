extends Node2D
class_name Unit

@export var stats: UnitStats

@onready var visuals: Node2D = %Visuals
@onready var sprite: Sprite2D = %Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
