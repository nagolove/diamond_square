local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string


require('love')

local cam_common = require('camera_common')

local Pipeline = require('pipeline')


local sformat = string.format






local Camera = {}































































local Camera_mt = {
   __index = Camera,
}

local cam_bbox = {
   w = 0.8,
   h = 0.8,
}

function Camera.new(
   pipeline,
   _screenW,
   _screenH)


   local self = setmetatable({}, Camera_mt)
   self.screenW = _screenW
   self.screenH = _screenH
   self.x, self.y = 0, 0
   self.scale = 1.
   self.dt = 0
   self.pipeline = pipeline
   self.bbox_pix = cam_common.calc_bbox_pix(
   cam_bbox,
   self.screenW,
   self.screenH,
   self.x,
   self.y)

   self.pipeline:pushCodeFromFile('camera', "rdr_camera.lua")


   self.pipeline:pushCode("camera_axises", [[
    local yield = coroutine.yield
    local linew = 1.
    local color = {0, 0, 0, 1}
    while true do
        local oldlw = love.graphics.getLineWidth()
        local w, h = love.graphics.getDimensions()
        love.graphics.setLineWidth(linew)
        love.graphics.setColor(color)
        love.graphics.line(w / 2, 0, w / 2, h)
        love.graphics.line(0, h / 2, w, h / 2)
        love.graphics.setLineWidth(oldlw)
        yield()
    end
    ]])


   return self
end

function Camera:setTransform()







end

function Camera:setOrigin()

end

function Camera:draw_axises()
   self.pipeline:openAndClose("camera_axises")
end

function Camera:push2lines_buf()

   local msg = sformat(
   "camera: (%.3f, %.3f, %.4f)",
   self.x, self.y, self.scale)

   self.pipeline:push("add", "camera", msg)

   local fmt1 = "%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f,"
   local fmt2 = "%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f"







   self.pipeline:push("add", "camera_mat", msg)

end

function Camera:update(   dt,
   dx,
   dy,
   dscale,
   px,
   py)



   self:checkMovement(dx, dy)
   self:checkScale(dscale)

   self.dt = dt
   local cam_dx, cam_dy = 0., 0.
   local move = false

   if px < self.bbox_pix.x then
      cam_dx = self.bbox_pix.x - px
      move = true
   end
   local right = self.bbox_pix.x + self.bbox_pix.w
   if px > right then
      cam_dx = px - right
      move = true
   end

   if py < self.bbox_pix.y then
      cam_dy = self.bbox_pix.y - py
      move = true
   end
   local bottom = self.bbox_pix.y + self.bbox_pix.h
   if py > bottom then
      cam_dy = py - bottom
      move = true
   end

   print('px, py', px, py)


   if move then


      self.x = px
      self.y = py
   end



end

function Camera:reset()
   self.x, self.y, self.scale = 0., 0., 1.
end

function Camera:attach()
   self.pipeline:openPushAndClose(
   'camera', 'attach', self.x, self.y, self.scale)

end

function Camera:fromLocal2(x, y)





   local w, h = self.screenW, self.screenH
   x, y = x - self.x, y - self.y
   x, y = x - y, x + y
   local ox, oy = 0, 0
   return x * self.scale + w / 2 + ox, y * self.scale + h / 2 + oy
end

function Camera:fromLocal(x, y)

   local w, h = self.screenW, self.screenH
   x, y = (x - w / 2) / self.scale, (y - h / 2) / self.scale
   return self.x + x, self.y + y
end

function Camera:detach()

   self.pipeline:openPushAndClose('camera', 'detach')
end

function Camera:draw_bbox()
   self.pipeline:openPushAndClose('camera', 'draw_bbox')
end

function Camera:checkMovement(dx, dy)

   local amount_x, amount_y = 3000 * self.dt, 3000 * self.dt
   local tx, ty = 0., 0.
   local changed = false


   if dx > 0 then
      changed = true
      tx = -amount_x
   elseif dx < 0 then
      changed = true
      tx = amount_x
   end


   if dy > 0 then
      changed = true
      ty = -amount_y
   elseif dy < 0 then
      changed = true
      ty = amount_y
   end

   if changed then
      self.x = self.x - tx
      self.y = self.y - ty
   end
end


function Camera:checkScale(dscale)
   local factor = 1 * self.dt
   local px, py = self.screenW * factor / 2, self.screenH * factor / 2




   if dscale == -1 then


      self.scale = 1 + factor



   elseif dscale == 1 then
      self.scale = 1 - factor



   end

end





function Camera:checkIsPlayerInCircle()

end


function Camera:moveTo(px, py)
   print("moveTo x, y", px, py)
   print("camera x, y, scale", self.x, self.y, self.scale)
   self.x, self.y = px, py













end

function Camera:setToOrigin()







end

return Camera
