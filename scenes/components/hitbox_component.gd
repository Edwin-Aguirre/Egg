extends Area2D
class_name HitboxComponent

signal on_hit_hurtbox(hurtbox: HurtBoxComponent)

var damage := 1.0
var critical := false
var knockback_power := 0.0
var source: Node2D

func enable() -> void:
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func disable() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func setup(_damage: float, _critical: bool, _knockback: float, _source: Node2D) -> void:
	self.damage = _damage
	self.critical = _critical
	knockback_power = _knockback
	self.source = _source


func _on_area_entered(area: Area2D) -> void:
	if area is HurtBoxComponent:
		SoundManager.play_sound(SoundManager.Sound.ENEMY_HIT)
		on_hit_hurtbox.emit(area)
