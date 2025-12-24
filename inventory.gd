extends Control

# ============ 背包系统脚本 ============
# 功能：管理玩家背包界面，包括物品的添加、显示、装备和卸下
# Day 6 新增功能

# ============ 背包设置 ============

const MAX_SLOTS = 9  # 背包最大格子数（3行3列）
var item_slot_scene = preload("res://item_slot.tscn")  # 预加载格子场景

# ============ 背包数据 ============

var items = []  # 存储装备数据的数组
# 数据格式示例：
# [
#   {type: "weapon", name: "铁剑", rarity: 1, stats: {attack: 15}},  # 格子0：有武器
#   null,                                                            # 格子1：空
#   {type: "armor", name: "皮甲", rarity: 0, stats: {hp: 20}},      # 格子2：有防具
#   ...
# ]
# null 表示该格子为空

var selected_index = -1  # 当前选中的格子索引，-1 表示未选中

# ============ 节点引用 ============
# @onready 变量会在节点准备好后才赋值，避免 _ready() 中找不到节点

@onready var item_grid = $MainPanel/ItemGrid         # 格子容器（GridContainer）
@onready var detail_label = $MainPanel/DetailPanel/DetailLabel  # 详情文本标签
@onready var equip_button = $MainPanel/DetailPanel/EquipButton  # 装备/卸下按钮
@onready var title_label = $MainPanel/TitleLabel     # 标题标签（显示容量）

# ============ 初始化 ============

func _ready() -> void:
	"""背包初始化，在场景加载时自动调用"""
	# 第一步：初始化空背包数据
	# 创建包含 9 个 null 元素的数组，代表 9 个空格子
	for i in range(MAX_SLOTS):
		items.append(null)

	# 第二步：创建格子 UI
	# 动态实例化 9 个格子场景并添加到网格容器中
	create_slots()

	# 第三步：连接装备按钮的点击信号
	# 当玩家点击"装备"或"卸下"按钮时，会调用 _on_equip_button_pressed 方法
	equip_button.pressed.connect(_on_equip_button_pressed)

	# 第四步：默认隐藏背包
	# 背包初始状态是隐藏的，玩家按 I 键时才显示
	hide()

	# 第五步：更新标题显示
	# 显示当前装备数量和最大容量，例如："背包 (3/9) (按I关闭)"
	update_title()


func create_slots() -> void:
	"""创建背包格子的 UI 组件"""
	# 循环创建 9 个格子
	for i in range(MAX_SLOTS):
		# 实例化单个格子场景
		var slot = item_slot_scene.instantiate()

		# 设置格子名称，便于后续通过名称查找（可选）
		# 例如："Slot0", "Slot1", "Slot2", ...
		slot.name = "Slot" + str(i)

		# 将格子添加到网格容器中
		# GridContainer 会自动按 3 列布局排列格子
		item_grid.add_child(slot)

		# 连接格子的鼠标输入信号
		# gui_input 是 Panel 内置信号，当鼠标与格子交互时触发
		# .bind(i) 将格子的索引作为参数传递，这样点击时就知道是哪个格子
		slot.gui_input.connect(_on_slot_clicked.bind(i))


# ============ 输入处理 ============

func _input(event: InputEvent) -> void:
	"""全局输入事件处理，监听按键"""
	# 方式一：按 ESC 键（使用 Godot 预定义的 ui_cancel 动作）
	if event.is_action_pressed("ui_cancel"):
		toggle_inventory()

	# 方式二：按 I 键（自定义按键）
	# 检测是否是键盘事件、按键是否按下、是否是 I 键
	elif event is InputEventKey and event.pressed and event.keycode == KEY_I:
		toggle_inventory()


func toggle_inventory() -> void:
	"""切换背包的显示/隐藏状态"""
	# 切换可见性：显示→隐藏，隐藏→显示
	visible = !visible

	# 暂停/恢复游戏
	# 显示背包时暂停游戏，隐藏时恢复游戏
	# 这样玩家在整理背包时游戏不会继续
	if visible:
		get_tree().paused = true
	else:
		get_tree().paused = false


# ============ 添加装备 ============

func add_item(item_data: Dictionary) -> bool:
	"""
	【公共方法】向背包添加装备
	由 player.pickup_item() 调用

	参数：
		item_data - 装备数据字典，格式：{type: "weapon", name: "铁剑", rarity: 1, stats: {...}}

	返回：
		true - 添加成功
		false - 背包已满，添加失败
	"""
	# 遍历所有格子，查找第一个空格子
	for i in range(items.size()):
		if items[i] == null:  # 找到空格子
			# 将装备数据存入数组
			items[i] = item_data

			# 更新该格子的 UI 显示
			update_slot(i)

			# 更新背包标题的容量显示
			update_title()

			return true  # 添加成功

	# 如果循环结束还没返回，说明背包已满
	print("背包已满！")
	return false


func update_slot(index: int) -> void:
	"""
	更新指定格子的显示

	参数：
		index - 格子索引（0-8）
	"""
	# 获取对应索引的格子节点
	var slot = item_grid.get_child(index)

	# 获取该格子存储的装备数据
	var item = items[index]

	if item:
		# 【有装备】调用格子的 set_item_data 方法
		# 这会更新格子的颜色（品质）和名称
		slot.set_item_data(item)
	else:
		# 【空格子】调用格子的 clear_item 方法
		# 这会将格子重置为灰色状态
		slot.clear_item()


func update_title() -> void:
	"""更新背包标题，显示当前装备数量"""
	# 统计非空格子数量
	var count = 0
	for item in items:
		if item != null:
			count += 1

	# 更新标题文本，例如："背包 (3/9) (按I关闭)"
	title_label.text = "背包 (%d/%d) (按I关闭)" % [count, MAX_SLOTS]


# ============ 点击格子 ============

func _on_slot_clicked(event: InputEvent, index: int) -> void:
	"""
	格子的鼠标点击事件回调
	由 slot.gui_input 信号触发

	参数：
		event - 输入事件对象
		index - 被点击格子的索引
	"""
	# 检查是否是鼠标左键按下
	# MOUSE_BUTTON_LEFT 是 Godot 内置常量，代表左键
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 选中该格子
		select_slot(index)


func select_slot(index: int) -> void:
	"""
	选中指定格子，显示装备详情

	参数：
		index - 格子索引（0-8）
	"""
	# 记录当前选中的格子索引
	selected_index = index

	# 获取该格子的装备数据
	var item = items[index]

	if item:
		# 【有装备】显示装备详情面板
		show_item_details(item)
	else:
		# 【空格子】显示提示文本，隐藏按钮
		detail_label.text = "空格子"
		equip_button.visible = false


func show_item_details(item: Dictionary) -> void:
	"""
	在详情面板显示装备信息

	参数：
		item - 装备数据字典
	"""
	# 构建详情文本
	var details = ""

	# 第一行：装备全名（包含稀有度）
	# 例如："稀有 铁剑"
	details += ItemData.get_full_name(item) + "\n\n"

	# 第二部分：属性列表
	details += "属性:\n"
	for stat in item["stats"]:
		var value = item["stats"][stat]
		var stat_name = get_stat_display_name(stat)  # 转换为中文显示名
		details += stat_name + ": +" + str(value) + "\n"

	# 更新详情文本
	detail_label.text = details

	# 显示装备/卸下按钮
	equip_button.visible = true

	# 检查该装备是否已经装备在玩家身上
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var is_equipped = false  # 默认未装备

		# 根据装备类型检查对应的装备槽
		if item["type"] == "weapon":
			# 检查武器的名称是否匹配
			# 注意：不能直接用 player.equipped_weapon == item 比较
			# 因为字典是引用类型，即使内容相同也会返回 false
			# 所以我们需要比较字典内部的字段
			if player.equipped_weapon.has("name") and player.equipped_weapon["name"] == item["name"]:
				is_equipped = true

		elif item["type"] == "armor":
			# 检查防具的名称是否匹配
			if player.equipped_armor.has("name") and player.equipped_armor["name"] == item["name"]:
				is_equipped = true

		# 根据装备状态更新按钮文本
		if is_equipped:
			equip_button.text = "卸下"  # 已装备，显示"卸下"按钮
		else:
			equip_button.text = "装备"  # 未装备，显示"装备"按钮


func get_stat_display_name(stat: String) -> String:
	"""
	将属性代码转换为中文显示名称

	参数：
		stat - 属性代码（例如："attack"）

	返回：
		中文属性名称（例如："攻击力"）
	"""
	# 属性名称映射表
	var names = {
		"attack": "攻击力",  # 攻击力属性
		"hp": "生命值",      # 生命值属性
		"defense": "防御力", # 防御力属性
		"speed": "速度"      # 速度属性
	}

	# 如果找不到对应的中文名，返回原始代码
	return names.get(stat, stat)


# ============ 装备/卸下 ============

func _on_equip_button_pressed() -> void:
	"""装备/卸下按钮的点击事件回调"""
	# 安全检查：确保有选中的格子
	if selected_index < 0:
		return

	# 获取选中格子的装备数据
	var item = items[selected_index]

	# 安全检查：确保格子有装备
	if not item:
		return

	# 获取玩家节点
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# 检查该装备是否已装备
	var is_equipped = false
	if item["type"] == "weapon":
		if player.equipped_weapon.has("name") and player.equipped_weapon["name"] == item["name"]:
			is_equipped = true
	elif item["type"] == "armor":
		if player.equipped_armor.has("name") and player.equipped_armor["name"] == item["name"]:
			is_equipped = true

	# 根据当前状态执行装备或卸下操作
	if is_equipped:
		# 当前已装备 → 执行卸下
		unequip_item(item)
	else:
		# 当前未装备 → 执行装备
		equip_item(item)

	# 刷新详情面板显示
	# 这会更新按钮文本（装备↔卸下）和属性显示
	select_slot(selected_index)


func equip_item(item: Dictionary) -> void:
	"""
	装备指定的物品

	参数：
		item - 装备数据字典
	"""
	# 获取玩家节点
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# 根据装备类型调用对应的装备方法
	if item["type"] == "weapon":
		# 装备武器
		# 注意：简化版本直接替换，没有处理旧武器放回背包的逻辑
		player.equip_weapon(item)

	elif item["type"] == "armor":
		# 装备防具
		player.equip_armor(item)

	# 重新计算玩家属性
	# 这会将装备的属性加成应用到玩家身上
	player.recalculate_stats()

	# 控制台输出提示
	print("装备: ", ItemData.get_full_name(item))


func unequip_item(item: Dictionary) -> void:
	"""
	卸下指定的装备

	参数：
		item - 装备数据字典
	"""
	# 获取玩家节点
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# 根据装备类型清空对应的装备槽
	if item["type"] == "weapon":
		# 清空武器槽
		player.equipped_weapon = {}
		# 清空武器攻击力加成
		player.equipment_bonus["attack"] = 0

	elif item["type"] == "armor":
		# 清空防具槽
		player.equipped_armor = {}
		# 清空防具生命值加成
		player.equipment_bonus["hp"] = 0

	# 重新计算玩家属性
	# 这会移除装备的属性加成
	player.recalculate_stats()

	# 控制台输出提示
	print("卸下: ", ItemData.get_full_name(item))


# ============ 移除装备 ============

func remove_item(index: int) -> void:
	"""
	【公共方法】从背包移除装备
	可以用于丢弃物品、消耗品使用等场景

	参数：
		index - 格子索引（0-8）
	"""
	# 检查索引是否有效
	if index >= 0 and index < items.size():
		# 将该格子设为空
		items[index] = null

		# 更新该格子的 UI
		update_slot(index)

		# 更新背包标题
		update_title()
