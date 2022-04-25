local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local math = _tl_compat and _tl_compat.math or math; local table = _tl_compat and _tl_compat.table or table; require('love')


local inspect = require('inspect')
local colorize = require('ansicolors2').ansicolors
local cos = math.cos
local sin = math.sin
local fromPolar = require('vector-light').fromPolar
local gr = love.graphics
local yield = coroutine.yield
local ray_color = { 1, 1, 1, 1 }

local Command = {}






local commands = {}

local dist = 1.

function commands.set_dist()
   local d = graphic_command_channel:demand()
   if type(d) ~= 'number' then
      error("fire_dir.tl: set_dist() got not a number, " .. type(d))
   end
   dist = d
end

local lineWidth = 4

function commands.ray()
   local x1 = graphic_command_channel:demand()
   local y1 = graphic_command_channel:demand()
   local angle = graphic_command_channel:demand()

   local x2, y2 = fromPolar(angle, dist)
   x2, y2 = x1 + x2, y1 + y2

   gr.setColor(ray_color)
   gr.setLineWidth(lineWidth)
   gr.line(x1, y1, x2, y2)

   return true
end

function commands.enough()
   return false
end

local target_color = { 1, 0, 0, 1 }

function commands.target()
   local x = graphic_command_channel:demand()
   local y = graphic_command_channel:demand()
   local radius = 10
   gr.setColor(target_color)
   gr.circle("fill", x, y, radius)
   return true
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

   repeat
      cmd = graphic_command_channel:demand()
      push_cbuf(cmd)

      local fun = commands[cmd]
      if not fun then
         print_stack()
         error('fire_dir unknown command: ' .. cmd)
      end
      if not fun() then
         break
      end

   until not cmd

   yield()
end
