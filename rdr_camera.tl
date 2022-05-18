-- vim: set colorcolumn=85
-- vim: fdm=marker

global SCENE_PREFIX: string
global graphic_command_channel: love.thread.Channel

local cam_common = require 'camera_common'
local inspect = require 'inspect'
local gr = love.graphics
local yield = coroutine.yield
--local colorize = require 'ansicolors2'.ansicolors

---------------------------------------------------------------
---------------------------------------------------------------

-- В долях 0..1 от значений размеров экрана в пикселях
local cam_bbox = {
    w = 0.8,
    h = 0.8
}

local cam_x, cam_y, cam_scale: number, number, number = 0., 0., 1.
local cam_bbox_pix: BBox_pix = {}

local enum Command
    'attach'
    'detach'
    'draw_bbox'
    'set_bbox'
end

local commands = {}

function commands.attach(): boolean
    -- {{{
    local x = graphic_command_channel:demand() as number
    local y = graphic_command_channel:demand() as number
    local scale = graphic_command_channel:demand() as number

    cam_x, cam_y = x, y
    cam_scale = scale

    local w, h = gr.getDimensions()

    local dx, dy = 0, 0
    local cx, cy = dx + w / 2, dy + h / 2

    gr.push()
    gr.translate(cx, cy)
    gr.scale(scale)
    gr.translate(-x, -y)

    return false
    -- }}}
end

local bbox_color = {1, 1, 1, 1}

function commands.set_bbox(): boolean
    local factor_w = graphic_command_channel:demand() as number
    local factor_h = graphic_command_channel:demand() as number
    cam_bbox.w = factor_w
    cam_bbox.h = factor_h
    if not cam_common.check_bbox() then
        error("bad camera bbox: " .. inspect(cam_bbox))
    end
    local w, h = gr.getDimensions()
    cam_bbox_pix = cam_common.calc_bbox_pix(cam_bbox, w, h, cam_x, cam_y)
end

function commands.draw_bbox(): boolean
    gr.setColor(bbox_color)
    local oldw = gr.getLineWidth()
    local lw = 5
    gr.setLineWidth(lw)
    gr.rectangle(
        "line", 
        cam_bbox_pix.x,
        cam_bbox_pix.y,
        cam_bbox_pix.w,
        cam_bbox_pix.h
    )
    gr.setLineWidth(oldw)
    return false
end

function commands.detach(): boolean
    gr.pop()
    return false
end

local w, h = gr.getDimensions()
cam_bbox_pix = cam_common.calc_bbox_pix(cam_bbox, w, h, cam_x, cam_y)

while true do
    local cmd: Command

    repeat
        cmd = graphic_command_channel:demand() as Command

        local fun = commands[cmd]
        if not fun then
            error('rdr_camera unkonwn command: ' .. cmd)
        end
        if not fun() then
            break
        end

    until not cmd

    yield()
end
