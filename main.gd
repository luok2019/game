extends Node2D

# ============ 游戏状态 ============

var kill_count = 0  # 击杀数

# ============ UI引用 ============

@onready var kill_label = $UI/KillCountLabel

# ============ 初始化 ============

func _ready():
	update_kill_count()

# ============ 击杀计数 ============

func add_kill():
	# 【公共方法】敌人死亡时调用
	kill_count += 1
	update_kill_count()
	
	print("击杀数: ", kill_count)

func update_kill_count():
	# 更新UI显示
	if kill_label:
		kill_label.text = "击杀: " + str(kill_count)
