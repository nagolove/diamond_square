--[[
Модуль корутины рисования отладочного вывода chipmunk.
--]]

--local serpent = require 'serpent'

local inspect = require 'inspect'
local colorize = require('ansicolors2').ansicolors
local format = string.format
local yield = coroutine.yield
local gr = love.graphics

require 'love'

global graphic_command_channel: love.thread.Channel
global SCENE_PREFIX: string

---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

-- Прололжение работы после вызова pipeline:sync() --
--yield()

---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

-- счетчик команд
local cmd_num = 0

local commands = {}

local enum Command
    "circle"
    "segment"
    "fatsegment"
    "polygon"
    "dot"
    "flush"
    "enough"
end

local dbg_color = {0, 0.7, 0, 1}
local dbg_dot_color = {0.1, 0.6, 0.1}

function commands.circle(): boolean
    local px = graphic_command_channel:demand() as number
    local py = graphic_command_channel:demand() as number
    local angle = graphic_command_channel:demand() as number
    local rad = graphic_command_channel:demand() as number

    gr.setColor(dbg_color)
    gr.circle("line", px, py, rad)

    return true
end

function commands.segment(): boolean
    local ax = graphic_command_channel:demand() as number
    local ay = graphic_command_channel:demand() as number
    local bx = graphic_command_channel:demand() as number
    local by = graphic_command_channel:demand() as number

    gr.setColor(dbg_color)
    gr.line(ax, ay, bx, by)

    return true
end

function commands.fatsegment(): boolean
    local ax = graphic_command_channel:demand() as number
    local ay = graphic_command_channel:demand() as number
    local bx = graphic_command_channel:demand() as number
    local by = graphic_command_channel:demand() as number
    local rad = graphic_command_channel:demand() as number

    local oldw = gr.getLineWidth()
    gr.setLineWidth(rad)
    gr.line(ax, ay, bx, by)
    gr.setLineWidth(oldw)

    return true
end

function commands.polygon(): boolean
    local poly = graphic_command_channel:demand() as number
    local rad = graphic_command_channel:demand() as number

    gr.setColor(dbg_color)
    gr.polygon('line', poly)

    return true
end

function commands.dot(): boolean
    local size = graphic_command_channel:demand() as number
    local px = graphic_command_channel:demand() as number
    local py = graphic_command_channel:demand() as number

    gr.setColor(dbg_dot_color)
    gr.circle('fill', px, py, size)

    return true
end

-- Нарисовать все, выйти из цикла приема сообщений
function commands.flush(): boolean
    return false
end

-- Выйти из цикла приема сообщений, ничего не рисовать
function commands.enough(): boolean
    return false
end
--]]

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
    cmd_num = 0

--local ok, errmsg: boolean, string = pcall(function()

    repeat
        cmd = graphic_command_channel:demand() as Command
        push_cbuf(cmd)

        local fun = commands[cmd]
        if not fun then
            print_stack()
            error('dbg_phys unknown command: ' .. cmd)
        end
        if not fun() then
            break
        end

        cmd_num = cmd_num + 1
    until not cmd

--end)
--if not ok then 
    --print('dbg_phys:', errmsg)
--end

    yield()
end

