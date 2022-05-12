local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table





local inspect = require('inspect')
local colorize = require('ansicolors2').ansicolors
local format = string.format
local yield = coroutine.yield
local gr = love.graphics

require('love')


















local cmd_num = 0

local Command = {}









local dbg_color = { 0, 0.7, 0, 1 }
local dbg_dot_color = { 0.1, 0.6, 0.1 }

local commands = {}

function commands.circle()
   local px = graphic_command_channel:demand()
   local py = graphic_command_channel:demand()
   local angle = graphic_command_channel:demand()
   local rad = graphic_command_channel:demand()

   gr.setColor(dbg_color)
   gr.circle("line", px, py, rad)

   return true
end

function commands.segment()
   local ax = graphic_command_channel:demand()
   local ay = graphic_command_channel:demand()
   local bx = graphic_command_channel:demand()
   local by = graphic_command_channel:demand()

   gr.setColor(dbg_color)
   gr.line(ax, ay, bx, by)

   return true
end

function commands.fatsegment()
   local ax = graphic_command_channel:demand()
   local ay = graphic_command_channel:demand()
   local bx = graphic_command_channel:demand()
   local by = graphic_command_channel:demand()
   local rad = graphic_command_channel:demand()

   local oldw = gr.getLineWidth()
   gr.setLineWidth(rad)
   gr.line(ax, ay, bx, by)
   gr.setLineWidth(oldw)

   return true
end

function commands.polygon()
   local poly = graphic_command_channel:demand()
   local rad = graphic_command_channel:demand()

   gr.setColor(dbg_color)
   gr.polygon('line', poly)

   return true
end

function commands.dot()
   local size = graphic_command_channel:demand()
   local px = graphic_command_channel:demand()
   local py = graphic_command_channel:demand()

   gr.setColor(dbg_dot_color)
   gr.circle('fill', px, py, size)

   return true
end


function commands.flush()
   return false
end


function commands.enough()
   return false
end


local cmd_circle_buf = {}
local cmd_circle_buf_maxnum = 16 * 2

local function push_cbuf(cmd)
   if #cmd_circle_buf >= cmd_circle_buf_maxnum then
      table.remove(cmd_circle_buf, 1)
   end
   table.insert(cmd_circle_buf, cmd)
end

local function print_stack()
   print(colorize(
   "%{blue}cmd stack: " ..
   inspect(cmd_circle_buf) ..
   "%{reset}"))

end

while true do
   local cmd
   cmd_num = 0



   repeat
      cmd = graphic_command_channel:demand()


      local fun = commands[cmd]
      if not fun then
         print_stack()
         error('dbg_phys unknown command: ' .. cmd)
      end
      if not fun() then
         break
      end

      cmd_num = cmd_num + 1
   until not cmd






   yield()
end
