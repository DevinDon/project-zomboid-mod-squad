-- Squad 武器配置模块
-- 定义 NPC 可用的固定武器表和无限弹药配置
-- 客户端和服务端均加载此模块

-- 近战武器表（武器名称 → 基础伤害）
local MeleeWeapons = {
  ['Base.BaseballBat'] = { minDamage = 0.8, maxDamage = 1.2, range = 2.0 },
  ['Base.Axe'] = { minDamage = 1.0, maxDamage = 1.8, range = 1.8 },
  ['Base.HuntingKnife'] = { minDamage = 0.5, maxDamage = 0.9, range = 1.2 },
  ['Base.Hammer'] = { minDamage = 0.5, maxDamage = 1.0, range = 1.5 },
  ['Base.Crowbar'] = { minDamage = 0.6, maxDamage = 1.1, range = 1.8 },
  ['Base.WoodAxe'] = { minDamage = 0.9, maxDamage = 1.5, range = 2.0 },
  ['Base.Shovel'] = { minDamage = 0.7, maxDamage = 1.3, range = 1.8 },
  ['Base.PickAxe'] = { minDamage = 0.8, maxDamage = 1.4, range = 1.8 },
}

-- 远程武器表
local RangedWeapons = {
  ['Base.Pistol'] = { minDamage = 0.6, maxDamage = 1.0, range = 10.0 },
  ['Base.Shotgun'] = { minDamage = 1.2, maxDamage = 2.0, range = 7.0 },
  ['Base.HuntingRifle'] = { minDamage = 1.5, maxDamage = 2.5, range = 15.0 },
}

-- 获取武器配置，未配置的武器返回默认值
local getWeaponConfig = function(weaponType)
  local config = MeleeWeapons[weaponType] or RangedWeapons[weaponType]
  if config then
    return config
  end
  -- 默认配置：视为近战
  return { minDamage = 0.5, maxDamage = 1.0, range = 1.5 }
end

-- 是否为远程武器
local isRanged = function(weaponType)
  return RangedWeapons[weaponType] ~= nil
end

-- 默认武器（新招募 NPC 使用）
local DefaultWeapon = 'Base.BaseballBat'

return {
  MeleeWeapons = MeleeWeapons,
  RangedWeapons = RangedWeapons,
  DefaultWeapon = DefaultWeapon,
  getWeaponConfig = getWeaponConfig,
  isRanged = isRanged,
}
