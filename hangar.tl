--[[
Ангар - место порождения техники и ее ремонта.
--]]
local record Hangar
    vertices: {number}
    id: integer
    --objectType: ObjectType
    color: {number}
    --physbody: Physics.Body
    --polyshape: lp.PolygonShape
    rectXY: {number}
    rectWH: {number}
    --fixture: Physics.Fixture

    new: function(): Hangar
    update: function(Hangar)
    present: function(Hangar)
end

function Hangar.new(_: vector): Hangar
    local Hangar_mt: metatable<Hangar> = {
        __index = Hangar,
    }
    local self = setmetatable({} as Hangar, Hangar_mt)
    --self.objectType = "Hangar"
    return self
end

function Hangar:update()

end

function Hangar:present()
end

return Hangar
