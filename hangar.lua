


local Hangar = {}















function Hangar.new(_)
   local Hangar_mt = {
      __index = Hangar,
   }
   local self = setmetatable({}, Hangar_mt)

   return self
end

function Hangar:update()

end

function Hangar:present()
end

return Hangar
