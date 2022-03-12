-- vim: set colorcolumn=85
-- vim: fdm=marker

--local debug_print = print
local dprint = require 'debug_print'
local debug_print = dprint.debug_print

dprint.set_filter { 
    [1] = { "joy" },
    [2] = { 'phys' },
    [3] = { "thread", 'someName' },
    [4] = { "graphics" },
    [5] = { "input" },
    [6] = { "verts" },
    --[7] = { "phys" },
    --[8] = { "phys" },
    --[9] = { "phys" },
    --[0] = { "phys" },
}
--]]

local colorize = require 'ansicolors2'.ansicolors
debug_print('thread', colorize('%{yellow}>>>>>%{reset} t80 started'))

require "love_inc".require_pls_nographic()

debug_print('thread', 'love.filesystem.getRequirePath()', love.filesystem.getRequirePath())

--local require_path = SCENE_PREFIX .. "/?.lua;?.lua;?/init.lua;"
local require_path = "scenes/t80/?.lua;?.lua;?/init.lua;"
print('require_path', require_path)
love.filesystem.setRequirePath(require_path)

print('getCRequirePath()', love.filesystem.getCRequirePath())

love.filesystem.setCRequirePath("scenes/t80/?.so;?.so")

print("package.cpath", package.cpath)

print('getWorkingDirectory', love.filesystem.getWorkingDirectory())

local wrp = require "wrp"
--print('wrp', inspect(wrp))

-- {{{ require
require 'konstants'
require 'joystate'
require 'pipeline'
require "common"

-- Доработка keyconfig для джойстика
require "keyconfig"

local IMGUI = false
if love.system.getOS() == 'Linux' then
    require "imgui"
    IMGUI = true
end

require "love"

--local tween = require 'tween'
--local camMoveTween = tween.new()

local enum ObjectType
    "tank"
end

local sformat = string.format
local inspect = require "inspect"
local serpent = require 'serpent'
--local i18n = require "i18n"
local metrics = require "metrics"
local vec2 = require "vector"
--local vecl = require "vector-light"
--local tabular = require "tabular"

-- }}}

local Pipeline = require 'pipeline'
local pipeline = Pipeline.new(SCENE_PREFIX)

-- рисование стрелочек
local arrow = require 'arrow'
arrow.init(pipeline)

--local Shortcut = KeyConfig.Shortcut

--local abs, pow, sqrt = math.abs, math.pow, math.sqrt
--local abs = math.abs
local yield, resume = coroutine.yield, coroutine.resume

--[[
local enum Mode
    "normal"
    "command"
    "editor"
end
--]]

--[[
local enum Brush
    "None" -- ничего не рисовать
    "Hangar"
end
--]]

--local record DrawNode
    --f: function
    --self: any
--end

--[[
local record TurretCommon
    -- {{{
    barrelRectXY: {number}
    barrelRectWH: {number}
    towerRectXY: {number}
    towerRectWH: {number}
end
--]]

--[[
local turretCommon: TurretCommon = {
    barrelRectXY = {124, 0},
    barrelRectWH = {8, 109},
    towerRectXY = {101, 103},
    towerRectWH = {54, 58},
}
--]]

-- }}}

local record Edge
    x1: number
    y1: number
    x2: number
    y2: number
end

-- Чем занят класс Arena?
-- Класс Arena применяется для хранения геометрии ограничивающей игровое поле.
-- Также объект класса позволяет записать полное описание сцены в строку или файл и
-- восстановить сцену из файла. Сцена содержит списки танков, списки ребер, списки ангаров.
local record Arena
    -- {{{

    -- какая точка рисуется, первая или вторая
    enum Mode
        'first'
        'second'
    end

    mode: Mode
    edges: {Edge}

    -- interface

    new: function(fname: string): Arena
    present: function(Arena)
    update: function(Arena)
    mousemoved: function(Arena, x: number, y: number, dx: number, dy: number)
    mousepressed: function(Arena, x: number, y: number, btn: integer)

    save2file: function(Arena, fname: string)
    ser: function(Arena): string

    -- internal 

    createFixtures: function(Arena)

    -- }}}
end

local record FilterData
    categoies: integer
    mask: integer
    group: integer
end

--[[
local enum Particles
    "default"
    "rocket"
    "gauss"
end
--]]

local record Hangar
    vertices: {number}
    id: integer
    --objectType: ObjectType
    color: {number}
    --physbody: Physics.Body
    --polyshape: lp.PolygonShape
    rectXY: {number}
    rectWH: {number}
    --fixture: Physics.Fixture

    new: function(): Hangar
    update: function(Hangar)
    present: function(Hangar)
end

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
    new: function(pos: vector): Tank

    -- рисовать
    present: function(Tank)

    -- обновить логику, не физику
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

-- Пушка вместе с башней
local record Turret
    -- {{{
    rectXY: {number}
    rectWH: {number}

    id: integer
    --joint: lp.WeldJoint
    --fireCoro: thread

    -- категории, маски и группы столконовений box2d
    --barrelCategories: integer
    --barrelMask: integer
    --barrelGroup: integer
    --towerCategories: integer
    --towerMask: integer
    --towerGroup: integer

    filterdata: {FilterData}
    --physbody: love.physics.Body
    --tankphysbody: lp.Body
    --fixtureBarrel: love.physics.Fixture
    --fixtureTower: love.physics.Fixture

    --barrelShape: lp.PolygonShape
    --towerShape: lp.PolygonShape

    type: ObjectType
    --image: love.graphics.Image
    angle: number
    tank: Tank
    -- куда смотрит башня, направление выстрела
    dir: vector

    -- загружен-ли снаряд в пушку
    loaded: boolean

    -- боезапас пушки, в штуках
    shots: number

    new: function(t: Tank): Turret
    present: function(Turret)
    update: function(Turret)
    fire: function(Turret)
    rotateToMouse: function(Turret)
    --createFireCoro: function(): thread
    -- }}}
end

-- Ходовая часть с полигоном
local record Base
    -- {{{
    id: integer
    objectType: ObjectType
    rectXY: {number}
    rectWH: {number}

    -- тоже, что и в Tank.physbody
    --physbody: love.physics.Body

    filterdata: {FilterData}

    --fixture: love.physics.Fixture

    --pos: vector -- центр поворота корпуса
    tank: Tank
    --polyshape: lp.PolygonShape
    -- нормализованный вектор
    dir: vector

    -- следы движения
    track: {{number}}
    x4: number
    y4: number
    x1: number
    y1: number

    -- от 0 - пустой бак, до 1 - полный бак
    fuel: number
    -- потребление топлива, едениц в секунду
    fuelConsumption: number
    -- насколько нажат газ - от 0 до 1
    engineAcceleration: number

    new: function(t: Tank): Base
    present: function(Base)
    update: function(Base)

    updateDir: function(Base)

    left: function(Base)
    right: function(Base)
    forward: function(Base)
    backward: function(Base)

    -- один такт движения
    engineCycle: function(Base)
    -- продвинуть треки
    processTracks: function(Base)

    -- добавить трек в список
    pushTrack: function(Base)
    -- рисовать весь след
    drawTrack: function(Base)

    resetVelocities: function(Base)
    drawDirectionVector: function(Base)
    -- }}}
end

-- Основной боевой тип сняряда. Без фугасного воздействия.
local record Bullet
    -- {{{
    --physbody: love.physics.Body
    timestamp: number
    objectType: ObjectType
    id: integer
    dir: vector
    died: boolean
    px: number
    py: number

    -- START OF DEBUG STUFF
    velx: number
    vely: number
    mass: number
    -- END OF DEBUG STUFF
    -- }}}

    new: function(px: number, py: number, dirx: number, diry: number, 
                  tankId: integer): Bullet
    update: function()
end

-- информация о наборе частиц
local record ParticleSystemDefinition
    -- режим смешивания
    blendmode: love.graphics.BlendMode
    -- режим смешивания канала прозрачности
    alphamode: love.graphics.BlendAlphaMode
    lifetime1: number
    lifetime2: number
    -- интенсивность эммисия
    emissionRate: number
    -- вариация размеров
    sizeVariation: number
    -- линейное ускорение
    lineAcceleration: {number}
    colors: {{number}}
    emiterlifetimeexp: string
    rotation1: number
    rotation2: number
end

local type ParticlesMap = {string: ParticleSystemDefinition}

global particles: ParticlesMap= {
    -- {{{
    -- значение для по-умолчанию для новых эффектов
    ["default"] = {
        blendmode = 'alpha',
        alphamode = 'alphamultiply',
        lifetime1 = 1,
        lifetime2 = 2,
        emissionRate = 10,
        sizeVariation = 1,
        lineAcceleration = { -20, -20, 20, 20 },
        colors = {
            { 1, 1, 1, 1, },
            { 1, 1, 1, 0, },
        },
        emiterlifetimeexp = "return 0.1 + (rng:random() + 0.01) / 2",
        rotation1 = 0,
        rotation2 = math.pi * 2,
    }
    -- }}}
}

-- То, что создается когда происходит попадание снаряда в танк.
local record Hit 
    -- {{{
    -- в пикселях
    x: number
    -- в пикселях
    y: number
    ps: love.graphics.ParticleSystem

    -- координаты в метрах
    new: function(x: number, y: number): Hit
    -- }}}
end

-- {{{ Global and local variables.

-- Указатель на текущий подсвеченный навигатором танк.
--local currentNavigator: Tank

--local bodyIter_base: cm.cpSpaceBodyIteratorFunc
--local shapeIter_base: cm.cpSpaceShapeIteratorFunc

--local bodyIter_turret: pw.EachSpaceBodyIter
--local shapeIter_turret: pw.EachBodyShapeIter

--local bodyIter_verts: pw.EachSpaceBodyIter
--local shapeIter_verts: pw.EachBodyShapeIter

--local current_part: Tank.Part

local screenW, screenH: number, number

-- {{{ Konsole editing
--local historyfname = "cmdhistory.txt"

--[[
global mode: Mode = "normal"
global cmdline: string = ""
local cmdhistory: {string} = {}
global cursorpos: integer = 1
--global suggestList: List = List.new()
-- список имен переменных для отображения в консоли
global attachedVarsList: {string: function} = {}
--]]

require "Timer"

-- Все танки, в том числе и тот, которым управляет игрок.
local tanks: {Tank} = {}

-- Ангары(точки для ремонта, также точки появления техники
local hangars: {Hangar} = {}

-- Танк, которым управляет игрок
local playerTank: Tank

-- Логотип, картинка или главное меню?
require 'logo'

-- Счетчик живый танков
local tankCounter = 0

local rng: love.math.RandomGenerator = love.math.newRandomGenerator()

rng:setSeed(os.time())

local DiamonAndSquare = require 'diamondsquare'
local diamondSquare: DiamonAndSquare = DiamonAndSquare.new(8, rng, pipeline)
--local diamondSquare: DiamonAndSquare = nil

--local loadCannonSound = Audio.newSource(SCENE_PREFIX .. "/load.wav", 'static')
--local audMainTheme = Audio.newSource(SCENE_PREFIX .. "/audio/Lime of Adventure.mp3", 'static')

local event_channel = love.thread.getChannel("event_channel")
local main_channel = love.thread.getChannel("main_channel")

local is_stop = false
local last_render: number = love.timer.getTime()
-- }}}

local Joystick = love.joystick.Joystick
local joystick = love.joystick
local joyState: JoyState
--local joys: {joystick.Joystick} = {}
local joy: Joystick

-- TODO добавить инерцию к камере
local record Camera
    -- public
    new: function(): Camera
    setTransform: function(Camera)
    setOrigin: function(Camera)
    checkInput: function(Camera)
    update: function(Camera, dt: number)
    checkPlayerInCircle: function(Camera)
    moveToPlayer: function(Camera)
    moveToOrigin: function(Camera)

    -- разместить строку информациии в текстовом буфере lines_buf
    -- секция должна быть октрыта
    push2lines_buf: function(Camera)

    -- нарисовать оси координат, проходящие через центр экрана
    draw_axises: function(Camera)

    -- private
    checkMovement: function(Camera, j: Joystick)
    checkScale: function(Camera, j: Joystick)

    x: number
    y: number
    scale: number
    dt: number
    transform: love.math.Transform
end

local Camera_mt: metatable<Camera> = {
    __index = Camera,
}

function Camera:setTransform()
    pipeline:open('set_transform')
    pipeline:push(self.transform)
    pipeline:close()
end

function Camera:setOrigin()
    pipeline:openAndClose('origin_transform')
end

function Camera.new(): Camera
    local self: Camera = setmetatable({} as Camera, Camera_mt)
    self.x, self.y = 0, 0
    self.scale = 1.
    self.dt = 0
    self.transform = love.math.newTransform()
    pipeline:pushCode("camera_axises", [[
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

function Camera:checkInput(j: Joystick)
    self:checkMovement(j)
    self:checkScale(j)
end

function Camera:draw_axises()
    pipeline:openAndClose("camera_axises")
end

function Camera:push2lines_buf()
    local msg = sformat("camera: (%.3f, %.3f, %.4f)", self.x, self.y, self.scale)
    pipeline:push("add", "camera", msg)
    local mat = {self.transform:getMatrix()}
    local fmt1 = "%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f,"
    local fmt2 = "%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f"
    local msg = sformat(
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
    pipeline:push("add", "camera_mat", msg)
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
function Camera:checkScale(j: joystick.Joystick)
    local axes = {j:getAxes()}
    local dy = axes[2]
    local factor = 1 * self.dt
    --print('dy', dy)
    if dy == -1 then
        -- TODO добавить смещение по осям что-бы приближение и удаление 
        -- приходилось на центр экрана
        self.scale = 1 + factor
        self.transform:scale(1 + factor, 1 + factor)
        --print('camera:scale(1 + factor, 1 + factor)')
    elseif dy == 1 then
        self.scale = 1 - factor
        self.transform:scale(1 - factor, 1 - factor)
        --print('camera:scale(1 - factor, 1 - factor)')
    end
end

-- Проверяет, находится-ли центр танка игрока в пределах окружности 
-- определенного радиуса. Если танк выезжает за пределы, то камера сдвигается.
-- * Обеспечить плавность движения камеры.
-- * Камера должна сохранять какие-то абсолютные координаты?
function Camera:checkPlayerInCircle()
    local rad = 300
end

-- камера перемещается на танк игрока
function Camera:moveToPlayer()
    if not playerTank and playerTank.base then
        return
    end

    local px, py, _ = wrp.get_position(playerTank.base)
    print("camera x, y, scale", self.x, self.y, self.scale)
    print("tank x, y", px, py)
    self.x, self.y = 0, 0
    self.scale = 1.
    local dx, dy = self.x + -px + screenW / 2, self.y + -py + screenH / 2
    --self.x, self.y = self.x + dx, self.y + dy
    if self.x ~= dx or self.y ~= dy then
        --self.x, self.y = 0, 0
        self.transform:reset()
        self.transform:scale(self.scale)
        --self.transform:translate(-x, -y)
        self.transform:translate(dx, dy)
    end
end

function Camera:moveToOrigin()
    self.x, self.y = 0, 0
    self.scale = 1,
    self.transform:translate(self.x, self.y)
    self.transform:reset()
    self.transform:scale(self.scale, self.scale)
end

local camera: Camera

local function initJoy()
    for _, j in ipairs(joystick.getJoysticks()) do
        debug_print("joy", colorize('%{green}' .. inspect(j)))
    end
    joy = joystick.getJoysticks()[1]
    if joy then
        debug_print("joy", colorize('%{green}avaible ' .. joy:getButtonCount() .. ' buttons'))
        debug_print("joy", colorize('%{green}hats num: ' .. joy:getHatCount()))
    end
    joyState = JoyState.new(joy)
end

function Bullet.new(px: number, py: number, dirx: number, diry: number, 
    tankId: integer): Bullet
    -- {{{
    local Bullet_mt: metatable<Bullet> = {
        __index = Bullet,
    }
    local self: Bullet = setmetatable({} as Bullet, Bullet_mt)

    self.timestamp = love.timer.getTime()
    self.died = false
    self.px = px
    self.py = py

    self.dir = vec2.new(dirx, diry)
    self.id = tankId or 0
    --self.objectType = 'Bullet'

    return self
    -- }}}
end

local function print_io_rate()
    local bytes = pipeline:get_received_in_sec()
    local msg = sformat("передано за секунду Килобайт = %d", math.floor(bytes / 1024))
    pipeline:push('add', 'data_received', msg)
end

function Hangar.new(_: vector): Hangar
    local Hangar_mt: metatable<Hangar> = {
        __index = Hangar,
    }
    local self = setmetatable({} as Hangar, Hangar_mt)
    --self.objectType = "Hangar"
    return self
end

function Hangar:update()

end

function Hangar:present()
end

function Hit.new(x: number, y: number): Hit
    local Hit_mt: metatable<Hit> = {
        __index = Hit,
    }
    local self: Hit = setmetatable({} as Hit, Hit_mt)

    self.ps = nil
    error('self.ps = nil')

    x, y = x * M2PIX, y * M2PIX

    self.x = x
    self.y = y

    return self
end

function Turret:fire()
end

function Arena.new(_: string): Arena
    local Arena_mt: metatable<Arena> = { __index = Arena }
    local self: Arena = setmetatable({} as Arena, Arena_mt)

    --self.objectType = "Arena"

    return self
end

function Arena:mousemoved(_: number, _: number, _: number, _: number)
end

function Arena:update()
end

function Arena:mousepressed(x: number, y: number, _: integer)

    x, y = x * PIX2M, y * PIX2M
    if self.mode then
        if self.mode == 'first' then
            self.edges[#self.edges].x2 = x
            self.edges[#self.edges].y2 = y
            self.mode = 'second'
        elseif self.mode == 'second' then
            self.mode = nil
        end
    else
        self.mode = 'first'
        table.insert(self.edges, { x1 = x, y1 = y })
    end
end

function Arena:ser(): string
end

function Arena:save2file(fname: string)
    local root = {
        rngSeed = rng:getSeed(),
        edges = self.edges,
        hangars = {},
    }
    for _, v in ipairs(hangars) do
        table.insert(root.hangars, v.vertices)
    end
    local data = serpent.dump(root)
    love.filesystem.write(fname, data)
end

function Arena:createFixtures()
    assert(self.edges )
end

global arena: Arena

function Tank:fire()
end

function Base:left()
end

function Base:right()
end

function Base:forward()
    if self.tank.fuel > 0. then
    end
end

function Base:backward()
    if self.tank.fuel > 0. then
    end
end
--]]

function Tank:left()
    --self.base:left()
end

function Tank:right()
    --self.base:right()
end

function Tank:forward()
    --self.base:forward()
end

function Tank:backward()
    --self.base:backward()
end

--local base_tex_fname = 'tank_body_small.png'
local base_tex_fname = 'tank_body.cut.png'
local turret_text_fname = 'tank_tower.png'

local function getTankSize(): integer, integer
    local path = SCENE_PREFIX .. '/' .. base_tex_fname
    local image = love.image.newImageData(path)
    if not image then
        error('Could not load base_tex_fname: ' .. path)
    end
    return image:getDimensions() as (integer, integer)
end

local tank_width, tank_height = getTankSize()

-- местоположение передавать в метрах
-- направление шасси - нормализованный вектор
function Tank.new(pos: vector): Tank
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
    self.base = wrp.new_body(self.type, tank_width, tank_height, self as table)
    wrp.set_position(self.base, pos.x, pos.y)

    return self
end

function Base:drawDirectionVector()
    if self.dir then
        local x, y = 0, 0
        local scale = 100
        local color = {0., 0.05, 0.99, 1}
        x, y = x * M2PIX, y * M2PIX
        arrow.draw(x, y, x + self.dir.x * scale, y + self.dir.y * scale, color)
    end
end

function Base:resetVelocities()
end

function Base:updateDir()
end

function Base:engineCycle()
    -- расход топлива, едениц в секунду
    --local consumption = 10
    if self.tank.fuel > 0 then
    end
end

function Base:update()
    self:updateDir()
    if not self.filterdata then
        --self.filterdata = getBodyFilterData(self.physbody)
    end
    self:processTracks()
end

function Base:processTracks()
end

function Tank:update(): Tank

    if self.strength <= 0. then
        return self
    end

    return self
end

function Tank:present()
end

function Turret.new(t: Tank): Turret
    if not t then
        error("Could'not create Turret without Tank object")
    end

    local Turret_mt: metatable<Turret> = {
        __index = Turret,
    }

    local self: Turret = setmetatable({} as Turret, Turret_mt)
    self.tank = t

    return self
end

-- Как сделать медленный поворот башни?
-- скорость поворота башни танка т-80 - 40 градусов в секунду.
function Turret:rotateToMouse()
    local mx, my = love.mouse.getPosition()
    mx, my = mx * PIX2M, my * PIX2M
end

function Turret:update()
    -- поворачивать башню только у танка игрока
    if playerTank and self.tank == playerTank then
        self:rotateToMouse()
    end
end

function Turret:present()
end

function Base.new(t: Tank): Base
    -- {{{
    local Base_mt: metatable<Base> = {
        __index = Base,
    }

    if not t then
        error("Could'not create BaseP without Tank object")
    end

    local self: Base = setmetatable({} as Base, Base_mt)
    --self.objectType = "Base"
    self.tank = t
    self.track = {}

    -- цифры получены из картинки tank_body_small.png
    self.rectXY = {86, 72}
    self.rectWH = {84, 111}

    return self
end

function Base:present()
    self:drawTrack()
end

function Base:pushTrack()
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

function Base:drawTrack()
end

function Tank:damage(_: Bullet)
end

--[[
Где находится обрабатывающая функция?
В методах танка?
-----------------------------------------------------------------------
|                           Свободная функция?                        |
-----------------------------------------------------------------------
В методах пули?
В методах ангара?

танк и танк
танк и пуля
танк и грань
танк и ангар
--]]

--[[
local function processTankVsBullet(_: Tank, _: Bullet)
end

local function processTankVsTank(_: Tank, _: Bullet)
end
--]]

--[[
local contactMap = {
    ['Tank'] = {
        ['Bullet'] = function(_: Tank, _: Bullet)
        end,
        ['Tank'] = function(_: Tank, _: Tank)
        end,
    }
}
-]]

--[[
local function loadLocales()
    -- {{{
    local localePath = SCENE_PREFIX .. "/locales"
    local files = love.filesystem.getDirectoryItems(localePath)
    print("locale files", inspect(files))
    for _, v in ipairs(files) do 
        i18n.loadFile(localePath .. "/" .. v, function(path: string): any
            local chunk, errmsg = love.filesystem.load(path)
            if not chunk then
                error(errmsg)
            end
            return chunk
        end) 
    end
    --i18n.setLocale('en')
    i18n.setLocale('ru')
    --print("i18n", inspect(i18n))
    -- }}}
end
--]]

-- возвращает массив со значениями координат углов ландшафта в метрах по часовой
-- стрелке от левого верхнего угла.
function getTerrainCorners(): {vector}
end

--[[
local function bindDeveloperKeys()
    local kc = KeyConfig
    kc.bind(
        --'keypressed', { key = "p" },
        'isdown', { key = "p" },
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end

            print('works')
            if playerTank then
                --local x, y = playerTank.base.physbody:getWorldCenter()
                --newHit(x, y)
                --print('new Hit created at', x, y)
            end

            return false, sc
        end,
        --i18n("mt" .. "right"))
        'spawn Hit')
    kc.bind(
        --'keypressed', { key = "p" },
        'keypressed', { key = "r" },
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end

            --terrain()

            return false, sc
        end,
        --i18n("mt" .. "right"))
        'spawn Hit')
end
--]]

--[[
local function bindTerrainControlKeys()
    local kc = KeyConfig
    kc.bind(
        'keypressed', { key = "t" },
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end
            print('drawTerrain', drawTerrain)
            drawTerrain = not drawTerrain
            return false, sc
        end,
        --i18n("mt" .. "right"))
        'draw terrain or not')
end
--]]

--[[
local function buildParticlesNames(): {string}
    local res: {string} = {}
    for k, _ in pairs(particles) do
        table.insert(res, k)
    end
    return res
end
--]]

--local currentParticesType: integer = 0

--[[
local function selectParticleType(): string
    local v: number
    local st: boolean
    local names = buildParticlesNames()
    local zeroseparated, _ = separateByZeros(names)
    v, st = imgui.Combo("тип частиц", currentParticesType, zeroseparated)
    if st then
        currentParticesType = ceil(v)
        for k, s in ipairs(names) do
            if k == v then
                print(k, s)
                return s
            end
        end
    end
    return 'default'
end
--]]

global str: string = ""

--[[
local function drawParticlesEditor()
    imgui.Begin(i18n('effecteditor'), false, "AlwaysAutoResize")
    local v: number
    local st: boolean
    --local str: string

    local particleType = selectParticleType()

    str, st = imgui.InputText('название типа', str, "")
    imgui.SameLine()
    if imgui.Button('добавить новый тип') then

    end

    --str, st = imgui.InputText('название типа', str, "None")

    --print('particleType', particleType)
    local psdef = particles[particleType]
    --v, st = imgui.SliderInt('скорость частиц', 0, -1, 1)

    local zeroseparated = separateByZeros({ "1", "2" })
    -- как рисовать картинку здесь выбираемого изображения?
    v, st = imgui.Combo('выбор картинки', activeImage - 1, zeroseparated)
    if st then
        print('v', v)
        activeImage = ceil(tonumber(v)) + 1
    end

    psdef.lifetime1, st = imgui.SliderInt('время жизни от', psdef.lifetime1, 0, 1000)
    psdef.lifetime2, st = imgui.SliderInt('время жизни до', psdef.lifetime2, 0, 1000)
    psdef.emissionRate, st = imgui.SliderInt('эмиссия', psdef.emissionRate, 0, 1000)
    psdef.sizeVariation, st = imgui.SliderFloat('вариации размера', psdef.sizeVariation, 0, 1)

    psdef.lineAcceleration[1], st = imgui.SliderInt('парам1', psdef.lineAcceleration[1], -100, 100)
    psdef.lineAcceleration[2], st = imgui.SliderInt('парам2', psdef.lineAcceleration[2], -100, 100)
    psdef.lineAcceleration[3], st = imgui.SliderInt('парам3', psdef.lineAcceleration[3], -100, 100)
    psdef.lineAcceleration[4], st = imgui.SliderInt('парам4', psdef.lineAcceleration[4], -100, 100)

    psdef.colors[1][1], st = imgui.SliderFloat('цвет красный 1', psdef.colors[1][1], 0, 1)
    psdef.colors[1][2], st = imgui.SliderFloat('цвет зеленый 1', psdef.colors[1][2], 0, 1)
    psdef.colors[1][3], st = imgui.SliderFloat('цвет голубой 1', psdef.colors[1][3], 0, 1)
    psdef.colors[1][4], st = imgui.SliderFloat('цвет прозрачности 1', psdef.colors[1][4], 0, 1)

    psdef.colors[2][1], st = imgui.SliderFloat('цвет красный 2', psdef.colors[2][1], 0, 1)
    psdef.colors[2][2], st = imgui.SliderFloat('цвет зеленый 2', psdef.colors[2][2], 0, 1)
    psdef.colors[2][3], st = imgui.SliderFloat('цвет голубой 2', psdef.colors[2][3], 0, 1)
    psdef.colors[2][4], st = imgui.SliderFloat('цвет прозрачности 2', psdef.colors[2][4], 0, 1)

    --
    psdef.emiterlifetimeexp = imgui.InputTextMultiline("emiterlifetimeexp", psdef.emiterlifetimeexp, 600, 400);

    imgui.End()
end
--]]

local function spawnHangar(pos: vector): Hangar
    local hangar = Hangar.new(pos)
    table.insert(hangars, hangar)
    return hangar
end

--[[
local tmpColumns = {
    true,
    false,
    false,
}
--]]

--[[
local function drawArenaPallete()
    imgui.Begin('арена', false, "AlwaysAutoResize")
    if imgui.Button('выгрузить на накопитель нжмд') then

    end
    if imgui.Button('подгрузить с на накопителя нжмд') then
    end
    if imgui.Button('включить режим кисти граней') then

    end
    if imgui.Button(i18n('inserhangarmode')) then
        mode = 'editor'
        setupBrush('Hangar')
    end
    if imgui.Button('отключить редектирование') then
        mode = 'normal'
    end

    if imgui.BeginTable('какая-то таблица', 5) then
        imgui.TableNextColumn(); 
        tmpColumns[1] = imgui.Checkbox("Огурец", tmpColumns[1])
        imgui.TableNextColumn()
        tmpColumns[2] = imgui.Checkbox("Томат", tmpColumns[2])
        imgui.TableNextColumn()
        tmpColumns[3] = imgui.Checkbox("Паштет", tmpColumns[3])
        imgui.EndTable()
    end

    imgui.End()
end
--]]

--[[
local function bindCameraControl()
    -- {{{
    -- не прямой а квадратичный зум?
    local cameraAnimationDuration = 0.2

    local type Return = function(sc: Shortcut): boolean, Shortcut
    --local function makeMoveFunction(xc: number, yc: number): Return
    local function makeMoveFunction(_: number, _: number): Return
        -- {{{
        return function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end

            --local reldx = cameraSettings.dx / cam.scale 
            --local reldy = cameraSettings.dy / cam.scale
            camTimer:during(cameraAnimationDuration, 
                --function(dt: number, time: number, delay: number)
                function(_: number, _: number, _: number)
                    --local dx = -reldx * (delay - time) * xc
                    --local dy = -reldy * (delay - time) * yc
                    --if delay - time > 0 then
                        --cam:move(dx * dt, dy * dt)
                    --end
                end,
                function()
                    --print("after camera moving")
                end)
            return true, sc
            --return false, sc
        end
        -- }}}
    end

    local bindMode: KeyConfig.BindType = "isdown"
    KeyConfig.bind(bindMode, { key = "left" }, makeMoveFunction(1., 0), 
        i18n("mcleft"), "camleft")
    KeyConfig.bind(bindMode, { key = "right" }, makeMoveFunction(-1.0, 0.), 
        i18n("mcright"), "camright")
    KeyConfig.bind(bindMode, { key = "up" }, makeMoveFunction(0., 1.), 
        i18n("mcup"), "camup") 
    KeyConfig.bind(bindMode, { key = "down" }, makeMoveFunction(0., -1.), 
        i18n("mcdown"), "camdown")

    KeyConfig.bind("keypressed", { key = "c" }, 
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end
            --moveCameraToTank(playerTank)
            return false, sc
        end, 
        i18n("cam2tank"), "cam2tank")
    -- }}}
end
--]]

--[[
local function bindKonsole()
    -- {{{
    KeyConfig.bind("keypressed", { key = "`" }, 
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end
            --linesbuf.show = not linesbuf.show
            return false, sc
        end
    )
    -- }}}
end
--]]

--[[
-- Сомнительная функция, не работает наверное.
local function bindEscape()
    -- {{{
    KeyConfig.bind("keypressed", { key = "escape" }, 
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end
            if showLogo == true then
                print('your pressed Escape. exit to system')
                love.event.quit()
            else
                showLogo = true
            end
            return false, sc
        end
    )
    -- }}}
end
--]]

function printBody(body: love.physics.Body)
    -- {{{
    print(">>>>>>>>")
    print("mass:", body:getMass())
    local x, y = body:getWorldCenter()
    x, y = x * M2PIX, y * M2PIX
    print("getWorldCenter() x, y in pixels", x, y)
    print("getAngle()", body:getAngle())
    print(">>>>>>>>")
    -- }}}
end

    --[[
local function render_tank_base()
    --current_part = 'base_first_render'

    --cm.eachSpaceBody(bodyIter_base)

    --eachBody_base(nil)

    --cm.cpSpaceEachBody(cur_space, bodyIter_base, nil)
    call_counter = call_counter + 1
    print('call_counter', call_counter)

    --cm.cpSpaceEachBody(cur_space, FUNC)
    --pw.for_each_body(cur_space, bodyIter_base)

    --pipeline:open('base_shape')
    --pipeline:push('flush')
    --pipeline:close()
end
--]]

--jitoptions.on()

--[[
local function render_tank_turret()
    --current_part = 'base_first_render'
    pipeline:open('turret_shape')
    --cm.eachSpaceBody(bodyIter_turret)
    pipeline:push('flush')
    pipeline:close()
end
--]]

local function on_each_body(x: number, y: number, angle: number, obj: any)
    local tank = obj as Tank
    if tank then
        pipeline:push('new', tank.id, x, y, angle)
    end
    --print('lua: on_each_body')
    --print('id, x, y, angle', tank.id, x, y, angle)
    --print('tank.id', tank.id)
end

local function renderInternal()
    pipeline:openAndClose('clear')

    -- установка камеры
    camera:setTransform()

    --print("------ query ---------")
    --pipeline:open('base_shape')

    --wrp.query_all_tanks(
        --function(x: number, y: number, angle: number, obj: any)
            --local tank = obj as Tank
            --print('processed', tank.id)
        --end
    --)
    --pipeline:push('flush')
    --pipeline:close()
    --print("--------------------------")

    --print("------ query ---------")
    pipeline:open('base_shape')
    --wrp.query_all_shapes(on_each_body)
    wrp.query_all_tanks(on_each_body)
    pipeline:push('flush')
    pipeline:close()
    --print("--------------------------")

    pipeline:open('border_segments')
    --pipeline:push("draw", 0, 100, 1000, 1000)
    --pipeline:push("draw", 0, 0, 2000, 4000)
    --pipeline:push("draw", 400, 1100, 1000, 1000)

    wrp.draw_static_segments(
        function(x1: number, y1: number, x2: number, y2:number)
            pipeline:push('draw', x1, y1, x2, y2)
        end
    )
    pipeline:push('flush')
    pipeline:close()

    local player_x, player_y: number, number

    if playerTank then
        pipeline:open('selected_object')
        local body = playerTank.base
        player_x, player_y = wrp.get_position(body)
        --print('selected object:', player_x, player_y)
        pipeline:push(wrp.get_position(body))
        pipeline:close()
    else
        error('Player should not be nil')
    end
    --]]

    pipeline:openAndClose('main_axises')

    -- сброс трансформации камеры
    camera:setOrigin()

    pipeline:open('lines_buf')
    print_io_rate()
    camera:push2lines_buf()
    local msg = sformat("player pos (%.3f, %.3f)", player_x, player_y)
    pipeline:push("add", "player_pos", msg)
    pipeline:push('flush')
    pipeline:close()

    camera:draw_axises()
end

local function renderScene()
    -- Ограничение кадров в секунду до 60
    local nt = love.timer.getTime()
    local fps_limit = 1. / 300.
    local diff = nt - last_render

    if diff >= fps_limit then
        last_render = nt
        renderInternal()
        pipeline:sync()
    end
end

local function updateTanks()
    -- {{{
    local alive: {Tank} = {}
    for _, tank in ipairs(tanks) do
        local t =  tank:update()
        if t then
            table.insert(alive, t)
        else
            print('---------------')
        end
    end
    tanks = alive
    -- }}}
end

local lastPosX, lastPosY: number, number

--[[
local function backspaceCmdLine()
    -- {{{
    local u8 = require "utf8"
    -- get the byte offset to the last UTF-8 character in the string.
    local byteoffset = u8.offset(cmdline, -1)
    if byteoffset then
        -- remove the last UTF-8 character.
        -- string.sub operates on bytes rather than UTF-8 characters, 
        -- so we couldn't do string.sub(text, 1, -2).
        cmdline = string.sub(cmdline, 1, byteoffset - 1)
        if cursorpos - 1 >= 1 then
            cursorpos = cursorpos - 1
        end
    end
    -- }}}
end
--]]

--local function enterCommandMode()
--end

--[[
local function leaveCommandMode()
    -- {{{
    print("command mode disabled.")
    mode = "normal"
    love.keyboard.setKeyRepeat(false)
    love.keyboard.setTextInput(false)
    cmdline = ""
    -- }}}
end
--]]

--[[
function attach(varname: string)
    if type(varname) == "string" then
        attachedVarsList[varname] = function()
            local ok, errmsg: boolean, string = pcall(function()
                local l = (_G as {any:any})[varname]
                local output = tabular.show2(l)
                if output then 

                else

                end
            end)
            if not ok then
                print("attach callback error:", errmsg)
                print('attach removed')
                attachedVarsList[varname] = nil
            end
        end
    end
end
--]]

--[[
function detach(varname: string)
    if type(varname) == "string" then
        attachedVarsList[varname] = nil
    end
end
--]]

--[[
local function evalCommand()
    -- {{{

    -- {{{ preload
    local path = SCENE_PREFIX .. '/eval_preload.lua'
    local content = love.filesystem.read(path)
    if not content then
        error('Could not load: ' .. path)
    end

    local preload = content
    -- }}}

    cmdline = trim(cmdline)
    local func, loaderrmsg: function, string = load(preload .. cmdline)
    --local time = 2

    --TODO в обработке ошибок искать ]:1: и обрезать сообщение об ошибке.
    if not func then
        --linesbuf:push(time, "load() errmsg: " .. loaderrmsg)
        print("load() errmsg:|" .. loaderrmsg .. "|")
    else
        local ok, pcallerrmsg: boolean, string = pcall(function()
            func()
        end)
        if not ok then
            --linesbuf:push(time, "pcall() errmsg: " .. pcallerrmsg)
            print("pcall() errmsg:|" .. pcallerrmsg .. "|")
        end
    end
    --local trimmed = trim(cmdline) or ""
    if #cmdline ~= 0 then
        table.insert(cmdhistory, cmdline)
        love.filesystem.append(historyfname, cmdline .. "\n")
    end
    --suggestList = nil
    -- }}}
end
--]]

--local cmdhistoryIndex = 0

--[[
local function setPreviousCommand()
    -- {{{
    if #cmdhistory ~= 0 then
        if cmdhistoryIndex - 1 < 1 then
            cmdhistoryIndex = #cmdhistory
        else
            cmdhistoryIndex = cmdhistoryIndex - 1
        end
        cmdline = cmdhistory[cmdhistoryIndex]
        cursorpos = #cmdline + 1
    end
    -- }}}
end
--]]

--[[
local function setNextCommand()
    -- {{{
    if #cmdhistory ~= 0 then
        if cmdhistoryIndex + 1 > #cmdhistory then
            cmdhistoryIndex = 1
        else
            cmdhistoryIndex = cmdhistoryIndex + 1
        end
        cmdline = cmdhistory[cmdhistoryIndex]
        cursorpos = #cmdline + 1
    end
    -- }}}
end
--]]

--[[
local function processCommandModeKeys(key: string)
    -- {{{
    if key == "backspace" then
        backspaceCmdLine()
    elseif key == "tab" then
        print('tab pressed.')
        suggestCompletion()
    elseif key == "escape" then
        leaveCommandMode()
    elseif key == "return" then
        evalCommand()
    elseif key == "up" then
        setPreviousCommand()
    elseif key == "down" then
        setNextCommand()
    elseif key == "left" then
        if cursorpos - 1 >= 1 then
            cursorpos = cursorpos - 1
        end
        print('left')
    elseif key == "right" then
        if cursorpos <= #cmdline then
            cursorpos = cursorpos + 1
        end
        print('right')
    elseif key == "home" then
        cursorpos = 1
        print('home')
    elseif key == "end" then
        cursorpos = #cmdline
        print('end')
    end
    -- }}}
end
--]]

local function keypressed(key: string)
    -- {{{
    print('keypressed', key)

    --[[
    if showLogo then
        showLogo = false
        print("showLogo", showLogo)
    end

    if mode == "command" then
        processCommandModeKeys(key)
    else
        if key == ";" and love.keyboard.isDown("lctrl") then
            enterCommandMode()
        end
    end
    --]]

    -- }}}
end

--[[
local function bindKonsoleCameraZoomKeys()
    -- {{{
    local ids = {
        KeyConfig.bind(
            "isdown",
            { mod = { "lshift" },
                key = "z" },
            function(sc: Shortcut): boolean, Shortcut
                if mode ~= "normal" then
                    return false, sc
                end

                --if konsoleCam.scale < camZoomHigher then
                    --konsoleCam:zoom(1. + zoomSpeed)
                --end

                return false, sc
            end,
            "zoom camera in",
            "zoomin"
        ),
        KeyConfig.bind(
            "isdown",
            { key = "x" },
            function(sc: Shortcut): boolean, Shortcut
                if mode ~= "normal" then
                    return false, sc
                end

                --if konsoleCam.scale > camZoomLower then
                    --konsoleCam:zoom(1.0 - zoomSpeed)
                --end

                return false, sc
            end,
            "zoom camera out",
            "zoomout"
        ),
    }
    cameraKeyConfigIds = {}
    for _, v in ipairs(ids) do
        table.insert(cameraKeyConfigIds, v)
    end
    print('bindKonsoleCameraZoomKeys')
    -- }}}
end
--]]

--[[
local function bindCameraZoomKeys()
    -- {{{
    local ids = {
        KeyConfig.bind(
            "isdown",
            { key = "z" },
            function(sc: Shortcut): boolean, Shortcut
                if mode ~= "normal" then
                    return false, sc
                end

                --if cam.scale < camZoomHigher then
                    --cam:zoom(1. + zoomSpeed)
                --end

                return false, sc
            end,
            "zoom camera in",
            "zoomin"
        ),
        KeyConfig.bind(
            "isdown",
            { key = "x" },
            function(sc: Shortcut): boolean, Shortcut
                if mode ~= "normal" then
                    return false, sc
                end

                --if cam.scale > camZoomLower then
                    --cam:zoom(1.0 - zoomSpeed)
                --end

                return false, sc
            end,
            "zoom camera out",
            "zoomout"
        ),
    }
    cameraKeyConfigIds = {}
    for _, v in ipairs(ids) do
        table.insert(cameraKeyConfigIds, v)
    end
    print('bindCameraZoomKeys')
    -- }}}
end
--]]

local function bindFullscreenSwitcher()
    -- {{{
    KeyConfig.bind(
        "keypressed", 
        { key = "f11" }, 
        function(sc: KeyConfig.Shortcut): boolean, KeyConfig.Shortcut
            local isfs = love.window.getFullscreen()
                --diamondSquare:draw2canvas()
            if isfs then
                --setWindowMode()
            else
                --setFullscreenMode()
            end
            return false, sc
        end,
        "switch fullscreen and windowed modes", 
        "switchwindowmode")
    -- }}}
end

local function initRenderCode()
    -- {{{

    -- рисовать ортогональные оси координат в левом верхнем углу экрана
    pipeline:pushCode("main_axises", [[
    local col = {0.3, 0.5, 1, 1}
    while true do
        local size = 1000
        --love.graphics.setColor(col)
        love.graphics.setColor {0, 0, 0, 1}
        local rad = 100
        love.graphics.circle("line", 0, 0, rad)
        love.graphics.line(0, size, 0, -size)
        love.graphics.line(-size, 0, size, 0)
        coroutine.yield()
    end
    ]])

    -- Буфер для вывода отладочной информации в левом верхнем углу экрана.
    pipeline:pushCodeFromFile('lines_buf', 'lines_buf.lua')
    -- Буфер для вывода отладочной информации при наведении на физическое тело.
    pipeline:pushCodeFromFile('phys_object_lines_buf', 'lines_buf.lua')

    -- Рисование прозрачного прямоугольника над определенным телом.
    pipeline:pushCode('selected_object', [[
    -- жесткие значения ширины и высоты, как проверить что они соответствуют
    -- действительным?
    local width, height = 256, 256

    local x, y, angle: number
    local gr = love.graphics
    while true do
        x = graphic_command_channel:demand() as number
        y = graphic_command_channel:demand() as number
        angle = graphic_command_channel:demand() as number

        gr.push()
        gr.translate(x, y)
        gr.rotate(angle)
        gr.translate(-width / 2, -height / 2)

        gr.setColor {0, 0.5, 1, 0.3}

        --gr.setColor {1, 1, 1, 1}

        gr.rectangle('fill', 0, 0, width, height)
        --gr.draw(texture, quad, 0, 0, width, height)
        --gr.draw(texture, quad, 0, 0)

        gr.pop()

        coroutine.yield()
    end
    ]])

    -- Очистка экрана
    pipeline:pushCode('clear', [[
    while true do
        love.graphics.clear{0.5, 0.5, 0.5}
        coroutine.yield()
    end
    ]])

    -- Установить трансформацию
    pipeline:pushCode('set_transform', [[
    local gr = love.graphics
    local yield = coroutine.yield
    while true do
        gr.applyTransform(graphic_command_channel:demand())
        yield()
    end
    ]])

    -- Сброс трансформации
    pipeline:pushCode('origin_transform', [[
    local gr = love.graphics
    local yield = coroutine.yield
    while true do
        gr.origin()
        yield()
    end
    ]])

    -- Рисование физических тел.
    pipeline:pushCodeFromFile("base_shape", 'poly_shape.lua')
    -- Рисование физических тел.
    pipeline:pushCodeFromFile("turret_shape", 'poly_shape.lua')

    -- Рисование линий физических сегментов используемых для ограничения 
    -- игрового поля.
    pipeline:pushCode('border_segments', [[
    local yield = coroutine.yield
    local linew = 6
    while true do
        local cmd: string
        
        local oldlw = love.graphics.getLineWidth()
        love.graphics.setLineWidth(linew)
        repeat
            cmd = graphic_command_channel:demand() as string

            if cmd == "draw" then
                local x1, y1, x2, y2: number, number, number, number
                x1 = graphic_command_channel:demand() as number
                y1 = graphic_command_channel:demand() as number
                x2 = graphic_command_channel:demand() as number
                y2 = graphic_command_channel:demand() as number

                love.graphics.setColor {0, 0, 0, 1}
                love.graphics.line(x1, y1, x2, y2)
                --print(x1, y1, x2, y2)

            elseif cmd == 'flush' then
                break
            else
                error('unkonwn command: ' .. cmd)
            end

        until not cmd
        love.graphics.setLineWidth(oldlw)

        yield()
    end
    ]])

    -- }}}
end

-- Инициализация параметрами объектов-корутин на стороне главного потока.
local function initPipelineObjects()
    pipeline:open('base_shape')
    pipeline:push(base_tex_fname, tank_width, tank_height)
    --[[
    Пиксели для вырезки
    82*108
    86(?), 74
    --]]
    pipeline:close()

    pipeline:open('turret_shape')
    pipeline:push(turret_text_fname, tank_width, tank_height)
    --[[
    Пиксели для вырезки
    52*159
    102, 1
    --]]
    pipeline:close()

    --pipeline:openPushAndClose('lines_buf', "DejaVuSansMono.ttf", 40)
    pipeline:openPushAndClose('lines_buf', "DejaVuSansMono.ttf", 24)
    pipeline:openPushAndClose('phys_object_lines_buf', "DejaVuSansMono.ttf", 24)

    pipeline:sync()

    pipeline:openPushAndClose(
        'lines_buf',                -- coroutine object name
        "add",                      -- object command
        'hi',                       -- message id
        "привет из недр движка",    -- message(payload)
        "flush"                     -- render buffer and break waiting cycle
    )
end

--[[
local function eachShape_base(b: cm.cpBody, shape: cm.cpShape)
    --debug_print('phys', 'eachShape call')
    --print('phys', 'eachShape call')

    local shape_type = getShapeType(shape)

    if shape_type == cm.CP_POLY_SHAPE then

        --local body_wrap = pw.cpBody2Body(b)
        local tank = getUserData(b) as Tank

        if not tank then
            error("tank is nil")
        end

        local posx, posy = b.p.x, b.p.y
        local angle = b.a

        if tank.base_first_render then
            pipeline:push('new', tank.id, posx, posy, angle)

            -- первоначальная установка значений положения и угла
            tank.px, tank.py = posx, posy
            tank.angle = angle

            tank.base_first_render = false

            --tank.prev_posx = body_wrap.body.p.x
            --tank.prev_posy = body_wrap.body.p.y

        else
            local newx, newy = b.p.x, b.p.y
            local new_angle = b.a

            local px_diff, py_diff = abs(newx - tank.px), abs(newy - tank.py)
            local angle_diff = abs(new_angle - tank.angle)

            --print('px_diff, py_diff', px_diff, py_diff)
            --print('angle_diff', angle_diff)

            -- как может накапливаться ошибка?
            local pos_epsilon, angle_epsilon = 0.05, 0.05

            local pos_part = px_diff > pos_epsilon and py_diff > pos_epsilon 
            local angle_part = angle_diff > angle_epsilon

            --print('pos_part', pos_part)
            --print('angle_part', angle_part)

            if pos_part or angle_part then
                pipeline:push('new', tank.id, posx, posy, angle)

                --print('new')
                --if pos_part and angle_diff < epsilon then
                --pipeline:push('draw', tank.id)
                --print('using drawing cache')

                tank.px, tank.py = b.p.x, b.p.y
                tank.angle = b.a
            else

                --print('none')
                --print('os.exit(100)')
                --os.exit(100)
                --tank.first_render = true

            end

            --tank.px, tank.py = b.p.x, b.p.y
            --tank.angle = b.a

        end
    end
end
--]]

local space: Wrapper.Space

local function init()
    -- {{{
    print('init started')

    metrics.init()

    --pw.init(pipeline)
    --cur_space = cm.cpSpaceNew()
    space = wrp.init_space()
    print('space', space)

    initJoy()
    initRenderCode()
    initPipelineObjects()

    -- требует инициализации после создания объекта pipeline
    camera = Camera.new()

    --loadLocales()

    --logo = Logo.new()

    --bindCameraZoomKeys()
    --bindKonsoleCameraZoomKeys()
    --bindCameraControl()
    bindFullscreenSwitcher()
    --bindEscape()
    --bindKonsole()
    --bindTerrainControlKeys()
    --bindDeveloperKeys()

    screenW, screenH = pipeline:getDimensions()
    print('screenW, screenH', screenW, screenH)
 
    arena = Arena.new("arena.lua")
    --terrain()
    local corners = getTerrainCorners()
    if corners then
        for _, c in ipairs(corners) do
            spawnHangar(c)
        end
    end

    -- }}}
    last_render = love.timer.getTime()
    print('init finished')
end

local function quit()
    -- {{{
    metrics.quit()
    tanks = {}
    --writeParticles(particlesfname)
    -- }}}
end

local function mousemoved(x: number, y: number, dx: number, dy: number)
    metrics.mousemoved(x, y, dx, dy)

    local absx, absy = camera.x, camera.y
    print('absx, absy', absx, absy)
    wrp.get_shape_under_point(x + absx, y + absy, 
        function(
            shape: Wrapper.Shape,
            x: number,
            y: number,
            distance: number,
            gradx: number,
            grady: number
        )

        print('on get_shape_under_point()')
        print('shape', shape)
        print('point', x, y)
        print('distance', distance)
        print('gradient', gradx, grady)

        --[[
        pipeline:openPushAndClose(
            'phys_object_lines_buf',
            "add",
            1,
            tostring(shape),
            "flush"
        )
        --]]

    end)

    --if mode == 'editor' then
        --arena:mousemoved(x, y, dx, dy)
    --end
end

local function wheelmoved(x: number, y: number)
    metrics.wheelmoved(x, y)
end

--[[
Сделать передвижение камеры по зажатию средней клавиши мыши.
--]]
local function mousepressed(x: number, y: number, btn: integer)
    -- {{{
    metrics.mousepressed(x, y, btn)
    -- }}}
end

local function updateJoyState()
    joyState:update()
    if joyState.state and joyState.state ~= "" then
        debug_print('joy', joyState.state)
    end
end

local function process_events()
    local events = event_channel:pop() as {any}
    if events then
        for _, e in ipairs(events) do
            local evtype: string = (e as {string})[1]
            if evtype == "mousemoved" then

                local x, y = (e as {number})[2], (e as {number})[3]
                local dx, dy = (e as {number})[4], (e as {number})[5]
                mousemoved(x, y, dx, dy)

            elseif evtype == 'wheelmoved' then

                local x, y = (e as {number})[2], (e as {number})[3]
                wheelmoved(x, y)

            elseif evtype == "keypressed" then
                local key = (e as {string})[2]
                local scancode = (e as {string})[3]

                local msg = '%{green}keypressed '
                debug_print('input', colorize(msg .. key .. ' ' .. scancode))

                dprint.keypressed(scancode)

                if scancode == "escape" then
                    is_stop = true
                    debug_print('input', colorize('%{blue}escape pressed'))
                    break
                end

                -- Использовать scancode или key?
                keypressed(scancode)

                --msg = '%{yellow}keypressed '
                --print(colorize(msg .. key .. ' ' .. scancode))

            elseif evtype == "mousepressed" then

                --local x: number = (e as {number})[2]
                --local y: number = (e as {number})[3]
                --local button: number = (e as {number})[4]
                --local istouch: boolean = (e as {boolean})[5]
                --local presses: number = (e as {number})[6]
                local x, y = (e as {number})[2], (e as {number})[3]
                local btn = (e as {integer})[4]
                mousepressed(x, y, btn)

            elseif evtype == "joystickpressed" then
                local joystick = (e as {number})[2] as Joystick
                local button = (e as {number})[3]

                print('joystick', inspect(joystick))
                print('button', inspect(button))

                local left_shift = 5
                local right_shift = 6

                --if joystick:isDown(right_shift) then
                if button == left_shift then
                    print("moveToOrigin()")
                    camera:moveToOrigin()
                end
                if button == right_shift then
                    print("moveToPlayer()")
                    camera:moveToPlayer()
                end
            end
        end
    end
end

local enum State 
    'garage'
    'map'
end

local state: State = 'map'

-- не добавляет в таблицу рисовки на стороне потока рендера
local function spawnTank(px: number, py: number): Tank
    local tank = Tank.new(vec2(px, py))
    table.insert(tanks, tank)
    local px, py, angle = wrp.get_position(tank.base)
    tank._prev_x, tank._prev_y = px, py
    pipeline:openPushAndClose(
        'base_shape',
        'new', 
        tank.id, 
        px, py, angle, 
        "flush"
    )
    return tank
end

local function spawnPlayer()
    playerTank = spawnTank(-20, -20)
end

local record Borders
    x1: number
    y1: number
    x2: number
    y2: number
end

-- границы в которых создаются танки
local borders: Borders = {}

--[[
Задача: написать модуль, встроенный в бинарный файл love, для замены
pipeline.tl
--]]
--local pp = require "mtpipeline"
--pp.init()
--pp.free()

local function spawnTanks()

    --[[
    Если больше 150 объектов, то начинается периодическое мелькание.
    Расчитать количество передаваемых данных за кадр и в среднем за секунду
    которое приводит к мельканию.
    --]]
    local tanks_num = 5
    --local tanks_num = 10

    local minx, maxx = 0, 4000
    local miny, maxy = 0, 4000

    borders.x1, borders.y1 = minx, miny
    borders.x2, borders.y2 = maxx, maxy

    -- информация о танчиках записывается в таблицу на стороне потока рисования
    -- что-бы позже передавать данные только от изменивших положение объектах
    --pipeline:open('base_shape')
    for _ = 1, tanks_num do
        local px, py = rng:random(minx, maxx), rng:random(miny, maxy)
        local tank = spawnTank(px, py)
    end
    --pipeline:push('enough')
    --pipeline:close()
end

local function applyInput(j: Joystick)
    local left, right, up, down = 3, 2, 4, 1

    if j and playerTank then
        local body = playerTank.base

        local px, py = 0, 0
        local amount = 100

        -- FIXME Если прикладывать слишком большой импульс, то объект пролетает
        -- за заграждение в виде EdgeShape
        if j:isDown(right) then
            wrp.apply_impulse(body, amount, 0, px, py);
        elseif j:isDown(left) then
            wrp.apply_impulse(body, -amount, 0, px, py);
        elseif j:isDown(up) then
            wrp.apply_impulse(body, 0, -amount, px, py);
        elseif j:isDown(down) then
            wrp.apply_impulse(body, 0, amount, px, py);
        end

    end
end

local function spawnBorders()
    local b = borders
    local space = 5000
    wrp.new_static_segment(b.x1 - space, b.y1 - space, b.x2 + space, b.y1 - space)
    wrp.new_static_segment(b.x2 + space, b.y1 - space, b.x2 + space, b.y2 + space)
    wrp.new_static_segment(b.x2 + space, b.y2 + space, b.x1 - space, b.y2 + space)
    wrp.new_static_segment(b.x1 - space, b.y2 + space, b.x1 - space, b.y1 - space)
end

local stateCoro: thread = coroutine.create(function(dt: number)

    spawnTanks()
    spawnBorders()
    spawnPlayer()

    while true do
        if state == 'map' then
            process_events()
            renderScene()
            updateTanks()

            ------------ UPDATE HERE PLEASE ------------ 
            --arena:update()

            camera:checkInput(joy)
            camera:update(dt)

            -- шаг физики
            wrp.step(dt);

            --[[
            Почему тела не расталкиваются?
            Мигания рендера
            --]]
    
            applyInput(joy)
            updateJoyState()

            dt = yield() as number
        elseif state == 'garage' then
            --coroutine.yield()
        end
        --print('state', state)
    end
end)

local function mainloop()
    local last_time = love.timer.getTime()
    while not is_stop do
        local now_time = love.timer.getTime()
        local dt = now_time - last_time
        last_time = now_time

        local ok, errmsg = resume(stateCoro, dt) as (boolean, string)
        if not ok then
            error('stateCoro: ' .. errmsg)
        end

        local timeout = 0.0001
        love.timer.sleep(timeout)
    end
end

--[[
-- {{{ BulletPool prototype
local record BulletPool
    new: function(BulletPool, num: integer): BulletPool
    spaw: function(x: number, y: number): Bullet
end

function BulletPool.new(num: integer): BulletPool
    local BulletPool_mt: metatable<BulletPool> = {
        __index = BulletPool,
    }
    local self = setmetatable({} as BulletPool, BulletPool_mt)
    return self
end
-- }}}
--]]

init()
mainloop()

if is_stop then
    quit()
    print('space', space)
    wrp.free_space(space)
    main_channel:push('quit')
    debug_print('thread', 'Thread resources are freed')
end

debug_print('thread', colorize('%{yellow}<<<<<%{reset} t80 finished'))
