-- Squad NPC AI 执行模块
-- 服务端 AI 状态机：每 N 秒遍历所有 NPC，执行大脑中的任务
-- 仅在服务端加载

local Data = require('squad/data')
local Brain = require('squad/brain')
local Combat = require('squad/combat')
local Utils = require('squad/utils')

-- 守卫范围半径（发现僵尸自动攻击的范围）
local GuardRadius = 8

-- 跟随距离（NPC 与队长的最大距离）
local FollowDistance = 3

-- 执行攻击任务
local executeAttackTask = function(npc, brain, task)
  local targetId = task.params and task.params.targetId
  local target = Utils.findZombieById(targetId)

  -- 目标已死亡，任务完成
  if not target or Combat.isDead(target) then
    Brain.setState(brain, Data.State.Idle)
    Brain.clearTarget(brain)
    return true
  end

  -- 检查是否在武器范围内
  local config = require('squad/weapons').getWeaponConfig(brain.weapon)
  local dist = Utils.distTo(npc:getX(), npc:getY(), target:getX(), target:getY())

  if dist <= config.range then
    -- 执行攻击
    Brain.setState(brain, Data.State.Attacking)
    local hasHit, killed, damage = Combat.performAttack(
      npc:getX(), npc:getY(), target, brain.weapon
    )
    if killed then
      Utils.debugLog('ai', 'NPC ' .. brain.name .. ' killed target')
      Brain.setState(brain, Data.State.Idle)
      Brain.clearTarget(brain)
      return true
    end
    if hasHit then
      Utils.debugLog('ai', string.format(
        'NPC %s hit target, damage: %.2f', brain.name, damage
      ))
    end
  else
    -- 需要移动接近目标
    Brain.setState(brain, Data.State.Moving)
    local angle = math.atan2(target:getY() - npc:getY(), target:getX() - npc:getX())
    local moveDist = math.min(dist - config.range * 0.8, 2.0)
    local newX = npc:getX() + math.cos(angle) * moveDist
    local newY = npc:getY() + math.sin(angle) * moveDist
    npc:setX(newX)
    npc:setY(newY)
  end

  return false -- 任务未完成
end

-- 执行防御任务
local executeDefendTask = function(npc, brain)
  local gx, gy, gz = brain.guardX, brain.guardY, brain.guardZ

  -- 无守卫位置则跳过
  if not gx or not gy then
    return false
  end

  -- 检查是否在守卫点附近
  local distToGuard = Utils.distTo(npc:getX(), npc:getY(), gx, gy)

  -- 搜索守卫范围内的僵尸
  local nearestZombie = Utils.findNearestZombie(npc:getX(), npc:getY(), npc:getZ(), GuardRadius)

  if nearestZombie then
    -- 发现僵尸，临时切换为攻击
    Brain.setState(brain, Data.State.Attacking)
    local hasHit, killed, damage = Combat.performAttack(
      npc:getX(), npc:getY(), nearestZombie, brain.weapon
    )
    if killed then
      Utils.debugLog('ai', 'NPC ' .. brain.name .. ' killed zombie while defending')
    end
  else
    -- 没有威胁，回到守卫点
    if distToGuard > 1.5 then
      Brain.setState(brain, Data.State.Moving)
      local angle = math.atan2(gy - npc:getY(), gx - npc:getX())
      local moveDist = math.min(distToGuard, 1.5)
      npc:setX(npc:getX() + math.cos(angle) * moveDist)
      npc:setY(npc:getY() + math.sin(angle) * moveDist)
    else
      Brain.setState(brain, Data.State.Defending)
    end
  end

  return false -- 防御任务永不自动完成
end

-- 执行跟随任务
local executeFollowTask = function(npc, brain, task)
  local leaderId = task.params and task.params.leaderId

  -- 查找队长
  local leader = Utils.findPlayerById(leaderId)
  if not leader then
    Brain.setState(brain, Data.State.Idle)
    return false
  end

  local dist = Utils.distTo(npc:getX(), npc:getY(), leader:getX(), leader:getY())

  -- 距离太远则移动靠近
  if dist > FollowDistance then
    Brain.setState(brain, Data.State.Moving)
    local angle = math.atan2(leader:getY() - npc:getY(), leader:getX() - npc:getX())
    local moveDist = math.min(dist - FollowDistance + 0.5, 2.0)
    npc:setX(npc:getX() + math.cos(angle) * moveDist)
    npc:setY(npc:getY() + math.sin(angle) * moveDist)
  else
    Brain.setState(brain, Data.State.Idle)
  end

  -- 跟随过程中检测附近僵尸
  local nearestZombie = Utils.findNearestZombie(npc:getX(), npc:getY(), npc:getZ(), GuardRadius)
  if nearestZombie then
    Brain.setState(brain, Data.State.Attacking)
    Combat.performAttack(npc:getX(), npc:getY(), nearestZombie, brain.weapon)
  end

  return false -- 跟随任务永不自动完成
end

-- 执行移动任务：移动到指定坐标
local executeMoveTask = function(npc, brain, task)
  local tx = task.params and task.params.x
  local ty = task.params and task.params.y

  if not tx or not ty then
    return true -- 无目标坐标，任务完成
  end

  local dist = Utils.distTo(npc:getX(), npc:getY(), tx, ty)

  if dist <= 1.0 then
    -- 已到达目标
    return true
  end

  -- 向目标移动
  Brain.setState(brain, Data.State.Moving)
  local angle = math.atan2(ty - npc:getY(), tx - npc:getX())
  local moveDist = math.min(dist, 2.0)
  npc:setX(npc:getX() + math.cos(angle) * moveDist)
  npc:setY(npc:getY() + math.sin(angle) * moveDist)

  return false -- 尚未到达
end

-- 执行单个任务
-- 返回: 任务是否完成（可从队列移除）
local executeTask = function(npc, brain, task)
  if not task or not task.action then
    return true
  end

  if task.action == 'Attack' then
    return executeAttackTask(npc, brain, task)
  elseif task.action == 'Defend' then
    return executeDefendTask(npc, brain)
  elseif task.action == 'Follow' then
    return executeFollowTask(npc, brain, task)
  elseif task.action == 'Move' then
    return executeMoveTask(npc, brain, task)
  elseif task.action == 'Stop' then
    Brain.setState(brain, Data.State.Idle)
    return true
  end

  return true -- 未知任务类型，丢弃
end

-- AI 主循环：遍历所有 NPC，执行任务队列
local TICK_INTERVAL = 30 -- 每 30 帧执行一次（约 0.5 秒）
local tickCounter = 0

local tick = function()
  local cell = getCell()
  if not cell then
    return
  end

  local zombieList = cell:getZombieList()
  if not zombieList then
    return
  end

  for i = 0, zombieList:size() - 1 do
    local zombie = zombieList:get(i)
    if zombie and not zombie:isDead() then
      local brain = Data.getBrain(zombie)
      if brain then
        -- 执行任务队列中的第一个任务
        if Brain.hasTask(brain) then
          local task = brain.tasks[1]
          local completed = executeTask(zombie, brain, task)
          if completed then
            Brain.popTask(brain) -- 移除已完成任务
          end
        else
          -- 无任务时保持 Idle
          Brain.setState(brain, Data.State.Idle)
        end
      end
    end
  end
end

local onTick = function()
  tickCounter = tickCounter + 1
  if tickCounter < TICK_INTERVAL then
    return
  end
  tickCounter = 0
  tick()
end

return {
  tick = tick,
  onTick = onTick,
  GuardRadius = GuardRadius,
  FollowDistance = FollowDistance,
}
