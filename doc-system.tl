local Pipeline = require 'pipeline'

-- Вывод в таблицу
local tabular_t = require "tabular".show2

local record DocSystem
    init_render_stage1: function(pl: Pipeline)
    init_render_stage2: function()

    add_gamepad_doc: function(combo: string, doc: string)
    add_keyboard_doc: function(combo: string, doc: string)

    draw_gamepad: function()
    draw_keyboard: function()
    finish_gamepad_docs: function()
    finish_keyboard_docs: function()
end

local record Hotkey
    combo: string
    doc: string
end

-- Справка по клавишам на клавиатуре.
local keyboard_keys: {Hotkey} = {}
-- Справка по клавишам на геймпаде.
local gamepad_keys: {Hotkey} = {}

local pipeline: Pipeline
local dejavu_mono = "DejaVuSansMono.ttf"
local font_size = 40

function DocSystem.init_render_stage1(pl: Pipeline)
    pipeline = pl
    -- Буфер для вывода справки по клавишам клавиатуры
    pipeline:pushCodeFromFile('keyboard_render', 'lines_buf_ordered.lua')
    -- Буфер для вывода справки по клавишам геймпада
    pipeline:pushCodeFromFile('gamepad_render', 'lines_buf_ordered.lua')
end

function DocSystem.init_render_stage2()
    pipeline:openPushAndClose('keyboard_render', dejavu_mono, font_size)
    pipeline:openPushAndClose('gamepad_render', dejavu_mono, font_size)
end

function DocSystem.add_gamepad_doc(combo: string, doc: string)
    table.insert(gamepad_keys, { combo = combo, doc = doc })
end

function DocSystem.add_keyboard_doc(combo: string, doc: string)
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

    local background_color = {0.8, 0.1, 0.1, 1}
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

    local background_color = {0.8, 0.1, 0.1, 1}
    pipeline:push('use_background', true)
    pipeline:push('set_background_color', background_color)
    pipeline:push('border', true)
    pipeline:push('align_center')
    pipeline:push('enough')
    pipeline:close()
end

return DocSystem
