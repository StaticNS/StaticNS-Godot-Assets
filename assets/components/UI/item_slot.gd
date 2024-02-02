class_name ItemSlot
extends PanelContainer

@onready var texture_rect : TextureRect = %TextureRect
@onready var name_label : Label = %NameLabel
@onready var amount_label : Label = %AmountLabel


func display(item : Item, amount : int):
	texture_rect.texture = item.icon
	name_label.text = item.name
	amount_label.text = ""
	if amount > 1:
		amount_label.text = str(amount)
