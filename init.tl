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

print('love.filesystem.getRequirePath()', love.filesystem.getRequirePath())

-- {{{ require
require 'konstants'
require 'joystate'
require 'pipeline'
require "common"
require "keyconfig"

local IMGUI = false
if love.system.getOS() == 'Linux' then
    require "imgui"
    IMGUI = true
end

--require 'render'
--require 'profi'
require "love"

--require 'moonshine'
--local tween = require 'tween'
--local camMoveTween = tween.new()
--local moonshine = require 'moonshine'

local sformat = string.format
local inspect = require "inspect"
local serpent = require 'serpent'
local i18n = require "i18n"
local metrics = require "metrics"
local vec2 = require "vector"
local vecl = require "vector-light"
local tabular = require "tabular"
local pw = require "physics_wrapper"
local Cm = require 'chipmunk'
-- }}}

local pipeline = Pipeline.new(SCENE_PREFIX)

-- рисование стрелочек
local arrow = require 'arrow'
arrow.init(pipeline)

--print('love.graphics', inspect(love.graphics))

local Shortcut = KeyConfig.Shortcut

--local abs, pow, sqrt = math.abs, math.pow, math.sqrt
--local yield, resume = coroutine.yield, coroutine.resume
--local yield = coroutine.yield

local enum Mode
    "normal"
    "command"
    "editor"
end

--[[
local enum Brush
    "None" -- ничего не рисовать
    "Hangar"
end
--]]

local enum ObjectType
    "Arena"
    "Base"
    "Bullet"
    "Hangar"
    "Turret"
end

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

    --physbody: lp.Body
    objectType: ObjectType

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
    objectType: ObjectType
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

    record Options
        body_opts: pw.Options
    end

    -- {{{
    first_render: boolean

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

    body: pw.Body

    -- пушка
    --turret: Turret

    -- ходовая часть
    --base: Base

    -- абсолютные координаты в пикселях
    new: function(pos: vector, options: Options): Tank

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
    barrelCategories: integer
    barrelMask: integer
    barrelGroup: integer
    towerCategories: integer
    towerMask: integer
    towerGroup: integer

    filterdata: {FilterData}
    --physbody: love.physics.Body
    --tankphysbody: lp.Body
    --fixtureBarrel: love.physics.Fixture
    --fixtureTower: love.physics.Fixture

    --barrelShape: lp.PolygonShape
    --towerShape: lp.PolygonShape

    objectType: ObjectType
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
    physbody: love.physics.Body
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

--[[
local type CameraSettings = record
    -- {{{
    dx: number
    dy: number
    -- }}}
end
--]]

-- {{{ Global and local variables.

-- Указатель на текущий подсвеченный навигатором танк.
--local currentNavigator: Tank

local bodyIter: pw.EachSpaceBodyIter
local shapeIter: pw.EachBodyShapeIter

local bodyIter_verts: pw.EachSpaceBodyIter
local shapeIter_verts: pw.EachBodyShapeIter

-- максимальное количество частиц
global maxParticlesNumber = 512

global notificationDelay = 2.5

-- Размеры экрана по-умолчанию(начальное положение)
--global DEFAULT_W, DEFAULT_H = 1024, 768
global DEFAULT_W, DEFAULT_H = nil, nil

-- Размеры экрана
--global W, H = love.graphics.getDimensions()

--global W, H = pipeline:getDimensions()
--print("W, H", W, H)

--[[ Танк длиной пять метров имеет отображаемый размер 50 пикселей
коэффициент на который домножаю при переводе из метров в пиксели --]]
global M2PIX = 10

-- коэффициент на который домножаю при переводе из пикселей в метры
global PIX2M = 1 / 10

--local tankCollisionGroup = 1
--local bulletCollisionGroup = -1
-- Пули не сталкиваются с танками
--local bulletMask = 1

-- Множитель передачи импульса на шасси танка.
global tankForceScale = 8

-- {{{ Konsole editing
local historyfname = "cmdhistory.txt"

global mode: Mode = "normal"
global cmdline: string = ""
local cmdhistory: {string} = {}
global cursorpos: integer = 1
--global suggestList: List = List.new()
-- список имен переменных для отображения в консоли
global attachedVarsList: {string: function} = {}
-- }}}

-- верхний список отрисовки, рисуется после рисования пачки танков
--local drawlistTop: {DrawNode} = {}
-- нижний список отрисовки, рисуется после подложки, но до пачек танков
--local drawlistBottom: {DrawNode} = {}

require "Timer"

-- используется для анимации масштабирования камеры
local camTimer: Timer = require "Timer".new()
local camera: love.math.Transform = love.math.newTransform()

--local drawCoro: thread = nil
global showLogo = true
-- идентификаторы клавиш управления танком игрока
global playerTankKeyconfigIds: {integer} = {}
-- множитель углового импулься
global angularImpulseScale = 5 * math.pi / 4
-- минимальный и максимальные порог масштаба камеры
global camZoomLower, camZoomHigher = 0.075, 3.5

-- скорость изменения масштаба камеры
--[[
local zoomSpeed = 0.01
local cameraSettings: CameraSettings = {
    -- значение в пикселях
    dx = 2000, dy = 2000,
}
--]]

-- Все танки, в том числе и тот, которым управляет игрок.
global tanks: {Tank} = {}
global hangars: {Hangar} = {}
-- Танк, которым управляет игрок
global playerTank: Tank

-- Подложка
--global background: Background

-- Логотип, картинка или главное меню?
require 'logo'
--local logo: Logo

-- Все снаряды вырущенные из танков, пока не уничтоженные
--global bullets: {Bullet} = {}
-- Радиус снаряда пушки в пикселях
--local bulletRadius = 4
--local bulletColor = {0.1, 0.1, 0.1, 1}
-- Продолжительность жизни снаряда в секундах.
--global bulletLifetime = 35

-- Счетчик живый танков
local tankCounter = 0

local rng: love.math.RandomGenerator = love.math.newRandomGenerator()

--rng:setSeed(os.time())

require 'diamondsquare'
--local diamondSquare: DiamonAndSquare

--local loadCannonSound = Audio.newSource(SCENE_PREFIX .. "/load.wav", 'static')
--local audMainTheme = Audio.newSource(SCENE_PREFIX .. "/audio/Lime of Adventure.mp3", 'static')

local drawTerrain = true

global maxTrackCount = 128
global hits: {Hit} = {}
--local coroutines: {thread} = {}

local event_channel = love.thread.getChannel("event_channel")
local main_channel = love.thread.getChannel("main_channel")

local is_stop = false
local last_render: number = love.timer.getTime()
-- }}}

local joystick = love.joystick
local joyState: JoyState
--local joys: {joystick.Joystick} = {}
local joy: joystick.Joystick

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

--[[
local function updateCoroutines()
    -- {{{
    local alive: {thread} = {}
    for _, coro in ipairs(coroutines) do
        if coroutine.status(coro) ~= 'dead' then
            local ok, errmsg = coroutine.resume(coro) as boolean, string
            if ok then
                table.insert(alive, coro)
            else
                print('coro error:', errmsg)
            end
        end
    end
    coroutines = alive
    -- }}}
end
--]]

function Bullet.new(px: number, py: number, dirx: number, diry: number, 
    tankId: integer): Bullet
    -- {{{
    local Bullet_mt: metatable<Bullet> = {
        __index = Bullet,
    }
    local self: Bullet = setmetatable({} as Bullet, Bullet_mt)

    --self.physbody = love.physics.newBody(physworld, px, py, "dynamic")
    --self.physbody:setUserData(self)
    --self.physbody:setBullet(true)

    self.timestamp = love.timer.getTime()
    self.died = false
    self.px = px
    self.py = py
    --local shape = love.physics.newCircleShape(0, 0, bulletRadius * PIX2M)
    --love.physics.newFixture(self.physbody, shape as lp.Shape)

    --fixture:setGroupIndex(bulletCollisionGroup)
    --fixture:setMask(bulletMask)

    self.physbody:setMass(1)
    local impulse = 100
    if dirx and diry then
        self.physbody:applyLinearImpulse(dirx * impulse, diry * impulse)
    end
    --bullet.body:resetMassData()
    self.dir = vec2.new(dirx, diry)
    self.id = tankId or 0
    self.objectType = 'Bullet'

    return self
    -- }}}
end

local function gather_verts(shape: Cm.cpShape): {number}
    local num = pw.polyShapeGetCount(shape)
    local verts = {}
    for i = 0, num - 1 do
        local vert = pw.polyShapeGetVert(shape, i)
        table.insert(verts, vert.x)
        table.insert(verts, vert.y)
    end
    return verts
end

local function print_io_rate()
    local bytes = pipeline:get_received_in_sec()
    local msg = sformat("received_in_sec = %d", math.floor(bytes / 1024))
    pipeline:open('formated_text')
    pipeline:push(msg)
    pipeline:push(0)
    pipeline:push(140)
    pipeline:close()
end

local function eachBody_verts(b: Cm.cpBody)
    local body = pw.cpBody2Body(b)
    if body then
        pw.eachBodyShape(b, shapeIter_verts)
    else
        error('Body is nil:' .. debug.traceback())
    end
end

local function eachBody(b: Cm.cpBody)
    local body = pw.cpBody2Body(b)
    if body then
        pw.eachBodyShape(b, shapeIter)
    else
        error('Body is nil:' .. debug.traceback())
    end
end

--[[
local function contactFilter(fix1: lp.Fixture, fix2: lp.Fixture): boolean
    -- {{{
    --print('contactFilter', fixture1, fixture2)
    local collide = true
    local objectType1: ObjectType
    local objectType2: ObjectType
    local userdata1, userdata2: {string: any}, {string: any}

    if fix1 then
        userdata1 = fix1:getBody():getUserData() as {string:any}
        if userdata1 then
            objectType1 = userdata1['objectType'] as ObjectType
            --print("fixture1 userdata", userdata1['objectType'])
        end
    end
    if fix2 then
        userdata2 = fix2:getBody():getUserData() as {string:any}
        if userdata2 then
            --print(inspect(userdata2))
            objectType2 = userdata2['objectType'] as ObjectType
            --print("fixture2 userdata", userdata2['objectType'])
        end
    end

    --print('objects are here', inspect(objectType1), inspect(objectType2))

    if objectType1 and objectType2 then
        if objectType1 == 'Base' and objectType2 == 'Turret' then
            local id1 = userdata1['id'] as integer
            local id2 = userdata2['id'] as integer
            if id1 == id2 then
                --print('collide', collide)
                collide = true
            end
        end
    end

    return collide
    -- }}}
end
--]]

--[[
local function bugInit()
    -- {{{
    local bugDir = 'bug'
    print('SCENE_PREFIX', SCENE_PREFIX)
    local files = Filesystem.getDirectoryItems(SCENE_PREFIX .. "/" .. bugDir)
    local path = SCENE_PREFIX .. "/" .. bugDir .. "/"
    print('path', path)
    local images: {love.graphics.Texture} = {}
    for k, v in ipairs(files) do

        -- XXX Invalid token
        --if string.match(v, ".*%d*\.png") then

        if string.match(v, ".*%d*png") then
            print(v)
            local image = Graphics.newImage(path .. v) as Graphics.Texture
            table.insert(images, image)
        end

        print(k, inspect(v))
    end
    local imgw, imgh = images[1]:getDimensions()
    --local imgw, imgh = 
    --images[1]:getDimensions()
    print('imgw, imgh', imgw, imgh)
    local canvas = love.graphics.newCanvas(imgw * #files)

    love.graphics.setCanvas(canvas)
        for _, image in ipairs(images) do
            local x, y = 0, 0
            love.graphics.draw(image as love.graphics.Drawable, x, y)
        end
    love.graphics.setCanvas()

    local imageData = canvas:newImageData()
    imageData:encode('png', "bug_timeline.png")
    print('encoded')
    -- }}}
end
--]]

--[[
local function getBodyFilterData(body: lp.Body): {FilterData}
    -- {{{
    local result: {FilterData} = {}
    for _, fixture in ipairs(body:getFixtures()) do
        local categoies, mask, group = fixture:getFilterData()
        table.insert(result, { 
            categoies = categoies, 
            mask = mask, 
            group = group 
        })
    end
    return result
    -- }}}
end
--]]

function Hangar.new(pos: vector): Hangar
    local Hangar_mt: metatable<Hangar> = {
        __index = Hangar,
    }
    local self = setmetatable({} as Hangar, Hangar_mt)
    self.objectType = "Hangar"

    --self.physbody = Physics.newBody(physworld, 0, 0, "static")
    --self.physbody:setUserData(self)

    self.rectXY = {0, 0}
    self.rectWH = {511, 511}
    local px, py = pos.x, pos.y
    local vertices = {
        px - self.rectWH[1] / 2 * PIX2M, 
        py - self.rectWH[2] / 2 * PIX2M,  

        px + self.rectWH[1] / 2 * PIX2M, 
        py - self.rectWH[2] / 2 * PIX2M,  

        px + self.rectWH[1] / 2 * PIX2M, 
        py + self.rectWH[2] / 2 * PIX2M,  

        px - self.rectWH[1] / 2 * PIX2M,
        py + self.rectWH[2] / 2 * PIX2M,
    }

    --local shape = Physics.newPolygonShape(vertices)
    self.vertices = vertices
    --self.fixture = Physics.newFixture(self.physbody, shape as Physics.Shape)
    --self.f:setGroupIndex(tankCollisionGroup)
    --self.polyshape = shape

    self.color = {1, 1, 1, 1}
    return self
end

function Hangar:update()

end

function Hangar:present()
    --local shape = self.fixture:getShape()
    --if shape:getType() ~= "polygon" then
        --error("Tank BaseP shape should be polygon.")
    --end

    --local body = self.fixture:getBody()
    --    1   2   3   4   5   6   7   8
    --local x1, y1, x2, y2, x3, y3, x4, y4 = self.polyshape:getPoints()

    --x1, y1 = body:getWorldPoints(x1, y1)
    --x2, y2 = body:getWorldPoints(x2, y2)
    --x3, y3 = body:getWorldPoints(x3, y3)
    --x4, y4 = body:getWorldPoints(x4, y4)

    --x1, y1 = M2PIX * x1, M2PIX * y1
    --x2, y2 = M2PIX * x2, M2PIX * y2
    --x3, y3 = M2PIX * x3, M2PIX * y3
    --x4, y4 = M2PIX * x4, M2PIX * y4

    --hangarBatch:present(
        --x1, y1, x2, y2, x3, y3, x4, y4, 
        --self.rectXY[1], self.rectXY[2], self.rectWH[1], self.rectWH[2], 
        --self.color
    --)

    --self.x4 = x4
    --self.y4 = y4
    --self.x1 = x1
    --self.y1 = y1
    --hangarBatch:present()
end

--[[
local function updateHangars()
    for _, v in ipairs(hangars) do
        if v.update then
            v:update()
        end
    end
end
--]]

--[[
local function drawBullets()
    -- {{{
    for _, b in ipairs(bullets) do
        local px, py = b.physbody:getWorldCenter()
        px, py = px * M2PIX, py * M2PIX
        gr.setColor(bulletColor)
        gr.circle("fill", px, py, bulletRadius)
    end
    -- }}}
end
--]]

--[[
local function updateBullets()
    -- {{{
    local alive: {Bullet} = {}
    local now = love.timer.getTime()
    for _, bullet in ipairs(bullets) do
        -- Заполнение отладочных полей.
        bullet.velx, bullet.vely = bullet.physbody:getLinearVelocity()
        bullet.mass = bullet.physbody:getMass()
        bullet.px, bullet.py = bullet.physbody:getWorldCenter()
        bullet.px, bullet.py = bullet.px * M2PIX, bullet.py * M2PIX

        local diff = now - bullet.timestamp
        --print('diff', diff)
        if diff < bulletLifetime and not bullet.died then
            table.insert(alive, bullet)
        end
    end
    bullets = alive
    -- }}}
end
--]]

--local activeImage: integer = 1

function Hit.new(x: number, y: number): Hit
    local Hit_mt: metatable<Hit> = {
        __index = Hit,
    }
    local self: Hit = setmetatable({} as Hit, Hit_mt)

    --print('self.ps:getSizeVariation()', self.ps:getSizeVariation())

    --self.ps:setSizes(1, 0.1)
    --self.ps = newParticleSystemWithDef(particles['default'])
    self.ps = nil
    error('self.ps = nil')

    x, y = x * M2PIX, y * M2PIX

    self.x = x
    self.y = y

    return self
end

--[[
function Turret:createFireCoro(): thread
    return coroutine.create(function()
        if not self.loaded then
            --loadCannonSound:play()
            -- wait for loadin
        end

        -- wait loadCannonSound file length seconds
        -- and call fire() to create new bullets.
        -- {{{
        --if DEBUG_TURRET then
            --print("Turret:fire()")
        --end

        --local duration = loadCannonSound:getDuration('seconds')
        --local time = love.timer.getTime()
        --local stop = false

        --print('duration', duration)
        --repeat
            --local now = love.timer.getTime()
            --print('time', time)
            --print('now', now)
            --local diff = now - time 
            --print('diff', diff)
            --if diff > duration then
                --stop = true
            --end
            --love.timer.sleep(0.001)
            --yield()
        --until stop

        -- беру центр всего тела или цетра шасси или центр башни?
        --local px, py = self.tank.base.physbody:getWorldCenter()

        -- снаряд появляется за крайней точкой ствола пушки
        local magic = 14

        print(self.id)

        -- размеры в метрах
        table.insert(bullets, Bullet.new(
            px - self.dir.x * magic, 
            py - self.dir.y * magic, 
            -self.dir.x, -self.dir.y,
            self.id
        ))
    end)
end
--]]

function Turret:fire()
    --table.insert(coroutines, self:createFireCoro())
end

--[[
local function presentDrawlistBottom()
    for _, v in ipairs(drawlistBottom) do
        if v.self then
            v.f(v.self)
        else
            v.f()
        end
    end
end
--]]

--[[
local function presentDrawlistTop()
    for _, v in ipairs(drawlistTop) do
        if v.self then
            v.f(v.self)
        else
            v.f()
        end
    end
end
--]]

--[[
function push2drawlistTop(f: function, self: any)
    if not f then
        error("Draw could'not be nil.")
    end
    if type(f) ~= "function" then
        error("Draw function is not a function. It is a .. " .. type(f))
    end
    table.insert(drawlistTop, { f = f, self = self})
end
--]]

--[[
function push2drawlistBottom(f: function, self: any)
    if not f then
        error("Draw could'not be nil.")
    end
    if type(f) ~= "function" then
        error("Draw function is not a function. It is a .. " .. type(f))
    end
    table.insert(drawlistBottom, { f = f, self = self})
end
--]]

--function Arena.new(fname: string): Arena
function Arena.new(_: string): Arena
    local Arena_mt: metatable<Arena> = { __index = Arena }
    local self: Arena = setmetatable({} as Arena, Arena_mt)

    --[[
    if fname and type(fname) == "string" then
        local edges: {Edge} = {}
        local filedata = love.filesystem.read(fname)
        if filedata then
            local ok = false
            local root: any
            ok, root = serpent.load(filedata)
            self.edges = edges
            -- PLACE YOUR LOADING CODE HERE
            if (root as {any:any}).rngSeed then
                local seed = (root as {any:any}).rngSeed as number
                print('seed value loaded', seed)
                rng = love.math.newRandomGenerator(seed)
            end
            -- PLACE YOUR LOADING CODE HERE
            if not ok then
                print("Could'not do serpent.load()")
                self:createFixtures()
            end
        else
            self.edges = edges
            self:createFixtures()
        end
    end
    --]]

    self.objectType = "Arena"

    return self
end

function Arena:mousemoved(_: number, _: number, _: number, _: number)
    --[[
    push2drawlistTop(function()
        local linew = 3
        if self.mode then
            if self.mode == 'second' then
                gr.setColor {0, 0, 0.9, 1}
                local ow = gr.getLineWidth()
                gr.setLineWidth(linew)
                gr.line(
                    self.edges[#self.edges].x1,
                    self.edges[#self.edges].y1,
                    self.edges[#self.edges].x2,
                    self.edges[#self.edges].y2
                )
                gr.setLineWidth(ow)
            end
        end
    end)
    --]]
end

function Arena:update()
end

function Arena:mousepressed(x: number, y: number, _: integer)
    --[[
    push2drawlistTop(function()
        gr.circle('fill', x, y, 10)
    end)
    --]]
    --x, y = cam:worldCoords(x, y)
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

--[[
function Arena:present(fixture: lp.Fixture)
    local shape = fixture:getShape() as lp.EdgeShape
    local x1, y1, x2, y2 = shape:getPoints()
    x1, y1 = fixture:getBody():getWorldPoints(x1, y1)
    x2, y2 = fixture:getBody():getWorldPoints(x2, y2)
    x1, y1, x2, y2 = x1 * M2PIX, y1 * M2PIX, x2 * M2PIX, y2 * M2PIX
    local olw = gr.getLineWidth()
    local ocolor = {gr.getColor()}
    gr.setColor(edgeColor)
    gr.setLineWidth(edgeLineWidth)
    gr.line(x1, y1, x2, y2)
    gr.setColor(ocolor)
    gr.setLineWidth(olw)
end
--]]

function Arena:ser(): string

end

function Arena:save2file(fname: string)
    --local data = serpent.dump(self.edges)
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

    --if self.physbody then
        --self.physbody:destroy()
        --self.physbody = nil
    --end

    --if not self.physbody then
        --self.physbody = love.physics.newBody(physworld, 0, 0, 'static')
    --end

    --for _, edge in ipairs(self.edges) do
        --local shape = lp.newEdgeShape(edge.x1, edge.y1, edge.x2, edge.y2)
        --lp.newFixture(self.physbody, shape as lp.Shape)
    --end
end

global arena: Arena

function Tank:fire()
    -- {{{
    --if self.turret then
        --self.turret:fire()
    --end
    -- }}}
end

function Tank:circleMove()
    --[[
    table.insert(coroutines, coroutine.create(function()
        while true do
            love.timer.sleep(0.0001)
            local movementImpulsesNum = 10
            for _ = 0, rng:random() * movementImpulsesNum do
                self.base:forward()
                yield()
            end
            local chance = rng:random()
            if chance > 0.5 then
                self.base:left()
                yield()
            else
                self.base:right()
                yield()
            end
            --love.timer.sleep(0.01)
        end
    end))
    --]]
end

function Base:left()
    --self.physbody:applyTorque(-angularImpulseScale)
end

function Base:right()
    --self.physbody:applyTorque(angularImpulseScale)
end

function Base:forward()
    -- {{{
    if self.tank.fuel > 0. then
        --local x, y = self.dir.x * tankForceScale, self.dir.y * tankForceScale
        --self.physbody:applyForce(x, y)
    end
    -- }}}
end

function Base:backward()
    -- {{{
    if self.tank.fuel > 0. then
        --local x, y = self.dir.x * tankForceScale, self.dir.y * tankForceScale
        --self.physbody:applyForce(-x, -y)
    end
    -- }}}
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

local base_tex_fname = 'tank_body.png'

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
function Tank.new(pos: vector, options: Tank.Options): Tank
    -- {{{
    local Tank_mt: metatable<Tank> = {
        __index = Tank,
    }

    --if DEBUG_TANK then
        --print('Start of Tank creating..')
    --end
    local self: Tank = setmetatable({} as Tank, Tank_mt)

    tankCounter = tankCounter + 1

    --local w, h = 
    self.strength = 1.
    self.fuel = 1.
    self.id = tankCounter
    self.first_render = true

    --if not dir then
        --dir = vector.new(0, 0)
    --end

    --self.dir = dir:clone()

    --self.pos = pos:clone()
    --self.pos = pos
    self.color = {1, 1, 1, 1}
    --local angle, _ = dir:toPolar()
    --self.base = Base.new(self)
    --self.base.physbody:setAngle(angle)
    --self.turret = Turret.new(self)

    -- Связать части танка одинаковыми идентификаторами. 
    -- Используется в contactFilter()
    --self.base.id = self.id
    --self.turret.id = self.id

    local body_options = options and options.body_opts
    self.body = pw.newBoxBody(tank_width, tank_height, body_options)
    self.body:bodySetPosition(pos.x, pos.y)
    self.body.user_data = self

    return self
    -- }}}
end

--[[
local function drawBodyStat(body: love.physics.Body)
    -- {{{
    local color = {0, 0, 0, 1}
    local radius = 10
    local x, y = body:getWorldCenter()
    x, y = x * M2PIX, y * M2PIX

    -- зеленый цвет кружка
    gr.setColor{0.1, 1, 0.1}
    gr.circle("fill", x, y, radius)

    -- с черной точкой
    gr.setColor(color)
    gr.circle("fill", x, y, 2)

    local vx, vy = body:getLinearVelocity()
    local scale = 7.
    --gr.line(x, y, x + vx * scale, y + vy * scale)
    drawArrow(x, y, x + vx * scale, y + vy * scale, color)
    -- }}}
end
--]]

function Base:drawDirectionVector()
    if self.dir then
        local x, y = 0, 0
        --local x, y = self.physbody:getWorldCenter()
        local scale = 100
        local color = {0., 0.05, 0.99, 1}
        x, y = x * M2PIX, y * M2PIX
        --drawArrow(x, y, x + self.dir.x * scale, y + self.dir.y * scale, color)
        arrow.draw(x, y, x + self.dir.x * scale, y + self.dir.y * scale, color)
    end
end

function Base:resetVelocities()
    --[[
    if self.physbody then
        self.physbody:setAngularVelocity(0)
        self.physbody:setLinearVelocity(0, 0)
    end
    --]]
end

function Base:updateDir()
    -- {{{
    --local unit = 1
    -- возможно зад перепутан с передом
    --self.dir = vec2.fromPolar(self.physbody:getAngle() + math.pi / 2, unit)
    -- }}}
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

-- TODO трек должен менятся при изменении направления движения
function Base:processTracks()
    --local vx, vy = self.physbody:getLinearVelocity()
    --local len = vecl.len(vx, vy)
    --local threshold = 1
    --local w = self.physbody:getAngularVelocity()
    --if len > threshold or w > 0.1 then
        --self:pushTrack()
    --end
    --print('len', len)
end

--[[
local function removeTank(tank: Tank)
    for k, v in ipairs(tanks) do
        if v == tank then
            table.remove(tanks, k)
            print('tank removed. allright')
            break
        end
    end
end
--]]

function Tank:update(): Tank
    -- {{{
    --print("Tank:update()")
    --print("body angle", self.pbody:getAngle())

    if self.strength <= 0. then
        --[[
        table.insert(coroutines, coroutine.create(function()
            print('tank died')
            yield()
            -- waintg loop

            --self.base.physbody:destroy()
            --self.turret.physbody:destroy()

            removeTank(self)
        end))
        --]]
        return self
    end

    --if self.turret then
        --self.turret:update()
        --if not self.turret.filterdata then
            ----self.turret.filterdata = getBodyFilterData(self.turret.physbody)
        --end
    --end
    --if self.base then
        --self.base:update()
    --end

    return self
    -- }}}
end

--[[
local function drawFixture(f: love.physics.Fixture, color: {number})
    -- {{{
    local defaultcolor = {1, 0.5, 0, 0.5}
    if not color then
        color = defaultcolor
    end
    local shape = f:getShape()
    local shapeType = shape:getType()
    local body = f:getBody()
    if shapeType == 'circle' then
        local cShape: Physics.CircleShape = shape as Physics.CircleShape
        local px, py = cShape:getPoint()
        local radius = cShape:getRadius()
        px, py = body:getWorldPoints(px, py)
        local lw = 3
        local olw = gr.getLineWidth()
        gr.setLineWidth(lw)
        gr.setColor(color)
        gr.circle("line", px * M2PIX, py * M2PIX, radius * M2PIX)
        gr.setLineWidth(olw)
    elseif shapeType == 'polygon' then
        local pShape: Physics.PolygonShape = shape as Physics.PolygonShape
        local points = {pShape:getPoints()}
        local i = 1
        while i < #points do
            points[i], points[i + 1] = body:getWorldPoints(
                points[i], 
                points[i + 1]
            )
            points[i] = points[i] * M2PIX
            points[i + 1] = points[i + 1] * M2PIX
            i = i + 2
        end
        local lw = 3
        local olw = gr.getLineWidth()
        gr.setLineWidth(lw)
        gr.setColor(color)
        gr.polygon("line", points)
        gr.setLineWidth(olw)
    else
        error("Shape type " .. shapeType .. " unsupported.")
    end
    -- }}}
end
--]]

function Tank:present()
    -- {{{

    --if self.base and self.base.present then
        --self.base:present()
    --else
        --colprint('Tank ' .. self.id .. ' is damaged. No base.')
    --end
    --if self.turret and self.turret.present then
        --self.turret:present()
        ----push2drawlist(self.turret.present, self.turret)
    --else
        --colprint('Tank ' .. self.id .. ' is damaged. No turret.')
    --end

    -- }}}
end

function Turret.new(t: Tank): Turret
    -- {{{
    if not t then
        error("Could'not create Turret without Tank object")
    end

    local Turret_mt: metatable<Turret> = {
        __index = Turret,
    }

    local self: Turret = setmetatable({} as Turret, Turret_mt)
    self.tank = t
    self.objectType = "Turret"
    --self.tankphysbody = t.base.physbody

    --local px, py = t.pos.x, t.pos.y
    --local px, py = t.base.physbody:getWorldCenter()

    --[[
    local towerShapeVertices = {
        px - turretCommon.towerRectWH[1] / 2 * PIX2M - 0,
        py - turretCommon.towerRectWH[2] / 2 * PIX2M - 0,

        px + turretCommon.towerRectWH[1] / 2 * PIX2M + 0,
        py - turretCommon.towerRectWH[2] / 2 * PIX2M - 0,

        px + turretCommon.towerRectWH[1] / 2 * PIX2M + 0,
        py + turretCommon.towerRectWH[2] / 2 * PIX2M + 0,

        px - turretCommon.towerRectWH[1] / 2 * PIX2M - 0,
        py + turretCommon.towerRectWH[2] / 2 * PIX2M + 0,
    }
    --]]

    --local magic = 1.45
    --local towerSize = turretCommon.towerRectWH[2] * PIX2M * magic
    
    -- Нужно сместить ствол так, что-бы он едва касался башни.
    --[[
    local barrelShapeVertices = {
        px - turretCommon.barrelRectWH[1] / 2 * PIX2M, 
        py - turretCommon.barrelRectWH[2] / 2 * PIX2M + towerSize,

        px + turretCommon.barrelRectWH[1] / 2 * PIX2M, 
        py - turretCommon.barrelRectWH[2] / 2 * PIX2M + towerSize,

        px + turretCommon.barrelRectWH[1] / 2 * PIX2M, 
        py + turretCommon.barrelRectWH[2] / 2 * PIX2M + towerSize,

        px - turretCommon.barrelRectWH[1] / 2 * PIX2M,
        py + turretCommon.barrelRectWH[2] / 2 * PIX2M + towerSize,
    }
    --]]

    --self.physbody = love.physics.newBody(physworld, 0, 0, "dynamic")
    --self.physbody:setUserData(self)

    --self.barrelShape = love.physics.newPolygonShape(barrelShapeVertices)
    --self.towerShape = love.physics.newPolygonShape(towerShapeVertices)

    --self.fixtureBarrel = lp.newFixture(self.physbody, self.barrelShape as lp.Shape)
    --self.barrelCategories, self.barrelMask, self.barrelGroup = self.fixtureBarrel:getFilterData() as (integer, integer, integer)

    --print("barrelCategories, barrelMask, barrelGroup", self.barrelCategories, self.barrelMask, self.barrelGroup)
    --self.fixtureBarrel:setFilterData(-1, 0, 0)
    --print("barrelCategories, barrelMask, barrelGroup", self.barrelCategories, self.barrelMask, self.barrelGroup)

    --self.fixtureTower = lp.newFixture(self.physbody, self.towerShape as lp.Shape)
    --self.towerCategories, self.towerMask, self.towerGroup = self.fixtureTower:getFilterData() as (integer, integer, integer)

    --print("towerCategories, towerMask, towerGroup", self.towerCategories, self.towerMask, self.towerGroup)
    --self.fixtureTower:setFilterData(-2, 1, 1)
    --print("towerCategories, towerMask, towerGroup", self.towerCategories, self.towerMask, self.towerGroup)

    --print("self.fixtureBarrel", self.fixtureBarrel:getDensity())
    --print("self.fixtureTower", self.fixtureTower:getDensity())

    --self.fixtureTower:setDensity(0.0001)
    --self.fixtureBarrel:setDensity(0.0001)
    --self.physbody:resetMassData()

    --local magix = -100
    --local p1x, p1y = self.tank.base.physbody:getWorldCenter()
    --local p2x, p2y = self.tank.base.physbody:getWorldCenter()

    --p2x = p2x + 50

    --self.joint = lp.newWeldJoint(self.tank.base.physbody, self.physbody, p1x, p1y, p2x, p2y, false)
    --local joint = love.physics.newDistanceJoint(self.tank.physbody, self.physbody, p1x, p1y, p2x, p2y, true)

    --local joint = lp.newWeldJoint(self.tank.physbody, self.physbody, p1x, p1y, p2x, p2y, true)

    --local joint = lp.newWeldJoint(self.tank.physbody, self.physbody, 0, 0, 0, 0, false)
    --local joint = lp.newWeldJoint(self.tank.physbody, self.physbody, 0, 0, false)
    --print('joint:getFrequency()', joint:getFrequency())
    --joint:setFrequency(60)
    --joint:setFrequency(120)
    --os.exit()
    --local joint = love.physics.newDistanceJoint(self.tank.physbody, self.physbody, 0, 0, 0, 0, false)

    return self
    -- }}}
end

-- Как сделать медленный поворот башни?
-- скорость поворота башни танка т-80 - 40 градусов в секунду.
function Turret:rotateToMouse()
    -- {{{
    local mx, my = love.mouse.getPosition()
    --mx, my = cam:worldCoords(mx, my)
    mx, my = mx * PIX2M, my * PIX2M

    --local x, y = self.physbody:getWorldCenter()
    --local d = vec2.new(x - mx, y - my)
    --self.dir = d:normalizeInplace()
    --local a, _ = d:toPolar()

    --[[
    push2drawlist(function()
        local px, py = x * M2PIX, y * M2PIX
        local K = 20
        gr.setColor{1, 0, 0, 1}
        --gr.circle("fill", 0, 0, 1000)
        --local x1, y1, x2, y2 = px, py, px + self.dir.x * K, py + self.dir.y * K
        local x1, y1, x2, y2 = x, y, mx, my
        gr.line(x1, y1, x2, y2)
        drawArrow(x1, y1, x2, y2, {0, 1, 1, 1})
        print("line", x1, y1, x2, y2)
    end)
    --]]

    --self.angle = -a
    -- Вместо установки угла поробовать поворачитать тело через applyTorque()
    --self.physbody:setAngle(self.angle + math.pi)
    -- }}}
end

function Turret:update()
    -- {{{
    -- поворачивать башню только у танка игрока
    if playerTank and self.tank == playerTank then
        self:rotateToMouse()
    end

    --[[
    if self.fireCoro then
        local ok, errmsg: boolean, string = resume(self.fireCoro) as (boolean, string)
        if not ok then
            print("local ok: boolean = coroutine.resume(self.fireCoro)", errmsg)
        end
        self.fireCoro = nil
    end
    --]]

    -- }}}
end

function Turret:present()
    -- {{{
    --if not self.fixtureTower or not self.fixtureBarrel then
        --return
    --end

    --local towerShape = self.fixtureTower:getShape()
    --local barrelShape = self.fixtureBarrel:getShape()

    --if towerShape:getType() ~= "polygon" or 
       --barrelShape:getType() ~= "polygon" then
           --error("Only polygon shapes are allowed.")
    --end

    --local body = self.fixtureTower:getBody()

    --    1   2   3   4   5   6   7   8
    --local tx1, ty1, tx2, ty2, tx3, ty3, tx4, ty4 = self.towerShape:getPoints()

    --tx1, ty1 = body:getWorldPoints(tx1, ty1)
    --tx2, ty2 = body:getWorldPoints(tx2, ty2)
    --tx3, ty3 = body:getWorldPoints(tx3, ty3)
    --tx4, ty4 = body:getWorldPoints(tx4, ty4)

    --tx1, ty1 = M2PIX * tx1, M2PIX * ty1
    --tx2, ty2 = M2PIX * tx2, M2PIX * ty2
    --tx3, ty3 = M2PIX * tx3, M2PIX * ty3
    --tx4, ty4 = M2PIX * tx4, M2PIX * ty4

    --    1   2   3   4   5   6   7   8
    --local bx1, by1, bx2, by2, bx3, by3, bx4, by4 = self.barrelShape:getPoints()

    --bx1, by1 = body:getWorldPoints(bx1, by1)
    --bx2, by2 = body:getWorldPoints(bx2, by2)
    --bx3, by3 = body:getWorldPoints(bx3, by3)
    --bx4, by4 = body:getWorldPoints(bx4, by4)

    --bx1, by1 = M2PIX * bx1, M2PIX * by1
    --bx2, by2 = M2PIX * bx2, M2PIX * by2
    --bx3, by3 = M2PIX * bx3, M2PIX * by3
    --bx4, by4 = M2PIX * bx4, M2PIX * by4

    --[[
    turretBatch:present(
        tx1, ty1, tx2, ty2, tx3, ty3, tx4, ty4, 
        turretCommon.towerRectXY[1], 
        turretCommon.towerRectXY[2], 
        --turretCommon.towerRectWH[1], 
        --turretCommon.towerRectWH[2]
        turretCommon.towerRectWH[1], 
        turretCommon.towerRectWH[2],
        self.tank.color
    )
    turretBatch:present(
        bx1, by1, bx2, by2, bx3, by3, bx4, by4, 
        turretCommon.barrelRectXY[1], 
        turretCommon.barrelRectXY[2], 
        turretCommon.barrelRectWH[1], 
        turretCommon.barrelRectWH[2],
        self.tank.color
    )
    --]]

    -- }}}
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
    self.objectType = "Base"
    self.tank = t
    self.track = {}

    -- цифры получены из картинки tank_body_small.png
    self.rectXY = {86, 72}
    self.rectWH = {84, 111}

    --self.physbody = love.physics.newBody(physworld, 0, 0, "dynamic")
    --self.physbody:setAngularDamping(3.99)
    --self.physbody:setLinearDamping(2)
    --self.physbody:setUserData(self)

    --local px, py = t.pos.x, t.pos.y

    -- XXX Не используется rectXY, будут проблемы при перемещении 
    -- выделения на текстуре.
    --[[
    local vertices = {
        px - self.rectWH[1] / 2 * PIX2M, 
        py - self.rectWH[2] / 2 * PIX2M,  

        px + self.rectWH[1] / 2 * PIX2M, 
        py - self.rectWH[2] / 2 * PIX2M,  

        px + self.rectWH[1] / 2 * PIX2M, 
        py + self.rectWH[2] / 2 * PIX2M,  

        px - self.rectWH[1] / 2 * PIX2M,
        py + self.rectWH[2] / 2 * PIX2M,
    }
    --]]

    --local shape = Physics.newPolygonShape(vertices)
    --self.fixture = Physics.newFixture(self.physbody, shape as Physics.Shape)
    --self.f:setGroupIndex(tankCollisionGroup)
    --self.polyshape = shape

    return self
    -- }}}
end

-- TODO сделать меньше копирований
-- TODO Попробовать выставялть матрицы проекции для каждого танка вместо
-- заполнения сетки.
function Base:present()
    -- {{{

    --local shape = self.fixture:getShape()
    --if shape:getType() ~= "polygon" then
        --error("Tank BaseP shape should be polygon.")
    --end

    --local body = self.fixture:getBody()
    --    1   2   3   4   5   6   7   8
    --local x1, y1, x2, y2, x3, y3, x4, y4 = self.polyshape:getPoints()

    --x1, y1 = body:getWorldPoints(x1, y1)
    --x2, y2 = body:getWorldPoints(x2, y2)
    --x3, y3 = body:getWorldPoints(x3, y3)
    --x4, y4 = body:getWorldPoints(x4, y4)

    --x1, y1 = M2PIX * x1, M2PIX * y1
    --x2, y2 = M2PIX * x2, M2PIX * y2
    --x3, y3 = M2PIX * x3, M2PIX * y3
    --x4, y4 = M2PIX * x4, M2PIX * y4

    --[[
    baseBatch:present(
        x1, y1, x2, y2, x3, y3, x4, y4, 
        self.rectXY[1], self.rectXY[2], self.rectWH[1], self.rectWH[2], 
        self.tank.color
    )
    --]]

    --self.x4 = x4
    --self.y4 = y4
    --self.x1 = x1
    --self.y1 = y1
    self:drawTrack()
-- }}}
end

function Base:pushTrack()
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
end

function Base:drawTrack()
    --[[
    local linew = 2
    local olw = gr.getLineWidth()
    gr.setLineWidth(linew)
    gr.setColor{0, 0, 0, 1}
    for _, v in ipairs(self.track) do
        gr.line(v[1], v[2], v[3], v[4])
        gr.line(v[5], v[6], v[7], v[8])
    end
    gr.setLineWidth(olw)
    --]]
end

-- координаты в метрах
--local function newHit(x: number, y: number)
    --table.insert(hits, Hit.new(x, y))
--end

function Tank:damage(_: Bullet)
--function Tank:damage(bullet: Bullet)
    --[[
    local bulx, buly = bullet.physbody:getWorldCenter()
    local px, py = bullet.px, bullet.py
    local len = sqrt(pow(abs(bulx - px), 2) + pow(abs(buly - py), 2))
    print('len', len)
    local damage = 0.25
    self.strength = self.strength - damage
    print('strength', self.strength)
    --]]
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
local function onBeginContact(
    fixture1: love.physics.Fixture, 
    fixture2: love.physics.Fixture, 
    contact: love.physics.Contact
)
    -- {{{

    --local p1x, p1y, p2x, p2y = contact:getPositions()
    local p1x, p1y, _, _= contact:getPositions()

    local body1 = fixture1:getBody()
    local userdata1: {any:any} = body1:getUserData() as {any:any}
    local body2 = fixture2:getBody()
    local userdata2: {any:any} = body2:getUserData() as {any:any}
    local objectType1: ObjectType
    local objectType2: ObjectType

    if fixture1 then
        userdata1 = fixture1:getBody():getUserData() as {string:any}
        if userdata1 then
            objectType1 = userdata1['objectType'] as ObjectType
            --print("fixture1 userdata", userdata1['objectType'])
        end
    end
    if fixture2 then
        userdata2 = fixture2:getBody():getUserData() as {string:any}
        if userdata2 then
            --print(inspect(userdata2))
            objectType2 = userdata2['objectType'] as ObjectType
            --print("fixture2 userdata", userdata2['objectType'])
        end
    end

    --print('objectType1, objectType2', objectType1, objectType2)

    if objectType1 and objectType2 then
        if (objectType1 == 'Bullet' and objectType2 == 'Base') or 
           (objectType1 == 'Base' and objectType2 == 'Bullet') or
           (objectType1 == 'Turret' and objectType2 == 'Bullet') or
           (objectType1 == 'Base' and objectType2 == 'Turret') then
               local id1 = userdata1.id 
               local id2 = userdata2.id
               if id1 ~= id2 then
                   newHit(p1x, p1y)
                   if objectType1 == 'Bullet' then
                       local b = fixture1:getUserData() as Bullet
                       if b and b.died then
                           b.died = true
                       end
                       --processTankDamage(userdata2['tank'] as Tank)
                       (userdata2['tank'] as Tank):damage(userdata1 as Bullet)
                   end
                   if objectType2 == 'Bullet' then
                       local b = fixture2:getUserData() as Bullet
                       if b and b.died then
                           b.died = true
                       end
                       --processTankDamage(userdata1['tank'] as Tank)
                       (userdata1['tank'] as Tank):damage(userdata2 as Bullet)
                   end
                   --newHit(p2x, p2y)
               end
       end
    end

    -- }}}
end
--]]

--[[
local function onEndContact(
        _: love.physics.Fixture, 
        _: love.physics.Fixture,
        _: love.physics.Contact
    )
    -- {{{
    -- }}}
end
--]]

--[[
local function onQueryBoundingBox(fixture: love.physics.Fixture): boolean
    -- {{{
    local selfPtr: {any:any} = fixture:getBody():getUserData() as {any:any}
    if selfPtr and selfPtr['present'] then
        (selfPtr['present'] as function)(selfPtr, fixture)
    end
    return true
    -- }}}
end
--]]

--[[
local function queryBoundingBox()
    -- {{{
    if cam then
        --local tlx, tly = cam:worldCoords(0, 0)
        --local brx, bry = cam:worldCoords(gr.getDimensions())
        --brx, bry = brx + W, bry + H

        --physworld:queryBoundingBox(
            --tlx * PIX2M, tly * PIX2M, 
            --brx * PIX2M, bry * PIX2M, 
            --onQueryBoundingBox
        --)
    end
    -- }}}
end
--]]

local function unbindPlayerTankKeys()
    if #playerTankKeyconfigIds ~= 0 then
        for id in ipairs(playerTankKeyconfigIds) do
            KeyConfig.unbindid(id)
        end
        playerTankKeyconfigIds = {}
        collectgarbage("collect")
    end
end

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

--local function drawHits()
    --local blendmode, alphamode = love.graphics.getBlendMode()

    --print('blendmode', blendmode)
    --print('alphamode', alphamode)
    --print('os.exit()')
    --os.exit()

    --Graphics.setBlendMode('alpha', 'alphamultiply')

    -- Не работает как надо
    --Graphics.setBlendMode('alpha', 'premultiplied')

    --Graphics.setBlendMode('alpha', 'multiply')

    --[[
    for _, v in ipairs(hits) do
        gr.setColor{1, 1, 1, 1}
        love.graphics.draw(v.ps as Drawable, v.x, v.y)
    end
    --]]
--end

--[[
local function updateHits(dt: number)
    for _, v in ipairs(hits) do
        v.ps:update(dt)
    end
end
--]]

--[[
local function terrain(mapn: integer, rez: integer)
    if not mapn then
        mapn = 8
    end
    if not rez then
        rez = 128
    end
    print('terrain', mapn, rez)
    --linesbuf:push(notificationDelay, 'terrain mapn = %d, rez = %d', mapn, rez)

    --diamondSquare = DiamonAndSquare.new(mapn, rez, rng)
    --diamondSquare:eval()
    --diamondSquare:draw2canvas()

    --diamondSquare.canvas:newImageData():encode('png', 'terrain.png')
end
--]]

-- возвращает массив со значениями координат углов ландшафта в метрах по часовой
-- стрелке от левого верхнего угла.
function getTerrainCorners(): {vector}

end

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
        --[[
    kc.bind(
        'keypressed', { key = "v" },
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end
            playerTank["right"](playerTank)
            return false, sc
        end,
        --i18n("mt" .. "right"))
        'none')
        --]]
end

--[[
local function bindPlayerTankKeys()
    -- {{{
    if playerTank then
        -- {{{
        local kc = KeyConfig
        local bmode: kc.BindType = "isdown"
        
        local ids = {
            kc.bind(
                bmode, { key = "d" },
                function(sc: Shortcut): boolean, Shortcut
                    if mode ~= "normal" then
                        return false, sc
                    end
                    playerTank["right"](playerTank)
                    return false, sc
                end,
                i18n("mt" .. "right")),

            kc.bind(
                bmode, { key = "a" },
                function(sc: Shortcut): boolean, Shortcut
                    if mode ~= "normal" then
                        return false, sc
                    end
                    playerTank["left"](playerTank)
                    return false, sc
                end,
                i18n("mt" .. "left")),

            kc.bind(
                bmode, { key = "w" },
                function(sc: Shortcut): boolean, Shortcut
                    if mode ~= "normal" then
                        return false, sc
                    end
                    playerTank["forward"](playerTank)
                    return false, sc
                end,
                i18n("mt" .. "forward")),

            kc.bind(
                bmode, { key = "s" },
                function(sc: Shortcut): boolean, Shortcut
                    if mode ~= "normal" then
                        return false, sc
                    end
                    playerTank["backward"](playerTank)
                    return false, sc
                end,
                i18n("mt" .. "backward")),

            kc.bind(
                bmode, { key = "v" },
                function(sc: Shortcut): boolean, Shortcut
                    if mode ~= "normal" then
                        return false, sc
                    end
                    playerTank["resetVelocities"](playerTank)
                    return false, sc
                end,
                i18n("resetVelocities")),

            kc.bind(
                "isdown", { key = "space" },
                function(sc: Shortcut): boolean, Shortcut
                    if mode ~= "normal" then
                        return false, sc
                    end
                    if playerTank then
                        playerTank:fire()
                    end
                    return false, sc
                end,
                i18n("fire")),
        }
        for _, v in ipairs(ids) do
            table.insert(playerTankKeyconfigIds, v)
        end
        -- }}}
    else
        error("There is no player tank object instance, sorry. Keys are not binded.")
    end
    -- }}}
end
--]]

--local function changeKeyConfigListbackground()
    -- {{{
    --KeyConfig.setListSetupCallback(function(list: List)
        --list.colors.normal = {bg = {0.19, 0.61, 0.88}, fg = {1, 1., 1., 1.}}
    --end)
    -- }}}
--end

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

--[[
local function findTank(object: Tank): integer
    for i, v in ipairs(tanks) do
        if v == object then
            return i
        end
    end
    return nil
end
--]]

--[[
local function enableMovement()
    for _, tank in ipairs(tanks) do
        if tank ~= playerTank then
            tank:circleMove()
        end
    end
end
--]]

local function spawnHangar(pos: vector): Hangar
    local hangar = Hangar.new(pos)
    table.insert(hangars, hangar)
    return hangar
end

-- положение в метрах
--[[
local function spawnTank(pos: vector, dir: vector): Tank
    -- {{{
    local ok, errmsg: boolean, string = pcall(function()
        if #tanks >= 1 then
            -- XXX next line not work
             --unbindPlayerTankKeys()
        end
        table.insert(tanks, Tank.new(pos, dir))
        print("Tank spawn at", pos.x, pos.y)
    end)
    if not ok then
        error("Could'not load. Please implement stub-tank. " .. errmsg)
    end
    return tanks[#tanks]
    -- }}}
end
--]]

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
local function drawui()
    -- {{{
    imgui.StyleColorsLight()
    imgui.ShowDemoWindow()
    imgui.ShowUserGuide()

    -- рисовать редактор частиц
    drawParticlesEditor()
    -- рисовать навигатор объектов
    drawNavigator()
    -- рисовать редактор карты
    drawArenaPallete()

    -- }}}
end
--]]

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

--[[
local function removeFirstColon(s: string): string
    -- {{{
    if not s then
        return nil
    end
    if string.sub(s, 1, 1) == ":" then
        return string.sub(s, 2, #s)
    else
        return s
    end
    -- }}}
end
--]]

--[[
{{{ removeFirstColon tests
colprint("test removeFirstColon(':ss'): " .. removeFirstColon(':ss'))
colprint("test removeFirstColon(':'): " .. removeFirstColon(':'))
colprint("test removeFirstColon('::'): " .. removeFirstColon('::'))
}}}
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
local function processAttachedVariables()
    for _, v in pairs(attachedVarsList) do
        v()
    end
end
--]]

--[[
local function stats()
    linesbuf:pushi('Lua used %d Mb', (collectgarbage('count') as integer)/ 1024)
    local stat = love.graphics.getStats()
    linesbuf:pushi('drawcalls %d', stat.drawcalls)
    linesbuf:pushi('canvasswitches %d', stat.canvasswitches)
    --linesbuf:pushi('texturememory %d', (stat.texturememory as integer) / 1024)
end 
--]]

--[[
local function konsolePresent()
    -- {{{
    konsoleCam:attach()
    gr.setColor{1, 1, 1, 1}

    processAttachedVariables()

    if mode == "command" then
        cmdline = removeFirstColon(cmdline)
        if cmdline then
            --linesbuf:pushiColored("%{rd}>: %{black}" .. cmdline)
            --local prompt = "leading %{black}>: %{white}"
            --local prompt = "leading %{black}>: %{white} ww %{black}"
            local prompt = ">: "
            -- вывод цветного текста для консоли
            linesbuf:pushi(prompt .. cmdline)
        end
    end

    stats()

    --cam:attach()
    linesbuf.color = {0, 1, 1}
    linesbuf:draw()
    --cam:detach()
    konsoleCam:detach()

    if suggestList then
        -- XXX если раскоментить следущую строку, то программа падает.
        --suggestList:draw()
    end
    -- }}}
end
--]]

--local isCameraCircleOut: boolean = false

--[[
local function drawCameraCircle()
    local circleColor1 = {1, 0, 0, 1}
    local circleColor2 = {1, 1, 1, 1}
    local linew = 8
    local w, h = gr.getDimensions()
    local oldcolor = {gr.getColor()}
    local olw = gr.getLineWidth()
    --gr.setColor(isCameraCircleOut and circleColor1 or circleColor2)
    if isCameraCircleOut then
        gr.setColor(circleColor1)
    else
        gr.setColor(circleColor2)
    end
    gr.setLineWidth(linew)
    gr.circle("line", w / 2, h / 2, cameraZoneR)
    gr.setColor(oldcolor)
    gr.setLineWidth(olw)
end
--]]

--local function mainPresent()
    --baseBatch:prepare()
    --turretBatch:prepare()
    --hangarBatch:prepare()

    --push2drawlistTop(drawBullets)

    --cam:attach()
    --background:present()

    --[[
    if drawTerrain and diamondSquare then
            love.graphics.setColor{1, 1, 1, 1}
            love.graphics.circle('fill', 0, 0, 100)
            diamondSquare:present()
    end
    --]]

    --queryBoundingBox()

    --presentDrawlistBottom()

    --baseBatch:flush()
    --turretBatch:flush()
    --hangarBatch:flush()

    --drawHits()

    --presentDrawlistTop()

    --cam:detach()

    --drawCameraCircle()

    --drawlistTop = {}
    --drawlistBottom = {}

    --changeKeyConfigListbackground()

    --yield()
--end

--[[
local function drawCameraAxixes()
    -- {{{
    local color = {0., 0.1, 0.97}
    local lw = 5
    local radius = 40
    local len = W * 2
    local oldwidth = gr.getLineWidth()
    gr.setColor(color)
    gr.setLineWidth(lw)
    gr.circle("fill", cam.x, cam.y, radius)
    gr.line(cam.x, cam.y, cam.x + len, cam.y)
    gr.line(cam.x, cam.y, cam.x - len, cam.y)
    gr.line(cam.x, cam.y, cam.x, cam.y + len)
    gr.line(cam.x, cam.y, cam.x, cam.y - len)
    gr.setLineWidth(oldwidth)
    -- }}}
end
--]]

local function render_shapes_by_verts()
    pw.eachSpaceBody(bodyIter_verts)
end

local function renderScene()
    -- Ограничение кадров в секунду до 60
    local nt = love.timer.getTime()
    local fps_limit = 1. / 300.
    local diff = nt - last_render

    if diff >= fps_limit then
        last_render = nt

        pipeline:openAndClose('clear')

        pipeline:open('set_transform')
        pipeline:push(camera)
        pipeline:close()

        --render_shapes_by_verts()

        pipeline:open('poly_shape')
        pw.eachSpaceBody(bodyIter)
        pipeline:push('flush')
        pipeline:close()

        --pipeline:openAndClose('origin_transform')

        print_io_rate()

        --print('counter', pipeline.counter)
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
Функция двигает камеру если координаты центра масс танка игрока выходят за
радиус камеры.
--]]
local function moveCamera()
    if playerTank then

        --local w, h = gr.getDimensions()
        --local centerx, centery = w / 2, h / 2
        --print("centerx, centery", centerx, centery)
        --local tankx, tanky = playerTank.base.physbody:getWorldCenter()
        --tankx, tanky = tankx * M2PIX, tanky * M2PIX
        --print("tankx, tanky", tankx, tanky)
        --local diff = vecl.dist(centerx, centery, tankx, tanky)
        --diff = nil
        --print("diff", diff)

        --table.insert(posbuffer, { tankx, tanky })
        --if #posbuffer > maxBufLen then
            --table.remove(posbuffer, 1)
        --end

        if not lastPosX then
            --lastPosX = tankx
        end

        if not lastPosY then
            --lastPosY = tanky
        end


        --local dx, dy = lastPosX - tankx, lastPosY - tanky

        --lastPosX = tankx
        --lastPosY = tanky
        --cam:move(-dx, -dy)
    end
end

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

local function enterCommandMode()
    -- {{{
    --[[
    if linesbuf.show then
        print("command mode enabled.")
        mode = "command"
        cmdline = ""
        cursorpos = 1
        love.keyboard.setKeyRepeat(true)
        love.keyboard.setTextInput(true)

        local historydata = love.filesystem.read(historyfname)
        if historydata then
            --print("commands history loaded.")
            cmdhistory = {}
            for s in historydata:gmatch("[^\r\n]+") do
                table.insert(cmdhistory, s)
                --print("s", s)
            end
            --print("all entries.")
        end
    end
    --]]
    -- }}}
end

local function leaveCommandMode()
    -- {{{
    print("command mode disabled.")
    mode = "normal"
    love.keyboard.setKeyRepeat(false)
    love.keyboard.setTextInput(false)
    cmdline = ""
    -- }}}
end

function attach(varname: string)
    if type(varname) == "string" then
        attachedVarsList[varname] = function()
            local ok, errmsg: boolean, string = pcall(function()
                local l = (_G as {any:any})[varname]
                local output = tabular.show2(l)
                if output then 
                    --linesbuf:pushi(string.format("%s", output))
                    --if type(l) == 'table' then
                    --linesbuf:pushi(output)
                    --linesbuf:pushi(string.format("%s", varname))
                    --else
                        --linesbuf:pushi(string.format('%s = %s', varname, 
                            --tostring(l)))
                    --end
                else
                    --linesbuf:pushi(string.format("%s = nil", varname))
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

function detach(varname: string)
    if type(varname) == "string" then
        attachedVarsList[varname] = nil
    end
end

local function evalCommand()
    -- {{{

    -- {{{ preload
    local preload = [[
function ptabular(ref)
    print(tabular(ref, nil, "cyan"))
end

function pinspect(ref)
    print(inspect(ref))
end

function help()
    print('Добро пожаловать в консоль цикла разработки.')
    print('Список команд:')
    print('pinspect(_G)')
    print('ptabular(playerTank) для отображения значения переменной.')
    print('binds() все задействованные на данный момент клавиатурные сочетания')
end

function binds()
    print(tabular(KeyConfig.getShortcutsDown()))
    print(tabular(KeyConfig.getShortcutsPressed()))
end

function vars(pattern)
    for k, v in pairs(_G) do
        local ok, errmsg = pcall(function()
            local line = string.format("%s: %s", tostring(k), inspect(v))
            if suggestList then
                -- обязательно вызывать метод :clear()?
                --suggestList:clear()
                suggestList:add(line)
            end
            if pattern and #line ~= 0 then
                if string.match(line, pattern) then
                    print(line)
                end
            else
                print(line)
            end
        end)
        if not ok then
            print('Error in listing occured:', errmsg)
        end
    end
end

function detach(name)
    attachedVarsList[name] = nil
end

if not __ATTACH_ONCE__ then
    print('before')
    __ATTACH_ONCE__ = true
    attach('mode')
    attach("tankCounter")
end
    ]]
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

local cmdhistoryIndex = 0

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

local function suggestCompletion()
    -- {{{

    --if not suggestList then
        --suggestList = List.new()
    --end

    -- Как рисовать список идентификаторов?
    --for k, v in pairs(_G as {any:any}) do
        --suggestList:add(string.format("%s: %s", tostring(k), tostring(v)))
    --end
    -- }}}
end

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

local function keypressed(key: string)
    -- {{{
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
    -- }}}
end

global cameraKeyConfigIds: {integer} = {}

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

--local function setWindowMode()
    --love.window.setMode(DEFAULT_W, DEFAULT_H, { resizable = false })
--end

--local function setFullscreenMode()
    --love.window.setFullscreen(true)
--end

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

    pipeline:pushCode("poly_shape_verts", [[
    local col = {1, 0, 0, 1}
    local inspect = require "inspect"

    while true do
        love.graphics.setColor(col)

        local verts = graphic_command_channel:demand()
        love.graphics.polygon('fill', verts)

        coroutine.yield()
    end
    ]])

    pipeline:pushCode('clear', [[
    while true do
        love.graphics.clear{0.5, 0.5, 0.5}
        coroutine.yield()
    end
    ]])

    pipeline:pushCode('set_transform', [[
    local gr = love.graphics
    local yield = coroutine.yield
    while true do
        gr.applyTransform(graphic_command_channel:demand())
        yield()
    end
    ]])

    pipeline:pushCode('origin_transform', [[
    local gr = love.graphics
    local yield = coroutine.yield
    while true do
        gr.origin()
        yield()
    end
    ]])

    pipeline:pushCode('formated_text', [[
    local font = love.graphics.newFont(24)
    while true do
        local old_font = love.graphics.getFont()

        love.graphics.setColor{0, 0, 0}
        love.graphics.setFont(font)

        local msg = graphic_command_channel:demand()
        local x = math.floor(graphic_command_channel:demand())
        local y = math.floor(graphic_command_channel:demand())
        love.graphics.print(msg, x, y)

        love.graphics.setFont(old_font)

        coroutine.yield()
    end
    ]])

    pipeline:pushCodeFromFile("poly_shape", 'poly_shape.lua')

    pipeline:pushCode('chipmunk_vertex_order', [[
        -- {{{
        local verts_mat = {
            {2135,1982,2135,2238,1879,2238,1879,1982},
            {2589,1642,2589,1898,2333,1898,2333,1642},
            {2887,1937,2887,2193,2631,2193,2631,1937},
        }
        while true do
            for _, verts in ipairs(verts_mat) do
                local count = #verts
                love.graphics.setColor {0, 1, 0}
                love.graphics.polygon('fill', verts)
                --for i = 1, count / 2 - 1 do
                local i, j = 1, 1
                while i <= count do
                    love.graphics.setColor {0, 0, 1}
                    local rad = 100
                    love.graphics.circle('fill', verts[i], verts[i + 1], rad)
                    love.graphics.setColor { 1, 0, 0, 1}
                    --love.graphics.print(tostring(i), verts[i], verts[i + 1])
                    love.graphics.print(tostring(j), verts[i], verts[i + 1])
                    j = j + 1
                    i = i + 2
                end
            end
            coroutine.yield()
        end
        -- }}}
    ]])
end

local function initPipelineObjects()
    pipeline:open('poly_shape')
    pipeline:push(base_tex_fname, tank_width, tank_height)
    pipeline:close()

    pipeline:sync()
end

local function eachShape_verts(_: Cm.cpBody, shape: Cm.cpShape)
    local shape_type = pw.polyShapeGetType(shape)
    if shape_type == pw.CP_POLY_SHAPE then
        local verts = gather_verts(shape)
        pipeline:open('poly_shape_verts')
        pipeline:push(verts)
        pipeline:close()
    end
end

local function eachShape(b: Cm.cpBody, shape: Cm.cpShape)
    --debug_print('phys', 'eachShape call')
    --print('phys', 'eachShape call')

    local shape_type = pw.polyShapeGetType(shape)

    if shape_type == pw.CP_POLY_SHAPE then

        -- Возможно стоит поместить формирование таблички в 
        -- вспомогательную библиотеку или переписать с прямым доступом к
        -- shape->planes[i].v0

        local body_wrap = pw.cpBody2Body(b)
        local tank = body_wrap.user_data as Tank

        if not tank then
            error("tank is nil")
        end

        local posx, posy: number, number
        posx, posy = b.p.x, b.p.y
        local angle = b.a

        --print('posx, posy', posx, posy)
        --print('angle', b.a)

        if tank.first_render then
            --local verts = gather_verts(shape)

            --print('init.tl - verts', inspect(verts))

            --pipeline:push('new')
            --pipeline:push(tank.id)
            --pipeline:push(verts)

            pipeline:push('new', tank.id, posx, posy, angle)

            --tank.first_render = false

            --tank.prev_posx = body_wrap.body.p.x
            --tank.prev_posy = body_wrap.body.p.y
        else
            -- TODO сравнивать не только линейную скорость, но и угловую
            local len = vecl.len(b.v.x, b.v.y)
            print('len', len)
            local angular_vel = b.w
            print('angular_vel', angular_vel)

            local epsilon_vel = 0.0001 
            local epsilon_w = 0.00001

            --pipeline:push('draw')
            --pipeline:push(tank.id)

            if len < epsilon_vel and angular_vel < epsilon_w then
                --pipeline:push('draw')
                --pipeline:push(tank.id)
            else
                local verts = gather_verts(shape)
                --pipeline:push('new')
                --pipeline:push(tank.id)
                --pipeline:push(verts)
                --tank.first_render = true
            end

            --]]

        end
    end
    --]]
end

local function initPhysIterators()
    bodyIter = pw.newEachSpaceBodyIter(eachBody)
    shapeIter = pw.newEachBodyShapeIter(eachShape)
    
    bodyIter_verts = pw.newEachSpaceBodyIter(eachBody_verts)
    shapeIter_verts = pw.newEachBodyShapeIter(eachShape_verts)
end

local function init()
    -- {{{
    print('init started')

    metrics.init()

    pw.init(pipeline)

    initJoy()
    initRenderCode()
    initPipelineObjects()
    initPhysIterators()

    --setWindowMode()

    --effect = moonshine.chain(moonshine.effects.filmgrain).
        --chain(moonshine.effects.vignette)

    loadLocales()

    --logo = Logo.new()

    bindCameraZoomKeys()
    bindKonsoleCameraZoomKeys()
    bindCameraControl()
    bindFullscreenSwitcher()
    bindEscape()
    bindKonsole()
    bindTerrainControlKeys()
    bindDeveloperKeys()

    --drawCoro = createDrawCoroutine()

    --background = Background.new()

    --initParticles(particlesfname)

    arena = Arena.new("arena.lua")
    --terrain()
    local corners = getTerrainCorners()
    if corners then
        for _, c in ipairs(corners) do
            spawnHangar(c)
        end
    end

    --local herostartpos = vector.new(0, 0)
    --local alpha = rng:random() * math.pi
    --playerTank = spawnTank(herostartpos, fromPolar(alpha))

    --bindPlayerTankKeys()

    --enableDEBUG()
    --disableDEBUG()

    --bugInit()

    --cameraZoneR = H / 2
    -- }}}
    print('init finished')
end

local function quit()
    -- {{{
    metrics.quit()
    unbindPlayerTankKeys()
    tanks = {}
    --writeParticles(particlesfname)
    -- }}}
end

local function mousemoved(x: number, y: number, dx: number, dy: number)
    metrics.mousemoved(x, y, dx, dy)
    if mode == 'editor' then
        arena:mousemoved(x, y, dx, dy)
    end
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

--[[
local function resize(neww: integer, newh: integer)
    -- {{{
    metrics.resize(neww, newh)
    print("tanks window resized to w, h", neww, newh)
    W, H = neww, newh
    cameraZoneR = newh / 2
    -- FIXME Нужно менять эти переменные?
    DEFAULT_W, DEFAULT_H = neww, newh
    -- }}}
end
--]]

--[[
local function textinput(text: string)
    -- {{{
    metrics.textinput(text)
    if mode == "command" then
        -- Здесь добавить курсор.
        --cmdline = cmdline .. text
        local sub = string.sub
        cmdline = sub(cmdline, 1, cursorpos - 1) .. 
            text ..  sub(cmdline, cursorpos, #cmdline)
        cursorpos = cursorpos + 1
    end
    -- }}}
end
--]]

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

            end
        end
    end
end

local enum State 
    'garage'
    'map'
end

local state: State = 'map'

local function spawnTanks()
    local options: Tank.Options = {
        body_opts = {
            use_print = false,
        },
    }

    --local tanks_num = 1500
    local tanks_num = 500
    --local tanks_num = 10

    local minx, maxx = 0, 4000
    local miny, maxy = 0, 4000
    --local minx, maxx = 0, 1000
    --local miny, maxy = 0, 1000

    for _ = 1, tanks_num do
        local px, py = rng:random(minx, maxx), rng:random(miny, maxy)
        local tank = Tank.new(vec2(px, py), options)
        table.insert(tanks, tank)
    end
end

-- как лучше учитывать положение джойстика что-бы не было рывков?
local function cameraScale(j: joystick.Joystick, dt: number)
    local axes = {j:getAxes()}
    local dy = axes[2]
    local factor = 1 * dt
    --print('dy', dy)
    if dy == -1 then
        camera:scale(1 + factor, 1 + factor)
        --print('camera:scale(1 + factor, 1 + factor)')
    elseif dy == 1 then
        camera:scale(1 - factor, 1 - factor)
        --print('camera:scale(1 - factor, 1 - factor)')
    end
end

-- добавить инерцию к камере
local function cameraMovement(j: joystick.Joystick, dt: number)
    local axes = {j:getAxes()}
    local dx, dy = axes[4], axes[5]
    -- количество пикселей на которые передвигается камера
    local amount_x, amount_y = 3000 * dt, 3000 * dt
    local tx, ty = 0., 0.
    local changed = false

    if dx > 0 then
        changed = true
        tx = -amount_x
    elseif dx < 0 then
        changed = true
        tx = amount_x
    end

    if dy > 0 then
        changed = true
        ty = -amount_y
    elseif dy < 0 then
        changed = true
        ty = amount_y
    end

    if changed then
        camera:translate(tx, ty)
    end
end

local stateCoro: thread = coroutine.create(function(dt: number)

    spawnTanks()

    while true do
        if state == 'map' then
            process_events()
            renderScene()
            updateTanks()

            ------------ UPDATE HERE PLEASE ------------ 
            camTimer:update(dt)

            --updateBullets()
            --updateHangars()
            --updateHits(dt)
            --updateCoroutines()
            --arena:update()

            cameraScale(joy, dt)
            cameraMovement(joy, dt)

            moveCamera()

            -- шаг физики
            pw.update(dt)

            updateJoyState()

            dt = coroutine.yield() as number
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

        local ok, errmsg = coroutine.resume(stateCoro, dt) as (boolean, string)
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
    pw.free()
    main_channel:push('quit')
    debug_print('thread', 'Thread resources are freed')
end

debug_print('thread', colorize('%{yellow}<<<<<%{reset} t80 finished'))
