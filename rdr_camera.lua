local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine

local gr = love.graphics
local yield = coroutine.yield
local colorize = require('ansicolors2').ansicolors




local Command = {}




local commands = {}

function commands.attach()
   local x = graphic_command_channel:demand()
   local y = graphic_command_channel:demand()
   local scale = graphic_command_channel:demand()

   local w, h = gr.getDimensions()

   local dx, dy = 0, 0
   local cx, cy = dx + w / 2, dy + h / 2

   gr.push()
   gr.translate(cx, cy)
   gr.scale(scale)
   gr.translate(-x, -y)

   return false
end

function commands.detach()
   gr.pop()
   return false
end

while true do
   local cmd

   repeat
      cmd = graphic_command_channel:demand()

      local fun = commands[cmd]
      if not fun then
         error('rdr_camera unkonwn command: ' .. cmd)
      end
      if not fun() then
         break
      end

   until not cmd

   yield()
end
