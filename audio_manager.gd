extends Node

# ============ 音效管理器 ============
# Day 7 新增：统一管理游戏音效
# 使用单例模式（AutoLoad）

# ============ 音效预加载 ============

var sound_attack = preload("res://sounds/sword_swing.wav")
var sound_hit = preload("res://sounds/hit.wav")
var sound_pickup = preload("res://sounds/pickup.wav")
var sound_death = preload("res://sounds/death.wav")

# ============ 音效播放器池 ============

var audio_players = []
const MAX_PLAYERS = 10  # 最多同时播放10个音效

# ============ 初始化 ============

func _ready():
	"""创建音效播放器池"""
	for i in range(MAX_PLAYERS):
		var player = AudioStreamPlayer.new()
		add_child(player)
		audio_players.append(player)

# ============ 播放音效 ============

func play_sound(sound_name: String):
	"""
	【公共方法】播放指定音效

	参数：
		sound_name - 音效名称（"attack", "hit", "pickup", "death"）
	"""
	# 查找空闲的播放器
	for player in audio_players:
		if not player.playing:
			# 根据名称加载音效
			match sound_name:
				"attack":
					player.stream = sound_attack
				"hit":
					player.stream = sound_hit
				"pickup":
					player.stream = sound_pickup
				"death":
					player.stream = sound_death

			player.play()
			break

	print("播放音效: ", sound_name)
