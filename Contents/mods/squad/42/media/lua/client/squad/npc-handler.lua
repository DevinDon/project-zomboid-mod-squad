-- Squad NPC 客户端 AI 主循环
-- 通过 OnZombieUpdate 每帧接管 NPC 控制
-- 参考 Bandits 模组的客户端 AI 架构：初始化 + 状态拦截 + SquadActions 任务执行
-- 仅在客户端加载

local Data = require('squad/data')
local Brain = require('squad/brain')
local Utils = require('squad/utils')
local SquadActions = require('squad/squad-actions')

-- 已初始化过的 NPC 缓存
local humanized = {}
-- 帧计数器（用于周期性任务生成）
local updateTick = 0

-- ============================================================
-- 第 1 步：一次性初始化（外观 + 基础参数）
-- ============================================================
local humanizeNPC = function(zombie)
  -- 视觉：移除僵尸牙齿
  zombie:setNoTeeth(true)
  -- 标记
  zombie:setVariable('SquadMember', true)
  zombie:getModData().isDeadSquad = false
  -- 速度参数
  zombie:setVariable('LimpSpeed', 0.80)
  zombie:setVariable('RunSpeed', 0.65 + ZombRandFloat(0, 0.15))
  zombie:setVariable('WalkSpeed', 1.04)
  zombie:setVariable('SquadWalkType', 'Walk')
  -- 受击反应（防 moodle 崩溃）
  zombie:setVariable('ZombieHitReaction', 'Chainsaw')
  zombie:setVariable('NoLungeTarget', true)
  -- 停止僵尸声音
  zombie:getEmitter():stopAll()
  local desc = zombie:getDescriptor()
  if desc then
    desc:setVoicePrefix('SquadNPC')
  end
  -- 清空手持物品
  zombie:setPrimaryHandItem(nil)
  zombie:setSecondaryHandItem(nil)
  zombie:resetEquippedHandsModels()
  zombie:clearAttachedItems()

  Utils.debugLog('npc-handler', string.format(
    'humanized NPC: %s', tostring(Data.getBrain(zombie).name)
  ))
end

-- ============================================================
-- 第 2 步：每帧行为覆盖（持续禁用僵尸引擎）
-- ============================================================
local updateNPCPreframe = function(zombie)
  local isSinglePlayer = getWorld():getGameMode() ~= 'Multiplayer'
  zombie:setUseless(isSinglePlayer)
  zombie:setWalkType(zombie:getVariableString('SquadWalkType'))
  zombie:setSpeedMod(1)
  zombie:getEmitter():stopAll()
  zombie:setTarget(nil)
end

-- ============================================================
-- 第 3 步：拦截僵尸引擎动作状态
-- ============================================================
local manageActionState = function(npc)
  local asn = npc:getActionStateName()

  -- turnalerted → 强制空闲
  if asn == 'turnalerted' then
    npc:changeState(ZombieIdleState.instance())
    npc:clearAggroList()
    npc:setTarget(nil)
    return true
  end

  -- lunge → 禁用
  if asn == 'lunge' then
    npc:setUseless(true)
    npc:clearAggroList()
    npc:setTarget(nil)
    return true
  end

  -- pathfind → 不拦截（让 SquadActions.GoTo 控制）
  if asn == 'pathfind' then
    return true
  end

  -- 僵尸被击倒/受击状态 → 清除任务让引擎处理动画
  local zombieStates = {
    ['getup'] = true,
    ['getup-fromonback'] = true,
    ['staggerback'] = true,
    ['staggerback-knockeddown'] = true,
    ['onground'] = true,
    ['onground-breathing'] = true,
    ['falldown'] = true,
    ['hitreaction'] = true,
    ['knockeddown'] = true,
    ['bumped'] = true,
  }
  if zombieStates[asn] then
    local brain = Data.getBrain(npc)
    if brain then
      brain.currentTask = nil
      brain.taskState = nil
    end
    return false
  end

  -- 默认
  npc:setTarget(nil)
  return true
end

-- ============================================================
-- 第 4 步：生成任务（根据 brain 状态决定做什么）
-- ============================================================
local generateTask = function(npc, brain)
  -- 已有任务在执行，不生成新任务
  if brain.currentTask then
    return
  end

  -- 从 brain.tasks 队列取下一个任务（由服务端添加）
  if #brain.tasks > 0 then
    local task = table.remove(brain.tasks, 1)
    -- 展开 Data.makeTask 格式（params 嵌套）为扁平格式
    if task.params then
      for k, v in pairs(task.params) do
        task[k] = v
      end
      task.params = nil
    end
    brain.currentTask = task
    brain.taskState = 'NEW'
    return
  end

  -- 无队列任务时根据状态自动行为
  local state = brain.state

  if state == Data.State.Follow and brain.leaderId then
    local leader = Utils.findPlayerById(brain.leaderId)
    if leader then
      local dist = Utils.distTo(npc:getX(), npc:getY(), leader:getX(), leader:getY())
      if dist > 3 then
        brain.currentTask = {
          action = 'Move',
          x = leader:getX(),
          y = leader:getY(),
          walkType = 'Walk',
        }
        brain.taskState = 'NEW'
      end
    end
  elseif state == Data.State.Attacking and brain.targetId then
    -- 攻击状态：靠近目标并攻击
    local target = Utils.findZombieById(brain.targetId)
    if not target or not target:isAlive() then
      -- 目标已死，回到空闲
      Brain.setState(brain, Data.State.Idle)
      Brain.clearTarget(brain)
      return
    end
    local dist = Utils.distTo(npc:getX(), npc:getY(), target:getX(), target:getY())
    if dist <= 1.8 then
      -- 在攻击范围内，攻击
      brain.currentTask = {
        action = 'Smack',
        x = target:getX(),
        y = target:getY(),
        eid = brain.targetId,
        weapon = brain.weapon,
      }
      brain.taskState = 'NEW'
    else
      -- 需要靠近
      brain.currentTask = {
        action = 'Move',
        x = target:getX(),
        y = target:getY(),
        walkType = 'Walk',
      }
      brain.taskState = 'NEW'
    end
  elseif state == Data.State.Defending and brain.guardX then
    local nearestZombie = Utils.findNearestZombie(npc:getX(), npc:getY(), npc:getZ(), 8)
    if nearestZombie then
      brain.currentTask = {
        action = 'Smack',
        x = nearestZombie:getX(),
        y = nearestZombie:getY(),
        eid = Utils.getCharacterID(nearestZombie),
        weapon = brain.weapon,
      }
      brain.taskState = 'NEW'
    else
      local dist = Utils.distTo(npc:getX(), npc:getY(), brain.guardX, brain.guardY)
      if dist > 1.5 then
        brain.currentTask = {
          action = 'Move',
          x = brain.guardX,
          y = brain.guardY,
          walkType = 'Walk',
        }
        brain.taskState = 'NEW'
      end
    end
  elseif state == Data.State.Idle then
    local nearestZombie = Utils.findNearestZombie(npc:getX(), npc:getY(), npc:getZ(), 5)
    if nearestZombie then
      brain.currentTask = {
        action = 'Smack',
        x = nearestZombie:getX(),
        y = nearestZombie:getY(),
        eid = Utils.getCharacterID(nearestZombie),
        weapon = brain.weapon,
      }
      brain.taskState = 'NEW'
    end
  end
end

-- ============================================================
-- 第 5 步：处理任务（通过 SquadActions 执行）
-- ============================================================
local processTask = function(npc, task, taskState)
  if not task or not task.action then
    return true
  end

  local action = SquadActions[task.action]
  if not action then
    Utils.debugLog('npc-handler', 'unknown action: ' .. tostring(task.action))
    return true
  end

  if taskState == 'NEW' then
    local ok = action.onStart(npc, task)
    if ok then
      return 'WORKING'
    end
  elseif taskState == 'WORKING' then
    local done = action.onWorking(npc, task)
    if done then
      return 'COMPLETED'
    end
  elseif taskState == 'COMPLETED' then
    local ok = action.onComplete(npc, task)
    if ok then
      return nil -- 任务完全结束
    end
  end

  return taskState -- 保持不变
end

-- ============================================================
-- OnZombieUpdate 主入口
-- ============================================================
local onZombieUpdate = function(zombie)
  if isServer() then
    return
  end
  if not zombie:isAlive() or zombie:isRagdoll() then
    return
  end

  local brain = Data.getBrain(zombie)
  if not brain then
    return
  end

  -- Step 1：首次初始化
  local npcID = brain.id
  if not humanized[npcID] then
    humanizeNPC(zombie)
    humanized[npcID] = true
  end

  -- Step 2：每帧行为覆盖
  updateNPCPreframe(zombie)

  -- Step 3：拦截僵尸引擎状态
  local canProcess = manageActionState(zombie)
  if not canProcess then
    return
  end

  -- Step 4：任务处理
  local task = brain.currentTask
  if task then
    local newState = processTask(zombie, task, brain.taskState or 'NEW')
    if newState == nil then
      brain.currentTask = nil
      brain.taskState = nil
    else
      brain.taskState = newState
    end
  end

  -- Step 5：周期性生成新任务（每 15 帧 ≈ 0.25 秒）
  updateTick = updateTick + 1
  if updateTick >= 15 then
    updateTick = 0
    generateTask(zombie, brain)
  end
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

Utils.debugLog('npc-handler', 'NPC client AI handler loaded')
