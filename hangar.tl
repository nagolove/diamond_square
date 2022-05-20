local wrp = require "wrp"

--[[
Ангар - место порождения техники и ее ремонта.
--]]
local record Hangar
    id: integer
    --base: wrp.Hangar
    new: function(x: number, y: number, angle: number): Hangar
    update: function(Hangar)
end

function Hangar.new(x: number, y: number, angle: number): Hangar
    local Hangar_mt: metatable<Hangar> = {
        __index = Hangar,
    }
    local self = setmetatable({} as Hangar, Hangar_mt)
    --[[
    self.base = wrp.hangar_new({
            x = x,
            y = y,
            angle = angle,
            objectType = 'hangar',
            w = 128,
            h = 128,
        }, self)
    --]]
    return self
end

function Hangar:update()

end

return Hangar
