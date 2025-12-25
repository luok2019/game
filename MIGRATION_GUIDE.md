# Step 7.4: 项目结构迁移指南

## 目标结构

```
res://
├─ scenes/
│  ├─ characters/
│  │  ├─ player.tscn
│  │  ├─ enemy.tscn
│  │  └─ enemy_strong.tscn
│  ├─ items/
│  │  ├─ dropped_item.tscn
│  │  └─ item_slot.tscn
│  ├─ ui/
│  │  ├─ inventory.tscn
│  │  └─ damage_number.tscn
│  └─ main.tscn
├─ scripts/
│  ├─ characters/
│  │  ├─ base_character.gd
│  │  ├─ player.gd
│  │  └─ enemy.gd
│  ├─ systems/
│  │  ├─ item_data.gd
│  │  ├─ audio_manager.gd
│  │  └─ enemy_spawner.gd
│  └─ ui/
│     ├─ main.gd
│     ├─ inventory.gd
│     ├─ damage_number.gd
│     ├─ dropped_item.gd
│     └─ item_slot.gd
└─ assets/
   └─ sounds/
      ├─ sword_swing.wav
      ├─ hit.wav
      ├─ pickup.wav
      └─ death.wav
```

---

## 自动迁移脚本

使用项目根目录的 `migrate.sh` 脚本：

```bash
bash migrate.sh
```

---

## 需要手动更新的路径

### 1. project.godot

```ini
[application]
run/main_scene="res://scenes/main.tscn"

[autoload]
AudioManager="res://scripts/systems/audio_manager.gd"
```

### 2. 脚本中的 preload() 路径

| 文件 | 原路径 | 新路径 |
|------|--------|--------|
| `enemy_spawner.gd` | `res://enemy.tscn` | `res://scenes/characters/enemy.tscn` |
| `enemy_spawner.gd` | `res://enemy_strong.tscn` | `res://scenes/characters/enemy_strong.tscn` |
| `enemy.gd` | `res://dropped_item.tscn` | `res://scenes/items/dropped_item.tscn` |
| `base_character.gd` | `res://damage_number.tscn` | `res://scenes/ui/damage_number.tscn` |
| `audio_manager.gd` | `res://sounds/*.wav` | `res://assets/sounds/*.wav` |
| `inventory.gd` | `res://item_slot.tscn` | `res://scenes/items/item_slot.tscn` |

### 3. .tscn 文件中的脚本引用

| 场景文件 | 脚本路径 |
|----------|----------|
| `scenes/main.tscn` | `res://scripts/ui/main.gd` |
| `scenes/main.tscn` | `res://scripts/systems/enemy_spawner.gd` |
| `scenes/characters/player.tscn` | `res://scripts/characters/player.gd` |
| `scenes/characters/enemy*.tscn` | `res://scripts/characters/enemy.gd` |
| `scenes/items/dropped_item.tscn` | `res://scripts/ui/dropped_item.gd` |
| `scenes/items/item_slot.tscn` | `res://scripts/ui/item_slot.gd` |
| `scenes/ui/inventory.tscn` | `res://scripts/ui/inventory.gd` |
| `scenes/ui/damage_number.tscn` | `res://scripts/ui/damage_number.gd` |

---

## 重新导入资源

```bash
# 删除 .godot 缓存文件夹
rm -rf .godot

# 然后重新打开 Godot 项目
```

---

## 测试清单

- [ ] 游戏正常启动
- [ ] 玩家可以移动和攻击
- [ ] 敌人生成和AI正常
- [ ] 装备掉落和拾取正常
- [ ] 音效正常播放
- [ ] UI显示正常
