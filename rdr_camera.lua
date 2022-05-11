local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine





local cam_common = require('camera_common')
local inspect = require('inspect')
local gr = love.graphics
local yield = coroutine.yield
local colorize = require('ansicolors2').ansicolors





local cam_bbox = {
   w = 0.8,
   h = 0.8,
}

local cam_x, cam_y, cam_scale = 0., 0., 1.
local cam_bbox_pix = {}

local Command = {}






local commands = {}

function commands.attach()

   local x = graphic_command_channel:demand()
   local y = graphic_command_channel:demand()
   local scale = graphic_command_channel:demand()

   cam_x, cam_y = x, y
   cam_scale = scale

   local w, h = gr.getDimensions()

   local dx, dy = 0, 0
   local cx, cy = dx + w / 2, dy + h / 2

   gr.push()
   gr.translate(cx, cy)
   gr.scale(scale)
   gr.translate(-x, -y)

   return false

end

local bbox_color = { 1, 1, 1, 1 }

function commands.set_bbox()
   local factor_w = graphic_command_channel:demand()
   local factor_h = graphic_command_channel:demand()
   cam_bbox.w = factor_w
   cam_bbox.h = factor_h
   if not cam_common.check_bbox() then
      error("bad camera bbox: " .. inspect(cam_bbox))
   end
   local w, h = gr.getDimensions()
   cam_bbox_pix = cam_common.calc_bbox_pix(cam_bbox, w, h, cam_x, cam_y)
end

function commands.draw_bbox()
   gr.setColor(bbox_color)
   local oldw = gr.getLineWidth()
   local lw = 5
   gr.setLineWidth(lw)
   gr.rectangle(
   "line",
   cam_bbox_pix.x,
   cam_bbox_pix.y,
   cam_bbox_pix.w,
   cam_bbox_pix.h)

   gr.setLineWidth(oldw)
   return false
end

function commands.detach()
   gr.pop()
   return false
end

local w, h = gr.getDimensions()
cam_bbox_pix = cam_common.calc_bbox_pix(cam_bbox, w, h, cam_x, cam_y)

while true do
   local cmd

   repeat
      cmd = graphic_command_channel:demand()

      local fun = commands[cmd]
      if not fun then
         error('rdr_camera unkonwn command: ' .. cmd)
      end
      if not fun() then
         break
      end

   until not cmd

   yield()
end
