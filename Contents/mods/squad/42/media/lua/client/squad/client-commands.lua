-- Squad 客户端命令接收模块
-- 接收并处理服务端推送的数据更新和命令
-- 仅在客户端加载

local Utils = require('squad/utils')
local Data = require('squad/data')

-- 更新单个 NPC 的状态
local updateNpc = function(args)
  local npcId = args.npcId
  local npc = Utils.findNPCById(npcId)
  if not npc then
    return
  end

  local brain = Data.getBrain(npc)
  if not brain then
    return
  end

  -- 更新状态
  if args.state then
    brain.state = args.state
  end

  -- 更新目标
  if args.targetId then
    brain.targetId = args.targetId
    brain.targetX = args.targetX
    brain.targetY = args.targetY
    brain.targetZ = args.targetZ
  end

  Utils.debugLog('client-commands', 'NPC ' .. tostring(npcId) .. ' state updated')
end

-- 服务端事件处理
local onCommand = function(command, args)
  if command == 'UpdateNpc' then
    updateNpc(args)
  else
    Utils.debugLog('client-commands', 'unknown server command: ' .. tostring(command))
  end
end

return {
  onCommand = onCommand,
}
