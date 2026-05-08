-- Squad 全局数据定义
-- 定义小队、NPC 状态、命令类型等核心数据结构与常量
-- 客户端和服务端均加载此模块

-- 命令类型枚举
local CommandType = {
  Attack = 'Attack',
  Defend = 'Defend',
  Follow = 'Follow',
  Stop = 'Stop',
}

-- NPC 基础状态
local State = {
  Idle = 'Idle',
  Moving = 'Moving',
  Attacking = 'Attacking',
  Defending = 'Defending',
  Follow = 'Follow',
  Dead = 'Dead',
}

-- 任务结构：NPC 当前正在执行的动作
local makeTask = function(action, params)
  -- action: 'Move', 'Attack', 'Defend', 'Stop'
  -- params: { targetX, targetY, targetZ, targetId, ... }
  return {
    action = action,
    params = params or {},
    created = getGameTime():getWorldAgeHours() or 0,
  }
end

-- NPC 大脑结构（存储在 NPC:getModData().brain 中）
local makeBrain = function(npcId, name, weaponType)
  return {
    -- 基础信息
    id = npcId,
    name = name,
    state = State.Idle,

    -- 武器（固定武器、无限弹药）
    weapon = weaponType or 'Base.BaseballBat',

    -- 任务队列
    tasks = {},
    -- 当前正在执行的任务（客户端 AI 使用）
    currentTask = nil,
    taskState = nil,

    -- 当前目标
    targetId = nil,
    targetX = nil,
    targetY = nil,
    targetZ = nil,

    -- 守卫位置
    guardX = nil,
    guardY = nil,
    guardZ = nil,

    -- 所属小队
    squadId = nil,

    -- 跟随的队长 ID
    leaderId = nil,
  }
end

-- 小队结构（存储在全局 ModData.Squads 中）
local makeSquad = function(ownerId)
  return {
    ownerId = ownerId,
    memberIds = {}, -- NPC ID 列表
    maxMembers = 3, -- 首版最多 3 名队员
    createdAt = getGameTime():getWorldAgeHours() or 0,
  }
end

-- 获取 NPC 大脑
local getBrain = function(npc)
  local modData = npc:getModData()
  return modData.brain
end

-- 设置 NPC 大脑
local setBrain = function(npc, brain)
  local modData = npc:getModData()
  modData.brain = brain
end

-- 移除 NPC 大脑
local removeBrain = function(npc)
  local modData = npc:getModData()
  modData.brain = nil
end

-- 清空 NPC 任务队列
local clearTasks = function(brain)
  if brain then
    brain.tasks = {}
    brain.currentTask = nil
    brain.taskState = nil
  end
end

-- 添加任务到队列
local addTask = function(brain, task)
  if brain and task then
    brain.tasks = brain.tasks or {}
    table.insert(brain.tasks, task)
  end
end

return {
  CommandType = CommandType,
  State = State,
  makeTask = makeTask,
  makeBrain = makeBrain,
  getBrain = getBrain,
  setBrain = setBrain,
  removeBrain = removeBrain,
  makeSquad = makeSquad,
  clearTasks = clearTasks,
  addTask = addTask,
}
