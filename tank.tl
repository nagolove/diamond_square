-- vim: set colorcolumn=85
-- vim: fdm=marker

require 'konstants'
require 'common'
require 'vector'

local PCamera = require "pcamera"
local serpent = require("serpent")
local Pipeline = require 'pipeline'
local inspect = require 'inspect'
local wrp = require "wrp"
--local Bullet = require "bullet"

-- Класс основного боевого танка.
local record Tank
    -- {{{

    record Rect
        x: number
        y: number
        w: number
        h: number
    end

    record FullInfo
        rect_body: Rect
        rect_turret: Rect
        init_table: wrp.TankInit
        base_tex_fname: string
        turret_tex_fname: string
    end

    -- _ префикс нижнего подчеркивания означает, что переменные могут быть
    -- изменены со стороны Lua C API
    _prev_x: number
    _prev_y: number
    -- Пушка
    --turret: wrp.Body

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

    -- Абсолютные координаты в пикселях
    new: function(x: number, y: number): Tank
    -- Вызывается один раз для инициализации модуля.
    initPipelineObjects: function(pl: Pipeline, cam: PCamera)

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

    -- запустить сопрограмму движения по кругу
    --circleMove: function(Tank)
    -- }}}

end -- Tank record

local pipeline: Pipeline
local camera: PCamera

-- Кусок вырезаемый из текстуры
local rect_body: Tank.Rect = {
    x = 87, y = 73,
    w = 82, h = 110,
}

-- Кусок вырезаемый из текстуры
local rect_turret: Tank.Rect = {
    x = 101, y = 0,
    w = 54, h = 160,
}

local init_table: wrp.TankInit = {
    -- {{{ 
    x = 0,
    y = 0,

    type = "tank",
    w = rect_body.w,
    h = rect_body.h,

    -- Точки сочленения тел
    anchorA = { 0., 0. },
    anchorB = { 
        0., 
        ---30., -- Смещение башни
        -25., -- Смещение башни
    },

    -- Смещение координат турели
    turret_dx = 0, -- Фактически не влияет
    turret_dy = 0, -- Фактически не влияет
    turret_rot_point = { rect_turret.w / 2., rect_turret.h / 2.},
    -- Размеры турели
    turret_w = rect_turret.w,
    turret_h = rect_turret.h,
    -- }}}
} 

-- Точка приложения импулься
local px, py = 0, 0
local impulse_amount = 5
-- Предел скорости движения
local vel_limit = 160
-- Предел скорости вращения корпуса
local ang_vel_limit = 2

local fromPolar = require 'vector-light'.fromPolar
local fire_dist = 5000

function Tank:fire()
    print('Tank:fire')
    --local x, y, angle = self.base:get_position()
    local x1, y1, angle = self.base:turret_get_pos()
    angle = angle + math.pi / 2
    print('x, y', x1, y1)
    -- Прибавлять координаты камеры
    -- Учитывать масштаб
    local x2, y2 = fromPolar(angle, fire_dist)
    pipeline:open('fire_dir')
    pipeline:push('ray', x1 + camera.x, y1 + camera.y, angle)
    wrp.space_query_segment_first(x1, y1, x1 + x2, y1 + y2, 
        function(
            tank: wrp.Tank, 
            x: number, y: number, 
            nx: number, ny: number, 
            alpha: number
        )
            pipeline:push('target', x, y)
        end
    )
    pipeline:push('enough')
    pipeline:close()
    --pipeline:openPushAndClose("fire_dir", x + camera.x, y + camera.y, angle)
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

local Tank_mt: metatable<Tank> = {
    __index = Tank,
}

function Tank.new(x: number, y: number): Tank
    if x ~= x or y ~= y then
        error("NaN in tank positon.")
    end

    local self: Tank = setmetatable({} as Tank, Tank_mt)

    tankCounter = tankCounter + 1

    self.strength = 1.
    self.fuel = 1.
    self.id = tankCounter
    self.color = {1, 1, 1, 1}
    self.type = "tank"

    local debug_verts: {{number}} = nil

    init_table.x, init_table.y = math.floor(x), math.floor(y)
    self.base, debug_verts = wrp.tank_new(init_table, self as table)

    if debug_verts then
        print("debug_verts:", inspect(debug_verts))
    end

    print('self.base', self.base)
    
    --wrp.set_position(self.base, pos.x, pos.y)

    -- }}}

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

function Tank.initPipelineObjects(pl: Pipeline, cam: PCamera)
    assert(pl)
    assert(cam)
    camera = cam
    pipeline = pl

    pipeline:pushCodeFromFile("base_shape", 'poly_shape.lua')
    pipeline:open('base_shape')
    local full_info: Tank.FullInfo = {
        rect_body = rect_body,
        rect_turret = rect_turret,
        init_table = init_table,
        base_tex_fname = "gfx/body.png",
        turret_tex_fname = "gfx/turret.png",
    }
    local ser_full_info = serpent.dump(full_info)
    pipeline:push(ser_full_info)
    pipeline:close()

    pipeline:pushCodeFromFile("fire_dir", 'fire_dir.lua')
    pipeline:openPushAndClose('fire_dir', 'set_dist', fire_dist)
end

return Tank
