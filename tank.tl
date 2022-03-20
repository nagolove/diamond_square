require 'konstants'
require 'common'
require 'vector'

local wrp = require "wrp"
--local Bullet = require "bullet"

-- Класс основного боевого танка.
local record Tank

    -- {{{

    -- _ префикс нижнего подчеркивания означает, что переменные могут быть
    -- изменены со стороны Lua C API
    _prev_x: number
    _prev_y: number

    -- прочность танка от 1 до 0
    strength: number
    -- запас топлива от 1 до 0
    fuel: number
    -- цвет
    color: {number}

    -- нормализованный вектор направления движения
    --dir: vector

    -- уникальное за сеанс игры число
    id: integer

    type: ObjectType
    base: wrp.Body
    turret: wrp.Body

    -- {{{ px, py, angle используются в eachShape для проверки на необходимсоть 
    -- рисования
    -- положение
    px: number
    py: number
    -- угол
    angle: number
    -- }}}

    -- пушка
    --turret: Turret

    -- ходовая часть
    --base: Base

    -- абсолютные координаты в пикселях
    new: function(pos: vector, w: number, h: number): Tank

    -- Обновить логику, не физику.
    -- Если возвращается nil, то объект считается убитым.
    update: function(Tank): Tank

    -- сбросить скорость до нуля
    resetVelocities: function(Tank)

    -- движение
    left: function(Tank)
    right: function(Tank)

    forward: function(Tank)
    backward: function(Tank)

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
    if ang_vel_limit > wrp.get_body_ang_vel(self.base) then
        wrp.apply_impulse(self.base, -0.2, 0, 128, 128)
    end
    --wrp.set_torque(body, -10)
end

function Tank:right()
    if ang_vel_limit > wrp.get_body_ang_vel(self.base) then
        wrp.apply_impulse(self.base, 0.2, 0, 128, 128)
        --wrp.set_body_ang_vel(self.base, 0.5);
    end
end

function Tank:forward()
    local vx, vy = wrp.get_body_vel(self.base)
    local len = vec_len(vx, vy)
    if len < vel_limit then
        --wrp.apply_force(self.base, 0, -amount, px, py);
        wrp.apply_impulse(self.base, 0, -impulse_amount, px, py);
    end
    --self.base:forward()
end

function Tank:backward()
    --wrp.apply_impulse(body, 0, amount, px, py);
    local vx, vy = wrp.get_body_vel(self.base)
    local len = vec_len(vx, vy)
    if len < vel_limit then
        wrp.apply_impulse(self.base, 0, impulse_amount, px, py);
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
    self.base = wrp.new_body(self.type, pos.x, pos.y, w, h, self as table)
    --wrp.set_position(self.base, pos.x, pos.y)

    return self
end

function Tank:update(): Tank

    if self.strength <= 0. then
        return nil
    end

    return self
end

return Tank
