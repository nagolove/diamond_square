require 'love'

local Pipeline = require 'pipeline'
local lj = love.joystick
local Joystick = lj.Joystick
local sformat = string.format
local Tank = require 'tank'

-- TODO добавить инерцию к камере
local record Camera
    --Локальная система координат - отображаемое окно, координаты курсора мыши.
    --Глобальная система координат - все игровое поле. Имеет свою точку (0, 0).

    new: function(pipeline: Pipeline, _screenW: number, _screenH: number): Camera

    -- Установка танка, который считается игроком.
    setPlayer: function(Camera, tank: Tank)

    -- Включить камеру
    setTransform: function(Camera)
    -- Отключить камеру
    setOrigin: function(Camera)
    -- Проверка ввода с геймпада.
    -- TODO Вынести из камеры наружу.
    checkInput: function(Camera)
    -- Обновить состояние.
    update: function(Camera, dt: number)

    -- Из оконных координаты в абсолютные.
    fromLocal: function(Camera, x: number, y: number): number, number
    -- Из абсолютных в оконные. 
    -- Что возвращать если точка лежит за пределами окна?
    fromGlobal: function(Camera)

    -- Проверить, не выехал ли игрок за круг в локальной системе координат.
    -- Если выехал, то вернуть его обратно.
    checkIsPlayerInCircle: function(Camera)

    -- Передвинуть к текущему игроку.
    moveToPlayer: function(Camera)

    -- Сбросить смещение в начальное положение.
    setToOrigin: function(Camera)

    -- Разместить строку информациии в текстовом буфере lines_buf
    -- Секция должна быть октрыта.
    push2lines_buf: function(Camera)

    -- нарисовать оси координат, проходящие через центр экрана
    draw_axises: function(Camera)

    -- PRIVATE
    checkMovement: function(Camera, j: Joystick)
    checkScale: function(Camera, j: Joystick)

    playerTank: Tank
    screenW: number
    screenH: number
    pipeline: Pipeline
    x: number
    y: number
    scale: number
    dt: number
    transform: love.math.Transform
end

local Camera_mt: metatable<Camera> = {
    __index = Camera,
}

function Camera.new(pipeline: Pipeline, _screenW: number, _screenH: number): Camera
    local self: Camera = setmetatable({} as Camera, Camera_mt)
    self.screenW = _screenW
    self.screenH = _screenH
    self.x, self.y = 0, 0
    self.scale = 1.
    self.dt = 0
    self.transform = love.math.newTransform()
    self.pipeline = pipeline
    self.pipeline:pushCode("camera_axises", [[
    local yield = coroutine.yield
    local linew = 1.
    local color = {0, 0, 0, 1}
    while true do
        local oldlw = love.graphics.getLineWidth()
        local w, h = love.graphics.getDimensions()
        love.graphics.setLineWidth(linew)
        love.graphics.setColor(color)
        love.graphics.line(w / 2, 0, w / 2, h)
        love.graphics.line(0, h / 2, w, h / 2)
        love.graphics.setLineWidth(oldlw)
        yield()
    end
    ]])
    return self
end

function Camera:setTransform()
    self.pipeline:open('set_transform')
    self.pipeline:push(self.transform)
    self.pipeline:close()
end

function Camera:setOrigin()
    self.pipeline:openAndClose('origin_transform')
end

function Camera:setPlayer(tank: Tank)
    self.playerTank = tank
end

function Camera:checkInput(j: Joystick)
    self:checkMovement(j)
    self:checkScale(j)
end

function Camera:draw_axises()
    self.pipeline:openAndClose("camera_axises")
end

function Camera:push2lines_buf()
    local msg = sformat("camera: (%.3f, %.3f, %.4f)", self.x, self.y, self.scale)
    self.pipeline:push("add", "camera", msg)
    local mat = {self.transform:getMatrix()}
    local fmt1 = "%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f,"
    local fmt2 = "%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f"
    msg = sformat(
        "camera mat: (" .. fmt1 .. fmt2 .. ")",
        mat[1],
        mat[2],
        mat[3],
        mat[4],
        mat[5],
        mat[6],
        mat[7],
        mat[8],
        mat[9],
        mat[10],
        mat[11],
        mat[12],
        mat[13],
        mat[14],
        mat[15],
        mat[16]
    )
    self.pipeline:push("add", "camera_mat", msg)
end

function Camera:update(dt: number)
    self.dt = dt
end

function Camera:checkMovement(j: Joystick)
    local axes = {j:getAxes()}
    local dx, dy = axes[4], axes[5]
    -- количество пикселей на которые передвигается камера
    local amount_x, amount_y = 3000 * self.dt, 3000 * self.dt
    local tx, ty = 0., 0.
    local changed = false

    -- проверка наклона стика геймпада
    if dx > 0 then
        changed = true
        tx = -amount_x
    elseif dx < 0 then
        changed = true
        tx = amount_x
    end

    -- проверка наклона стика геймпада
    if dy > 0 then
        changed = true
        ty = -amount_y
    elseif dy < 0 then
        changed = true
        ty = amount_y
    end

    if changed then
        self.x = self.x + tx
        self.y = self.y + ty
        self.transform:translate(tx, ty)
    end
end

-- как лучше учитывать положение джойстика что-бы не было рывков?
function Camera:checkScale(j: Joystick)
    local axes = {j:getAxes()}
    local dy = axes[2]
    local factor = 1 * self.dt
    local px, py = self.screenW * factor / 2, self.screenH * factor / 2
    if dy == -1 then
        -- TODO добавить смещение по осям что-бы приближение и удаление 
        -- приходилось на центр экрана
        self.scale = 1 + factor
        self.transform:scale(1 + factor, 1 + factor)

        self.transform:translate(-px, -py)
    elseif dy == 1 then
        self.scale = 1 - factor
        self.transform:scale(1 - factor, 1 - factor)
        self.transform:translate(px, py)
    end
end

-- Проверяет, находится-ли центр танка игрока в пределах окружности 
-- определенного радиуса. Если танк выезжает за пределы, то камера сдвигается.
-- * Обеспечить плавность движения камеры.
-- * Камера должна сохранять какие-то абсолютные координаты?
function Camera:checkIsPlayerInCircle()
    --local rad = 300
end

-- камера перемещается на танк игрока
function Camera:moveToPlayer()
    if not self.playerTank and self.playerTank.base then
        return
    end

    local px, py, _ = self.playerTank.base:get_position()
    print("camera x, y, scale", self.x, self.y, self.scale)
    print("tank x, y", px, py)
    --self.x, self.y = 0, 0
    self.scale = 1.
    local dx = self.x - px + self.screenW / 2
    local dy = self.y - py + self.screenH / 2
    self.x, self.y = self.x + dx, self.y + dy
    if self.x ~= dx or self.y ~= dy then
        --self.x, self.y = 0, 0
        self.transform:reset()
        self.transform:scale(self.scale)
        --self.transform:translate(-x, -y)
        self.transform:translate(dx, dy)
    end
end

function Camera:setToOrigin()
    self.x, self.y = 0, 0
    self.scale = 1,
    self.transform:translate(self.x, self.y)
    self.transform:reset()
    self.transform:scale(self.scale, self.scale)
end

return Camera
