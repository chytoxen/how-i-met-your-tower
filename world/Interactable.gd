class_name Interactable
extends StaticBody3D
## Anything the player can look at and press [E] on. The Player's ray looks for a
## body with an interact() method and shows its `prompt`.

@export var prompt := "Use  [E]"

func interact(_by: Node) -> void:
	pass
