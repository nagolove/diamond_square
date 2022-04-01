require('konstants')
require('common')
require('vector')

local wrp = require("wrp")



local Tank = {}






































































































local px, py = 0, 0
local impulse_amount = 100
local force_amount = 200
local vel_limit = 160
local ang_vel_limit = 2

function Tank:fire()
end

function Tank:left()


   if ang_vel_limit > self.base:get_ang_vel() then
      self.base:apply_impulse(-0.2, 0, 128, 128)
   end

end

function Tank:right()
   if ang_vel_limit > self.base:get_ang_vel() then
      self.base:apply_impulse(0.2, 0, 128, 128)

   end
end

function Tank:forward()
   local vx, vy = self.base:get_vel()
   local len = vec_len(vx, vy)
   if len < vel_limit then

      self.base:apply_impulse(0, -impulse_amount, px, py);
   end

end

function Tank:backward()

   local vx, vy = self.base:get_vel()
   local len = vec_len(vx, vy)
   if len < vel_limit then
      self.base:apply_impulse(0, impulse_amount, px, py);
   end

end


local tankCounter = 0



function Tank.new(pos, w, h)

   local Tank_mt = {
      __index = Tank,
   }

   local self = setmetatable({}, Tank_mt)

   tankCounter = tankCounter + 1


   self.strength = 1.
   self.fuel = 1.
   self.id = tankCounter

   self.color = { 1, 1, 1, 1 }

   self.type = "tank"

   if pos.x ~= pos.x or pos.y ~= pos.y then
      error("NaN in tank positon.")
   end

   self.base = wrp.new_tank(self.type, pos.x, pos.y, w, h, self)

   print('self.base', self.base)



   return self
end

function Tank:update()

   if self.strength <= 0. then
      return nil
   end

   return self
end

function Tank:engineCycle()


   if self.fuel > 0 then
   end
end

function Tank:pushTrack()






























end

function Tank:drawDirectionVector()










end

return Tank
