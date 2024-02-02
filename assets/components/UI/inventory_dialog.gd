class_name InventoryDialog
extends PanelContainer

@export var slot_scene : PackedScene
@onready var grid_container : GridContainer = %GridContainer


func open(inventory : Inventory):
	show()
	
	for child in grid_container.get_children():
		child.queue_free()
	
	var contents = inventory.get_items()
	for item in contents:
		var slot : ItemSlot = slot_scene.instantiate()
		grid_container.add_child(slot)
		slot.display(item, contents[item])


func close():
	hide()


func _on_close_button_pressed():
	close()
