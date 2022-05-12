local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local table = _tl_compat and _tl_compat.table or table; local Pipeline = require('pipeline')


local tabular_t = require("tabular").show2

local DocSystem = {}












local Hotkey = {}





local keyboard_keys = {}

local gamepad_keys = {}

local pipeline
local dejavu_mono = "DejaVuSansMono.ttf"
local font_size = 40

function DocSystem.init_render_stage1(pl)
   pipeline = pl

   pipeline:pushCodeFromFile('keyboard_render', 'rdr_lines_buf_ordered.lua')


   pipeline:pushCodeFromFile('gamepad_render', 'rdr_lines_buf_ordered.lua')

end

function DocSystem.init_render_stage2()
   pipeline:openPushAndClose('keyboard_render', dejavu_mono, font_size)
   pipeline:openPushAndClose('gamepad_render', dejavu_mono, font_size)
end

function DocSystem.add_gamepad_doc(combo, doc)
   table.insert(gamepad_keys, { combo = combo, doc = doc })
end

function DocSystem.add_keyboard_doc(combo, doc)
   table.insert(keyboard_keys, { combo = combo, doc = doc })
end

function DocSystem.draw_keyboard()
   pipeline:openPushAndClose('keyboard_render', 'flush')
end

function DocSystem.draw_gamepad()
   pipeline:openPushAndClose('gamepad_render', 'flush')
end

function DocSystem.finish_gamepad_docs()
   pipeline:open('gamepad_render')

   local tab = tabular_t(gamepad_keys)
   for k, v in ipairs(tab) do
      pipeline:push('add', v)
   end

   local background_color = { 0.8, 0.1, 0.1, 1 }
   pipeline:push('use_background', true)
   pipeline:push('set_background_color', background_color)
   pipeline:push('border', true)
   pipeline:push('align_center')
   pipeline:push('enough')
   pipeline:close()
end

function DocSystem.finish_keyboard_docs()
   pipeline:open('keyboard_render')

   local tab = tabular_t(keyboard_keys)
   for k, v in ipairs(tab) do
      pipeline:push('add', v)
   end

   local background_color = { 0.8, 0.1, 0.1, 1 }
   pipeline:push('use_background', true)
   pipeline:push('set_background_color', background_color)
   pipeline:push('border', true)
   pipeline:push('align_center')
   pipeline:push('enough')
   pipeline:close()
end

return DocSystem
