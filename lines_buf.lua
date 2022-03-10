local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local pairs = _tl_compat and _tl_compat.pairs or pairs

local yield = coroutine.yield

local timeout = 0.5
local t1 = love.timer.getTime()

local font_name = graphic_command_channel:demand(timeout)




local font_size = graphic_command_channel:demand(timeout)



local t2 = love.timer.getTime()

if t2 - t1 >= timeout then
   error("Could not demand data, timeout elapsed.")
end


print("SCENE_PREFIX", SCENE_PREFIX)
local path = SCENE_PREFIX .. "/" .. font_name
local font = love.graphics.newFont(path, font_size)


local buffer = {}

yield()

while true do
   local cmd


   local oldfont = love.graphics.getFont()
   repeat
      cmd = graphic_command_channel:demand()

      if cmd == "add" then
         local id = graphic_command_channel:demand()
         local message = graphic_command_channel:demand()

         if type(id) ~= 'string' then
            error('id in lines_buf should be a string')
         end
         if type(message) ~= 'string' then
            error('message in lines_buf should be a string')
         end

         buffer[id] = message

      elseif cmd == 'remove' then
         local id = graphic_command_channel:demand()
         buffer[id] = nil
      elseif cmd == 'clear' then
         buffer = {}
      elseif cmd == 'flush' then
         love.graphics.setFont(font)
         love.graphics.setColor({ 0, 0, 0, 1 })
         local y = 0.

         for _, v in pairs(buffer) do
            love.graphics.print(v, 0, y)
            y = y + font:getHeight()
         end

         break
      else
         error('lines_buf unkonwn command: ' .. cmd)
      end

   until not cmd
   love.graphics.setFont(oldfont)

   yield()
end
