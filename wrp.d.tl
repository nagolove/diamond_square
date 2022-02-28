--local cm = require 'chipmunk'

global record Wrapper
    --average: function(...:any): number
    --each_body: function(function(iter_num: integer), call_count: integer)
    --init_space: function(space: cm.cpSpace)
    record Space end
    record Body end

    init_space: function(): Space
    free_space: function(Space)
    step: function(dt: number)

    type EachShapeCallback = function(x: number, y: number, angle: number, obj: any)
    --query_all_shapes: function(space: cm.cpSpace, EachShapeCallback)

    query_all_shapes: function(EachShapeCallback)
    new_box_body: function(w: number, h: number, self: table): Body
    set_position: function(b: Body, x: number, y: number)
    get_position: function(b: Body): number, number, number
    apply_impulse: function(b: Body, ix: number, iy: number, px: number, py: number)

    new_static_segment: function(x1: number, y1: number, x2: number, y2: number)
    --pass_combo: function(cdata: any)
end

return Wrapper
