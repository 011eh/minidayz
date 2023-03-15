extends Dialog


signal item_splitted


var item: NumberItem


func show_dialog(item: NumberItem) -> void:
	self.item = item
	var id := item.get_item_id()
	%ItemLabel.text = item.get_item_name()
	%SpinBox.max_value = item.number - 1
	%SpinBox.value = item.number / 2
	%ItemIcon.texture.region = Rect2(id % 5 * 32, id / 5 * 32, 32, 32)
	visible = true

func button_action() -> void:
	var splitted := item.duplicate()
	splitted.number = %SpinBox.value
	item.number -= %SpinBox.value
	visible = false
	item_splitted.emit(splitted)
