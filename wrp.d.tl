
global record Wrapper
    record Space end
    record Body end

    init_space: function(): Space
    free_space: function(Space)
    step: function(dt: number)

    type EachSegmentCallback = function(x1: number, y1: number, x2: number, y2: number)
    type EachBodyCallback = function(x: number, y: number, angle: number, obj: any)

    enum ObjectType
        "tank"
    end

    query_all_shapes: function(EachBodyCallback)
    query_all_tanks: function(EachBodyCallback)

    new_body: function(type: ObjectType, w: number, h: number, self: table): Body

    set_position: function(b: Body, x: number, y: number)
    get_position: function(b: Body): number, number, number
    apply_impulse: function(b: Body, ix: number, iy: number, px: number, py: number)

    new_static_segment: function(x1: number, y1: number, x2: number, y2: number)
    draw_static_segments: function(EachBodyCallback)
end

return Wrapper
