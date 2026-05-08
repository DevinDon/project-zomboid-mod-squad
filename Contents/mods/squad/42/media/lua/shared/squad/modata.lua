-- Squad 全局 ModData 管理模块
-- 负责 ModData.getOrCreate('Squad') 的初始化、读写和同步
-- 客户端和服务端均加载此模块

-- ModData 键名
local Key = 'Squad'

-- 初始化全局数据结构
local initModData = function()
  local data = ModData.getOrCreate(Key)
  if not data.Squads then
    data.Squads = {}
  end
  if not data.Version then
    data.Version = 1
  end
  return data
end

-- 获取全局 ModData（只读，不创建）
local getModData = function()
  return ModData.getOrCreate(Key)
end

-- 请求服务端同步 ModData（客户端调用）
local requestSync = function()
  ModData.request(Key)
end

-- 推送 ModData 到所有客户端（服务端调用）
local transmit = function()
  ModData.transmit(Key)
end

-- 添加小队到全局数据
local addSquad = function(squad)
  local data = getModData()
  data.Squads[squad.ownerId] = squad
  transmit()
end

-- 移除小队
local removeSquad = function(ownerId)
  local data = getModData()
  data.Squads[ownerId] = nil
  transmit()
end

-- 获取指定玩家的小队
local getSquad = function(ownerId)
  local data = getModData()
  return data.Squads and data.Squads[ownerId]
end

-- 获取所有小队
local getAllSquads = function()
  local data = getModData()
  return data.Squads or {}
end

return {
  Key = Key,
  initModData = initModData,
  getModData = getModData,
  requestSync = requestSync,
  transmit = transmit,
  addSquad = addSquad,
  removeSquad = removeSquad,
  getSquad = getSquad,
  getAllSquads = getAllSquads,
}
