# SBTI cards

基于 Godot `4.6.2` 的单局生存制人格翻牌游戏。当前版本已经跑通标题页、选角页、战斗页和结果页，25 张人格卡、15 张牌池、命运重分配、伙伴席位、压力倍率、挡伤溅射和主要技能分支都已接入代码。

## 画面预览

| 首页 | 选角页 |
|---|---|
| ![首页](./docs/screenshots/title-screen.png) | ![选角页](./docs/screenshots/character-select-screen.png) |

| 战斗页总览 | 战斗揭示 |
|---|---|
| ![战斗页总览](./docs/screenshots/battle-screen-overview.png) | ![战斗揭示](./docs/screenshots/battle-screen-reveal.png) |

## 当前玩法

1. 从 25 张人格卡里选择 1 张作为主角。
2. 系统从剩余 24 张中无放回抽出 15 张牌。
3. 每回合选 1 张牌翻开，它会以伙伴或敌人的身份结算。
4. 翻到伙伴时尝试入队，翻到敌人时结算伤害、驱散、封槽或概率效果。
5. 15 张牌全部处理完且主角仍然存活即胜利，中途 HP 归零则失败。

完整规则请看 [docs/gameplay-rules.zh-CN.md](./docs/gameplay-rules.zh-CN.md)。

## 当前状态

- 主流程已可完整游玩：标题页、选角页、战斗页、结果页。
- 当前版本包含 25 张可选人格卡和 15 张牌池流程。
- 已实现命运预分配、魅力修正、命运连击纠偏、强制命运和重分配逻辑。
- 已实现伙伴入队、替换、锁定、编外、间谍、休眠、成长、自动挡伤和自动击退。
- 已实现压力倍率、伙伴离队增压、低血恐惧、挡伤溅射和结果页存活判定。
- 视觉层已统一为剧场化牌桌风格，包含翻牌舞台、席位系统和战报弹窗。
- 已接入一版 `CC0` 开源音效，运行时文件位于 [assets/audio/sfx/final/](./assets/audio/sfx/final/)。

## 下载运行

玩家使用时不需要安装 Godot，直接从 GitHub Releases 页面下载对应平台的打包附件即可：

[GitHub Releases 下载页](https://github.com/mewamew/SBTI_cards/releases)

下载时优先选择最新版本的 Release。

Windows：

1. 下载 `sbti-cards-*-windows-x64.exe`
2. 双击 `.exe` 启动游戏。

macOS：

1. 如果你的 Mac 是 Apple Silicon，下载 `sbti-cards-*-macos-arm64.zip`
2. 如果你的 Mac 是 Intel，下载 `sbti-cards-*-macos-x86_64.zip`
3. 解压后打开 `.app`
4. 如果系统提示“Apple 无法验证”，先点“完成”
5. 打开 `系统设置 -> 隐私与安全性`，在安全区域对 `SBTI cards` 点击“仍要打开”
6. 系统会再弹出一次确认窗口，在弹窗里继续点击“仍要打开”即可
7. 如果仍然打不开，可以在 Finder 中对 `.app` 右键后选择“打开”

## 开发说明

开发环境要求：

- Godot `4.6.2.stable`

首次克隆项目或在全新环境中打开仓库时，需要先完成一次资源导入。可任选一种方式：

```bash
godot --headless --path . --import
```

或直接在 Godot 编辑器中打开 [project.godot](./project.godot)，等待首次导入完成。

首次导入会生成本地 `.godot/` 缓存，时间可能较长。导入完成后再运行项目：

本地运行项目：

```bash
godot --path .
```

资源导入完成后，也可以直接在 Godot 编辑器中运行 [project.godot](./project.godot)。

当前项目配置：

- 主场景：[scenes/app.tscn](./scenes/app.tscn)
- 逻辑入口：[scripts/app.gd](./scripts/app.gd)
- 默认视口：`1600 x 900`
- 拉伸模式：`canvas_items + keep`
- 渲染方法：`mobile`

## 仓库结构

- [assets/](./assets/)：运行时素材根目录，含卡图、背景、头像、UI、特效、应用图标与音频资源。
- [assets/audio/bgm/final/](./assets/audio/bgm/final/)：标题页、选人页、战斗页使用的背景音乐。
- [assets/audio/sfx/final/](./assets/audio/sfx/final/)：战斗与演出使用的音效，以及来源说明。
- [assets/ui/audio_controls/](./assets/ui/audio_controls/)：左上角音频开关按钮所用的运行时图标资源。
- [data/](./data/)：角色数据、入场姿态和相关清单。
- [docs/](./docs/)：规则文档与 README 展示截图。
- [scenes/](./scenes/)：Godot 场景入口和子场景。
- [scripts/](./scripts/)：纯运行时代码，包含页面脚本、战斗逻辑、数值和平衡逻辑。
- [shaders/](./shaders/)：卡牌、命运揭晓和氛围相关着色器。

## 关键代码入口

- [scripts/game_state.gd](./scripts/game_state.gd)：单局状态容器，维护 HP、回合、伙伴、牌池和胜负状态。
- [scripts/deck_manager.gd](./scripts/deck_manager.gd)：牌池生成、魅力计算、命运重分配和连击纠偏。
- [scripts/game_balance.gd](./scripts/game_balance.gd)：数值常量、角色覆盖值和伤害公式。
- [scripts/battle_screen.gd](./scripts/battle_screen.gd)：战斗主流程、技能结算、动画、席位和模态弹窗。
- [data/characters.json](./data/characters.json)：25 张人格卡的基础配置。
- [data/characters.gd](./data/characters.gd)：角色数据加载入口，运行时会叠加 `game_balance.gd` 中的覆盖值。

## 文档入口

- [docs/gameplay-rules.zh-CN.md](./docs/gameplay-rules.zh-CN.md)：当前实现的玩法规则说明文档。
- [assets/audio/sfx/final/README.md](./assets/audio/sfx/final/README.md)：当前音效文件来源说明。

## 音效来源

当前音效 [assets/audio/sfx/final/](./assets/audio/sfx/final/) 均整理自 `CC0` 开源素材：

- `card_hover.wav`：`Playing Card Sounds / contact1.wav`
- `card_select.ogg`：`54 Casino sound effects / card-place-2.ogg`
- `card_flip.wav`：`Playing Card Sounds / cut.wav`
- `ally_join.ogg`：`80 CC0 RPG SFX / spell_01.ogg`
- `ally_replace.ogg`：`54 Casino sound effects / card-shove-2.ogg`
- `enemy_hit.ogg`：`100 CC0 metal and wood SFX / wood_hit_04.ogg`
- `ally_block.ogg`：`100 CC0 metal and wood SFX / metal_hit_02.ogg`
- `heal.ogg`：`80 CC0 RPG SFX / spell_02.ogg`
- `spy_reveal.wav`：`Card Game sounds / stagechange.wav`
- `spotlight_reveal.ogg`：`54 Casino sound effects / cards-pack-open-1.ogg`
- `fate_reveal.ogg`：`100 CC0 metal and wood SFX / wood_hit_04.ogg`
- `victory.wav`：`Win sound effect / Win sound.wav`
- `defeat.ogg`：`Lose Game Short Music Clip / losegamemusic.ogg`
