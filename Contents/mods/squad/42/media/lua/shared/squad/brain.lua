-- Squad NPC 大脑辅助函数模块
-- 提供任务管理、状态查询等与大脑数据结构相关的操作
-- 客户端和服务端均加载此模块

local Data = require('squad/data')

-- 检查大脑是否有待执行的任务
local hasTask = function(brain)
  return brain and brain.tasks and #brain.tasks > 0
end

-- 检查大脑是否有某种类型的任务
local hasTaskType = function(brain, actionType)
  if not brain or not brain.tasks then
    return false
  end
  for _, task in ipairs(brain.tasks) do
    if task.action == actionType then
      return true
    end
  end
  return false
end

-- 检查大脑是否有移动类任务（Move、GoTo）
local hasMoveTask = function(brain)
  if not brain or not brain.tasks then
    return false
  end
  for _, task in ipairs(brain.tasks) do
    if task.action == 'Move' or task.action == 'GoTo' then
      return true
    end
  end
  return false
end

-- 获取大脑中第一个指定类型的任务
local getTask = function(brain, actionType)
  if not brain or not brain.tasks then
    return nil
  end
  for _, task in ipairs(brain.tasks) do
    if task.action == actionType then
      return task
    end
  end
  return nil
end

-- 推送一个任务到大脑的任务队列末尾
local pushTask = function(brain, task)
  if not brain then
    return
  end
  brain.tasks = brain.tasks or {}
  table.insert(brain.tasks, task)
end

-- 弹出并返回大脑任务队列的第一个任务
local popTask = function(brain)
  if not brain or not brain.tasks or #brain.tasks == 0 then
    return nil
  end
  return table.remove(brain.tasks, 1)
end

-- 清空大脑的所有任务
local clearTasks = function(brain)
  if not brain then
    return
  end
  brain.tasks = {}
end

-- 获取大脑当前状态（Idle、Moving、Attacking 等）
local getState = function(brain)
  if not brain then
    return Data.State.Dead
  end
  return brain.state or Data.State.Idle
end

-- 设置大脑状态
local setState = function(brain, state)
  if not brain then
    return
  end
  brain.state = state
end

-- 设置大脑的攻击目标
local setTarget = function(brain, targetId, x, y, z)
  if not brain then
    return
  end
  brain.targetId = targetId
  brain.targetX = x
  brain.targetY = y
  brain.targetZ = z
end

-- 清除大脑的攻击目标
local clearTarget = function(brain)
  if not brain then
    return
  end
  brain.targetId = nil
  brain.targetX = nil
  brain.targetY = nil
  brain.targetZ = nil
end

return {
  hasTask = hasTask,
  hasTaskType = hasTaskType,
  hasMoveTask = hasMoveTask,
  getTask = getTask,
  pushTask = pushTask,
  popTask = popTask,
  clearTasks = clearTasks,
  getState = getState,
  setState = setState,
  setTarget = setTarget,
  clearTarget = clearTarget,
}
