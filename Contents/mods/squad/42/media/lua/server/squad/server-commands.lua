-- Squad 服务端命令处理模块
-- 接收并处理客户端发来的命令
-- 仅修改 brain 数据（通过 modData 自动同步到客户端），由客户端 AI 执行具体行为
-- 仅在服务端加载

local Data = require('squad/data')
local Brain = require('squad/brain')
local Utils = require('squad/utils')

-- 查找 NPC 并获取其大脑
local getNPCAndBrain = function(npcId)
  local npc = Utils.findNPCById(npcId)
  if not npc then
    Utils.debugLog('server-commands', 'NPC not found: ' .. tostring(npcId))
    return nil, nil
  end
  local brain = Data.getBrain(npc)
  if not brain then
    Utils.debugLog('server-commands', 'NPC has no brain: ' .. tostring(npcId))
    return nil, nil
  end
  return npc, brain
end

-- 通知客户端更新 NPC 状态显示
local syncNPCState = function(npcId, state)
  sendServerCommand('Squad', 'UpdateNpc', { npcId = npcId, state = state })
end

-- 处理攻击命令：设置攻击目标，客户端 AI 自动执行
local handleAttack = function(player, args)
  local npcId = args.npcId
  local targetId = args.targetId
  local npc, brain = getNPCAndBrain(npcId)
  if not npc then return end

  local target = Utils.findZombieById(targetId)
  if not target then
    Utils.debugLog('server-commands', 'target not found: ' .. tostring(targetId))
    return
  end

  Data.clearTasks(brain)
  Brain.setTarget(brain, targetId, target:getX(), target:getY(), target:getZ())
  Brain.setState(brain, Data.State.Attacking)

  Utils.debugLog('server-commands', string.format(
    'NPC %s received attack command, target: %s',
    tostring(npcId), tostring(targetId)
  ))
  syncNPCState(npcId, Data.State.Attacking)
end

-- 处理防御命令：设置守卫位置
local handleDefend = function(player, args)
  local npcId = args.npcId
  local x, y, z = args.x, args.y, args.z
  local npc, brain = getNPCAndBrain(npcId)
  if not npc then return end

  Data.clearTasks(brain)
  brain.guardX = x
  brain.guardY = y
  brain.guardZ = z
  Brain.clearTarget(brain)
  Brain.setState(brain, Data.State.Defending)

  Utils.debugLog('server-commands', string.format(
    'NPC %s received defend command, pos: (%d, %d, %d)',
    tostring(npcId), x, y, z
  ))
  syncNPCState(npcId, Data.State.Defending)
end

-- 处理跟随命令：设置队长 ID
local handleFollow = function(player, args)
  local npcId = args.npcId
  local leaderId = args.leaderId
  local npc, brain = getNPCAndBrain(npcId)
  if not npc then return end

  Data.clearTasks(brain)
  Brain.clearTarget(brain)
  brain.guardX = nil
  brain.guardY = nil
  brain.guardZ = nil
  brain.leaderId = leaderId
  Brain.setState(brain, Data.State.Follow)

  Utils.debugLog('server-commands', string.format(
    'NPC %s received follow command, leader: %s',
    tostring(npcId), tostring(leaderId)
  ))
  syncNPCState(npcId, Data.State.Follow)
end

-- 处理停止命令
local handleStop = function(player, args)
  local npcId = args.npcId
  local npc, brain = getNPCAndBrain(npcId)
  if not npc then return end

  Data.clearTasks(brain)
  Brain.clearTarget(brain)
  brain.leaderId = nil
  brain.guardX = nil
  brain.guardY = nil
  brain.guardZ = nil
  Brain.setState(brain, Data.State.Idle)

  Utils.debugLog('server-commands', 'NPC ' .. tostring(npcId) .. ' received stop command')
  syncNPCState(npcId, Data.State.Idle)
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

-- 服务端命令入口
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
