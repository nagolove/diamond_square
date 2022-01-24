require 'pipeline'

local pipeline: Pipeline

local function init(pl: Pipeline)
    assert(pl, 'Please use valid pipeline')
    pipeline = pl
    pipeline:pushCode("draw_arrow", [[
    ]])
end

--local vecl = require "vector-light"

local function draw(
    _: number, _: number, _: number, _: number, 
    _: {number}
)
--local function draw(
    --fromx: number, fromy: number, tox: number, toy: number, 
    --color: {number}
--)

    -- {{{
    --local angle = math.pi / 11
    --local arrowDiv = 20

    --[[
    color = color or {1, 1, 1, 1}
    local x, y = fromx - tox, fromy - toy
    local ux, uy = vecl.normalize(abs(fromx - tox), abs(fromy - toy))
    local len = vecl.len(x, y) / arrowDiv
    local lx, ly = vecl.rotate(angle, ux, uy)
    local rx, ry = vecl.rotate(-angle, ux, uy)
    lx, ly = len * lx, len * ly
    rx, ry = len * rx, len * ry

    local oldlinew = gr.getLineWidth()
    local linew = 15
    gr.setLineWidth(linew)
    gr.setColor(color)

    -- left line
    gr.line(tox, toy, tox - lx, toy - ly)
    -- right line
    gr.line(tox, toy, tox - rx, toy - ry)
    -- main line
    gr.line(fromx, fromy, tox, toy)
    -- }}}
    gr.setLineWidth(oldlinew)
    --]]
end

return {
    init = init,
    draw = draw,
}
