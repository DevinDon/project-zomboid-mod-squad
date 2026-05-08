-- Squad 客户端入口模块
-- 注册客户端事件、命令发送接口、UI 入口
-- 仅在客户端加载

local ClientCommands = require('squad/client-commands')
local Utils = require('squad/utils')

-- 加载调试右键菜单（仅在调试模式下显示）
require('squad/menu')

-- 加载 NPC 行为处理器（将僵尸转换为人类型为）
require('squad/npc-handler')

-- 服务端命令处理：路由到对应模块
local onServerCommand = function(module, command, args)
  if module ~= 'Squad' then
    return
  end

  Utils.debugLog('main', string.format(
    'received server command: %s', tostring(command)
  ))

  ClientCommands.onCommand(command, args)
end

-- 发送命令到服务端的便捷函数
local sendCommand = function(commandType, args)
  sendClientCommand('Squad', commandType, args)
  Utils.debugLog('main', 'send command: ' .. commandType)
end

-- 注册客户端事件
Events.OnServerCommand.Add(onServerCommand)

Utils.debugLog('main', 'client entry loaded')
