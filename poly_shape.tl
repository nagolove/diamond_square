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
local mesh_size = 6
local mesh = love.graphics.newMesh(mesh_size, "triangles", "static")
--local mesh_verts: {{number}} = {}

mesh:setTexture(texture)

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
    local rad = 20

    gr.push()
    gr.translate(x, y)
    gr.rotate(angle)
    gr.translate(-width / 2, -height / 2)

    --gr.setColor {0, 0.5, 1, 1}

    gr.setColor {1, 1, 1, 1}

    --gr.rectangle('fill', 0, 0, width, height)
    --gr.draw(texture, quad, 0, 0, width, height)

    gr.draw(texture, quad, 0, 0)

    gr.pop()

    --gr.setColor {0, 0, 1, 1}
    --gr.circle('fill', x, y, rad)
end

local function get_id(): number
    local id = graphic_command_channel:demand() as number

    if type(id) ~= 'number' then
        error('id type should be a number, not ' .. type(id))
    end

    return id
end

--ffi.cdef [[
--typedef {
    --double x, y, angle;
--} Object;
--]]

--[[
local max_count = 4096
local buf: {number} = ffi.new('Object[?]', max_count)
local last_buf_index = 0

--]]

while true do
    local cmd: string

    cmd_num = 0

    -- команды cmd:
    -- new      - создать новый объект и рисовать
    -- имя команды, идентификатор объекта, x, y, угол

    -- update   - обновить вершины объекта и рисовать
    -- имя команды, идентификатор объекта, вершины

    -- draw     - рисовать существущий
    -- имя команды, идентификатор объекта 

    -- remove   - удалить объект
    -- имя команды, идентификатор объекта 

    -- flush    - нарисовать все
    -- имя команды

    repeat
        cmd = graphic_command_channel:demand() as string
        --print('cmd', cmd)

        if cmd == "new" then
            local x, y, angle: number, number, number
            local id = get_id()
            x = graphic_command_channel:demand() as number
            y = graphic_command_channel:demand() as number
            angle = graphic_command_channel:demand() as number

            --draw(x, y, angle)

            hash[id] = {
                [1] = x,
                [2] = y,
                [3] = angle,
            }
            --]]

        --elseif cmd == "draw" then
            --local id = get_id()
            --draw(hash[id][1], hash[id][2], hash[id][3])

        elseif cmd == "remove" then
            local id = get_id()
            hash[id] = nil

            --print('remove')

        elseif cmd == 'flush' then
            --love.graphics.draw(mesh)
            --print('flush')
            for _, v in pairs(hash) do
                draw(v[1], v[2], v[3])
            end
            --hash = {}
            break
        else
            error('poly_shape unkonwn command: ' .. cmd)
        end

        cmd_num = cmd_num + 1
    until not cmd

    yield()
end
