extends Node2D

# ============ 安全区脚本 ============
# 功能：显示游戏数据，提供休息环境

# ============ 节点引用 ============

@onready var player = $Player
@onready var kill_label = $UI/KillCountLabel

# ============ 初始化 ============

func _ready() -> void:
	"""安全区初始化"""
	# 标记当前在安全区
	GameData.current_zone = "safe"

	# 加载玩家状态
	if player:
		GameData.load_player_state(player)

	# 显示总击杀数
	update_ui()

	print("欢迎回到安全区！")

# ============ UI 更新 ============

func update_ui() -> void:
	"""更新 UI 显示"""
	if kill_label:
		kill_label.text = "总击杀: " + str(GameData.kill_count)
