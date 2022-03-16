local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local pairs = _tl_compat and _tl_compat.pairs or pairs

































local gr = love.graphics
local yield = coroutine.yield
local colorize = require('ansicolors2').ansicolors

local timeout = 0.5
local t1 = love.timer.getTime()

local font_name = graphic_command_channel:demand(timeout)
if type(font_name) ~= "string" then
   error("Incorrect font name variable type.")
end

local font_size = graphic_command_channel:demand(timeout)
if type(font_size) ~= "number" then
   error("Declare font size as integer.")
end
local t2 = love.timer.getTime()

if t2 - t1 >= timeout then
   error("Could not demand data, timeout elapsed.")
end


print("SCENE_PREFIX", SCENE_PREFIX)
local path = SCENE_PREFIX .. "/" .. font_name
local font = gr.newFont(path, font_size)

local buffer = {}

local buffer_num = 0

local use_border = false

local border_w = 0

local border_line_width = 10


yield()


local posx, posy = 0., 0.

local function calculate_border_witdh()
   local max_len = 0
   gr.setLineWidth(border_line_width)
   for _, v in pairs(buffer) do
      local pix_len = font:getWidth(v)
      if pix_len > max_len then
         max_len = pix_len
      end
   end
   border_w = max_len
   print('calculate_border_witdh')
end

local text_color = { 0, 0, 0, 1 }
local border_color = { 0, 0, 0, 1 }


local function align_center()
   local w, h = gr.getDimensions()
   posx = (w - border_w) / 2
   posy = (h - buffer_num * font:getHeight()) / 2
   print('posx, posy', posx, posy)
   return true
end

local function draw()
   gr.setFont(font)
   gr.setColor(text_color)
   local y = posy
   for _, v in pairs(buffer) do
      gr.print(v, posx, y)
      y = y + font:getHeight()
   end
   return false
end

local commands = {
   ['add'] = function()
      local id = graphic_command_channel:demand()
      local message = graphic_command_channel:demand()

      if type(id) ~= 'string' and type(id) ~= 'number' then
         print('id, type(id)', id, type(id))
         error('id in lines_buf should be a string or number')
      end
      if type(message) ~= 'string' then
         error('message in lines_buf should be a string')
      end

      buffer[id] = message
      buffer_num = buffer_num + 1

      return true
   end,
   ['border'] = function()
      print(colorize('%{yellow}cmd == border'))
      local state = graphic_command_channel:demand()
      if type(state) ~= 'boolean' then
         error('lines_buf: border should be a boolean value')
      end
      use_border = state
      if use_border then
         calculate_border_witdh()
      end
      return true
   end,
   ['align_center'] = align_center,
   ['pos'] = function()
      local x = graphic_command_channel:demand()
      local y = graphic_command_channel:demand()

      if type(x) ~= 'number' then
         error('x should be a number in lines_buf->add')
      end
      if type(y) ~= 'number' then
         error('y should be a number in lines_buf->add')
      end

      posx, posy = x, y
      return true
   end,
   ['remove'] = function()
      local id = graphic_command_channel:demand()
      if buffer[id] then
         buffer[id] = nil
         buffer_num = buffer_num - 1
      end
      return true
   end,
   ['clear'] = function()
      buffer = {}
      buffer_num = 0
      return false
   end,
   ['enough'] = function()
      return false
   end,
   ['flush'] = draw,
}

while true do
   local cmd


   local oldfont = gr.getFont()
   repeat
      cmd = graphic_command_channel:demand()









      local fun = commands[cmd]
      if not fun then
         error('lines_buf unkonwn command: ' .. cmd)
      end
      if not fun() then
         break
      end

   until not cmd
   gr.setFont(oldfont)

   yield()
end
