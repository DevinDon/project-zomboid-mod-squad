-- Squad 服务端命令处理模块
-- 接收并处理客户端发来的命令（attack、defend、recruit 等）
-- 仅在服务端加载

local Data = require('squad/data')
local Brain = require('squad/brain')
local Utils = require('squad/utils')

-- 处理攻击命令：让指定 NPC 攻击指定目标
local handleAttack = function(player, args)
  local npcId = args.npcId
  local targetId = args.targetId

  -- 查找 NPC 实体
  local npc = Utils.findNPCById(npcId)
  if not npc then
    Utils.debugLog('server-commands', 'NPC not found: ' .. tostring(npcId))
    return
  end

  -- 查找目标实体（僵尸）
  local target = Utils.findZombieById(targetId)
  if not target then
    Utils.debugLog('server-commands', 'target not found: ' .. tostring(targetId))
    return
  end

  -- 获取或创建大脑
  local brain = Data.getBrain(npc)
  if not brain then
    Utils.debugLog('server-commands', 'NPC has no brain: ' .. tostring(npcId))
    return
  end

  -- 清空现有任务，设置新攻击目标
  Brain.clearTasks(brain)
  Brain.setTarget(brain, targetId, target:getX(), target:getY(), target:getZ())

  -- 添加移动任务和攻击任务
  local moveTask = Data.makeTask('Move', {
    x = target:getX(),
    y = target:getY(),
    z = target:getZ(),
  })
  local attackTask = Data.makeTask('Attack', {
    targetId = targetId,
  })
  Brain.pushTask(brain, moveTask)
  Brain.pushTask(brain, attackTask)
  Brain.setState(brain, Data.State.Moving)

  Utils.debugLog('server-commands', string.format(
    'NPC %s received attack command, target: %s',
    tostring(npcId), tostring(targetId)
  ))
end

-- 处理防御命令：让指定 NPC 守卫指定位置
local handleDefend = function(player, args)
  local npcId = args.npcId
  local x, y, z = args.x, args.y, args.z

  local npc = Utils.findNPCById(npcId)
  if not npc then
    Utils.debugLog('server-commands', 'NPC not found: ' .. tostring(npcId))
    return
  end

  local brain = Data.getBrain(npc)
  if not brain then
    Utils.debugLog('server-commands', 'NPC has no brain: ' .. tostring(npcId))
    return
  end

  -- 清空现有任务，设置守卫点
  Brain.clearTasks(brain)
  brain.guardX = x
  brain.guardY = y
  brain.guardZ = z
  Brain.clearTarget(brain)

  -- 移动到守卫点并防御
  local moveTask = Data.makeTask('Move', { x = x, y = y, z = z })
  local defendTask = Data.makeTask('Defend', {})
  Brain.pushTask(brain, moveTask)
  Brain.pushTask(brain, defendTask)
  Brain.setState(brain, Data.State.Moving)

  Utils.debugLog('server-commands', string.format(
    'NPC %s received defend command, pos: (%d, %d, %d)',
    tostring(npcId), x, y, z
  ))
end

-- 处理跟随命令：让指定 NPC 跟随队长
local handleFollow = function(player, args)
  local npcId = args.npcId
  local leaderId = args.leaderId

  local npc = Utils.findNPCById(npcId)
  if not npc then
    Utils.debugLog('server-commands', 'NPC not found: ' .. tostring(npcId))
    return
  end

  local brain = Data.getBrain(npc)
  if not brain then
    Utils.debugLog('server-commands', 'NPC has no brain: ' .. tostring(npcId))
    return
  end

  Brain.clearTasks(brain)
  Brain.clearTarget(brain)
  brain.guardX = nil
  brain.guardY = nil
  brain.guardZ = nil

  -- 跟随任务会持续更新目标位置
  local followTask = Data.makeTask('Follow', { leaderId = leaderId })
  Brain.pushTask(brain, followTask)
  Brain.setState(brain, Data.State.Idle)

  Utils.debugLog('server-commands', string.format(
    'NPC %s received follow command, leader: %s',
    tostring(npcId), tostring(leaderId)
  ))
end

-- 处理停止命令
local handleStop = function(player, args)
  local npcId = args.npcId

  local npc = Utils.findNPCById(npcId)
  if not npc then
    Utils.debugLog('server-commands', 'NPC not found: ' .. tostring(npcId))
    return
  end

  local brain = Data.getBrain(npc)
  if not brain then
    Utils.debugLog('server-commands', 'NPC has no brain: ' .. tostring(npcId))
    return
  end

  Brain.clearTasks(brain)
  Brain.clearTarget(brain)
  Brain.setState(brain, Data.State.Idle)

  Utils.debugLog('server-commands', 'NPC ' .. tostring(npcId) .. ' received stop command')
end

-- 调试：生成 Squad NPC
local handleDebugSpawnNPC = function(player, args)
  local Spawner = require('squad/spawner')
  local npc = Spawner.spawnNPC(args.x, args.y, args.z)
  if npc then
    Utils.debugLog('server-commands', 'debug spawned NPC at (' .. args.x .. ', ' .. args.y .. ', ' .. args.z .. ')')
  end
end

-- 调试：生成普通僵尸
local handleDebugSpawnZombie = function(player, args)
  local Spawner = require('squad/spawner')
  local zombie = Spawner.spawnZombie(args.x, args.y, args.z)
  if zombie then
    Utils.debugLog('server-commands', 'debug spawned zombie at (' .. args.x .. ', ' .. args.y .. ', ' .. args.z .. ')')
  end
end

-- 命令路由表
local commandHandlers = {
  [Data.CommandType.Attack] = handleAttack,
  [Data.CommandType.Defend] = handleDefend,
  [Data.CommandType.Follow] = handleFollow,
  [Data.CommandType.Stop] = handleStop,
  ['DebugSpawnNPC'] = handleDebugSpawnNPC,
  ['DebugSpawnZombie'] = handleDebugSpawnZombie,
}

-- 服务端命令入口：由 main.lua 中的 OnClientCommand 调用
local onCommand = function(command, player, args)
  local handler = commandHandlers[command]
  if handler then
    handler(player, args)
  else
    Utils.debugLog('server-commands', 'unknown command: ' .. tostring(command))
  end
end

return {
  onCommand = onCommand,
}
