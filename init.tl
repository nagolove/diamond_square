-- vim: fdm=marker
-- vim: set colorcolumn=85

global SCENE_PREFIX = "scenes/t90"

love.filesystem.setRequirePath("?.lua;?/init.lua;" .. SCENE_PREFIX .. "/?.lua")

-- {{{ require
require "tabular"
require "love"
require "common"
require "keyconfig"
require "camera"
require "vector"
require "Timer"
require "imgui"
require 'render'
require 'diamondsquare'
--require 'moonshine'

local List = require "list"
--local moonshine = require 'moonshine'
global i18n = require "i18n"
local metrics = require "metrics"
global vec2 = require "vector"
global vecl = require "vector-light"
global inspect = require "inspect"
global tabular = require "tabular"
-- }}}

local gr = love.graphics
local lp = love.physics
local Shortcut = KeyConfig.Shortcut

local enum Mode
    "normal"
    "command"
    "editor"
end

local enum ObjectType
    "Base"
    "Turret"
    "Bullet"
    "Arena"
end

local record DrawNode
    f: function
    self: any
end

-- Подложка арены
local record Background
    -- {{{
    img: gr.Image

    new: function(): Background
    present: function()
    -- }}}
end

local record TurretCommon
    -- {{{
    barrelRectXY: {number}
    barrelRectWH: {number}
    towerRectXY: {number}
    towerRectWH: {number}
end

local turretCommon: TurretCommon = {
    barrelRectXY = {124, 0},
    barrelRectWH = {8, 109},
    towerRectXY = {101, 103},
    towerRectWH = {54, 58},
}
-- }}}

local record Edge
    x1: number
    y1: number
    x2: number
    y2: number
end

local record Arena
    -- {{{

    -- какая точка рисуется, первая или вторая
    enum Mode
        'first'
        'second'
    end

    mode: Mode
    edges: {Edge}
    physbody: lp.Body
    objectType: ObjectType

    -- interface

    new: function(fname: string): Arena
    present: function(Arena)
    update: function(Arena)
    mousemoved: function(Arena, x: number, y: number, dx: number, dy: number)
    mousepressed: function(Arena, x: number, y: number, btn: integer)
    save2file: function(Arena, fname: string)

    -- internal 

    createFixtures: function(Arena)

    -- }}}
end

local record FilterData
    categoies: integer
    mask: integer
    group: integer
end

local record Bullet
    -- {{{
    body: love.physics.Body
    timestamp: number
    objectType: ObjectType
    id: integer
    dir: vector

    -- START OF DEBUG STUFF
    velx: number
    vely: number
    mass: number
    px: number
    py: number
    -- END OF DEBUG STUFF
    -- }}}

    new: function(px: number, py: number, dirx: number, diry: number, tankId: integer): Bullet
    update: function()
end

-- Пушка вместе с башней
local record Turret
    -- {{{
    rectXY: {number}
    rectWH: {number}

    id: integer
    joint: lp.WeldJoint
    fireCoro: thread

    barrelCategories: integer
    barrelMask: integer
    barrelGroup: integer
    towerCategories: integer
    towerMask: integer
    towerGroup: integer

    filterdata: {FilterData}
    physbody: love.physics.Body
    tankphysbody: lp.Body
    fixtureBarrel: love.physics.Fixture
    fixtureTower: love.physics.Fixture

    barrelShape: lp.PolygonShape
    towerShape: lp.PolygonShape

    objectType: ObjectType
    --image: love.graphics.Image
    angle: number
    tank: Tank
    -- куда смотрит башня, направление выстрела
    dir: vector

    new: function(t: Tank): Turret
    present: function(Turret)
    update: function(Turret)
    fire: function(Turret)
    rotateToMouse: function(Turret)
    createFireCoro: function(): thread
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
    physbody: love.physics.Body
    filterdata: {FilterData}
    fixture: love.physics.Fixture
    --pos: vector -- центр поворота корпуса
    tank: Tank
    polyshape: lp.PolygonShape
    -- нормализованный вектор
    dir: vector

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

    pushTrack: function(Base)
    drawTrack: function(Base)

    resetVelocities: function(Base)
    drawDirectionVector: function(Base)
    -- }}}
end

-- Класс основного боевого танка.
local record Tank
    -- {{{
    -- записывается положение в метрах при создании танка
    -- когда обновляется?
    pos: vector
    -- нормализованный вектор
    dir: vector
    -- уникальное за сеанс игры число
    id: integer
    -- пушка
    turret: Turret
    -- ходовая часть
    base: Base

    -- абсолютные координаты в пикселях
    new: function(pos: vector): Tank

    present: function(Tank)
    update: function(Tank): Tank

    resetVelocities: function(Tank)
    left: function(Tank)
    right: function(Tank)
    forward: function(Tank)
    backward: function(Tank)
    fire: function(Tank)
    -- }}}
end

-- Заставка
local record Logo
    -- {{{
    image: love.graphics.Image
    sx: number
    sy: number
    imgw: integer
    imgh: integer

    new: function(): Logo

    present: function()
    -- }}}
end

local type CameraSettings = record
    -- {{{
    dx: number
    dy: number
    -- }}}
end

-- {{{ DEBUG globals
global DEBUG_BASE = false
global DEBUG_TANK = false
global DEBUG_TANK_MOVEMENT = false
global DEBUG_TURRET = true
global DEBUG_CAMERA = false
global DEBUG_LOGO = false
global DEBUG_BULLET = true
global DEBUG_DIRECTION = false

--global DEBUG_DRAW_THREAD = true
--global DEBUG_TEXCOORDS = true
--global DEBUG_PHYSICS = true

global DEBUG_DRAW_THREAD = false
global DEBUG_TEXCOORDS = true
global DEBUG_PHYSICS = false

-- Глобальные флаги отображения
global cmd_drawBodyStat: boolean = true
global cmd_drawCameraAxixes: boolean = false

local debugStack: {{string:boolean}} = {}
-- }}}

-- {{{ Global and local variables.

global notificationDelay = 2.5
-- Размеры экрана по-умолчанию(начальное положение)
global DEFAULT_W, DEFAULT_H = 1024, 768
-- Размеры экрана
global W, H = love.graphics.getDimensions()
--[[ Танк длиной пять метров имеет отображаемый размер 50 пикселей
коэффициент на который домножаю при переводе из метров в пиксели --]]
global M2PIX = 10
-- коэффициент на который домножаю при переводе из пикселей в метры
global PIX2M = 1 / 10

--local tankCollisionGroup = 1
--local bulletCollisionGroup = -1
-- Пули не сталкиваются с танками
local bulletMask = 1

-- Множитель передачи импульса на шасси танка.
global tankForceScale = 8

-- {{{ Konsole editing
local historyfname = "cmdhistory.txt"
local linesbuf = require "kons".new(SCENE_PREFIX .. "/VeraMono.ttf", 20)
global mode: Mode = "normal"
global cmdline: string = ""
local cmdhistory: {string} = {}
global cursorpos: integer = 1
global suggestList: List = List.new()
-- список имен переменных для отображения в консоли
global attachedVarsList: {string: function} = {}
-- }}}

-- верхний список отрисовки, рисуется после рисования пачки танков
local drawlistTop: {DrawNode} = {}
-- нижний список отрисовки, рисуется после подложки, но до пачек танков
local drawlistBottom: {DrawNode} = {}

global cam: Camera

-- используется для анимации масштабирования камеры
local camTimer: Timer = require "Timer".new()
local drawCoro: thread = nil
global showLogo = true
-- идентификаторы клавиш управления танком игрока
global playerTankKeyconfigIds: {integer} = {}
-- множитель углового импулься
global angularImpulseScale = 5 * math.pi / 4
-- минимальный и максимальные порог масштаба камеры
global camZoomLower, camZoomHigher = 0.075, 3.5
-- скорость изменения масштаба камеры
local zoomSpeed = 0.01
local cameraSettings: CameraSettings = {
    -- значение в пикселях
    dx = 2000, dy = 2000,
}
-- Экземпляр мира box2d
global physworld: love.physics.World
-- Все танки, в том числе и тот, которым управляет игрок.
global tanks: {Tank} = {}
-- Танк, которым управляет игрок
global playerTank: Tank
-- Подложка
global background: Background
-- Логотип, картинка
global logo: Logo
-- Все снаряды вырущенные из танков, пока не уничтоженные
global bullets: {Bullet} = {}
-- Радиус снаряда пушки в пикселях
local bulletRadius = 4
local bulletColor = {0.1, 0.1, 0.1, 1}
-- Продолжительность жизни снаряда в секундах.
global bulletLifetime = 35
-- Счетчик живый танков
global tankCounter = 0
global rng: love.math.RandomGenerator = love.math.newRandomGenerator()
global diamondSquare: DiamonAndSquare
-- значение в пикселях радиуса окружности, выход танка игрока за которую двигает камеру 
local cameraZoneR: number

local edgeColor = {0, 0, 0, 1}
local edgeLineWidth = 10
local loadCannonSound = love.audio.newSource(SCENE_PREFIX .. "/load.wav", 'static')
local drawTerrain = true

local baseBatch: Batch = Batch.new("tank_body_small.png")
local turretBatch: Batch = Batch.new("tank_tower.png")

global maxTrackCount = 128

local coroutines: {thread} = {}
-- }}}

local function coroutinesUpdate()
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
end

function Bullet.new(px: number, py: number, dirx: number, diry: number, tankId: integer): Bullet
    -- {{{
    local Bullet_mt: metatable<Bullet> = {
        __index = Bullet,
    }
    local self: Bullet = setmetatable({} as Bullet, Bullet_mt)

    self.body = love.physics.newBody(physworld, px, py, "dynamic")
    self.body:setBullet(true)
    self.timestamp = love.timer.getTime()
    local shape = love.physics.newCircleShape(0, 0, bulletRadius * PIX2M)
    love.physics.newFixture(self.body, shape as lp.Shape)
    --fixture:setGroupIndex(bulletCollisionGroup)
    --fixture:setMask(bulletMask)
    self.body:setMass(1)
    local impulse = 100
    if dirx and diry then
        self.body:applyLinearImpulse(dirx * impulse, diry * impulse)
    end
    --bullet.body:resetMassData()
    self.dir = vec2.new(dirx, diry)
    self.id = tankId or 0
    self.objectType = 'Bullet'

    return self
    -- }}}
end

local function contactFilter(fixture1: lp.Fixture, fixture2: lp.Fixture): boolean
    -- {{{
    --print('contactFilter', fixture1, fixture2)
    local collide = true
    local objectType1: ObjectType
    local objectType2: ObjectType
    local userdata1, userdata2: {string: any}, {string: any}

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
            objectType2 = userdata2['objectType'] as ObjectType
            --print("fixture2 userdata", userdata2['objectType'])
        end
    end
    print('objects are here', inspect(objectType1), inspect(objectType2))
    if objectType1 and objectType2 then
        if objectType1 == 'Base' and objectType2 == 'Turret' then
            local id1 = userdata1['id'] as integer
            local id2 = userdata2['id'] as integer
            if id1 == id2 then
                print('collide', collide)
                collide = true
            end
        end
    end
    return collide
    -- }}}
end

function disableDEBUG()
    -- {{{
    DEBUG_BASE = false
    DEBUG_TANK = false
    DEBUG_TANK_MOVEMENT = false
    DEBUG_TURRET = false
    DEBUG_CAMERA = false
    DEBUG_LOGO = false
    DEBUG_BULLET = false
    DEBUG_DRAW_THREAD = false
    DEBUG_TEXCOORDS = false
    DEBUG_PHYSICS = false
    cmd_drawBodyStat = false
    cmd_drawCameraAxixes = false
    -- }}}
end

function enableDEBUG()
    -- {{{
    DEBUG_BASE = true
    DEBUG_TANK = true
    DEBUG_TANK_MOVEMENT = true
    DEBUG_TURRET = true
    DEBUG_CAMERA = true
    DEBUG_LOGO = true
    DEBUG_BULLET = true
    DEBUG_DRAW_THREAD = true
    DEBUG_TEXCOORDS = true
    DEBUG_PHYSICS = true
    cmd_drawBodyStat = true
    cmd_drawCameraAxixes = true
    -- }}}
end

function pushDEBUG()
    -- {{{
    table.insert(debugStack, {
        ["DEBUG_BASE "] = DEBUG_BASE,
        ["DEBUG_TANK "] = DEBUG_TANK,
        ["DEBUG_TANK_MOVEMENT "] = DEBUG_TANK_MOVEMENT,
        ["DEBUG_TURRET "] = DEBUG_TURRET,
        ["DEBUG_CAMERA "] = DEBUG_CAMERA,
        ["DEBUG_LOGO "] = DEBUG_LOGO,
        ["DEBUG_BULLET "] = DEBUG_BULLET,
        ["DEBUG_DRAW_THREAD "] = DEBUG_DRAW_THREAD,
        ["DEBUG_TEXCOORDS "] = DEBUG_TEXCOORDS,
        ["DEBUG_PHYSICS "] = DEBUG_PHYSICS,
        ["cmd_drawBodyStat "] = cmd_drawBodyStat,
        ["cmd_drawCameraAxixes "] = cmd_drawCameraAxixes,
    })
    -- }}}
end

function popDEBUG()
    -- {{{
    if #debugStack >= 1 then
        local entry = debugStack[#debugStack]
        DEBUG_BASE = entry["DEBUG_BASE"]
        DEBUG_TANK = entry["DEBUG_TANK"]
        DEBUG_TANK_MOVEMENT = entry["DEBUG_TANK_MOVEMENT"]
        DEBUG_TURRET = entry["DEBUG_TURRET"]
        DEBUG_CAMERA = entry["DEBUG_CAMERA"]
        DEBUG_LOGO = entry["DEBUG_LOGO"]
        DEBUG_BULLET = entry["DEBUG_BULLET"]
        DEBUG_DRAW_THREAD = entry["DEBUG_DRAW_THREAD"]
        DEBUG_TEXCOORDS = entry["DEBUG_TEXCOORDS"]
        DEBUG_PHYSICS = entry["DEBUG_PHYSICS"]
        cmd_drawBodyStat = entry["cmd_drawBodyStat"]
        cmd_drawCameraAxixes = entry["cmd_drawCameraAxixes"]
    end
    -- }}}
end

local function bugInit()
    -- {{{
    local bugDir = 'bug'
    print('SCENE_PREFIX', SCENE_PREFIX)
    local files = love.filesystem.getDirectoryItems(SCENE_PREFIX .. "/" .. bugDir)
    local path = SCENE_PREFIX .. "/" .. bugDir .. "/"
    print('path', path)
    local images: {love.graphics.Texture} = {}
    for k, v in ipairs(files) do

        -- XXX Invalid token
        --if string.match(v, ".*%d*\.png") then

        if string.match(v, ".*%d*png") then
            print(v)
            table.insert(images, love.graphics.newImage(path .. v) as love.graphics.Texture)
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

local function getBodyFilterData(body: lp.Body): {FilterData}
    local result: {FilterData} = {}
    for _, fixture in ipairs(body:getFixtures()) do
        local categoies, mask, group = fixture:getFilterData()
        table.insert(result, { categoies = categoies, mask = mask, group = group })
    end
    return result
end

local function drawArrow(
    fromx: number, fromy: number, tox: number, toy: number, 
    color: {number}
)
    -- {{{
    local angle = math.pi / 11
    local arrowDiv = 20

    color = color or {1, 1, 1, 1}
    local x, y = fromx - tox, fromy - toy
    local abs = math.abs
    local ux, uy = vecl.normalize(abs(fromx - tox), abs(fromy - toy))
    local len = vecl.len(x, y) / arrowDiv
    local lx, ly = vecl.rotate(angle, ux, uy)
    local rx, ry = vecl.rotate(-angle, ux, uy)
    lx, ly = len * lx, len * ly
    rx, ry = len * rx, len * ry

    local oldlinew = gr.getLineWidth()
    local linew = 15
    gr.setLineWidth(linew)
    gr.setColor(color)

    -- left line
    gr.line(tox, toy, tox - lx, toy - ly)
    -- right line
    gr.line(tox, toy, tox - rx, toy - ry)
    -- main line
    gr.line(fromx, fromy, tox, toy)
    -- }}}
    gr.setLineWidth(oldlinew)
end

local function drawBullets()
    -- {{{
    for _, b in ipairs(bullets) do
        local px, py = b.body:getWorldCenter()
        px, py = px * M2PIX, py * M2PIX
        gr.setColor(bulletColor)
        if DEBUG_BULLET then
            --print("bullet", px, py, bulletRadius)
        end
        gr.circle("fill", px, py, bulletRadius)
    end
    -- }}}
end

local function updateBullets()
    -- {{{
    local alive: {Bullet} = {}
    local now = love.timer.getTime()
    for _, bullet in ipairs(bullets) do
        bullet.velx, bullet.vely = bullet.body:getLinearVelocity()
        bullet.mass = bullet.body:getMass()
        bullet.px, bullet.py = bullet.body:getWorldCenter()
        bullet.px, bullet.py = bullet.px * M2PIX, bullet.py * M2PIX
        local diff = now - bullet.timestamp
        --print('diff', diff)
        if diff < bulletLifetime then
            table.insert(alive, bullet)
        end
    end
    bullets = alive
    -- }}}
end

function Turret:createFireCoro(): thread
    return coroutine.create(function()
        --loadCannonSound:play()

        -- wait loadCannonSound file length seconds
        -- and call fire() to create new bullets.
        -- {{{
        --if DEBUG_TURRET then
            --print("Turret:fire()")
        --end

        local duration = loadCannonSound:getDuration('seconds')
        local time = love.timer.getTime()
        local stop = false

        --[[
        print('duration', duration)
        repeat
            local now = love.timer.getTime()
            print('time', time)
            print('now', now)
            local diff = now - time 
            print('diff', diff)
            if diff > duration then
                stop = true
            end
            love.timer.sleep(0.001)
            coroutine.yield()
        until stop
        --]]

        -- беру центр всего тела или цетра шасси или центр башни?
        local px, py = self.tank.base.physbody:getWorldCenter()

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

function Turret:fire()
    if not self.fireCoro then
        self.fireCoro = self:createFireCoro()
    end
    -- }}}
end

local function presentDrawlistBottom()
    for _, v in ipairs(drawlistBottom) do
        if v.self then
            v.f(v.self)
        else
            v.f()
        end
    end
end

local function presentDrawlistTop()
    for _, v in ipairs(drawlistTop) do
        if v.self then
            v.f(v.self)
        else
            v.f()
        end
    end
end

function push2drawlistTop(f: function, self: any)
    if not f then
        error("Draw could'not be nil.")
    end
    if type(f) ~= "function" then
        error("Draw function is not a function. It is a .. " .. type(f))
    end
    table.insert(drawlistTop, { f = f, self = self})
end

function push2drawlistBottom(f: function, self: any)
    if not f then
        error("Draw could'not be nil.")
    end
    if type(f) ~= "function" then
        error("Draw function is not a function. It is a .. " .. type(f))
    end
    table.insert(drawlistBottom, { f = f, self = self})
end

function Arena.new(fname: string): Arena
    local Arena_mt: metatable<Arena> = { __index = Arena }
    local self: Arena = setmetatable({} as Arena, Arena_mt)
    local edges: {Edge} = {}
    local data = love.filesystem.read(fname)
    if data then
        local serpent = require 'serpent'
        local ok = false
        ok, edges = serpent.load(data) as (boolean, {Edge})
        self.edges = edges
        if not ok then
            print("Could'not do serpent.load()")
            self:createFixtures()
        end
    else
        self.edges = edges
        self:createFixtures()
    end

    self.objectType = "Arena"

    return self
end

function Arena:mousemoved(_: number, _: number, _: number, _: number)
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
end

function Arena:update()
end

function Arena:mousepressed(x: number, y: number, _: integer)
    push2drawlistTop(function()
        gr.circle('fill', x, y, 10)
    end)
    x, y = cam:worldCoords(x, y)
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

function Arena:save2file(fname: string)
    local serpent = require 'serpent'
    local data = serpent.dump(self.edges)
    love.filesystem.write(fname, data)
end

function Arena:createFixtures()
    assert(self.edges )
    if self.physbody then
        self.physbody:destroy()
        self.physbody = nil
    end
    if not self.physbody then
        self.physbody = love.physics.newBody(physworld, 0, 0, 'static')
    end
    for _, edge in ipairs(self.edges) do
        local shape = lp.newEdgeShape(edge.x1, edge.y1, edge.x2, edge.y2)
        lp.newFixture(self.physbody, shape as lp.Shape)
    end
end

global arena: Arena

function Tank:fire()
    -- {{{
    if self.turret then
        self.turret:fire()
    end
    -- }}}
end

function Base:left()
    self.physbody:applyTorque(-angularImpulseScale)
end

function Base:right()
    self.physbody:applyTorque(angularImpulseScale)
end

function Base:forward()
    -- {{{
    local x, y = self.dir.x * tankForceScale, self.dir.y * tankForceScale
    self.physbody:applyForce(x, y)
    -- }}}
end

function Base:backward()
    -- {{{
    local x, y = self.dir.x * tankForceScale, self.dir.y * tankForceScale
    self.physbody:applyForce(-x, -y)
    -- }}}
end
--]]

function Tank:left()
    self.base:left()
    --self.physbody:applyTorque(-angularImpulseScale)
end

function Tank:right()
    self.base:right()
    --self.physbody:applyTorque(angularImpulseScale)
end

function Tank:forward()
    self.base:forward()
end

function Tank:backward()
    self.base:backward()
end

-- местоположение передавать в метрах
-- направление шасси - нормализованный вектор
function Tank.new(pos: vector, dir: vector): Tank
    -- {{{
    local Tank_mt: metatable<Tank> = {
        __index = Tank,
    }

    if DEBUG_TANK then
        print('Start of Tank creating..')
    end
    local self: Tank = setmetatable({} as Tank, Tank_mt)

    tankCounter = tankCounter + 1

    if not dir then
        dir = vector.new(0, -1)
        print('dir is nil, using default value', inspect(dir))
    end
    --self.pbody:setAngle(math.pi / 3)

    self.id = tankCounter
    self.dir = dir:clone()
    self.pos = pos:clone()
    self.base = Base.new(self)
    self.turret = Turret.new(self)

    -- Связать части танка одинаковыми идентификаторами. Используется в contactFilter()
    self.base.id = self.id
    self.turret.id = self.id

    if DEBUG_TANK then
        print('self.turret', self.turret)
        print('self.base', self.base)
        print('End of Tank creating.')
    end
    return self
    -- }}}
end

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

function Base:drawDirectionVector()
    -- {{{
    if self.dir then
        local x, y = self.physbody:getWorldCenter()
        local scale = 100
        local color = {0., 0.05, 0.99, 1}
        x, y = x * M2PIX, y * M2PIX
        drawArrow(x, y, x + self.dir.x * scale, y + self.dir.y * scale, color)
    end
    -- }}}
end

function Base:resetVelocities()
    -- {{{
    if self.physbody then
        self.physbody:setAngularVelocity(0)
        self.physbody:setLinearVelocity(0, 0)
    end
    -- }}}
end

function Base:updateDir()
    -- {{{
    local unit = 1
    -- возможно зад перепутан с передом
    self.dir = vec2.fromPolar(self.physbody:getAngle() + math.pi / 2, unit)
    -- }}}
end

function Base:update()
    self:updateDir()
    if not self.filterdata then
        self.filterdata = getBodyFilterData(self.physbody)
    end

    local vx, vy = self.physbody:getLinearVelocity()
    local len = vecl.len(vx, vy)
    local threshold = 1
    local w = self.physbody:getAngularVelocity()
    if len > threshold or w > 0.1 then
        self:pushTrack()
    end
    --print('len', len)
end

function Tank:update(): Tank
    -- {{{
    --print("Tank:update()")
    --print("body angle", self.pbody:getAngle())

    if self.turret then
        self.turret:update()
        if not self.turret.filterdata then
            self.turret.filterdata = getBodyFilterData(self.turret.physbody)
        end
    end
    if self.base then
        self.base:update()
    end

    return self
    -- }}}
end

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
        local cShape: love.physics.CircleShape = shape as love.physics.CircleShape
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
        local pShape: love.physics.PolygonShape = shape as love.physics.PolygonShape
        local points = {pShape:getPoints()}
        local i = 1
        while i < #points do
            points[i], points[i + 1] = body:getWorldPoints(points[i], points[i + 1])
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

function Tank:present()
    -- {{{
    if self.base and self.base.present then
        self.base:present()
    else
        colprint('Tank ' .. self.id .. ' is damaged. No base.')
    end
    if self.turret and self.turret.present then
        self.turret:present()
        --push2drawlist(self.turret.present, self.turret)
    else
        colprint('Tank ' .. self.id .. ' is damaged. No turret.')
    end

    if cmd_drawBodyStat then
        push2drawlistTop(function()
            local baseBody = self.base.physbody
            for _, f in ipairs(baseBody:getFixtures()) do
                -- Не работает
                drawFixture(f)
                --push2drawlist(function()
                --drawFixture(f)
                --end)
            end
            if DEBUG_DIRECTION then
                self.base:drawDirectionVector()
            end
            drawBodyStat(self.base.physbody)
        end)
        if self.turret then
            push2drawlistTop(function()
                for _, f in ipairs(self.turret.physbody:getFixtures()) do
                    -- Не работает
                    drawFixture(f)
                    --push2drawlist(function()
                    --drawFixture(f)
                    --end)
                end
                drawBodyStat(self.turret.physbody)
            end)
        end
    end
    -- }}}
end

function Turret.new(t: Tank): Turret
    -- {{{
    if DEBUG_TURRET then
        print("Start of Turret creating..")
    end
    if not t then
        error("Could'not create Turret without Tank object")
    end

    local Turret_mt: metatable<Turret> = {
        __index = Turret,
    }

    local self: Turret = setmetatable({} as Turret, Turret_mt)
    self.tank = t
    self.objectType = "Turret"
    --self.image = turretBatch.image
    self.tankphysbody = t.base.physbody

    local px, py = t.pos.x, t.pos.y

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

    local magic = 1.45
    local towerSize = turretCommon.towerRectWH[2] * PIX2M * magic
    
    -- Нужно сместить ствол так, что-бы он едва касался башни.
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

    self.physbody = love.physics.newBody(physworld, 0, 0, "dynamic")
    self.physbody:setUserData(self)

    self.barrelShape = love.physics.newPolygonShape(barrelShapeVertices)
    self.towerShape = love.physics.newPolygonShape(towerShapeVertices)

    self.fixtureBarrel = lp.newFixture(self.physbody, self.barrelShape as lp.Shape)
    self.barrelCategories, self.barrelMask, self.barrelGroup = self.fixtureBarrel:getFilterData() as (integer, integer, integer)
    print("barrelCategories, barrelMask, barrelGroup", self.barrelCategories, self.barrelMask, self.barrelGroup)
    --self.fixtureBarrel:setFilterData(-1, 0, 0)
    print("barrelCategories, barrelMask, barrelGroup", self.barrelCategories, self.barrelMask, self.barrelGroup)

    self.fixtureTower = lp.newFixture(self.physbody, self.towerShape as lp.Shape)
    self.towerCategories, self.towerMask, self.towerGroup = self.fixtureTower:getFilterData() as (integer, integer, integer)
    print("towerCategories, towerMask, towerGroup", self.towerCategories, self.towerMask, self.towerGroup)
    --self.fixtureTower:setFilterData(-2, 1, 1)
    print("towerCategories, towerMask, towerGroup", self.towerCategories, self.towerMask, self.towerGroup)

    --print("self.fixtureBarrel", self.fixtureBarrel:getDensity())
    --print("self.fixtureTower", self.fixtureTower:getDensity())

    self.fixtureTower:setDensity(0.0001)
    self.fixtureBarrel:setDensity(0.0001)
    self.physbody:resetMassData()

    --local magix = -100
    local p1x, p1y = self.tank.base.physbody:getWorldCenter()
    local p2x, p2y = self.tank.base.physbody:getWorldCenter()

    --p2x = p2x + 50

    self.joint = lp.newWeldJoint(self.tank.base.physbody, self.physbody, p1x, p1y, p2x, p2y, false)
    --local joint = love.physics.newDistanceJoint(self.tank.physbody, self.physbody, p1x, p1y, p2x, p2y, true)

    --local joint = lp.newWeldJoint(self.tank.physbody, self.physbody, p1x, p1y, p2x, p2y, true)

    --local joint = lp.newWeldJoint(self.tank.physbody, self.physbody, 0, 0, 0, 0, false)
    --local joint = lp.newWeldJoint(self.tank.physbody, self.physbody, 0, 0, false)
    --print('joint:getFrequency()', joint:getFrequency())
    --joint:setFrequency(60)
    --joint:setFrequency(120)
    --os.exit()
    --local joint = love.physics.newDistanceJoint(self.tank.physbody, self.physbody, 0, 0, 0, 0, false)

    if DEBUG_TURRET then
        print("circle shape created x, y, r", px, py)
    end

    return self
    -- }}}
end

-- Как сделать медленный поворот башни?
-- скорость поворота башни танка т-80 - 40 градусов в секунду.
function Turret:rotateToMouse()
    -- {{{
    local mx, my = love.mouse.getPosition()
    mx, my = cam:worldCoords(mx, my)
    mx, my = mx * PIX2M, my * PIX2M

    local x, y = self.physbody:getWorldCenter()
    local d = vec2.new(x - mx, y - my)
    self.dir = d:normalizeInplace()
    local a, _ = d:toPolar()

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

    self.angle = -a
    self.physbody:setAngle(self.angle + math.pi)
    -- }}}
end

function Turret:update()
    -- {{{
    -- поворачивать башню только у танка игрока
    if playerTank and self.tank == playerTank then
        self:rotateToMouse()
    end
    if self.fireCoro then
        local ok, errmsg: boolean, string = coroutine.resume(self.fireCoro) as (boolean, string)
        if not ok then
            print("local ok: boolean = coroutine.resume(self.fireCoro)", errmsg)
        end
        self.fireCoro = nil
    end
    -- }}}
end

function Turret:present()
    -- {{{
    if not self.fixtureTower or not self.fixtureBarrel then
        return
    end

    local towerShape = self.fixtureTower:getShape()
    local barrelShape = self.fixtureBarrel:getShape()

    if towerShape:getType() ~= "polygon" or barrelShape:getType() ~= "polygon" then
        error("Only polygon shapes are allowed.")
    end

    local body = self.fixtureTower:getBody()

    --    1   2   3   4   5   6   7   8
    local tx1, ty1, tx2, ty2, tx3, ty3, tx4, ty4 = self.towerShape:getPoints()

    tx1, ty1 = body:getWorldPoints(tx1, ty1)
    tx2, ty2 = body:getWorldPoints(tx2, ty2)
    tx3, ty3 = body:getWorldPoints(tx3, ty3)
    tx4, ty4 = body:getWorldPoints(tx4, ty4)

    tx1, ty1 = M2PIX * tx1, M2PIX * ty1
    tx2, ty2 = M2PIX * tx2, M2PIX * ty2
    tx3, ty3 = M2PIX * tx3, M2PIX * ty3
    tx4, ty4 = M2PIX * tx4, M2PIX * ty4

    --    1   2   3   4   5   6   7   8
    local bx1, by1, bx2, by2, bx3, by3, bx4, by4 = self.barrelShape:getPoints()

    bx1, by1 = body:getWorldPoints(bx1, by1)
    bx2, by2 = body:getWorldPoints(bx2, by2)
    bx3, by3 = body:getWorldPoints(bx3, by3)
    bx4, by4 = body:getWorldPoints(bx4, by4)

    bx1, by1 = M2PIX * bx1, M2PIX * by1
    bx2, by2 = M2PIX * bx2, M2PIX * by2
    bx3, by3 = M2PIX * bx3, M2PIX * by3
    bx4, by4 = M2PIX * bx4, M2PIX * by4

    turretBatch:present(
        tx1, ty1, tx2, ty2, tx3, ty3, tx4, ty4, 
        turretCommon.towerRectXY[1], 
        turretCommon.towerRectXY[2], 
        --turretCommon.towerRectWH[1], 
        --turretCommon.towerRectWH[2]
        turretCommon.towerRectWH[1], 
        turretCommon.towerRectWH[2]
    )
    turretBatch:present(
        bx1, by1, bx2, by2, bx3, by3, bx4, by4, 
        turretCommon.barrelRectXY[1], 
        turretCommon.barrelRectXY[2], 
        turretCommon.barrelRectWH[1], 
        turretCommon.barrelRectWH[2]
    )

    -- }}}
end

function Base.new(t: Tank): Base
    -- {{{
    local Base_mt: metatable<Base> = {
        __index = Base,
    }

    if DEBUG_BASE then
        print("BaseP.new()")
    end
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

    self.physbody = love.physics.newBody(physworld, 0, 0, "dynamic")
    self.physbody:setAngularDamping(3.99)
    self.physbody:setLinearDamping(2)
    self.physbody:setUserData(self)

    if DEBUG_PHYSICS then
        print("angular damping", self.physbody:getAngularDamping())
        print("linear damping", self.physbody:getLinearDamping())
    end

    local px, py = t.pos.x, t.pos.y

    -- XXX Не используется rectXY, будут проблемы при перемещении выделения на текстуре.
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

    local shape = love.physics.newPolygonShape(vertices)
    self.fixture = love.physics.newFixture(self.physbody, shape as love.physics.Shape)
    --self.f:setGroupIndex(tankCollisionGroup)
    self.polyshape = shape
    if DEBUG_TURRET then
        print("polygon shape created x, y, r", px, py)
    end

    return self
    -- }}}
end

-- TODO сделать меньше копирований
-- TODO Попробовать выставялть матрицы проекции для каждого танка вместо
-- заполнения сетки.
function Base:present()
    -- {{{
    local shape = self.fixture:getShape()
    if shape:getType() ~= "polygon" then
        error("Tank BaseP shape should be polygon.")
    end

    if DEBUG_PHYSICS then
        drawFixture(self.fixture, {0, 0, 0, 1})
    end

    local body = self.fixture:getBody()
    --    1   2   3   4   5   6   7   8
    local x1, y1, x2, y2, x3, y3, x4, y4 = self.polyshape:getPoints()

    x1, y1 = body:getWorldPoints(x1, y1)
    x2, y2 = body:getWorldPoints(x2, y2)
    x3, y3 = body:getWorldPoints(x3, y3)
    x4, y4 = body:getWorldPoints(x4, y4)

    x1, y1 = M2PIX * x1, M2PIX * y1
    x2, y2 = M2PIX * x2, M2PIX * y2
    x3, y3 = M2PIX * x3, M2PIX * y3
    x4, y4 = M2PIX * x4, M2PIX * y4

    baseBatch:present(
        x1, y1, x2, y2, x3, y3, x4, y4, 
        self.rectXY[1], self.rectXY[2], self.rectWH[1], self.rectWH[2]
    )

    self.x4 = x4
    self.y4 = y4
    self.x1 = x1
    self.y1 = y1
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
    local linew = 2
    local olw = gr.getLineWidth()
    gr.setLineWidth(linew)
    gr.setColor{0, 0, 0, 1}
    for _, v in ipairs(self.track) do
        gr.line(v[1], v[2], v[3], v[4])
        gr.line(v[5], v[6], v[7], v[8])
    end
    gr.setLineWidth(olw)
end

local function onBeginContact(
    fixture1: love.physics.Fixture, 
    fixture2: love.physics.Fixture, 
    contact: love.physics.Contact
)
    -- {{{
    --[[
  --if drawContactPoints then
    --local x1, y1, x2, y2 = contact:getPositions()
    --local body1 = fixture1:getBody()
    --local body2 = fixture2 and fixture2:getBody() or nil  
    --if x1 and y1 then
----    x1, y1 = Snake.cam:worldCoords(x1, y1)
      ---- отправляю контакты на отрисовку
      --push2drawlist(function()
          --lg.setColor(CONTACT_BEGIN_DRAW_COLOR)
          --lg.circle("fill", x1 * M2PIX, y1 * M2PIX, 10)
        --end)
    --end
    --if x2 and y2 then    
      --x2, y2 = Snake.cam:worldCoords(x2, y2)
      ---- отправляю контакты на отрисовку
      --push2drawlist(function()
          --lg.setColor(CONTACT_BEGIN_DRAW_COLOR)
          --lg.circle("fill", x2 * M2PIX, y2 * M2PIX, 10)
        --end)
    --end
  --end
  --]]

    local p1x, p1y, p2x, p2y = contact:getPositions()

    local body1 = fixture1:getBody()
    local userdata1: {any:any} = body1:getUserData() as {any:any}
    local body2 = fixture2:getBody()
    local userdata2: {any:any} = body2:getUserData() as {any:any}

    if userdata1 and userdata1.objectType and userdata1.objectType == "Bullet" then
        print('1111111')
        if userdata2.objectType then
            if userdata2.objectType == "Turret" then
                print('Bullet with Turret')
            elseif userdata2.objectType == "Base" then
                print('Bullet with Base')
            end
        end
    end

    if userdata2 and userdata2.objectType and userdata2.objectType == "Bullet" then
        print('2222222')
        if userdata1.objectType then
            if userdata1.objectType == "Turret" then
                print('Turret with Bullet')
            elseif userdata1.objectType == "Base" then
                print('Base with Base')
            end
        end
    end

    push2drawlistTop(function()
        local contactRadius = 3
        gr.setColor{1, 0, 0, 1}
        if p1x and p1y then
            p1x, p1y = p1x * M2PIX, p1y * M2PIX
            gr.circle('fill', p1x, p1y, contactRadius)
        end
        if p2x and p2y then
            p2x, p2y = p2x * M2PIX, p2y * M2PIX
            gr.circle('fill', p2x, p2y, contactRadius)
        end
    end)
      -- }}}
end

local function onEndContact(
        _: love.physics.Fixture, 
        _: love.physics.Fixture,
        _: love.physics.Contact
    )
    -- {{{
    -- }}}
end

local function onQueryBoundingBox(fixture: love.physics.Fixture): boolean
    -- {{{
    local selfPtr: {any:any} = fixture:getBody():getUserData() as {any:any}
    if selfPtr and selfPtr['present'] then
        (selfPtr['present'] as function)(selfPtr, fixture)
    end
    return true
    -- }}}
end

local function queryBoundingBox()
    -- {{{
    if cam then
        local tlx, tly = cam:worldCoords(0, 0)
        local brx, bry = cam:worldCoords(gr.getDimensions())
        brx, bry = brx + W, bry + H

        if DEBUG_PHYSICS then
            -- рисовать окно ограничивающего прямоугольника
            push2drawlistTop(function()
                local oldwidth = gr.getLineWidth()
                local lwidth = 4
                gr.setLineWidth(lwidth)
                gr.setColor{0., 0., 1.}
                gr.rectangle("line", tlx, tly, brx - tlx, bry - tly)
                gr.setLineWidth(oldwidth)
            end)
        end

        physworld:queryBoundingBox(
            tlx * PIX2M, tly * PIX2M, 
            brx * PIX2M, bry * PIX2M, 
            onQueryBoundingBox
        )
    end
    -- }}}
end

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

local function bindTerrainControlKeys()
    local kc = KeyConfig
    kc.bind(
        'keypressed', { key = "c" },
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end
            print('drawTerrain', drawTerrain)
            drawTerrain = not drawTerrain
            return false, sc
        end,
        --i18n("mt" .. "right"))
        'none')
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

local function changeKeyConfigListbackground()
    -- {{{
    KeyConfig.setListSetupCallback(function(list: List)
        list.colors.normal = {bg = {0.19, 0.61, 0.88}, fg = {1, 1., 1., 1.}}
    end)
    -- }}}
end

local function drawParticlesEditor()
end

local function drawui()
    -- {{{
    imgui.StyleColorsLight()
    imgui.ShowDemoWindow()
    imgui.ShowUserGuide()

    drawParticlesEditor()

    -- }}}
end

local function moveCameraToPlayer()
    -- {{{
    if playerTank then
        local x, y = playerTank.base.physbody:getWorldCenter()
        x, y = x * M2PIX, y * M2PIX
        cam:lookAt(x, y)
    end
    -- }}}
end

local function bindCameraControl()
    -- {{{
    -- не прямой а квадратичный зум?
    local cameraAnimationDuration = 0.2

    local function makeMoveFunction(xc: number, yc: number): function(sc: Shortcut): boolean, Shortcut
        -- {{{
        return function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end
            local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
            camTimer:during(cameraAnimationDuration, 
                function(dt: number, time: number, delay: number)
                    local dx = -reldx * (delay - time) * xc
                    local dy = -reldy * (delay - time) * yc
                    if delay - time > 0 then
                        cam:move(dx * dt, dy * dt)
                    end
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
            moveCameraToPlayer()
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
            linesbuf.show = not linesbuf.show
            return false, sc
        end
    )
    -- }}}
end

-- Сомнительная функция, не работает наверное.
local function bindEscape()
    -- {{{
    KeyConfig.bind("keypressed", { key = "escape" }, function(sc: Shortcut): boolean, Shortcut
        if mode ~= "normal" then
            return false, sc
        end
        if showLogo == true then
            love.event.quit()
        else
            showLogo = true
        end
        return false, sc
    end)
    -- }}}
end

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

local function processAttachedVariables()
    for _, v in pairs(attachedVarsList) do
        v()
    end
end

local function stats()
    linesbuf:pushi('Lua used %d Mb', (collectgarbage('count') as integer)/ 1024)
    local stat = love.graphics.getStats()
    linesbuf:pushi('drawcalls %d', stat.drawcalls)
    linesbuf:pushi('canvasswitches %d', stat.canvasswitches)
    --linesbuf:pushi('texturememory %d', (stat.texturememory as integer) / 1024)
end 

local function konsolePresent()
    -- {{{
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

    cam:attach()
    linesbuf:draw()
    cam:detach()

    if suggestList then
        -- XXX если раскоментить следущую строку, то программа падает.
        --suggestList:draw()
    end
    -- }}}
end

function Background.new(): Background
    -- {{{
    local Background_mt: metatable<Background> = {
        __index = Background,
    }
    local self = setmetatable({} as Background, Background_mt)
    --self.img = gr.newImage(SCENE_PREFIX .. "/grass.jpg")
    --self.img = gr.newImage(SCENE_PREFIX .. "/forrest_ground_01_diff_4k.jpg")
    self.img = gr.newImage(SCENE_PREFIX .. "/grass3.jpg")

    return self
    -- }}}
end

function Background:present()
    -- {{{
    local len = 50
    local imgw, imgh = (self.img as gr.Texture):getDimensions()
    local sx, sy = 1, 1
    gr.setColor(1, 1, 1, 1)
    for i = 0, len - 1 do
        for j = 0, len - 1 do
            gr.draw(self.img as gr.Drawable, i * imgw * sx, j * imgh * sy, 0, sx, sy)
        end
    end
    -- }}}
end

local isCameraCircleOut: boolean = false

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

local function mainPresent()
    baseBatch:prepare()
    turretBatch:prepare()

    push2drawlistTop(drawBullets)

    cam:attach()
    --background:present()
    if drawTerrain and diamondSquare then
            --diamondSquare:draw()
            diamondSquare:present()
    end
    queryBoundingBox()

    presentDrawlistBottom()

    baseBatch:flush()
    turretBatch:flush()

    presentDrawlistTop()

    cam:detach()

    drawCameraCircle()

    drawlistTop = {}
    drawlistBottom = {}

    changeKeyConfigListbackground()

    coroutine.yield()
end

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

local function draw()
    -- {{{
    local ok, errmsg: boolean, string = coroutine.resume(drawCoro) as (boolean, string)
    if not ok then
        error("drawCoro thread is end: " .. errmsg)
    end
    if cmd_drawCameraAxixes then
        drawCameraAxixes()
    end
    konsolePresent()

    --drawArrow(300, 600, 400, 600, {1, 0, 0, 1})
    --drawArrow(0, 0, 40, 700, {0, 1, 0, 1})
    --drawArrow(600, 300, 40, 300, {0, 0, 1, 1})
    -- }}}
end

local function updateTanks()
    -- {{{
    local alive: {Tank} = {}
    for _, v in ipairs(tanks) do
        local t =  v:update()
        if t then
            table.insert(alive, t)
        end
    end
    tanks = alive
    -- }}}
end

--[[ Функция двигает камеру если координаты центра масс танка игрока выходят за
радиус камеры.
--]]
local function moveCamera()
    if playerTank then
        local w, h = gr.getDimensions()
        local centerx, centery = w / 2, h / 2
        --print("centerx, centery", centerx, centery)
        local tankx, tanky = playerTank.base.physbody:getWorldCenter()
        --print("tankx, tanky", tankx, tanky)
        local diff = vecl.dist(centerx, centery, tankx, tanky)
        --print("diff", diff)
    end
end

local function update(dt: number)
    camTimer:update(dt)
    physworld:update(1 / 60)
    linesbuf:update()
    updateTanks()
    updateBullets()
    arena:update()
    coroutinesUpdate()
    moveCamera()
end

local function backspaceCmdLine()
    -- {{{
    local u8 = require "utf8"
    -- get the byte offset to the last UTF-8 character in the string.
    local byteoffset = u8.offset(cmdline, -1)
    if byteoffset then
        -- remove the last UTF-8 character.
        -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
        cmdline = string.sub(cmdline, 1, byteoffset - 1)
        if cursorpos - 1 >= 1 then
            cursorpos = cursorpos - 1
        end
    end
    -- }}}
end

local function enterCommandMode()
    -- {{{
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
        --]]
    end
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

-- TODO
function konsolePrint(...: any)
    -- {{{
    for _, v in ipairs({...}) do
        if type(v) == "string" then
            linesbuf:push(0.5, tostring(v))
        else
            colprint("konsolePrint warning")
        end
    end
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
                    linesbuf:pushi(output)
                    linesbuf:pushi(string.format("%s", varname))
                    --else
                        --linesbuf:pushi(string.format('%s = %s', varname, tostring(l)))
                    --end
                else
                    linesbuf:pushi(string.format("%s = nil", varname))
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
-- Aliases section
if not _G['pt'] then
    pt = playerTank
end

function editor()
    mode = 'editor'
    print('mode', mode)
end

function exiteditor()
    arena:save2file('arena.lua')
    mode = 'normal'
    print('mode', mode)
end

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

-- XXX Global variable
systemPrint = print
--print = konsolePrint

if not __ATTACH_ONCE__ then
    print('before')
    -- attached variables
    --attach("playerTank")
    --attach("DEFAULT_W")
    --attach("DEFAULT_H")
    --attach("W")
    --attach("H")
    --attach("M2PIX")
    --attach("PIX2M")
    --attach("tankForceScale")
    --attach("cam")
    --attach("showLogo")
    --attach("playerTankKeyconfigIds")
    --attach("angularImpulseScale")
    --attach("rot")
    --attach("camZoomLower")
    --attach("camZoomHigher")
    --attach("pworld")
    ----attach("tanks")
    --attach("playerTank")
    --attach("background")
    --attach("logo")
    ----attach("bullets")
    --attach("bulletLifetime")
    --attach("tankCounter")
    --attach("rng")
    --print('after')
    __ATTACH_ONCE__ = true
    attach('mode')
    attach("tankCounter")
end
    ]]
    -- }}}

    --local preload = [[]]

    cmdline = trim(cmdline)
    local func, loaderrmsg: function, string = load(preload .. cmdline)
    local time = 2

    --TODO в обработке ошибок искать ]:1: и обрезать сообщение об ошибке.
    if not func then
        linesbuf:push(time, "load() errmsg: " .. loaderrmsg)
        print("load() errmsg:|" .. loaderrmsg .. "|")
    else
        local ok, pcallerrmsg: boolean, string = pcall(function()
            func()
        end)
        if not ok then
            linesbuf:push(time, "pcall() errmsg: " .. pcallerrmsg)
            print("pcall() errmsg:|" .. pcallerrmsg .. "|")
        end
    end
    --local trimmed = trim(cmdline) or ""
    if #cmdline ~= 0 then
        table.insert(cmdhistory, cmdline)
        love.filesystem.append(historyfname, cmdline .. "\n")
    end
    suggestList = nil
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
    if not suggestList then
        suggestList = List.new()
    end
    -- Как рисовать список идентификаторов?
    for k, v in pairs(_G as {any:any}) do
        suggestList:add(string.format("%s: %s", tostring(k), tostring(v)))
    end
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
        if key == ";" and love.keyboard.isDown("lshift") then
            enterCommandMode()
        end
    end
    -- }}}
end

-- положение в метрах
local function spawnTank(pos: vector, dir: vector): Tank
    -- {{{
    local ok, errmsg: boolean, string = pcall(function()
        if #tanks >= 1 then
            -- XXX next line not work
             --unbindPlayerTankKeys()
        end
        table.insert(tanks, Tank.new(pos, dir))
        if DEBUG_TANK then
            print("Tank spawn at", pos.x, pos.y)
        end
    end)
    if not ok then
        error("Could'not load. Please implement stub-tank. " .. errmsg)
    end
    return tanks[#tanks]
    -- }}}
end

global cameraKeyConfigIds: {integer} = {}

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
                if cam.scale < camZoomHigher then
                    cam:zoom(1. + zoomSpeed)
                end
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
                if cam.scale > camZoomLower then
                    cam:zoom(1.0 - zoomSpeed)
                end
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

local function setWindowMode()
    love.window.setMode(DEFAULT_W, DEFAULT_H, { resizable = false })
end

local function setFullscreenMode()
    love.window.setFullscreen(true)
end

local function bindFullscreenSwitcher()
    -- {{{
    KeyConfig.bind(
        "keypressed", 
        { key = "f11" }, 
        function(sc: KeyConfig.Shortcut): boolean, KeyConfig.Shortcut
            local isfs = love.window.getFullscreen()
            if isfs then
                setWindowMode()
            else
                setFullscreenMode()
            end
            return false, sc
        end,
        "switch fullscreen and windowed modes", 
        "switchwindowmode")
        -- }}}
end

function Logo.new(): Logo
    -- {{{
    local Logo_mt: metatable<Logo> = {
        __index = Logo,
    }

    if DEBUG_LOGO then
        print("Logo.new()")
    end
    local self = setmetatable({} as Logo, Logo_mt)
    local fname = SCENE_PREFIX .. "/t80_background_2.png"
    self.image = love.graphics.newImage(fname)
    local tex = self.image as gr.Texture
    local ceil = math.ceil
    local windowscale = 0.7
    self.imgw, self.imgh = ceil(tex:getWidth()), ceil(tex:getHeight())
    DEFAULT_W, DEFAULT_H = ceil(self.imgw * windowscale), ceil(self.imgh * windowscale)
    self.sx, self.sy = DEFAULT_W / self.imgw, DEFAULT_H / self.imgh
    setWindowMode()
    if DEBUG_LOGO then
        print("self.imgw, self.imgh:", self.imgw, self.imgh)
        print("self.sx, self.sy:", self.sx, self.sy)
    end
    return self
    -- }}}
end

function Logo:present()
    -- {{{
    gr.setColor{1, 1, 1, 1}
    --print('Logo:present() self.sx, self.sy:', self.sx, self.sy)
    love.graphics.draw(self.image as gr.Drawable, 0, 0, 0., self.sx, self.sy)
    coroutine.yield()
    -- }}}
end

local function createDrawCoroutine(): thread
    return coroutine.create(function()
        if DEBUG_DRAW_THREAD then
            print("drawCoro started")
        end
        while true do
            -- режим игрового меню
            while showLogo == true do
                logo:present()
            end
            -- режим сражения
            while showLogo == false do
                mainPresent()
            end
        end
        if DEBUG_DRAW_THREAD then
            print("drawCoro finished")
        end
    end)
end

-- параметры в метрах
local function makeArmy(x: number, y: number)
    -- {{{
    x = x or 0
    y = y or 0
    local len = 10
    local space = 200
    pushDEBUG()
    disableDEBUG()
    for i = 1, len do
        for j = 1, len do
            spawnTank(vector.new(x + i * space, y + j * space))
        end
    end
    popDEBUG()
    -- }}}
end

local function physInit()
    local canSleep = true
    physworld = love.physics.newWorld(0., 0., canSleep)
    if DEBUG_PHYSICS then
        print("physics world canSleep:", canSleep)
    end
    physworld:setCallbacks(onBeginContact, onEndContact)
    physworld:setContactFilter(contactFilter)
end

--local effect: moonshine.Effect
--local effect: any

function drawMiniMap()

end

function terrain(mapn: integer, rez: integer)
    if not mapn then
        mapn = 8
    end
    if not rez then
        rez = 32
    end
    print('terrain', mapn, rez)
    linesbuf:push(notificationDelay, 'terrain mapn = %d, rez = %d', mapn, rez)
    diamondSquare = DiamonAndSquare.new(mapn, rez, rng)
    diamondSquare:eval()
    diamondSquare:draw2canvas()
    diamondSquare.canvas:newImageData():encode('png', 'terrain.png')
end

local function init()
    -- {{{
    metrics.init()
    setWindowMode()

    --effect = moonshine.chain(moonshine.effects.filmgrain).
        --chain(moonshine.effects.vignette)

    loadLocales()
    physInit()

    logo = Logo.new()
    cam = require 'camera'.new()
    if DEBUG_CAMERA then
        print("camera created x, y, scale, rot", cam.x, cam.y, cam.scale, cam.rot)
    end

    bindCameraZoomKeys()
    bindCameraControl()
    bindFullscreenSwitcher()
    bindEscape()
    bindKonsole()
    bindTerrainControlKeys()

    drawCoro = createDrawCoroutine()

    background = Background.new()
    arena = Arena.new("arena.lua")

    --makeArmy()
    --makeArmy()
    --makeArmy()
    --makeArmy()
    --makeArmy()
    --makeArmy()

    --for _ = 1, 30 do 
    for i = 1, 13 do 
        for j = 1, 3 do
            spawnTank(vector.new(j * 45, i * 30))
        end
    end

    --local startpos = vector.new(500, 500)
    --local startpos = vector.new(-500, 500)
    local startpos = vector.new(0, 0)

    -- TODO прикрепить камеру к игроку
    playerTank = spawnTank(startpos)
    bindPlayerTankKeys()

    --makeArmy()
    --makeArmy(0, 500)
    --makeArmy(500, 0)
    --makeArmy(500, 500)

    --enableDEBUG()
    disableDEBUG()

    bugInit()
    terrain()

    cameraZoneR = H / 2
    -- }}}
end

-- работает плохо, сбрасывается отладочное рисование
function reset()
    print('reset')
    -- обрати внимание, происходит глобольная очистка клавиш
    KeyConfig.clear()
    if physworld then
        physworld:destroy()
        print('physworld destroyed.')
        local object: love.Object = physworld as love.Object
        object:release()
        print('physworld object released.')
        physworld = nil
    end
    tanks = {}
    playerTank = {}
    bullets = {}
    baseBatch = Batch.new("tank_body_small.png")
    turretBatch = Batch.new("tank_tower.png")

    --pushDEBUG()
    init()
    --popDEBUG()
end

local function quit()
    -- {{{
    metrics.quit()
    unbindPlayerTankKeys()
    tanks = {}
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

local function mousepressed(x: number, y: number, btn: integer)
    -- {{{
    metrics.mousepressed(x, y, btn)
    if mode == 'normal' then
        if btn == 1 then
            if playerTank then
                playerTank:fire()
            end
        elseif btn == 2 then
            x, y = cam:worldCoords(x, y)
            x, y = x * PIX2M, y * PIX2M
            spawnTank(vector.new(x, y))
        end
    elseif mode == 'editor' then
        arena:mousepressed(x, y, btn)
    end
    -- }}}
end

local function resize(neww: integer, newh: integer)
    -- {{{
    metrics.resize(neww, newh)
    if DEBUG_CAMERA then
        print("tanks window resized to w, h", neww, newh)
    end
    W, H = neww, newh
    cameraZoneR = newh / 2
    -- FIXME Нужно менять эти переменные?
    DEFAULT_W, DEFAULT_H = neww, newh
    -- }}}
end

local function textinput(text: string)
    -- {{{
    metrics.textinput(text)
    if mode == "command" then
        -- Здесь добавить курсор.
        --cmdline = cmdline .. text
        local sub = string.sub
        cmdline = sub(cmdline, 1, cursorpos - 1) .. text .. sub(cmdline, cursorpos, #cmdline)
        cursorpos = cursorpos + 1
    end
    -- }}}
end

return {
    -- {{{
    init = init,
    quit = quit,
    draw = draw,
    drawui = drawui,
    update = update,
    keypressed = keypressed,
    mousepressed = mousepressed,
    resize = resize,
    textinput = textinput,
    mousemoved = mousemoved,
    wheelmoved = wheelmoved
    -- }}}
}

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

