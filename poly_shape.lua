local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string





local format = string.format
local yield = coroutine.yield

require('love')


require('ffi')




local timeout = 0.5
local texture_msg = graphic_command_channel:demand(timeout)
local width = graphic_command_channel:demand(timeout)
local height = graphic_command_channel:demand(timeout)





if not texture_msg or not width or not height then
   print("texture_msg, width, height", texture_msg, width, height)
   error("Not enough data received to initializate poly_shape renderer.")
end

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


















yield()






local hash = {}



local cmd_num = 0

local gr = love.graphics
local quad = gr.newQuad(0, 0, 256, 256, texture)

local function draw(x, y, angle)
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

while true do
   local cmd

   cmd_num = 0
















   repeat
      cmd = graphic_command_channel:demand()


      if cmd == "new" then
         local id = get_id()
         local x = graphic_command_channel:demand()
         local y = graphic_command_channel:demand()
         local angle = graphic_command_channel:demand()

         hash[id] = { [1] = x, [2] = y, [3] = angle }
      elseif cmd == "remove" then
         local id = get_id()
         hash[id] = nil

      elseif cmd == 'clear' then
         hash = {}
         break
      elseif cmd == 'flush' then
         for _, v in pairs(hash) do
            draw(v[1], v[2], v[3])
         end

         break
      elseif cmd == 'enough' then
         break
      else
         error('poly_shape unkonwn command: ' .. cmd)
      end

      cmd_num = cmd_num + 1
   until not cmd

   yield()
end
