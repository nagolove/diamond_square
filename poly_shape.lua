local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table





local inspect = require('inspect')
local colorize = require('ansicolors2').ansicolors
local format = string.format
local yield = coroutine.yield
local gr = love.graphics

require('love')




local timeout = 0.5


local texture_msg = graphic_command_channel:demand(timeout)

local texture_msg_t = graphic_command_channel:demand(timeout)


local width = graphic_command_channel:demand(timeout)
local height = graphic_command_channel:demand(timeout)


local width_t = graphic_command_channel:demand(timeout)
local height_t = graphic_command_channel:demand(timeout)





local errmsg = 'Not enough data received to ' ..
'initializate %s poly_shape renderer.'





if not texture_msg or not width or not height then
   print("texture_msg, width, height", texture_msg, width, height)
   error(format(errmsg, "body"))
end

if not texture_msg_t or not width_t or not height_t then
   print("texture_msg_t, width_t, height_t", texture_msg_t, width_t, height_t)
   error(format(errmsg, "turret"))
end

if type(texture_msg) ~= 'string' or type(texture_msg_t) ~= 'string' then
   error('Wrong texture(t) type')
end

if type(width) ~= 'number' or type(width_t) ~= 'number' then
   error('Wrong width(t) type')
end

if type(height) ~= 'number' or type(height_t) ~= 'number' then
   error('Wrong height(t) type')
end



local path = SCENE_PREFIX .. '/' .. texture_msg
local path_t = SCENE_PREFIX .. '/' .. texture_msg_t

print("path", path)
print("path_t", path_t)

local texture = love.graphics.newImage(path)
local texture_t = love.graphics.newImage(path_t)

local function check(tex, tex_path)
   if tex then
      local w, h = tex:getDimensions()
      local msg = format('"%s" loaded %dx%d', tex_path, w, h)
      print(msg)
   else
      error('Could not load texture:' .. path)
   end
end

check(texture, path)
check(texture_t, path)

print('width, height:', width, height)
print('width_t, height_t:', width_t, height_t)













yield()






local hash = {}



local cmd_num = 0


local quad = gr.newQuad(0, 0, 256, 256, texture)




local quad_t = gr.newQuad(102, 0, 54, 160, texture_t)

local function draw(
   texture,
   quad,
   x, y, angle)

   gr.push()
   gr.translate(x, y)
   gr.rotate(angle)
   gr.translate(-width / 2, -height / 2)
   gr.setColor({ 1, 1, 1, 1 })
   gr.draw(texture, quad, 0, 0)
   gr.pop()
end

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
      draw(texture, quad, v[1], v[2], v[3])
      draw(texture_t, quad_t, v[4], v[5], v[6])
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
