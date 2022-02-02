local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local string = _tl_compat and _tl_compat.string or string





local format = string.format
local yield = coroutine.yield

require('love')

local C = require('ffi')
require('ffi')




local texture_msg = graphic_command_channel:demand()
local width = graphic_command_channel:demand()
local height = graphic_command_channel:demand()

if type(texture_msg) ~= 'string' then
   error('Wrong texture type')
end
if type(width) ~= 'number' then
   error('Wrong width type')
end
if type(height) ~= 'number' then
   error('Wrong height type')
end

local path = SCENE_PREFIX .. '/' .. texture_msg
local texture = love.graphics.newImage(path)
if texture then
   local w, h = texture:getDimensions()
   local msg = format('"%s" loaded %dx%d', path, w, h)
   print(msg)
else
   error('Could not load texture:' .. path)
end

print('shape width, height:', width, height)






local mesh_size = 6
local mesh = love.graphics.newMesh(mesh_size, "triangles", "static")


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



         local rad = 20

         love.graphics.push()
         love.graphics.translate(x, y)
         love.graphics.rotate(angle)
         love.graphics.translate(-width / 2, -height / 2)

         love.graphics.setColor({ 0, 0.5, 1, 1 })
         love.graphics.rectangle('fill', 0, 0, width, height)

         love.graphics.pop()

         love.graphics.setColor({ 0, 0, 1, 1 })
         love.graphics.circle('fill', x, y, rad)

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
