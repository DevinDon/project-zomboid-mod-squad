-- Squad 自定义动作框架 SquadActions
-- 参考 Bandits 模组的 ZombieActions 模式
-- 每个动作定义 onStart / onWorking / onComplete 三个生命周期方法
-- 仅在客户端加载

local Utils = require('squad/utils')

-- Move：朝目标直线移动
local Move = {
  onStart = function(npc, task)
    npc:setVariable('SquadWalkType', task.walkType or 'Walk')
    if task.walkType == 'Run' then
      npc:setBumpType('IdleToRun')
    else
      npc:setBumpType('IdleToWalk')
    end
    return true
  end,
  onWorking = function(npc, task)
    npc:setVariable('SquadWalkType', task.walkType or 'Walk')
    local dx = task.x - npc:getX()
    local dy = task.y - npc:getY()
    local dist = math.sqrt(dx * dx + dy * dy)
    npc:faceLocationF(task.x, task.y)
    if dist <= 0.5 then
      return true
    end
    local speed = (task.walkType == 'Run') and 0.4 or 0.15
    local step = math.min(dist, speed)
    local angle = math.atan2(dy, dx)
    npc:setX(npc:getX() + math.cos(angle) * step)
    npc:setY(npc:getY() + math.sin(angle) * step)
    return false
  end,
  onComplete = function(npc, task)
    return true
  end,
}

-- GoTo：寻路移动到坐标
local GoTo = {
  onStart = function(npc, task)
    npc:setVariable('SquadWalkType', task.walkType or 'Walk')
    npc:getPathFindBehavior2():pathToLocation(task.x, task.y, task.z or npc:getZ())
    return true
  end,
  onWorking = function(npc, task)
    npc:setVariable('SquadWalkType', task.walkType or 'Walk')
    local dx = task.x - npc:getX()
    local dy = task.y - npc:getY()
    if dx * dx + dy * dy <= 1.0 then
      npc:getPathFindBehavior2():cancel()
      npc:setPath2(nil)
      return true
    end
    if not npc:getPathFindBehavior2():isPathFinding() then
      npc:getPathFindBehavior2():pathToLocation(task.x, task.y, task.z or npc:getZ())
    end
    return false
  end,
  onComplete = function(npc, task)
    npc:getPathFindBehavior2():cancel()
    npc:setPath2(nil)
    return true
  end,
}

-- Smack：近战攻击
local Smack = {
  onStart = function(npc, task)
    npc:setBumpType('Smack')
    if task.x then
      npc:faceLocationF(task.x, task.y)
    end
    return true
  end,
  onWorking = function(npc, task)
    if task.x then
      npc:faceLocationF(task.x, task.y)
    end
    -- 等待攻击动画完成
    if npc:getBumpType() ~= 'Smack' then
      -- 执行实际伤害
      local target = task.eid and Utils.findZombieById(task.eid)
      if target and target:isAlive() then
        local weaponItem = instanceItem(task.weapon or 'Base.BaseballBat')
        if weaponItem then
          npc:DoAttack(weaponItem)
        end
      end
      return true
    end
    return false
  end,
  onComplete = function(npc, task)
    return true
  end,
}

-- Time：等待/播放动画
local Time = {
  onStart = function(npc, task)
    if task.anim then
      npc:setBumpType(task.anim)
    end
    return true
  end,
  onWorking = function(npc, task)
    if npc:getBumpType() ~= task.anim then
      return true
    end
    return false
  end,
  onComplete = function(npc, task)
    return true
  end,
}

-- Die：死亡
local Die = {
  onStart = function(npc, task)
    npc:setBumpType(task.anim or 'Die')
    return true
  end,
  onWorking = function(npc, task)
    return npc:isDead()
  end,
  onComplete = function(npc, task)
    return true
  end,
}

Utils.debugLog('squad-actions', 'SquadActions loaded')

return {
  Move = Move,
  GoTo = GoTo,
  Smack = Smack,
  Time = Time,
  Die = Die,
}
