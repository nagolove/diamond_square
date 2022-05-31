




local Hangar = {}






function Hangar.new(x, y, angle)
   local Hangar_mt = {
      __index = Hangar,
   }
   local self = setmetatable({}, Hangar_mt)










   return self
end

function Hangar:update()

end

return Hangar
