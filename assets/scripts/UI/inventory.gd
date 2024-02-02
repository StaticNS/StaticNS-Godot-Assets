class_name Inventory

var _content := {}

func add_item(item : Item, amount := 1):
	if !_content.has(item):
		_content[item] = amount
		return

	_content[item] += amount


func remove_item(item : Item, amount := 1):
	if !_content.has(item):
		return

	_content[item] -= amount

	if _content[item] <= 0 or amount < 0:
		_content.erase(item)


func get_items() -> Dictionary:
	return _content
