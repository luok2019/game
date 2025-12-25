extends Panel

# ============ 装备槽脚本 ============
# 功能：管理单个背包格子的显示
# 每个格子显示一个装备的颜色（品质）和名称
# Day 6 新增功能

# ============ 装备数据 ============

var item_data: Dictionary = {}  # 存储该格子中的装备数据
# 数据格式：{type: "weapon", name: "铁剑", rarity: 1, stats: {attack: 15}}
# 如果为空字典 {}，表示该格子没有装备

var slot_index: int = -1  # 格子在背包中的索引（0-8）
# 预留字段，当前未使用，可用于后续扩展功能


# ============ 设置装备数据 ============

func set_item_data(data: Dictionary) -> void:
	"""
	设置格子的装备数据并更新显示

	参数：
		data - 装备数据字典
	"""
	# 保存装备数据到实例变量
	item_data = data

	# 更新格子的视觉显示
	update_display()


func update_display() -> void:
	"""根据装备数据更新格子的视觉效果"""
	# 获取子节点引用
	# $ItemIcon 是装备图标（彩色方块）
	# $ItemName 是装备名称标签
	var icon = $ItemIcon
	var name_label = $ItemName

	if item_data.has("name"):
		# 【有装备】显示装备的颜色和名称

		# 设置装备图标颜色
		# ItemData.rarity_colors 是一个预定义的颜色数组
		# 根据稀有度（rarity）选择对应颜色：
		# - 0 (普通) → 白色
		# - 1 (优秀) → 绿色
		# - 2 (稀有) → 蓝色
		# - 3 (史诗) → 紫色
		icon.color = ItemData.rarity_colors[item_data["rarity"]]

		# 显示装备名称
		name_label.text = item_data["name"]
	else:
		# 【空格子】显示灰色，无名称
		icon.color = Color(0.5, 0.5, 0.5)  # 灰色
		name_label.text = ""  # 清空名称


func clear_item() -> void:
	"""
	清空格子的装备数据
	当装备被移除或格子被清空时调用
	"""
	# 将装备数据重置为空字典
	item_data = {}

	# 更新显示为空格子状态
	update_display()
