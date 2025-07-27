extends Area2D
class_name HurtBoxComponent

signal on_damage(hitbox: HitboxComponent)



func _on_area_entered(area: Area2D) -> void:
	if area is HitboxComponent:
		on_damage.emit(area)
