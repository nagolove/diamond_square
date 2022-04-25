local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local load = _tl_compat and _tl_compat.load or load; local math = _tl_compat and _tl_compat.math or math; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table





local Tank = require("tank")
local inspect = require('inspect')
local colorize = require('ansicolors2').ansicolors
local format = string.format
local yield = coroutine.yield
local gr = love.graphics

require('love')




local timeout = 0.5


local ser_full_info = graphic_command_channel:demand(timeout)
local fun, errmsg = load(ser_full_info)
if errmsg then
   error(format("poly_shape.tl: load error '%s'", errmsg))
end
local full_info = fun()

local rect_turret = full_info.rect_turret
local rect_body = full_info.rect_body
local init_tank = full_info.init_table



local path = SCENE_PREFIX .. '/' .. full_info.base_tex_fname
local path_t = SCENE_PREFIX .. '/' .. full_info.turret_tex_fname

local tex_body = love.graphics.newImage(path)
local tex_turret = love.graphics.newImage(path_t)







yield()






local hash = {}


local cmd_num = 0


local quad_body = gr.newQuad(
rect_body.x, rect_body.y, rect_body.w, rect_body.h, tex_body)


local quad_turret = gr.newQuad(
rect_turret.x, rect_turret.y, rect_turret.w, rect_turret.h, tex_turret)


















local function get_id()
   local id = graphic_command_channel:demand()

   if type(id) ~= 'number' then
      error('id type should be a number, not ' .. type(id))
   end

   return id
end

local commands = {}

local Command = {}





















function commands.new_t()
   local id = get_id()


   local x = graphic_command_channel:demand()
   local y = graphic_command_channel:demand()
   local angle = graphic_command_channel:demand()


   local tx = graphic_command_channel:demand()
   local ty = graphic_command_channel:demand()
   local tangle = graphic_command_channel:demand()

   hash[id] = {

      [1] = x, [2] = y, [3] = angle,

      [4] = tx, [5] = ty, [6] = tangle,
   }
   return true
end


function commands.remove()
   local id = get_id()
   hash[id] = nil
   return true
end


function commands.clear()
   hash = {}
   return false
end


function commands.flush()






   for _, v in pairs(hash) do
      local x, y, angle = v[1], v[2], v[3]
      local tur_x, tur_y, tur_angle = v[4], v[5], v[6]

      gr.setColor({ 1, 1, 1, 1 })
      gr.push()
      gr.translate(x, y)
      gr.rotate(angle)
      gr.translate(-rect_body.w / 2, -rect_body.h / 2)

      gr.draw(tex_body, quad_body, 0, 0)
      gr.pop()




      gr.push()
      gr.translate(tur_x, tur_y)

      gr.rotate(tur_angle + math.pi)
      gr.translate(
      -rect_turret.w / 2,

      -rect_turret.h / 2 + init_tank.anchorB[2])

      gr.draw(tex_turret, quad_turret, 0, 0)
      gr.pop()
   end

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
      push_cbuf(cmd)

      local fun = commands[cmd]
      if not fun then
         print_stack()
         error('poly_shape unknown command: ' .. cmd)
      end
      if not fun() then
         break
      end

      cmd_num = cmd_num + 1
   until not cmd

   yield()
end
