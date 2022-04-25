local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; require('love')

local Pipeline = require('pipeline')
local lj = love.joystick
local Joystick = lj.Joystick
local sformat = string.format


local Camera = {}
























































local Camera_mt = {
   __index = Camera,
}

function Camera.new(pipeline, _screenW, _screenH)
   local self = setmetatable({}, Camera_mt)
   self.screenW = _screenW
   self.screenH = _screenH
   self.x, self.y = 0, 0
   self.scale = 1.
   self.dt = 0
   self.transform = love.math.newTransform()
   self.pipeline = pipeline

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



   pipeline:pushCode('set_transform', [[
    local gr = love.graphics
    local yield = coroutine.yield
    while true do
        gr.applyTransform(graphic_command_channel:demand())
        yield()
    end
    ]])




   pipeline:pushCode('origin_transform', [[
    local gr = love.graphics
    local yield = coroutine.yield
    while true do
        gr.origin()
        yield()
    end
    ]])


   return self
end

function Camera:setTransform()





end

function Camera:setOrigin()

end

function Camera:checkInput(j)
   self:checkMovement(j)
   self:checkScale(j)
end

function Camera:draw_axises()
   self.pipeline:openAndClose("camera_axises")
end

function Camera:push2lines_buf()
   local msg = sformat("camera: (%.3f, %.3f, %.4f)", self.x, self.y, self.scale)
   self.pipeline:push("add", "camera", msg)
   local mat = { self.transform:getMatrix() }
   local fmt1 = "%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f,"
   local fmt2 = "%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f"
   msg = sformat(
   "camera mat: (" .. fmt1 .. fmt2 .. ")",
   mat[1], mat[2], mat[3], mat[4], mat[5], mat[6], mat[7], mat[8],
   mat[9], mat[10], mat[11], mat[12], mat[13], mat[14], mat[15], mat[16])

   self.pipeline:push("add", "camera_mat", msg)
end

function Camera:update(dt)
   self.dt = dt
end

function Camera:reset()
   self.x, self.y, self.scale = 0., 0., 1.
end

function Camera:attach()
   local w, h = 1920, 1080
   local x, y = 0, 0
   local cx, cy = x + w / 2, y + h / 2









   print('self.x, self.y', self.x, self.y)
   self.pipeline:openPushAndClose(
   'camera', 'attach', self.x, self.y, self.scale)

end

function Camera:detach()

   self.pipeline:openPushAndClose('camera', 'detach')
end

function Camera:checkMovement(j)
   local axes = { j:getAxes() }
   local dx, dy = axes[4], axes[5]

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
      self.x = self.x + tx
      self.y = self.y + ty
   end
end


function Camera:checkScale(j)
   local axes = { j:getAxes() }
   local dy = axes[2]
   local factor = 1 * self.dt
   local px, py = self.screenW * factor / 2, self.screenH * factor / 2




   if dy == -1 then


      self.scale = 1 + factor



   elseif dy == 1 then
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
