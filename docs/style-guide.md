# Squad 模组代码风格与编程习惯

该文档用于记录本项目的编码规范与协作惯例，供任何 AI Agent 或开发者参考。

- 用中文对话，包括注释。

## 文件与目录规范

- 文件命名统一使用小写字母和连字符。
- 文件名应尽量直白简洁，一个单词最好，但必须避免歧义。
- 专有名词缩写（如 NPC、ID）应当保持全大写或全小写，但不应混用大小写（如 Npc）。
- 代码应当放在 `squad` 子目录下，避免与其他模组出现同名文件冲突。
- 参考 `Contents/mods/squad/42` 目录结构：
  - `client/squad/` 目录仅包含客户端本地功能。
  - `server/squad/` 目录仅包含服务端运算逻辑，如物品生成、角色修改、授权验证等。
  - `shared/squad/` 目录存放共用工具类、类型结构、业务模型等。
  - `main.lua` 作为 `client` 和 `server` 的入口文件名。

## Lua 代码风格

- 缩进使用 2 空格。
- `require` 语句使用模块导入风格：

  ```lua
  local Utils = require('squad/utils')
  ```

- 不需要在 `require` 路径中包含 `client`、`server` 或 `shared` 前缀。
- 模块内部所有变量和函数均使用 `local` 声明，避免污染全局命名空间。
- 模块整体导入时，变量名应当大写（如 `local Utils = require('squad/utils')`）。
- 导出的模块采用扁平结构，直接返回各项，不嵌套包装表：

  ```lua
  return {
    CommandType = CommandType,
    State = State,
    makeTask = makeTask,
    getBrain = getBrain,
  }
  ```

- 类似枚举、常量、数据表的变量以大写驼峰命名（如 `CommandType`、`State`、`MaleFirstNames`），避免全大写下划线。
- 函数以小写驼峰命名（如 `distTo`、`generateName`）。
- 构造器/工厂函数以小写 `make` 开头：`makeTask`、`makeBrain`；getter/setter 以 `get`/`set` 开头：`getBrain`、`setBrain`。
- 行尾逗号是必须的，即使是最后一个条目。
- 注释用中文，简洁直接，不需要装饰性分隔线（如 `-- ====`）。
- 调试日志以 `[Debug - 模组名 - 模块名]` 开头，如 `print('[Debug - Squad - main.lua#onGameStart]' .. message)`。
- 调试输出的内容使用英文，因为游戏控制台对中文支持有限。
- 开发阶段应使用必要的调试输出来辅助验证逻辑，正式发布前再清理或降级。
- 函数声明使用 `local fn = function() ... end` 的方式。
- 所有函数都应当添加注释，核心关键路径也要注释说明逻辑。
- 每个文件头部添加注释，解释该文件的目的和能力。

## 项目架构原则

- 游戏分为客户端和服务端两个运行环境：客户端是用户的操作界面，服务端提供联机能力。本地单人游戏也是类似联机的实现，只不过客户端和服务器都在玩家电脑上运行。
- `shared/` 目录下的代码在客户端和服务端都会优先加载运行。然后客户端会执行 `client/` 目录下的代码，导入也会从 `shared/` 和 `client/` 两个目录下查找。服务端会执行 `server/` 目录下的代码，同理也是查找 `server/` 和 `shared/` 两个目录的代码。所有导入均不需要声明是 `shared` 还是 `client`，所以 `client/` 和 `server/` 都不应当和 `shared/` 中的文件有命名冲突。
- 优先设计多人兼容架构，因为多人模式兼容单人模式。
- 单机功能应作为多人兼容架构的一个特殊情形，而不是完全独立实现。
- 服务器端负责权威数据和复杂运算，客户端负责输入处理、显示和本地 UI。
- 共享逻辑放在 `shared/`，避免 `client/` 和 `server/` 重复实现。

## 迭代与补充

- 本文档将随着项目进展逐步完善。
- 任何新的约定或发现的最佳实践，应补充到本文件中。
- 该文档也可作为 AI Agent 的行为规范参考。
