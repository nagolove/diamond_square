--[[
Модуль корутины рисования polyshape полученного от физического движка.
--]]

--local inspect = require 'inspect'
--local serpent = require 'serpent'
local format = string.format
local yield = coroutine.yield

require 'love'

--local C = require 'ffi'
require 'ffi'

global graphic_command_channel: love.thread.Channel
global SCENE_PREFIX: string

local timeout = 0.5
local texture_msg: string = graphic_command_channel:demand(timeout) as string
local width = graphic_command_channel:demand(timeout) as number
local height = graphic_command_channel:demand(timeout) as number
--]]

--local texture_msg = 'tank_body.png'
--local width, height = 256, 256

if not texture_msg or not width or not height then
    print("texture_msg, width, height", texture_msg, width, height)
    error("Not enough data received to initializate poly_shape renderer.")
end

if type(texture_msg) ~= 'string' then
    error('Wrong texture type')
end
if type(width) ~= 'number' then
    error('Wrong width type')
end
if type(height) ~= 'number' then
    error('Wrong height type')
end

local path = SCENE_PREFIX .. '/' .. texture_msg
local texture = love.graphics.newImage(path) as love.graphics.Texture
if texture then
    local w, h = texture:getDimensions()
    local msg = format('"%s" loaded %dx%d', path, w, h)
    print(msg)
else
    error('Could not load texture:' .. path)
end

print('shape width, height:', width, height)

--local slots_num = 4096
--local free_slots: {number} = C.new('uint16_t[?]', slots_num) as {number}


-- TODO Использовать соединенные треугольники
--local mesh_size = 6
--local mesh = love.graphics.newMesh(mesh_size, "triangles", "static")
--local mesh_verts: {{number}} = {}
--mesh:setTexture(texture)

--local font = love.graphics.newFont(32)

---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

yield()

---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

local hash: {number: {number}} = {}
--local verts: {number} = nil

-- счетчик команд
local cmd_num = 0

local gr = love.graphics
local quad = gr.newQuad(0, 0, 256, 256, texture)

local function draw(x: number, y: number, angle: number)
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

local enum Commands
    "new"
    "new_t"
    "remove"
    "clear"
    "flush"
    "enough"
end

-- Создать новый объект
function commands.new(): boolean
    local id = get_id()
    local x = graphic_command_channel:demand() as number
    local y = graphic_command_channel:demand() as number
    local angle = graphic_command_channel:demand() as number
    hash[id] = {[1] = x, [2] = y, [3] = angle, }
    return true
end

-- Создать новый объект с башней
function commands.new(): boolean
    local id = get_id()
    local x = graphic_command_channel:demand() as number
    local y = graphic_command_channel:demand() as number
    local angle = graphic_command_channel:demand() as number
    hash[id] = {[1] = x, [2] = y, [3] = angle, }
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
        draw(v[1], v[2], v[3])
    end
    return false
end

-- Выйти из цикла приема сообщений, ничего не рисовать
function commands.enough(): boolean
    return false
end

while true do
    local cmd: Commands

    cmd_num = 0

    repeat
        cmd = graphic_command_channel:demand() as Commands

        local fun = commands[cmd]
        if not fun then
            error('poly_shape unknown command: ' .. cmd)
        end
        if not fun() then
            break
        end

        cmd_num = cmd_num + 1
    until not cmd

    yield()
end
