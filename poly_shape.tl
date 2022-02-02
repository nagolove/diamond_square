--[[
Модуль корутины рисования polyshape полученного от физического движка.
--]]

--local inspect = require 'inspect'
--local serpent = require 'serpent'
local format = string.format
local yield = coroutine.yield

require 'love'

local C = require 'ffi'
require 'ffi'

global graphic_command_channel: love.thread.Channel
global SCENE_PREFIX: string

local texture_msg: string = graphic_command_channel:demand() as string
local width = graphic_command_channel:demand() as number
local height = graphic_command_channel:demand() as number

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

local hash = {}
local verts: {number} = nil

-- счетчик команд
local cmd_num = 0

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
            local id = graphic_command_channel:demand()
            x = graphic_command_channel:demand() as number
            y = graphic_command_channel:demand() as number
            angle = graphic_command_channel:demand() as number

            --print('x, y', x, y)
            --print('angle', angle)
            local rad = 20

            love.graphics.push()
            love.graphics.translate(x, y)
            love.graphics.rotate(angle)
            love.graphics.translate(-width / 2, -height / 2)

            love.graphics.setColor {0, 0.5, 1, 1}
            love.graphics.rectangle('fill', 0, 0, width, height)

            love.graphics.pop()
            
            love.graphics.setColor {0, 0, 1, 1}
            love.graphics.circle('fill', x, y, rad)

            hash[id] = verts

            --print('new')
            --print('id', id)

        elseif cmd == "draw" then
            local id = graphic_command_channel:demand()
            verts = hash[id]

            --print('draw')
            --print('id', id)

        elseif cmd == "remove" then
            local id = graphic_command_channel:demand()
            hash[id] = nil

            --print('remove')

        elseif cmd == 'flush' then
            --love.graphics.draw(mesh)
            --print('flush')
            break
        end

        --print('id', id)
        --print('cmd', cmd)
        --print('verts', inspect(verts))

        if verts then
            --love.graphics.setColor {1, 1, 1, 1}
            --love.graphics.polygon('fill', verts)

            --love.graphics.setColor { 0, 0, 0, 0}

            --print(verts[1], verts[2])
            --print(verts[3], verts[4])
            --print(verts[5], verts[6])
            --print(verts[7], verts[8])
            --print('---')
            --print('font height', love.graphics.getFont():getHeight())
            
            --local old_font = love.graphics.getFont()
            --love.graphics.setFont(old_font)

            --if cmd_num == 10 or cmd_num == 1 then
                --local serpent = require 'serpent'
                ----love.filesystem.write("verts-order.txt", serpent.dump(verts))
                --local s = serpent.dump(verts) .. '\n'
                --love.filesystem.append("verts-order.txt", s)
                --print("os.exit(100)")
                --os.exit(100)
            --end

            --love.graphics.print('x', 0, 0)
            --love.graphics.print('1', verts[1], verts[2])
            --love.graphics.print('2', verts[3], verts[4])
            --love.graphics.print('3', verts[5], verts[6])
            --love.graphics.print('4', verts[7], verts[8])

            --love.graphics.setFont(old_font)
        end

        cmd_num = cmd_num + 1
    until not cmd

    yield()
end
