-- Squad 战斗判定模块
-- 负责命中判定、伤害计算、击杀检测等战斗相关逻辑
-- 客户端和服务端均加载此模块

local Utils = require('squad/utils')
local Weapons = require('squad/weapons')

-- 计算近战命中
-- 返回: hasHit (bool), damage (number)
local calculateMeleeHit = function(attackerX, attackerY, targetX, targetY, weaponType)
  local config = Weapons.getWeaponConfig(weaponType)
  local dist = Utils.distTo(attackerX, attackerY, targetX, targetY)

  -- 超出武器范围则未命中
  if dist > config.range then
    return false, 0
  end

  -- 基础命中率 80%，距离越近命中率越高
  local hitChance = 0.8 + (1 - dist / config.range) * 0.2
  if ZombRand(100) / 100 > hitChance then
    return false, 0
  end

  -- 计算伤害：在 minDamage 和 maxDamage 之间随机
  local damage = config.minDamage + ZombRand(100) / 100 * (config.maxDamage - config.minDamage)
  return true, damage
end

-- 计算远程命中
-- 返回: hasHit (bool), damage (number)
local calculateRangedHit = function(attackerX, attackerY, targetX, targetY, weaponType)
  local config = Weapons.getWeaponConfig(weaponType)
  local dist = Utils.distTo(attackerX, attackerY, targetX, targetY)

  -- 超出武器射程
  if dist > config.range then
    return false, 0
  end

  -- 远程命中率随距离递减
  local hitChance = 0.7 - (dist / config.range) * 0.4
  if ZombRand(100) / 100 > hitChance then
    return false, 0
  end

  local damage = config.minDamage + ZombRand(100) / 100 * (config.maxDamage - config.minDamage)
  return true, damage
end

-- 检查目标是否已死亡
local isDead = function(target)
  if not target then
    return true
  end
  -- IsoZombie 判定
  if target.getHealth and target:getHealth() <= 0 then
    return true
  end
  -- isDead 方法
  if target.isDead and target:isDead() then
    return true
  end
  return false
end

-- 对目标施加伤害
-- 返回: 是否击杀
local applyDamage = function(target, damage)
  if not target or isDead(target) then
    return false
  end

  -- 尝试使用 Hit 方法
  if target.Hit then
    target:Hit(damage)
  else
    -- 直接扣血
    local currentHealth = target:getHealth()
    if currentHealth then
      target:setHealth(currentHealth - damage)
    end
  end

  return isDead(target)
end

-- 执行一次攻击
-- 返回: hasHit (bool), killed (bool), damage (number)
local performAttack = function(attackerX, attackerY, target, weaponType)
  if not target or isDead(target) then
    return false, false, 0
  end

  local tx = target:getX()
  local ty = target:getY()

  local hasHit, damage
  if Weapons.isRanged(weaponType) then
    hasHit, damage = calculateRangedHit(attackerX, attackerY, tx, ty, weaponType)
  else
    hasHit, damage = calculateMeleeHit(attackerX, attackerY, tx, ty, weaponType)
  end

  if not hasHit then
    return false, false, 0
  end

  local killed = applyDamage(target, damage)
  return true, killed, damage
end

return {
  calculateMeleeHit = calculateMeleeHit,
  calculateRangedHit = calculateRangedHit,
  isDead = isDead,
  applyDamage = applyDamage,
  performAttack = performAttack,
}
