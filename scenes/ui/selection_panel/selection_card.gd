extends Button
class_name SelectionCard

func set_icon(texture: Texture2D) -> void:
	icon = texture

func _on_pressed() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)

func _on_mouse_entered() -> void:
	SoundManager.play_sound(SoundManager.Sound.UI)
	
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.1,1.1), 0.1)
	
	if tween.finished:
		tween.tween_property(self, "scale", Vector2(1,1), 0.1)
