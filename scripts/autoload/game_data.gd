extends Node

# ============ 全局数据管理器 ============
# 功能：保存游戏数据，在场景切换后不丢失
# 使用方式：GameData.kill_count（任何脚本都能访问）

# ============ 游戏数据 ============

var kill_count: int = 0  # 击杀数
var player_items: Array = []  # 背包装备

# 玩家属性
var player_hp: int = 100
var player_max_hp: int = 100
var player_attack: int = 100

# ============ 当前场景标记 ============

var current_zone: String = "safe"  # "safe" 或 "battle"

# ============ 数据操作方法 ============

func add_kill() -> void:
	"""增加击杀数"""
	kill_count += 1
	print("全局击杀数: ", kill_count)

func reset_game() -> void:
	"""重置游戏数据（新游戏/死亡后）"""
	kill_count = 0
	player_items.clear()
	player_hp = 100
	player_max_hp = 100
	player_attack = 100
	print("游戏数据已重置")

func save_player_state(player: Variant) -> void:
	"""
	保存玩家状态（切换场景前调用）

	参数：player - 玩家节点（使用 Variant 类型以支持不同类型）
	"""
	if player and player.has_method("take_damage"):
		player_hp = player.hp
		player_max_hp = player.max_hp
		# 安全获取攻击力
		if player.has_method("recalculate_stats"):
			player_attack = player.attack_power
		# 背包数据由 Inventory 自己管理

func load_player_state(player: Variant) -> void:
	"""
	加载玩家状态（进入场景后调用）

	参数：player - 玩家节点（使用 Variant 类型以支持不同类型）
	"""
	if player and player.has_method("take_damage"):
		player.hp = player_hp
		player.max_hp = player_max_hp
		if player.has_method("recalculate_stats"):
			player.attack_power = player_attack
		# 延迟更新血条，确保场景树已构建完成
		player.call_deferred("update_hp_bar")
