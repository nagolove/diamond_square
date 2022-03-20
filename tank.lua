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


   if ang_vel_limit > wrp.get_body_ang_vel(self.base) then
      wrp.apply_impulse(self.base, -0.2, 0, 128, 128)
   end

end

function Tank:right()
   if ang_vel_limit > wrp.get_body_ang_vel(self.base) then
      wrp.apply_impulse(self.base, 0.2, 0, 128, 128)

   end
end

function Tank:forward()
   local vx, vy = wrp.get_body_vel(self.base)
   local len = vec_len(vx, vy)
   if len < vel_limit then

      wrp.apply_impulse(self.base, 0, -impulse_amount, px, py);
   end

end

function Tank:backward()

   local vx, vy = wrp.get_body_vel(self.base)
   local len = vec_len(vx, vy)
   if len < vel_limit then
      wrp.apply_impulse(self.base, 0, impulse_amount, px, py);
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
   self.base = wrp.new_body(self.type, pos.x, pos.y, w, h, self)


   return self
end

function Tank:update()

   if self.strength <= 0. then
      return nil
   end

   return self
end

return Tank
