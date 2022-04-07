local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table





local inspect = require('inspect')
local colorize = require('ansicolors2').ansicolors
local format = string.format
local yield = coroutine.yield
local gr = love.graphics

require('love')




local color = { 194 / 255, 27 / 255, 27 / 255, 1 }

print(colorize("%{green}debug_vertices inited.%{reset}"))







yield()






















local commands = {}

local Command = {}









function commands.new()
   print("debug_vertices: new")
   local tables_num = graphic_command_channel:demand()
   print('tables_num', tables_num)
   local oldw = gr.getLineWidth()
   local linew = 7
   gr.setColor(color)

   gr.setLineWidth(linew)
   for i = 1, tables_num do
      local verts = graphic_command_channel:demand()
      print('verts', inspect(verts))
      gr.polygon("line", verts)
   end
   gr.setLineWidth(oldw)

   return true
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
   "%{blue}debug_vertices: cmd stack: " ..
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
         error('debug_vertices unknown command: ' .. cmd)
      end
      if not fun() then
         break
      end

   until not cmd

   yield()
end
