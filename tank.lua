require('konstants')
local wrp = require("wrp")



local Tank = {}


































































function Tank:fire()
end

function Tank:left()

end

function Tank:right()

end

function Tank:forward()

end

function Tank:backward()

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
   self.base = wrp.new_body(self.type, w, h, self)
   wrp.set_position(self.base, pos.x, pos.y)

   return self
end


return Tank
