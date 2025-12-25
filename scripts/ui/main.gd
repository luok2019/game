extends Node2D

# ============ 游戏状态 ============

var kill_count = 0  # 击杀数
# 【用途】记录玩家击杀敌人的总数
# 【显示】在屏幕左上角的 KillCountLabel 中显示

# ============ UI引用（Day 5 扩展）============

@onready var kill_label = $UI/KillCountLabel
# 【节点类型】Label
# 【用途】显示击杀数，格式： "击杀: 15"

@onready var attack_label = $UI/AttackLabel
# 【Day 5 新增】显示玩家攻击力
# 【节点类型】Label
# 【用途】显示当前攻击力，格式： "攻击力: 35"
# 【位置】在击杀数下方 (Position: 20, 50)
#
# 【注意】需要在 main.tscn 场景中手动添加 AttackLabel 节点
# 参考 Step 5.5 的场景搭建说明

@onready var player = $Player
# 【Day 5 新增】引用玩家节点
# 【用途】访问玩家的属性（如 attack_power）用于 UI 显示
# 【为什么需要】玩家的 attack_power 会随装备变化，需要实时获取最新值
#
# 【访问示例】
# player.attack_power  → 获取当前攻击力
# player.max_hp        → 获取最大血量
# player.hp            → 获取当前血量

@onready var camera = $Camera2D
# 【Day 7 新增】相机节点引用
# 【用途】实现震屏效果
# 【为什么需要】玩家受击时触发相机震动，增强打击感

# ============ 初始化 ============

func _ready() -> void:
	# 【生命周期】场景加载完成后自动调用
	# 【执行时机】游戏启动时执行一次

	# 初始化击杀数显示
	update_kill_count()

	# 【Day 5 新增】初始化攻击力显示
	update_player_stats()
	# 【效果】在屏幕左上角显示 "攻击力: 20"（初始值）


# ============ 击杀计数系统 ============

func add_kill() -> void:
	# 【公共接口方法】由敌人（enemy.gd）调用
	# 【调用时机】敌人死亡时（die() 函数中）
	# 【调用方式】main.add_kill()
	#
	# 【工作流程】
	# 1. 敌人被击杀 → enemy.die()
	# 2. enemy 获取 Main 节点 → get_tree().root.get_node("Main")
	# 3. enemy 调用此方法 → main.add_kill()
	# 4. kill_count 增加 → update_kill_count()
	# 5. UI 更新 → 屏幕显示新的击杀数

	# 击杀数加 1
	kill_count += 1

	# 更新 UI 显示
	update_kill_count()

	# 在控制台输出（用于调试）
	print("击杀数: ", kill_count)
	# 【输出示例】"击杀数: 15"


func update_kill_count() -> void:
	# 【方法职责】更新击杀数的 UI 显示
	#
	# 【调用时机】
	# 1. 游戏启动时（_ready 中）
	# 2. 每次击杀敌人后（add_kill 中）

	# 安全检查：确保 kill_label 节点存在
	if kill_label:
		# 更新 Label 的文本内容
		# 【格式】"击杀: " + 数字
		kill_label.text = "击杀: " + str(kill_count)
		# 【显示示例】
		# kill_count = 0  → "击杀: 0"
		# kill_count = 15 → "击杀: 15"
		# kill_count = 100 → "击杀: 100"
	#
	# 【为什么用 str()】
	# kill_count 是 int 类型，text 需要 String 类型
	# str() 将数字转换为字符串


# ============ 玩家属性显示系统（Day 5 新增）============

func update_player_stats() -> void:
	# 【公共接口方法】由玩家（player.gd）调用
	# 【调用时机】拾取装备、属性变化时
	# 【调用方式】main.update_player_stats()
	#
	# 【工作流程】
	# 1. 玩家拾取装备 → player.pickup_item()
	# 2. 重新计算属性 → player.recalculate_stats()
	# 3. 获取 Main 节点 → get_tree().root.get_node("Main")
	# 4. 调用此方法 → main.update_player_stats()
	# 5. UI 更新 → 屏幕显示新的攻击力
	#
	# 【为什么需要这个方法】
	# 玩家的 attack_power 是私有的，Main 需要通过接口获取
	# 这样实现了解耦：Player 不需要知道 UI 的具体实现

	# 安全检查：确保 player 和 attack_label 节点都存在
	# 【逻辑与】两个条件都为 true 才执行
	if player and attack_label:
		# 更新攻击力显示
		attack_label.text = "攻击力: " + str(player.attack_power)
		# 【显示示例】
		# 初始： attack_power = 20  → "攻击力: 20"
		# 拾取铁剑后： attack_power = 35 → "攻击力: 35"
		# 拾取稀有剑： attack_power = 55 → "攻击力: 55"
		#
		# 【实时更新】
		# 每次拾取装备，player.attack_power 重新计算
		# 此方法被调用，UI 显示最新值
	#
	# 【未来扩展】可以添加更多属性显示
	# if player:
	#     attack_label.text = "攻击力: " + str(player.attack_power)
	#     hp_label.text = "血量: " + str(player.hp) + "/" + str(player.max_hp)
	#     defense_label.text = "防御: " + str(player.defense)


# ============ 相机震动系统（Day 7 新增）============

func shake_camera(intensity: float = 5.0, duration: float = 0.2) -> void:
	"""
	【公共方法】触发相机震动效果

	参数：
		intensity - 震动强度（像素偏移量），默认5.0
		duration - 震动持续时间（秒），默认0.2

	使用示例：
		shake_camera(3.0, 0.15)  # 轻微震动
		shake_camera(10.0, 0.3)  # 强烈震动
	"""
	# 安全检查：确保相机存在
	if not camera:
		return

	# 保存原始偏移量
	var original_offset = camera.offset
	var shake_timer = 0.0

	# 震动循环
	while shake_timer < duration:
		# 生成随机偏移
		camera.offset = original_offset + Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		# 累计时间
		shake_timer += get_process_delta_time()
		# 等待下一帧
		await get_tree().process_frame

	# 恢复原始偏移
	camera.offset = original_offset
