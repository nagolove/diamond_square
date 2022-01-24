local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; require('pipeline')

local pipeline

local function init(pl)
   assert(pl, 'Please use valid pipeline')
   pipeline = pl
   pipeline:pushCode("draw_arrow", [[
    ]])
end



local function draw(
   _, _, _, _,
   _)


































end

return {
   init = init,
   draw = draw,
}
