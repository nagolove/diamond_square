--[[
Модуль корутины рисования polyshape полученного от физического движка.
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

local timeout = 0.5

-- Корпус
local texture_msg: string = graphic_command_channel:demand(timeout) as string
-- Башня
local texture_msg_t: string = graphic_command_channel:demand(timeout) as string

-- Размеры корпуса
local width = graphic_command_channel:demand(timeout) as number
local height = graphic_command_channel:demand(timeout) as number

-- Размеры башни
local width_t = graphic_command_channel:demand(timeout) as number
local height_t = graphic_command_channel:demand(timeout) as number
--]]

--local texture_msg = 'tank_body.png'
--local width, height = 256, 256

local errmsg = 'Not enough data received to ' ..
               'initializate %s poly_shape renderer.'

--[[----------------------------------------------------------------------]]--

-- XXX Переписать блок проверки полученных данных для корпуса и башни.

if not texture_msg or not width or not height then
    print("texture_msg, width, height", texture_msg, width, height)
    error(format(errmsg, "body"))
end

if not texture_msg_t or not width_t or not height_t then
    print("texture_msg_t, width_t, height_t", texture_msg_t, width_t, height_t)
    error(format(errmsg, "turret"))
end

if type(texture_msg) ~= 'string' or type(texture_msg_t) ~= 'string' then
    error('Wrong texture(t) type')
end

if type(width) ~= 'number' or type(width_t) ~= 'number' then
    error('Wrong width(t) type')
end

if type(height) ~= 'number' or type(height_t) ~= 'number' then
    error('Wrong height(t) type')
end

--[[----------------------------------------------------------------------]]--

local path = SCENE_PREFIX .. '/' .. texture_msg
local path_t = SCENE_PREFIX .. '/' .. texture_msg_t

print("path", path)
print("path_t", path_t)

local texture = love.graphics.newImage(path) as love.graphics.Texture
local texture_t = love.graphics.newImage(path_t) as love.graphics.Texture

local function check(tex: gr.Texture, tex_path: string)
    if tex then
        local w, h = tex:getDimensions()
        local msg = format('"%s" loaded %dx%d', tex_path, w, h)
        print(msg)
    else
        error('Could not load texture:' .. path)
    end
end

check(texture, path)
check(texture_t, path)

print('width, height:', width, height)
print('width_t, height_t:', width_t, height_t)

-- TODO Использовать соединенные треугольники
--local mesh_size = 6
--local mesh = love.graphics.newMesh(mesh_size, "triangles", "static")
--local mesh_verts: {{number}} = {}
--mesh:setTexture(texture)

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

local hash: {number: {number}} = {}
--local verts: {number} = nil

-- счетчик команд
local cmd_num = 0

-- Корпус
local quad = gr.newQuad(0, 0, 256, 256, texture)

-- Башня
--local quad_t = gr.newQuad(0, 0, 256, 256, texture_t)
local quad_t = gr.newQuad(102, 0, 54, 160, texture_t)

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

local function get_id(): number
    local id = graphic_command_channel:demand() as number

    if type(id) ~= 'number' then
        error('id type should be a number, not ' .. type(id))
    end

    return id
end

local commands = {}

local enum Command
    --"new"
    "new_t"
    "remove"
    "clear"
    "flush"
    "enough"
end

--[[
-- Создать новый объект
function commands.new(): boolean
    local id = get_id()
    local x = graphic_command_channel:demand() as number
    local y = graphic_command_channel:demand() as number
    local angle = graphic_command_channel:demand() as number
    hash[id] = {[1] = x, [2] = y, [3] = angle, }
    return true
end
--]]

-- Создать новый объект с башней
function commands.new_t(): boolean
    local id = get_id()

    -- Корпус
    local x = graphic_command_channel:demand() as number
    local y = graphic_command_channel:demand() as number
    local angle = graphic_command_channel:demand() as number

    -- Башня
    local tx = graphic_command_channel:demand() as number
    local ty = graphic_command_channel:demand() as number
    local tangle = graphic_command_channel:demand() as number

    hash[id] = {
        -- для корпуса
        [1] = x, [2] = y, [3] = angle, 
        -- для башни
        [4] = tx, [5] = ty, [6] = tangle,
    }
    return true
end

-- Удалить объект
function commands.remove(): boolean
    local id = get_id()
    hash[id] = nil
    return true
end

-- Очистить внутренний буфер
function commands.clear(): boolean
    hash = {}
    return false
end

-- Нарисовать все, выйти из цикла приема сообщений
function commands.flush(): boolean
    for _, v in pairs(hash) do
        draw(texture as gr.Texture, quad, v[1], v[2], v[3])
        draw(texture_t as gr.Texture, quad_t, v[4], v[5], v[6])
    end
    return false
end

-- Выйти из цикла приема сообщений, ничего не рисовать
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
        "%{blue}cmd stack: " .. 
        inspect(cmd_circle_buf) .. 
        "%{reset}"
    ))
end

while true do
    local cmd: Command
    cmd_num = 0

    repeat
        cmd = graphic_command_channel:demand() as Command
        push_cbuf(cmd)

        local fun = commands[cmd]
        if not fun then
            print_stack()
            error('poly_shape unknown command: ' .. cmd)
        end
        if not fun() then
            break
        end

        cmd_num = cmd_num + 1
    until not cmd

    yield()
end
