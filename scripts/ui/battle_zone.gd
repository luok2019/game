extends Node2D

# ============ 战斗区脚本 ============
# 功能：战斗区域逻辑，同步全局数据

# ============ 节点引用 ============

@onready var player = $Player
@onready var kill_label = $UI/KillCountLabel
@onready var attack_label = $UI/AttackLabel
@onready var camera = $Camera2D

# ============ 游戏状态 ============

var kill_count = 0  # 击杀数（本地显示用）

# ============ 初始化 ============

func _ready() -> void:
	"""战斗区初始化"""
	# 标记当前在战斗区
	GameData.current_zone = "battle"

	# 从 GameData 加载玩家状态
	if player:
		GameData.load_player_state(player)

	# 从 GameData 同步击杀数
	kill_count = GameData.kill_count

	# 初始化 UI
	update_kill_count()
	update_player_stats()

	print("进入战斗区，当前击杀数: ", kill_count)

# ============ 击杀计数系统 ============

func add_kill() -> void:
	"""击杀敌人 - 同步到全局数据"""
	# 本地击杀数 +1
	kill_count += 1

	# 同步到全局数据
	GameData.kill_count = kill_count

	# 更新 UI
	update_kill_count()

	print("击杀数: ", kill_count)

func update_kill_count() -> void:
	"""更新击杀数的 UI 显示"""
	if kill_label:
		kill_label.text = "击杀: " + str(kill_count)

# ============ 玩家属性显示系统 ============

func update_player_stats() -> void:
	"""更新玩家属性显示"""
	if player and attack_label:
		attack_label.text = "攻击力: " + str(player.attack_power)

# ============ 相机震动系统 ============

func shake_camera(intensity: float = 5.0, duration: float = 0.2) -> void:
	"""触发相机震动效果"""
	if not camera:
		return

	var original_offset = camera.offset
	var shake_timer = 0.0

	while shake_timer < duration:
		# 检查场景是否仍在树中
		if not is_inside_tree():
			return

		camera.offset = original_offset + Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		shake_timer += get_process_delta_time()
		await get_tree().process_frame

	# 最后检查一次，确保场景仍在
	if is_inside_tree() and camera:
		camera.offset = original_offset
