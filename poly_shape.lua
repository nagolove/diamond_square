local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine





local yield = coroutine.yield

local mesh_size = 1024

require('love')
require('ffi')




local texture_msg = graphic_command_channel:demand()
if type(texture_msg) ~= 'string' then
   error('Wrong texture type')
end




local C = require('ffi')


local mesh = love.graphics.newMesh(mesh_size * 6, "triangles", "dynamic")


local path = SCENE_PREFIX .. '/' .. texture_msg
print('path', path)
local texture = love.graphics.newImage(path)
if texture then
   print('texture loaded', texture:getDimensions())
end
mesh:setTexture(texture)








yield()






local hash = {}
local verts = nil


local cmd_num = 0

while true do
   local cmd

   cmd_num = 0

















   repeat
      cmd = graphic_command_channel:demand()


      if cmd == "new" then
         local x, y, angle
         local id = graphic_command_channel:demand()
         x = graphic_command_channel:demand()
         y = graphic_command_channel:demand()
         angle = graphic_command_channel:demand()

         print('x, y', x, y)
         print('angle', angle)

         hash[id] = verts




      elseif cmd == "draw" then
         local id = graphic_command_channel:demand()
         verts = hash[id]




      elseif cmd == "remove" then
         local id = graphic_command_channel:demand()
         hash[id] = nil



      elseif cmd == 'flush' then


         break
      end





      if verts then































      end

      cmd_num = cmd_num + 1
   until not cmd

   yield()
end
