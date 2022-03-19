require('konstants')
require('common')
require('vector')

local wrp = require("wrp")



local Tank = {}
































































local px, py = 0, 0
local amount = 200
local max_vel_len = 10

function Tank:fire()
end

function Tank:left()



end

function Tank:right()


   wrp.apply_impulse(self.base, amount, 0, 256, 256);
end

function Tank:forward()

   local vx, vy = wrp.get_body_vel(self.base)
   local len = vec_len(vx, vy)
   if len < max_vel_len then
      wrp.apply_force(self.base, 0, -amount, px, py);
   end

end

function Tank:backward()

   wrp.apply_force(self.base, 0, amount, px, py);

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
