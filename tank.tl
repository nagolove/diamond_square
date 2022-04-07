require 'konstants'
require 'common'
require 'vector'

local inspect = require 'inspect'
local wrp = require "wrp"
--local Bullet = require "bullet"

-- Класс основного боевого танка.
local record Tank

    -- {{{

    -- _ префикс нижнего подчеркивания означает, что переменные могут быть
    -- изменены со стороны Lua C API
    _prev_x: number
    _prev_y: number
    -- Пушка
    _turret: wrp.Body

    -- цифры получены из картинки tank_body_small.png
    --self.rectXY = {86, 72}
    --self.rectWH = {84, 111}

    -- куда смотрит башня, направление выстрела
    --dir: vector
    angle: number

    -- загружен-ли снаряд в пушку
    loaded: boolean

    -- боезапас пушки, в штуках
    shots: number

    pushTrack: function(Tank)
    fire: function(Tank)

    -- скорость поворота башни танка т-80 - 40 градусов в секунду.
    rotateToMouse: function(Tank)

    engineCycle: function(Tank)

    -- добавить один след от гусениц в список
    pushTrack: function(Tank)
    -- рисовать весь след
    drawTrack: function(Tank)
    -- продвинуть следы - удалить старые
    processTracks: function(Tank)

    -- прочность танка от 1 до 0
    strength: number
    -- от 0 - пустой бак, 1 - полный бак
    fuel: number
    -- цвет
    color: {number}
    -- потребление топлива, едениц в секунду
    fuelConsumption: number
    -- насколько нажат газ - от 0 до 1
    engineAcceleration: number

    -- следы движения
    track: {{number}}
    x4: number
    y4: number
    x1: number
    y1: number

    -- нормализованный вектор направления движения
    --dir: vector

    -- уникальное за сеанс игры число
    id: integer

    type: ObjectType
    base: wrp.Tank
    --turret: wrp.Body

    -- {{{ px, py, angle используются в eachShape для проверки на необходимсоть 
    -- рисования
    -- положение
    --px: number
    --py: number
    -- угол
    --angle: number
    -- }}}

    -- абсолютные координаты в пикселях
    new: function(pos: vector, w: number, h: number): Tank

    -- Обновить логику, не физику.
    -- Если возвращается nil, то объект считается убитым.
    update: function(Tank): Tank

    drawDirectionVector: function(Tank)

    -- сбросить скорость до нуля
    resetVelocities: function(Tank)

    -- движение
    left: function(Tank)
    right: function(Tank)

    forward: function(Tank)
    backward: function(Tank)

    enum Direction
        "left"
        "right"
    end
    rotate_turret: function(Tank, dir: Direction)

    fire: function(Tank)

    -- запустить сопрограмму движения по кругу
    --circleMove: function(Tank)
    -- }}}
end

local px, py = 0, 0
local impulse_amount = 100
local force_amount = 200
local vel_limit = 160
local ang_vel_limit = 2

function Tank:fire()
end

function Tank:left()
    --self.base:left()
    --print("w", wrp.get_body_ang_vel(self.base))
    if ang_vel_limit > self.base:get_ang_vel() then
        self.base:apply_impulse(-0.2, 0, 128, 128)
    end
    --wrp.set_torque(body, -10)
end

function Tank:right()
    if ang_vel_limit > self.base:get_ang_vel() then
        self.base:apply_impulse(0.2, 0, 128, 128)
        --wrp.set_body_ang_vel(self.base, 0.5);
    end
end

function Tank:forward()
    local vx, vy = self.base:get_vel()
    local len = vec_len(vx, vy)
    if len < vel_limit then
        --wrp.apply_force(self.base, 0, -amount, px, py);
        self.base:apply_impulse(0, -impulse_amount, px, py);
    end
    --self.base:forward()
end

function Tank:backward()
    --wrp.apply_impulse(body, 0, amount, px, py);
    local vx, vy = self.base:get_vel()
    local len = vec_len(vx, vy)
    if len < vel_limit then
        self.base:apply_impulse(0, impulse_amount, px, py);
    end
    --self.base:backward()
end

-- Счетчик живый танков
local tankCounter = 0

-- местоположение передавать в метрах
-- направление шасси - нормализованный вектор
function Tank.new(pos: vector, w: number, h: number): Tank
    -- {{{
    local Tank_mt: metatable<Tank> = {
        __index = Tank,
    }

    local self: Tank = setmetatable({} as Tank, Tank_mt)

    tankCounter = tankCounter + 1

    --local w, h = 
    self.strength = 1.
    self.fuel = 1.
    self.id = tankCounter

    self.color = {1, 1, 1, 1}

    self.type = "tank"

    if pos.x ~= pos.x or pos.y ~= pos.y then
        error("NaN in tank positon.")
    end

    local debug_verts: {{number}} = nil
    self.base, debug_verts = wrp.tank_new(
        self.type, 
        pos.x, pos.y, 
        w, h, 
        self as table
    )
    if debug_verts then
        print("debug_verts:", inspect(debug_verts))
    end

    print('self.base', self.base)
    
    --wrp.set_position(self.base, pos.x, pos.y)

    return self
end

function Tank:update(): Tank

    if self.strength <= 0. then
        return nil
    end

    return self
end

function Tank:engineCycle()
    -- расход топлива, едениц в секунду
    --local consumption = 10
    if self.fuel > 0 then
    end
end

function Tank:pushTrack()
    --[[
    if self.x4 and self.y4 and self.x1 and self.y1 then
        local trackNode = {}
        local len = 15
        local deltalen = 3
        local dx1, dx2 = vecl.normalize(self.x4 - self.x1, self.y4 - self.y1)
        local deltax, deltay = dx1 * deltalen, dx2 * deltalen
        local x1, y1, x4, y4: number, number, number, number
        dx1, dx2 = dx1 * len, dx2 * len
        x4, y4 = self.x4 - deltax, self.y4 - deltay

        table.insert(trackNode, x4)
        table.insert(trackNode, y4)
        table.insert(trackNode, x4 - dx1)
        table.insert(trackNode, y4 - dx2)

        x1, y1 = self.x1 + deltax, self.y1 + deltay

        table.insert(trackNode, x1)
        table.insert(trackNode, y1)
        table.insert(trackNode, x1 + dx1)
        table.insert(trackNode, y1 + dx2)

        table.insert(self.track, trackNode)

        if #self.track > maxTrackCount then
            table.remove(self.track, 1)
        end
    end
    --]]
end

function Tank:drawDirectionVector()
    --[[
    -- Использовать self.angle
    if self.dir then
        local x, y = 0, 0
        local scale = 100
        local color = {0., 0.05, 0.99, 1}
        --x, y = x * M2PIX, y * M2PIX
        --arrow.draw(x, y, x + self.dir.x * scale, y + self.dir.y * scale, color)
    end
    --]]
end

function Tank:rotate_turret(dir: Tank.Direction)
    if dir == "left" then
        self.base:turret_rotate(-1)
    elseif dir == "right" then
        self.base:turret_rotate(1)
    end
    --]]
end

return Tank
