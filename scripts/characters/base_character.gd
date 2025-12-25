extends CharacterBody2D
class_name BaseCharacter

# ============ 基础角色类 ============
# 功能：Player 和 Enemy 的共同功能
# Day 7 新增：代码重构，消除重复代码
# 让其他脚本可以继承这个类
# 使用方式：extends BaseCharacter

# ============ 场景预加载 ============

var damage_number_scene = preload("res://scenes/ui/damage_number.tscn")

# ============ 基础属性 ============

@export var hp = 100
@export var max_hp = 100
# 使用 @export 让子场景可以在 Inspector 中设置不同的值
# 例如：enemy.tscn 用 50，enemy_strong.tscn 用 150

# ============ 节点引用 ============

@onready var hp_bar = $ProgressBar

# ============ 初始化 ============

func _ready() -> void:
	"""基础角色初始化"""
	if hp_bar:
		update_hp_bar()

# ============ 受伤系统 ============

func take_damage(damage: int) -> void:
	"""
	【核心方法】处理受到伤害
	所有角色（玩家、敌人）的通用受伤逻辑

	参数：
		damage - 受到的伤害值
	"""
	hp -= damage

	# 更新血条
	update_hp_bar()

	# 显示伤害数字
	spawn_damage_number(damage)

	# 受击闪红效果
	flash_red()

	# 调用钩子（子类重写）
	on_take_damage()

	# 检查死亡
	if hp <= 0:
		die()


func update_hp_bar() -> void:
	"""更新血条显示"""
	if hp_bar:
		var hp_percent = (float(hp) / max_hp) * 100
		hp_bar.value = hp_percent


func spawn_damage_number(damage_value: int) -> void:
	"""
	生成并显示伤害数字
	在角色位置创建飘动的伤害数字效果

	参数：
		damage_value - 要显示的伤害数值
	"""
	var dmg_num = damage_number_scene.instantiate()
	dmg_num.position = position + Vector2(0, -50)
	dmg_num.set_damage(damage_value)
	get_parent().add_child(dmg_num)


func flash_red() -> void:
	"""
	【受击闪红效果】
	角色受伤时闪烁红色，提供视觉反馈
	使用 modulate 改变颜色
	"""
	modulate = Color(1.5, 0.5, 0.5)  # 红色（1.5倍亮度）

	# 0.1秒后恢复正常颜色
	await get_tree().create_timer(0.1).timeout
	# 检查节点是否仍然有效且在场景树中
	if is_instance_valid(self) and is_inside_tree():
		modulate = Color(1, 1, 1)  # 白色（正常）


func die() -> void:
	"""
	【虚函数】角色死亡
	子类可以重写此方法实现不同的死亡逻辑
	例如：玩家重新开始，敌人掉落装备
	"""
	print("角色死亡")

	# 调用钩子（子类重写）
	on_die()

	queue_free()


# ============ 音效钩子（子类可选实现）============

func on_take_damage() -> void:
	"""受击时的钩子，子类可重写播放音效"""
	pass

func on_die() -> void:
	"""死亡时的钩子，子类可重写播放音效"""
	pass
