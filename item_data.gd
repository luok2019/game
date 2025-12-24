extends Object
# 【说明】这不是Node，是纯数据类
# 不能添加到场景树，只用来存储数据

class_name ItemData
# 【概念】class_name
# - 给这个类一个全局名称
# - 其他脚本可以直接用ItemData
# - 不需要preload()

# ============ 品质枚举 ============

enum Rarity {
	COMMON,    # 0 - 普通（白色）
	UNCOMMON,  # 1 - 优秀（绿色）
	RARE,      # 2 - 稀有（蓝色）
	EPIC       # 3 - 史诗（紫色）
}
# 【概念】enum（枚举）
# - 定义一组命名的常量
# - 比用字符串更安全（拼写错误会报错）
# - 比用数字更可读（Rarity.RARE比2清晰）

# ============ 品质配置 ============

static var rarity_colors = {
	Rarity.COMMON: Color(0.8, 0.8, 0.8),    # 白色
	Rarity.UNCOMMON: Color(0.3, 0.8, 0.3),  # 绿色
	Rarity.RARE: Color(0.3, 0.5, 1.0),      # 蓝色
	Rarity.EPIC: Color(0.7, 0.3, 1.0)       # 紫色
}
# 【说明】每个品质对应一个颜色

static var rarity_names = {
	Rarity.COMMON: "普通",
	Rarity.UNCOMMON: "优秀",
	Rarity.RARE: "稀有",
	Rarity.EPIC: "史诗"
}

# ============ 装备模板 ============

static var item_templates = {
	"weapon": {
		"sword_1": {
			"name": "铁剑",
			"base_attack": 10
		},
		"sword_2": {
			"name": "钢剑",
			"base_attack": 20
		},
		"sword_3": {
			"name": "精钢剑",
			"base_attack": 35
		}
	},
	"armor": {
		"armor_1": {
			"name": "布衣",
			"base_hp": 30
		},
		"armor_2": {
			"name": "皮甲",
			"base_hp": 60
		}
	}
}
# 【说明】base_attack是基础攻击力
# 实际掉落时会根据品质加成

# ============ 生成随机装备 ============

static func generate_random_item() -> Dictionary:
	# 【返回类型】-> Dictionary
	# 表示这个函数返回一个字典
	
	# 随机选择类型（武器或防具）
	var types = ["weapon", "armor"]
	var item_type = types.pick_random()
	
	# 随机选择该类型的模板
	var templates = item_templates[item_type]
	var template_keys = templates.keys()
	var template_id = template_keys.pick_random()
	var template = templates[template_id]
	
	# 随机品质（带权重）
	var rarity = generate_random_rarity()
	
	# 创建装备数据
	var item = {
		"type": item_type,
		"template_id": template_id,
		"name": template["name"],
		"rarity": rarity,
		"stats": {}
	}
	
	# 根据品质计算属性
	if item_type == "weapon":
		var base_attack = template["base_attack"]
		item["stats"]["attack"] = calculate_stat_with_rarity(base_attack, rarity)
	elif item_type == "armor":
		var base_hp = template["base_hp"]
		item["stats"]["hp"] = calculate_stat_with_rarity(base_hp, rarity)
	
	return item
	# 【示例返回值】
	# {
	#     "type": "weapon",
	#     "template_id": "sword_1",
	#     "name": "铁剑",
	#     "rarity": Rarity.RARE,
	#     "stats": {"attack": 15}
	# }

static func generate_random_rarity() -> int:
	# 【品质掉落概率】Day 5 测试用：提高稀有装备概率
	#
	# 【原版概率】（正式发布时可恢复）
	# - 普通：60%（0.00 - 0.60）
	# - 优秀：30%（0.60 - 0.90）
	# - 稀有：8%（0.90 - 0.98）
	# - 史诗：2%（0.98 - 1.00）
	#
	# 【Day 5 测试版概率】（当前使用）
	# - 普通：50%（0.00 - 0.50）
	# - 优秀：30%（0.50 - 0.80）
	# - 稀有：15%（0.80 - 0.95）
	# - 史诗：5%（0.95 - 1.00）
	#
	# 【为什么提高概率】
	# - 测试装备系统时需要频繁遇到稀有装备
	# - 稀有装备从 8% 提高到 15%（近2倍）
	# - 史诗装备从 2% 提高到 5%（2.5倍）
	# - 这样玩家能更快体验到完整系统
	#
	# 【如何恢复原版】
	# 将下方的数值改回：
	# 0.50 → 0.60（普通）
	# 0.80 → 0.90（优秀）
	# 0.95 → 0.98（稀有）

	var rand = randf()  # 生成 0.0 到 1.0 的随机数
	# 【概念】randf() = random float
	# 返回值示例：0.123, 0.456, 0.789, 0.987

	# 【判断逻辑】从低到高依次判断
	if rand < 0.50:  # 【Day 5 改】原值 0.60
		# 0% - 50% 的区间
		return Rarity.COMMON
		# 返回 0（普通品质）
		# 【概率】50%

	elif rand < 0.80:  # 【Day 5 改】原值 0.90
		# 50% - 80% 的区间
		return Rarity.UNCOMMON
		# 返回 1（优秀品质）
		# 【概率】30%

	elif rand < 0.95:  # 【Day 5 改】原值 0.98
		# 80% - 95% 的区间
		return Rarity.RARE
		# 返回 2（稀有品质）
		# 【概率】15%

	else:
		# 95% - 100% 的区间
		return Rarity.EPIC
		# 返回 3（史诗品质）
		# 【概率】5%

	# 【验证计算】
	# 50% + 30% + 15% + 5% = 100% ✓
	# 所有情况都被覆盖，不会有遗漏

static func calculate_stat_with_rarity(base_value: float, rarity: int) -> int:
	# 【品质加成】
	# 普通：100%
	# 优秀：130%
	# 稀有：170%
	# 史诗：220%
	
	var multipliers = {
		Rarity.COMMON: 1.0,
		Rarity.UNCOMMON: 1.3,
		Rarity.RARE: 1.7,
		Rarity.EPIC: 2.2
	}
	
	var multiplier = multipliers[rarity]
	return int(base_value * multiplier)
	# 【示例】
	# 铁剑基础攻击10
	# 稀有品质：10 * 1.7 = 17

# ============ 获取装备显示名称 ============

static func get_full_name(item: Dictionary) -> String:
	# 【格式】品质 + 名称
	# 例如："稀有 铁剑"
	var rarity_name = rarity_names[item["rarity"]]
	return rarity_name + " " + item["name"]
