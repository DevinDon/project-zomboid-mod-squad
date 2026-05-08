-- Squad 调试右键菜单模块
-- 仅在调试模式（isDebugEnabled）下显示，提供 NPC 生成与命令测试入口
-- 仅在客户端加载

local Utils = require('squad/utils')

-- 生成 NPC 并招募
local spawnNPCAt = function(player, square)
  local x = square:getX()
  local y = square:getY()
  local z = square:getZ()
  sendClientCommand('Squad', 'DebugSpawnNPC', { x = x, y = y, z = z })
  Utils.debugLog('menu', 'sent DebugSpawnNPC at (' .. x .. ', ' .. y .. ', ' .. z .. ')')
end

-- 生成僵尸
local spawnZombieAt = function(player, square)
  local x = square:getX()
  local y = square:getY()
  local z = square:getZ()
  sendClientCommand('Squad', 'DebugSpawnZombie', { x = x, y = y, z = z })
  Utils.debugLog('menu', 'sent DebugSpawnZombie at (' .. x .. ', ' .. y .. ', ' .. z .. ')')
end

-- 获取点击位置上的 Squad NPC（如果有的话）
local getSquadNPCOnSquare = function(square)
  local zombie = square:getZombie()
  if not zombie then
    -- 尝试相邻格
    local s = square:getS()
    if s then zombie = s:getZombie() end
    if not zombie then
      local w = square:getW()
      if w then zombie = w:getZombie() end
    end
  end
  if zombie and zombie:getModData() and zombie:getModData().brain then
    return zombie
  end
  return nil
end

-- 发送命令到指定 NPC
local sendNPCCommand = function(npc, commandType, extraArgs)
  local brain = npc:getModData().brain
  if not brain then return end
  local args = { npcId = brain.id }
  if extraArgs then
    for k, v in pairs(extraArgs) do
      args[k] = v
    end
  end
  sendClientCommand('Squad', commandType, args)
  Utils.debugLog('menu', 'sent command ' .. commandType .. ' to NPC ' .. tostring(brain.id))
end

-- 右键菜单入口
local onPreFillWorldContextMenu = function(playerID, context, worldobjects, test)
  if not isDebugEnabled() then
    return
  end

  local player = getSpecificPlayer(playerID)
  if not player then
    return
  end

  -- 获取点击的方格（从 worldobjects 取第一个物体的方格）
  local square = Utils.getClickedSquare()
  Utils.debugLog('menu', 'clicked square: (' .. square:getX() .. ', ' .. square:getY() .. ', ' .. square:getZ() .. ')')

  -- 检查点击位置是否有 Squad NPC
  local npc = getSquadNPCOnSquare(square)

  -- 创建 [Squad Debug] 子菜单
  local debugOption = context:addOption('[Squad Debug]')
  local debugMenu = context:getNew(context)
  context:addSubMenu(debugOption, debugMenu)

  -- 始终可用的生成类选项
  debugMenu:addOption('Spawn NPC (Recruit)', player, spawnNPCAt, square)
  debugMenu:addOption('Spawn Zombie', player, spawnZombieAt, square)

  -- 如果点击了 Squad NPC，显示命令选项
  if npc then
    local brain = npc:getModData().brain
    local name = brain and brain.name or 'Unknown'

    -- NPC 命令子菜单（嵌套在 debugMenu 下）
    local npcOption = debugMenu:addOption('Commands for ' .. name)
    local npcMenu = context:getNew(context)
    debugMenu:addSubMenu(npcOption, npcMenu)

    npcMenu:addOption('Attack nearest zombie', player, function(p)
      -- 查找最近的僵尸作为目标
      local z = Utils.findNearestZombie(npc:getX(), npc:getY(), npc:getZ(), 20)
      if z then
        local zombieId = z:getPersistentOutfitID() or z:getOnlineID()
        sendNPCCommand(npc, 'Attack', { targetId = zombieId })
      end
    end)

    npcMenu:addOption('Defend here', player, function(p)
      sendNPCCommand(npc, 'Defend', {
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
      })
    end)

    npcMenu:addOption('Follow me', player, function(p)
      local playerId = Utils.getCharacterID(player)
      sendNPCCommand(npc, 'Follow', { leaderId = playerId })
    end)

    npcMenu:addOption('Stop', player, function(p)
      sendNPCCommand(npc, 'Stop')
    end)
  end
end

Events.OnPreFillWorldObjectContextMenu.Add(onPreFillWorldContextMenu)
