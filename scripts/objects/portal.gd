extends Area2D

# ============ 传送门脚本 ============
# 功能：玩家靠近后按 E 键传送到目标场景

# ============ 配置 ============

@export_file("*.tscn") var target_scene: String = ""
# @export_file 让你在 Inspector 中选择场景文件
# 例如：res://scenes/battle_zone.tscn

@export var portal_name: String = "传送门"
# 传送门的显示名称

# ============ 状态 ============

var player_in_range: bool = false  # 玩家是否在范围内
var player: Variant = null  # 玩家引用（使用 Variant 以支持类型检查）

# ============ 节点引用 ============

@onready var label = $Label

# ============ 初始化 ============

func _ready() -> void:
	"""传送门初始化"""
	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 验证目标场景
	if target_scene.is_empty():
		push_error("传送门未设置目标场景！")

# ============ 输入检测 ============

func _process(_delta: float) -> void:
	"""每帧检测交互键"""
	# 只有玩家在范围内才检测输入
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		teleport()

# ============ 信号回调 ============

func _on_body_entered(body: Node2D) -> void:
	"""玩家进入传送门范围"""
	# 类型检查：确保是玩家
	if body is CharacterBody2D and body.is_in_group("player"):
		player_in_range = true
		player = body
		if label:
			label.visible = true  # 显示提示文字
		print("玩家进入传送门范围")

func _on_body_exited(body: Node2D) -> void:
	"""玩家离开传送门范围"""
	if body is CharacterBody2D and body.is_in_group("player"):
		player_in_range = false
		player = null
		if label:
			label.visible = false  # 隐藏提示文字
		print("玩家离开传送门范围")

# ============ 传送逻辑 ============

func teleport() -> void:
	"""执行传送"""
	# 验证目标场景
	if target_scene.is_empty():
		push_error("错误：未设置目标场景")
		return

	# 检查场景文件是否存在
	if not ResourceLoader.exists(target_scene):
		push_error("错误：目标场景文件不存在: %s" % target_scene)
		return

	# 保存玩家状态（传送前）
	if is_instance_valid(player):
		GameData.save_player_state(player)

	print("传送到: ", target_scene)

	# 切换场景
	get_tree().change_scene_to_file(target_scene)
