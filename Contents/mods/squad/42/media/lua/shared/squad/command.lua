-- Squad 命令定义与校验模块
-- 定义攻击、防御、跟随、停止等命令的数据结构与合法性检查
-- 客户端和服务端均加载此模块

local Data = require('squad/data')
local CommandType = Data.CommandType

-- 构建攻击目标命令参数
local makeAttackCommand = function(npcId, targetId)
  return {
    type = CommandType.Attack,
    npcId = npcId,
    targetId = targetId,
  }
end

-- 构建防御区域命令参数
local makeDefendCommand = function(npcId, x, y, z)
  return {
    type = CommandType.Defend,
    npcId = npcId,
    x = x,
    y = y,
    z = z,
  }
end

-- 构建跟随命令参数
local makeFollowCommand = function(npcId, leaderId)
  return {
    type = CommandType.Follow,
    npcId = npcId,
    leaderId = leaderId,
  }
end

-- 构建停止命令参数
local makeStopCommand = function(npcId)
  return {
    type = CommandType.Stop,
    npcId = npcId,
  }
end

-- 校验攻击命令是否合法
local validateAttackCommand = function(cmd)
  if not cmd or cmd.type ~= CommandType.Attack then
    return false, '命令类型错误'
  end
  if not cmd.npcId then
    return false, '缺少 NPC ID'
  end
  if not cmd.targetId then
    return false, '缺少目标 ID'
  end
  return true, nil
end

-- 校验防御命令是否合法
local validateDefendCommand = function(cmd)
  if not cmd or cmd.type ~= CommandType.Defend then
    return false, '命令类型错误'
  end
  if not cmd.npcId then
    return false, '缺少 NPC ID'
  end
  if not cmd.x or not cmd.y or not cmd.z then
    return false, '缺少守卫坐标'
  end
  return true, nil
end

-- 校验跟随命令是否合法
local validateFollowCommand = function(cmd)
  if not cmd or cmd.type ~= CommandType.Follow then
    return false, '命令类型错误'
  end
  if not cmd.npcId then
    return false, '缺少 NPC ID'
  end
  if not cmd.leaderId then
    return false, '缺少队长 ID'
  end
  return true, nil
end

-- 校验停止命令是否合法
local validateStopCommand = function(cmd)
  if not cmd or cmd.type ~= CommandType.Stop then
    return false, '命令类型错误'
  end
  if not cmd.npcId then
    return false, '缺少 NPC ID'
  end
  return true, nil
end

-- 根据命令类型执行校验
local validate = function(cmd)
  if not cmd then
    return false, '命令为空'
  end
  if cmd.type == CommandType.Attack then
    return validateAttackCommand(cmd)
  elseif cmd.type == CommandType.Defend then
    return validateDefendCommand(cmd)
  elseif cmd.type == CommandType.Follow then
    return validateFollowCommand(cmd)
  elseif cmd.type == CommandType.Stop then
    return validateStopCommand(cmd)
  end
  return false, '未知命令类型'
end

return {
  makeAttackCommand = makeAttackCommand,
  makeDefendCommand = makeDefendCommand,
  makeFollowCommand = makeFollowCommand,
  makeStopCommand = makeStopCommand,
  validate = validate,
}
