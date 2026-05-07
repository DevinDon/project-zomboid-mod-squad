# Squad 模组开发计划

## 目标

构建一个以战斗为核心的 NPC 小队模组，首版仅实现：

- NPC 招募与小队管理
- 攻击与防御命令
- 固定武器、无限弹药
- NPC 基础 AI 行为：锁定目标、移动、攻击、防守

后续版本再逐步扩展：背包/装备、技能成长、搜刮/肃清、体验面板、多人同步。

## 实现思路

### 1. 直接做联机版本，兼容单机

本项目从一开始就采用“服务器权威 + 客户端轻量同步”架构，单机模式作为该架构的一个特殊情形。

- 服务器负责 NPC 数据、AI 逻辑、命令执行、战斗判定以及权威状态更新。
- 客户端负责玩家输入、UI、显示和本地交互。
- 共享逻辑放在 `shared/`，避免客户端和服务器重复实现。
- 单机模式下，服务器与客户端可以同机运行，仍然使用相同的数据结构和事件接口。

这种方式能够最大限度减少后期从单机到联机的改造成本。

### 2. 联机架构重点

核心设计要点：

- 全局数据通过 `ModData.getOrCreate('Squad')` / `ModData.transmit('Squad')` 同步。
- 客户端发送命令给服务器，服务器验证后执行并广播结果。
- NPC 私有状态通过 `npc:getModData()` 存储，服务端读取和更新。
- `client/main.lua` 只做 UI 和本地交互；`server/main.lua` 做 AI、战斗、实体修改。

### 3. 首个版本范围

第一版只关注“战斗系统”，包括：

- NPC 招募与小队管理
- `attack` 命令：锁定僵尸、移动接近、攻击
- `defend` 命令：守住位置、阻止僵尸靠近
- 固定武器、无限弹药
- 简单战斗判定和伤害机制

首版暂不做：

- 背包物品系统
- 装备管理
- 经验/技能成长
- 搜刮、肃清、基地建设

### 4. 需要补充的内容

建议补充：

- **最小命令集**：`attack-target`、`defend-area`、`stop`、`follow-leader`
- **首版 NPC 数量**：建议 1-3 名队员，避免 AI 复杂度过高
- **目标对象**：首版限定僵尸目标
- **更新频率**：优先低频度更新（如 `Events.EveryOneMinute` 或 `Events.EveryTenMinutes`）而非每帧
- **调试支持**：日志、聊天提示或临时图标，便于验证行为
- **数据接口**：预留 `npc:getModData().brain`、`npc:getModData().taskQueue` 等字段

## 任务清单

### 初始化与基础架构

1. `mod.info` 定义模组信息和加载顺序。
2. 搭建模块目录：
   - `client/main.lua`
   - `server/main.lua`
   - `shared/squad/manager.lua`
   - `shared/squad/data.lua`
   - `shared/squad/command.lua`
3. 实现 `shared` 公共模块，定义数据结构与常量。
4. 实现 `server/main.lua`：初始化全局 `ModData`，注册服务器事件。
5. 实现 `client/main.lua`：注册客户端事件、UI 命令入口、发送服务器命令。

### 联机同步与数据管理

6. 实现全局 ModData 初始化与请求机制。
7. 实现客户端到服务器的命令传输接口。
8. 实现服务器端状态更新后广播机制。
9. 实现 NPC 私有 `getModData()` 状态结构。

### 战斗系统 MVP

10. 实现 `attack-target` 命令：
    - 选择目标僵尸
    - 生成攻击任务
    - 执行移动和攻击行为
11. 实现 `defend-area` 命令：
    - 设置守卫点
    - NPC 在该点周边阻挡僵尸
12. 实现固定武器与无限弹药逻辑。
13. 实现简单战斗判定：命中、伤害、击杀判定。
14. 实现调试输出与行为日志。

### 客户端交互与测试

15. 实现基础 UI 或快捷命令用于测试NPC命令。
16. 验证联机模式下客户端发送命令、服务器处理、客户端同步的流程。
17. 运行单机测试，确认服务器与客户端合并模式正常工作。

## 里程碑

### 里程碑 1：联机架构搭建完成

- `server/squad/main.lua`、`client/squad/main.lua`、`shared/squad/` 模块初步搭建
- 全局 `ModData` 初始化
- 客户端命令发送/服务器接收机制可用
- 单机可运行

### 里程碑 2：战斗 AI MVP

- `attack-target` 和 `defend-area` 命令实现
- NPC 能在服务端执行战斗行为
- 简单命中与伤害逻辑完成
- 客户端能看到 NPC 行为反馈

### 里程碑 3：游戏内测试验证

- 能在游戏内召唤/激活 NPC
- 能给 NPC 发出 `attack` / `defend` 指令
- NPC 能反应并与僵尸战斗
- 单机和本地联机模式验证通过

## MVP 可测试范围

MVP 版本目标是：

- 在游戏内成功加载模组
- 通过客户端 UI 或命令给 NPC 下达攻击/防御指令
- NPC 在服务端执行行为并与僵尸战斗
- 客户端能够显示基本效果，且单机模式可用

这个版本不要求完整的 UI、背包、升级等系统，只要战斗行为可观察并稳定运行。

---

## 实现架构（基于 Bandits 参考代码）

### 模块职责

#### `shared/squad/`（共用代码，客户端/服务端均加载）

| 文件 | 职责 |
|------|------|
| `data.lua` | 小队全局数据结构、NPC 状态字段、命令类型枚举 |
| `gmd.lua` | `ModData.getOrCreate('Squad')` 初始化、数据集群、同步请求 |
| `utils.lua` | 距离计算、随机选择、通用工具函数 |
| `names.lua` | NPC 姓名生成 |
| `brain.lua` | NPC 大脑数据结构（武器、弹药、任务队列） |
| `command.lua` | 命令定义与校验（attack、defend、follow、stop） |
| `weapons.lua` | 固定武器表、无限弹药配置 |
| `combat.lua` | 战斗判定逻辑（命中、伤害、击杀） |

#### `server/squad/`

| 文件 | 职责 |
|------|------|
| `main.lua` | 服务端入口：注册 `OnClientCommand`、`OnInitGlobalModData`、AI 定时循环 |
| `server-commands.lua` | 处理客户端发来的命令（attack/defend/recruit 等），更新 NPC 大脑 |
| `spawner.lua` | NPC 实体生成逻辑 |
| `ai.lua` | NPC AI 状态机执行器（每 N 秒 Tick） |

#### `client/squad/`

| 文件 | 职责 |
|------|------|
| `main.lua` | 客户端入口：注册 `OnServerCommand`、右键菜单、热键 |
| `client-commands.lua` | 接收并处理服务端推送的数据更新 |

### 数据流

```text
[玩家右键菜单]
       │ sendClientCommand('Squad', 'AttackTarget', {npcId, targetId})
       ▼
[服务端 main.lua] → OnClientCommand → ServerCommands.AttackTarget()
       │ 验证权限、更新 brain.tasks、写入 ModData
       ▼
[服务端 AI 循环 Events.EveryTenSeconds]
       │ AI.Tick() → 遍历所有 NPC，执行 brain.tasks
       │ 移动、攻击、伤害判定
       ▼
[ModData.transmit('Squad')] → 广播到所有客户端
       ▼
[客户端 main.lua] → OnServerCommand → ClientCommands.UpdateNpc()
       │ 更新本地 NPC 显示、动画
       ▼
[玩家看到 NPC 行为]
```

### 命令路由约定

- 客户端 → 服务端：`sendClientCommand('Squad', 'CommandName', args)`，服务端 `OnClientCommand` 监听 `module == 'Squad'`
- 服务端 → 客户端：`sendServerCommand('Squad', 'CommandName', args)`，客户端 `OnServerCommand` 监听 `module == 'Squad'`
- 与 Bandits 参考代码保持一致的路由模式

### 首版 MVP 文件清单

```shell
Contents/mods/squad/42/media/lua/
├── shared/squad/
│   ├── data.lua            # 全局数据结构
│   ├── mod-data.lua        # ModData 管理
│   ├── utils.lua           # 工具函数
│   ├── names.lua           # 姓名生成
│   ├── brain.lua           # NPC 大脑
│   ├── command.lua         # 命令定义
│   ├── weapons.lua         # 武器配置
│   └── combat.lua          # 战斗判定
├── client/squad/
│   ├── main.lua            # 客户端入口
│   └── client-commands.lua
└── server/squad/
    ├── main.lua            # 服务端入口
    ├── server-commands.lua
    ├── spawner.lua         # NPC 生成
    └── ai.lua              # AI 执行器
```
