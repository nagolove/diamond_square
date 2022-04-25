require 'love'
global graphic_command_channel: love.thread.Channel

local inspect = require 'inspect'
local colorize = require 'ansicolors2'.ansicolors
local cos = math.cos
local sin = math.sin
local fromPolar = require 'vector-light'.fromPolar
local gr = love.graphics
local yield = coroutine.yield
local ray_color = {1, 1, 1, 1}

local enum Command
    "ray"
    "target"
    'enough'
    'set_dist'
end

local commands = {}

local dist = 1.

function commands.set_dist(): boolean
    local d = graphic_command_channel:demand() as number
    if type(d) ~= 'number' then
        error("fire_dir.tl: set_dist() got not a number, " .. type(d))
    end
    dist = d
end

local lineWidth = 4

function commands.ray(): boolean
    local x1 = graphic_command_channel:demand() as number
    local y1 = graphic_command_channel:demand() as number
    local angle = graphic_command_channel:demand() as number

    local x2, y2 = fromPolar(angle, dist)
    x2, y2 = x1 + x2, y1 + y2

    gr.setColor(ray_color)
    gr.setLineWidth(lineWidth)
    gr.line(x1, y1, x2, y2)

    return true
end

function commands.enough(): boolean
    return false
end

local target_color = {1, 0, 0, 1}

function commands.target(): boolean
    local x = graphic_command_channel:demand() as number
    local y = graphic_command_channel:demand() as number
    local radius = 10
    gr.setColor(target_color)
    gr.circle("fill", x, y, radius)
    return true
end

local cmd_circle_buf: {Command} = {}
local cmd_circle_buf_maxnum = 16 * 2

local function push_cbuf(cmd: Command)
    if #cmd_circle_buf >= cmd_circle_buf_maxnum then
        table.remove(cmd_circle_buf, 1)
    end
    table.insert(cmd_circle_buf, cmd)
end

local function print_stack()
    print(colorize(
        "%{blue}cmd stack: " .. 
        inspect(cmd_circle_buf) .. 
        "%{reset}"
    ))
end

while true do
    local cmd: Command

    repeat
        cmd = graphic_command_channel:demand() as Command
        push_cbuf(cmd)

        local fun = commands[cmd]
        if not fun then
            print_stack()
            error('fire_dir unknown command: ' .. cmd)
        end
        if not fun() then
            break
        end

    until not cmd

    yield()
end
