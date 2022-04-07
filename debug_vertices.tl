--[[
Модуль корутины рисования вершин полученных от chipmunk для отладки.
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

local color = {194 / 255, 27 / 255, 27 / 255, 1}

print(colorize("%{green}debug_vertices inited.%{reset}"))

---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

-- Прололжение работы после вызова pipeline:sync() --
yield()

---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

--[[
local function draw(
    texture: gr.Texture,
    quad: gr.Quad, 
    x: number, y: number, angle: number
)
    gr.push()
    gr.translate(x, y)
    gr.rotate(angle)
    gr.translate(-width / 2, -height / 2)
    gr.setColor {1, 1, 1, 1}
    gr.draw(texture, quad, 0, 0)
    gr.pop()
end
--]]

local commands = {}

local enum Command
    "new"
    --"new_t"
    --"remove"
    --"clear"
    --"flush"
    "enough"
end

-- Создать новый объект с башней
function commands.new(): boolean
    print("debug_vertices: new")
    local tables_num = graphic_command_channel:demand() as number
    print('tables_num', tables_num)
    local oldw = gr.getLineWidth()
    local linew = 7
    gr.setColor(color)

    gr.setLineWidth(linew)
    for i = 1, tables_num do
        local verts = graphic_command_channel:demand() as {number}
        print('verts', inspect(verts))
        gr.polygon("line", verts)
    end
    gr.setLineWidth(oldw)

    return true
end

function commands.enough(): boolean
    return false
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
        "%{blue}debug_vertices: cmd stack: " .. 
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
            error('debug_vertices unknown command: ' .. cmd)
        end
        if not fun() then
            break
        end

    until not cmd

    yield()
end

