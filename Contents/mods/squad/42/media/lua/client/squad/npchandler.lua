-- Squad NPC 客户端行为处理器
-- 在客户端将僵尸外观和行为转换为人类 NPC
-- 通过 OnZombieUpdate 事件每帧检测并覆盖 NPC 行为，禁用僵尸引擎 AI
-- 仅在客户端加载

local Data = require('squad/data')
local Utils = require('squad/utils')

-- 已初始化过的 NPC 缓存，避免重复执行一次性设置
local humanized = {}

-- 一次性初始化：外观和基础属性
local humanizeNPC = function(zombie)
  -- 移除僵尸牙齿视觉效果
  zombie:setNoTeeth(true)

  -- 标记为 Squad 成员（可供其他模组检测）
  zombie:setVariable('SquadMember', true)
  zombie:getModData().isDeadSquad = false

  -- 移动速度参数
  zombie:setVariable('LimpSpeed', 0.80)
  zombie:setVariable('RunSpeed', 0.65 + ZombRandFloat(0, 0.15))
  zombie:setVariable('WalkSpeed', 1.04)

  -- 人类步行动画（替代僵尸蹒跚步态）
  zombie:setWalkType('Walk')
  zombie:setVariable('SquadWalkType', 'Walk')

  -- 替换僵尸受击反应，防止因 moodle 缺失导致崩溃
  zombie:setVariable('ZombieHitReaction', 'Chainsaw')

  -- 阻止被其他僵尸扑击
  zombie:setVariable('NoLungeTarget', true)

  -- 停止僵尸发出的所有声音（呻吟、咆哮等）
  zombie:getEmitter():stopAll()
  -- 额外静音：设置 voice prefix 为非僵尸
  local desc = zombie:getDescriptor()
  if desc then
    desc:setVoicePrefix('SquadNPC')
  end

  -- 清空手持物品
  zombie:setPrimaryHandItem(nil)
  zombie:setSecondaryHandItem(nil)
  zombie:resetEquippedHandsModels()
  zombie:clearAttachedItems()

  Utils.debugLog('npchandler', string.format(
    'humanized NPC: %s (id=%s)', Data.getBrain(zombie).name, tostring(Data.getBrain(zombie).id)
  ))
end

-- 每帧行为覆盖：持续禁用僵尸引擎对 NPC 的控制
local updateNPC = function(zombie, brain)
  -- 单人模式：完全禁用僵尸引擎 AI，由我们的服务器 AI 控制
  -- 多人模式：让服务器控制移动，客户端仅做视觉和行为覆盖
  local isSinglePlayer = getWorld():getGameMode() ~= 'Multiplayer'
  zombie:setUseless(isSinglePlayer)

  -- 持续静音（引擎可能重新激活声音）
  zombie:getEmitter():stopAll()

  -- 确保 NPC 不会主动锁定目标或发出僵尸警报
  zombie:setTarget(nil)
end

-- OnZombieUpdate 事件处理器
-- PZ 每帧对每个僵尸调用此事件
local onZombieUpdate = function(zombie)
  -- 只在客户端执行
  if isServer() then
    return
  end

  -- 跳过已死亡的、布娃娃状态的僵尸
  if not zombie:isAlive() or zombie:isRagdoll() then
    return
  end

  -- 检查是否已有 Squad 大脑数据
  local brain = Data.getBrain(zombie)
  if not brain then
    return
  end

  -- 首次发现时执行一次性初始化
  local npcID = brain.id
  if not humanized[npcID] then
    humanizeNPC(zombie)
    humanized[npcID] = true
  end

  -- 每帧持续覆盖行为
  updateNPC(zombie, brain)
end

-- 清理已移除 NPC 的缓存
local onZombieDead = function(zombie)
  local brain = Data.getBrain(zombie)
  if brain then
    humanized[brain.id] = nil
  end
end

-- 注册事件
Events.OnZombieUpdate.Add(onZombieUpdate)
Events.OnZombieDead.Add(onZombieDead)

Utils.debugLog('npchandler', 'NPC handler loaded')
