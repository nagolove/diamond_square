global SCENE_PREFIX: string
global graphic_command_channel: love.thread.Channel
local gr = love.graphics
local yield = coroutine.yield
local colorize = require 'ansicolors2'.ansicolors

---------------------------------------------------------------
---------------------------------------------------------------

local enum Command
    'attach'
    'detach'
end

local commands = {}

function commands.attach(): boolean
    local x = graphic_command_channel:demand() as number
    local y = graphic_command_channel:demand() as number
    local scale = graphic_command_channel:demand() as number

    --local w, h = 1920, 1080
    local w, h = gr.getDimensions()
    --local x, y = 0, 0
    local cx, cy = x + w / 2, y + h / 2

    print("camera.attach", x, y, scale)

    gr.push()
    gr.translate(cx, cy)
    gr.scale(scale)
    gr.translate(-x, -y)

    return false
end

function commands.detach(): boolean
    gr.pop()
    return false
end

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
