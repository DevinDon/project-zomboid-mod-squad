-- Squad 工具函数模块
-- 提供距离计算、随机选择、通用辅助函数
-- 客户端和服务端均加载此模块

-- 计算两点之间的距离
local distTo = function(x1, y1, x2, y2)
  local dx = x2 - x1
  local dy = y2 - y1
  return math.sqrt(dx * dx + dy * dy)
end

-- 计算两点之间的曼哈顿距离
local manhattanDist = function(x1, y1, x2, y2)
  return math.abs(x2 - x1) + math.abs(y2 - y1)
end

-- 从表中随机选择一个元素
local choice = function(t)
  if not t or #t == 0 then
    return nil
  end
  return t[ZombRand(#t) + 1]
end

-- 获取角色唯一标识
-- 优先使用 OnlineID，单机模式用实体 ID
local getCharacterID = function(character)
  if not character then
    return nil
  end
  local onlineId = character:getOnlineID()
  if onlineId and onlineId > 0 then
    return onlineId
  end
  return character:getModData().squadId or tostring(character:getObjectName())
end

-- 调试日志：以统一格式输出
local debugLog = function(moduleName, message)
  print('[Debug - Squad - ' .. moduleName .. '] ' .. tostring(message))
end

-- 检查两点是否在指定半径内
local isInRadius = function(x1, y1, x2, y2, radius)
  return distTo(x1, y1, x2, y2) <= radius
end

-- 查找最近的僵尸（在指定半径内）
local findNearestZombie = function(x, y, z, radius)
  local cell = getCell()
  if not cell then
    return nil
  end

  local closest = nil
  local closestDist = radius + 1

  local zombies = cell:getZombieList()
  if not zombies then
    return nil
  end

  for i = 0, zombies:size() - 1 do
    local zombie = zombies:get(i)
    if zombie and not zombie:isDead() then
      local d = distTo(x, y, zombie:getX(), zombie:getY())
      if d < closestDist then
        closestDist = d
        closest = zombie
      end
    end
  end

  return closest
end

-- 根据 ID 查找 Squad NPC（遍历 zombieList 中带 brain 的实体）
local findNPCById = function(npcId)
  local cell = getCell()
  if not cell then
    return nil
  end
  local zombieList = cell:getZombieList()
  if not zombieList then
    return nil
  end
  for i = 0, zombieList:size() - 1 do
    local zombie = zombieList:get(i)
    if zombie and not zombie:isDead() then
      local modData = zombie:getModData()
      if modData and modData.brain and modData.brain.id == npcId then
        return zombie
      end
    end
  end
  return nil
end

-- 根据 ID 查找僵尸实体
local findZombieById = function(zombieId)
  local cell = getCell()
  if not cell then
    return nil
  end
  local zombieList = cell:getZombieList()
  if not zombieList then
    return nil
  end
  for i = 0, zombieList:size() - 1 do
    local zombie = zombieList:get(i)
    if zombie and not zombie:isDead() then
      -- 尝试多种 ID 匹配方式
      if zombie:getOnlineID() == zombieId then
        return zombie
      end
      local pid = zombie:getPersistentOutfitID()
      if pid and tostring(pid) == tostring(zombieId) then
        return zombie
      end
    end
  end
  return nil
end

-- 获取所有在线玩家
-- 返回 Java ArrayList，用 :size() / :get(i) 迭代，不要用 ipairs
local getPlayers = function()
  local world = getWorld()
  if not world then
    return nil
  end

  local gameMode = world:getGameMode()
  if gameMode == 'Multiplayer' then
    return getOnlinePlayers()
  else
    return IsoPlayer.getPlayers()
  end
end

-- 根据 ID 查找在线玩家
-- getPlayers 返回的是 Java ArrayList，需用 :size() / :get(i) 遍历
local findPlayerById = function(playerId)
  local players = getPlayers()
  if not players then
    return nil
  end
  for i = 0, players:size() - 1 do
    local player = players:get(i)
    if player then
      local id = getCharacterID(player)
      if id and tostring(id) == tostring(playerId) then
        return player
      end
    end
  end
  return nil
end

-- 获取点击的方格
local getClickedSquare = function()
  if getCore():getGameVersion():getMajor() >= 42 then
    local fetch = ISWorldObjectContextMenu.fetchVars
    return fetch.clickedSquare
  else
    return clickedSquare
  end
end

return {
  distTo = distTo,
  manhattanDist = manhattanDist,
  choice = choice,
  getCharacterID = getCharacterID,
  debugLog = debugLog,
  isInRadius = isInRadius,
  findNearestZombie = findNearestZombie,
  findNPCById = findNPCById,
  findZombieById = findZombieById,
  getPlayers = getPlayers,
  findPlayerById = findPlayerById,
  getClickedSquare = getClickedSquare,
}
