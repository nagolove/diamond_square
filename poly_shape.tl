    --local inspect = require 'inspect'
    --local serpent = require 'serpent'
    local yield = coroutine.yield
    --local color = {1, 1, 1, 1}
    local mesh_size = 1024

    require 'love'
    require 'ffi'

    global graphic_command_channel: love.thread.Channel
    global SCENE_PREFIX: string

    local texture_msg: string = graphic_command_channel:demand() as string
    if type(texture_msg) ~= 'string' then
        error('Wrong texture type')
    end

    local slots_num = 4096
    local free_slots: {number} = ffi.new('uint16_t[?]', slots_num)

    -- TODO Использовать соединенные треугольники
    --local mesh = love.graphics.newMesh(mesh_size * 6, "strip", "dynamic")
    local mesh = love.graphics.newMesh(mesh_size * 6, "triangles", "dynamic")
    --local mesh_verts: {{number}} = {}

    local path = SCENE_PREFIX .. '/' .. texture_msg
    print('path', path)
    local texture = love.graphics.newImage(path) as love.graphics.Texture
    if texture then
        print('texture loaded', texture:getDimensions())
    end
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
        -- имя команды, идентификатор объекта, вершины

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
                local id = graphic_command_channel:demand()
                verts = graphic_command_channel:demand() as {number}
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
                love.graphics.setColor {1, 1, 1, 1}
                love.graphics.polygon('fill', verts)

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
