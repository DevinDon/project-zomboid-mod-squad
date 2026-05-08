-- Squad NPC 与僵尸生成模块
-- 负责在服务端创建 NPC 和普通僵尸实体
-- 仅在服务端加载

local Data = require('squad/data')
local Names = require('squad/names')
local Utils = require('squad/utils')
local Weapons = require('squad/weapons')

-- 在指定坐标生成一个 NPC
-- 返回: npc 实体（IsoZombie），失败返回 nil
local spawnNPC = function(x, y, z, options)
  options = options or {}

  -- 通过 PZ 内置函数生成僵尸，确保正确注册到世界
  local female = options.female or (ZombRand(2) == 0)
  local zombieList = addZombiesInOutfit(x, y, z, 1, 'Random', female and 100 or 0)
  if not zombieList or zombieList:size() < 1 then
    Utils.debugLog('spawner', 'addZombiesInOutfit returned nil or empty at (' .. x .. ', ' .. y .. ', ' .. z .. ')')
    return nil
  end
  local npc = zombieList:get(0)

  -- 设置外观为人类
  npc:setFakeDead(false)
  npc:setCanWalk(true)
  -- 禁用僵尸引擎 AI，由我们的 AI 系统控制
  npc:setUseless(true)
  -- 应用人类皮肤纹理，替换默认僵尸外观
  local humanVisual = npc:getHumanVisual()
  if humanVisual then
    humanVisual:setSkinTextureName(female and 'FemaleBody01' or 'MaleBody01a')
    humanVisual:removeDirt()
    humanVisual:removeBlood()
  end

  -- 生成随机姓名
  local name = Names.generateName(female)

  -- 选择武器
  local weaponType = options.weapon or Weapons.DefaultWeapon

  -- 创建大脑数据
  local npcId = Utils.getCharacterID(npc)
  local brain = Data.makeBrain(npcId, name, weaponType)

  -- 将大脑写入 NPC 的 modData
  Data.setBrain(npc, brain)

  Utils.debugLog('spawner', string.format(
    'NPC spawned: %s (id=%s, weapon=%s, pos=(%d,%d,%d))',
    name, tostring(npcId), weaponType, x, y, z
  ))

  return npc
end

-- 在指定玩家附近生成 NPC
local spawnNearPlayer = function(player, options)
  local px = player:getX()
  local py = player:getY()
  local pz = player:getZ()

  -- 随机偏移 2-4 格
  local angle = ZombRand(360) * math.pi / 180
  local dist = 2 + ZombRand(3)
  local x = math.floor(px + math.cos(angle) * dist)
  local y = math.floor(py + math.sin(angle) * dist)

  return spawnNPC(x, y, pz, options)
end

-- 在指定坐标生成一个普通僵尸
-- 使用 PZ 内置的 addZombiesInOutfit 确保正确注册到世界
-- 返回: IsoZombie 对象，失败返回 nil
local spawnZombie = function(x, y, z)
  local zombieList = addZombiesInOutfit(x, y, z, 1, 'Random', 50)
  if zombieList and zombieList:size() > 0 then
    local zombie = zombieList:get(0)
    Utils.debugLog('spawner', string.format(
      'zombie spawned at (%d, %d, %d)', x, y, z
    ))
    return zombie
  end
  Utils.debugLog('spawner', string.format(
    'failed to spawn zombie at (%d, %d, %d)', x, y, z
  ))
  return nil
end

-- 移除 NPC 的大脑数据（NPC 死亡或清理时调用）
local despawnNPC = function(npc)
  if not npc then
    return
  end
  Data.removeBrain(npc)
end

return {
  spawnNPC = spawnNPC,
  spawnNearPlayer = spawnNearPlayer,
  spawnZombie = spawnZombie,
  despawnNPC = despawnNPC,
}
