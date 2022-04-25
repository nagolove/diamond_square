--[[
Модуль корутины рисования танка.
--]]

--local serpent = require 'serpent'

local Tank = require "tank"
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
local ser_full_info: string = graphic_command_channel:demand(timeout) as string
local fun, errmsg = load(ser_full_info)
if errmsg then
    error(format("poly_shape.tl: load error '%s'", errmsg))
end
local full_info: Tank.FullInfo = fun() as Tank.FullInfo

local rect_turret = full_info.rect_turret
local rect_body = full_info.rect_body
local init_tank = full_info.init_table

--[[----------------------------------------------------------------------]]--

local path = SCENE_PREFIX .. '/' .. full_info.base_tex_fname
local path_t = SCENE_PREFIX .. '/' .. full_info.turret_tex_fname

local tex_body = love.graphics.newImage(path) as love.graphics.Texture
local tex_turret = love.graphics.newImage(path_t) as love.graphics.Texture

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

-- счетчик команд
local cmd_num = 0

-- Корпус
local quad_body = gr.newQuad(
    rect_body.x, rect_body.y, rect_body.w, rect_body.h, tex_body
)
-- Башня
local quad_turret = gr.newQuad(
    rect_turret.x, rect_turret.y, rect_turret.w, rect_turret.h, tex_turret
)

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
    --[[
    for _, v in pairs(hash) do
        draw(texture as gr.Texture, quad, v[1], v[2], v[3])
        draw(texture_t as gr.Texture, quad_t, v[4], v[5], v[6])
    end
    --]]
    for _, v in pairs(hash) do
        local x, y, angle = v[1], v[2], v[3]
        local tur_x, tur_y, tur_angle = v[4], v[5], v[6]

        gr.setColor {1, 1, 1, 1}
        gr.push()
        gr.translate(x, y)
        gr.rotate(angle)
        gr.translate(-rect_body.w / 2, -rect_body.h / 2)
        --gr.draw(tex_body, quad_body, x, y, angle)
        gr.draw(tex_body, quad_body, 0, 0)
        gr.pop()

        --tur_x = tur_x - rect_turret.w / 2
        --tur_y = tur_y - rect_turret.h / 2

        gr.push()
        gr.translate(tur_x, tur_y)
        --gr.translate(tur_x, tur_y)
        gr.rotate(tur_angle + math.pi)
        gr.translate(
            -rect_turret.w / 2,
            ---rect_turret.h / 2 + init_tank.anchorB[2]
            -rect_turret.h / 2 + init_tank.anchorB[2]
        )
        gr.draw(tex_turret, quad_turret, 0, 0)
        gr.pop()
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
