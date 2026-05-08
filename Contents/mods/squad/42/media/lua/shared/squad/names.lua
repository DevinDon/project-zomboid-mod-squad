-- Squad 姓名生成模块
-- 提供 NPC 随机姓名生成功能
-- 客户端和服务端均加载此模块

local Utils = require('squad/utils')

-- 男性名字
local MaleFirstNames = {
  'Liam', 'Noah', 'Oliver', 'Elijah', 'James',
  'William', 'Benjamin', 'Lucas', 'Henry', 'Theodore',
  'Jack', 'Levi', 'Alexander', 'Jackson', 'Mateo',
  'Daniel', 'Michael', 'Mason', 'Sebastian', 'Ethan',
  'Logan', 'Owen', 'Samuel', 'Jacob', 'Asher',
  'Aiden', 'John', 'Joseph', 'Wyatt', 'David',
  'Leo', 'Luke', 'Julian', 'Hudson', 'Grayson',
  'Matthew', 'Ezra', 'Gabriel', 'Carter', 'Isaac',
  'Jayden', 'Luca', 'Anthony', 'Dylan', 'Lincoln',
  'Thomas', 'Maverick', 'Elias', 'Josiah', 'Charles',
}

-- 女性名字
local FemaleFirstNames = {
  'Olivia', 'Emma', 'Charlotte', 'Amelia', 'Sophia',
  'Isabella', 'Ava', 'Mia', 'Evelyn', 'Luna',
  'Harper', 'Camila', 'Gianna', 'Aria', 'Ella',
  'Scarlett', 'Grace', 'Chloe', 'Victoria', 'Riley',
  'Zoey', 'Lily', 'Aurora', 'Hazel', 'Penelope',
  'Layla', 'Nora', 'Mila', 'Stella', 'Ellie',
}

-- 姓氏
local Surnames = {
  'Smith', 'Johnson', 'Williams', 'Brown', 'Jones',
  'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
  'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson',
  'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
  'Lee', 'Perez', 'Thompson', 'White', 'Harris',
  'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson',
  'Walker', 'Young', 'Allen', 'King', 'Wright',
  'Scott', 'Torres', 'Nguyen', 'Hill', 'Flores',
  'Green', 'Adams', 'Nelson', 'Baker', 'Hall',
}

-- 生成随机姓名
local generateName = function(female)
  local firstName
  if female then
    firstName = Utils.choice(FemaleFirstNames)
  else
    firstName = Utils.choice(MaleFirstNames)
  end
  local surname = Utils.choice(Surnames)
  return firstName .. ' ' .. surname
end

return {
  MaleFirstNames = MaleFirstNames,
  FemaleFirstNames = FemaleFirstNames,
  Surnames = Surnames,
  generateName = generateName,
}
