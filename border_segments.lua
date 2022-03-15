local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local string = _tl_compat and _tl_compat.string or string








local yield = coroutine.yield
local linew = 12
local gr = love.graphics
local font = gr.newFont(42)


local print_coordinates = false

local msg_bool = 
"border_segments: print_coordinates " ..
"command should have boolean argument."

while true do
   local cmd

   local oldlw = gr.getLineWidth()
   local oldf = gr.getFont()
   gr.setFont(font)
   gr.setLineWidth(linew)
   repeat
      cmd = graphic_command_channel:demand()

      if cmd == "draw" then
         local x1, y1, x2, y2
         x1 = graphic_command_channel:demand()
         y1 = graphic_command_channel:demand()
         x2 = graphic_command_channel:demand()
         y2 = graphic_command_channel:demand()

         gr.setColor({ 0, 0, 0, 1 })
         gr.line(x1, y1, x2, y2)

         if print_coordinates then
            local msg
            gr.setColor({ 1, 0, 0, 1 })
            msg = string.format("(%d, %d)", x1, y1)
            gr.print(msg, x1, y1)
            msg = string.format("(%d, %d)", x2, y2)
            gr.print(msg, x2, y2)
         end

      elseif cmd == 'print_coordinates' then
         local state = graphic_command_channel:demand()
         if type(state) ~= 'boolean' then
            error(msg_bool)
         end
      elseif cmd == 'flush' then
         break
      else
         error('unkonwn command: ' .. cmd)
      end

   until not cmd
   gr.setLineWidth(oldlw)
   gr.setFont(oldf)

   yield()
end
