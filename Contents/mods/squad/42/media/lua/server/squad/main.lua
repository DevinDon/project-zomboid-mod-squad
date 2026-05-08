-- Squad 服务端入口模块
-- 注册服务端事件、初始化 ModData、启动 AI 循环
-- 仅在服务端加载

local ServerCommands = require('squad/server-commands')
local Modata = require('squad/modata')
local AI = require('squad/ai')
local Utils = require('squad/utils')

-- 客户端命令处理：路由到对应模块
local onClientCommand = function(module, command, player, args)
  if module ~= 'Squad' then
    return
  end

  Utils.debugLog('main', string.format(
    'received client command: %s (player: %s)',
    tostring(command), tostring(player:getUsername())
  ))

  ServerCommands.onCommand(command, player, args)
end

-- 全局 ModData 初始化
local onInitGlobalModData = function(isNewGame)
  Modata.initModData()
  Utils.debugLog('main', 'ModData init done (isNewGame=' .. tostring(isNewGame) .. ')')
end

-- AI 循环（每帧触发，AI 模块内部控制实际执行频率）
local onTick = function()
  AI.onTick()
end

-- 注册服务端事件
Events.OnClientCommand.Add(onClientCommand)
Events.OnInitGlobalModData.Add(onInitGlobalModData)
Events.OnTick.Add(onTick)

Utils.debugLog('main', 'server entry loaded')
