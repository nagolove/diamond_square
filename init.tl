-- vim: fdm=marker
-- vim: set colorcolumn=85

global SCENE_PREFIX = "scenes/t80u"

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

local List = require "list"
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

-- Пушка вместе с башней
local record Turret
    -- {{{
    physbody: love.physics.Body
    fixture: love.physics.Fixture
    image: love.graphics.Image
    angle: number
    tank: Tank
    -- куда смотрит башня, направление выстрела
    dir: vector

    new: function(t: Tank): Turret
    present: function(Turret)
    update: function(Turret)
    fire: function(Turret)
    rotateToMouse: function(Turret)
    -- }}}
end


local record Bullet
    -- {{{
    body: love.physics.Body
    timestamp: number
    -- }}}
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

-- Ходовая часть с полигоном
local record Base
    -- {{{
    physbody: love.physics.Body
    fixture: love.physics.Fixture
    image: love.graphics.Image
    --pos: vector -- центр поворота корпуса
    tank: Tank
    mesh: love.graphics.Mesh
    polyshape: lp.PolygonShape

    --meshVerts: {Vertex}
    meshVerts: {{number}}

    new: function(t: Tank): Base
    present: function(Base)
    updateMeshVerts: function(Base)
    updateMeshTexCoords: function(Base, x: number, y: number, w: number, h: number)
    initMeshVerts: function(Base)
    -- }}}
end

-- Класс основного боевого танка.
local record Tank
    -- {{{
    physbody: love.physics.Body
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
    updateDir: function(Tank)
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

--global DEBUG_DRAW_THREAD = true
--global DEBUG_TEXCOORDS = true
--global DEBUG_PHYSICS = true

global DEBUG_DRAW_THREAD = false
global DEBUG_TEXCOORDS = false
global DEBUG_PHYSICS = false

-- Глобальные флаги отображения
global cmd_drawBodyStat: boolean = true
global cmd_drawCameraAxixes: boolean = false

local debugStack: {{string:boolean}} = {}
-- }}}

-- {{{ Global and local variables.

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
global tankForceScale = 3

-- {{{ Konsole editing
local historyfname = "cmdhistory.txt"
local linesbuf = require "kons".new(SCENE_PREFIX .. "/VeraMono.ttf", 20)
local mode: Mode = "normal"
local cmdline: string = ""
local cmdhistory: {string} = {}
global suggestList: List = List.new()
global attachedVarsList: {string: function} = {}
-- }}}

local drawlist: {DrawNode} = {}
global cam: Camera
local camTimer: Timer = require "Timer".new()
local drawCoro: thread = nil
global showLogo = true
global playerTankKeyconfigIds: {integer} = {}
global angularImpulseScale = 5
global rot = math.pi / 4
global camZoomLower, camZoomHigher = 0.075, 3.5
local cameraSettings: CameraSettings = {
    -- значение в пикселях
    dx = 100, dy = 100,
}
-- Экземпляр box2d
global pworld: love.physics.World
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
local bulletColor = {1, 1, 1, 1}
-- Продолжительность жизни снаряда в секундах.
global bulletLifetime = 1
global tankCounter = 0
global rng: love.math.RandomGenerator = love.math.newRandomGenerator()

local cameraZoneR: number
-- }}}

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

    gr.setColor(color)

    -- left line
    gr.line(tox, toy, tox - lx, toy - ly)
    -- right line
    gr.line(tox, toy, tox - rx, toy - ry)
    -- main line
    gr.line(fromx, fromy, tox, toy)
    -- }}}
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
    for _, v in ipairs(bullets) do
        local diff = now - v.timestamp
        if diff > bulletLifetime then
            -- умер снаряд
        end
        table.insert(alive, v)
    end
    bullets = alive
    -- }}}
end

-- размеры в метрах
local function spawnBullet(px: number, py: number, dirx: number, diry: number)
    -- {{{
    print("spawnBullet")
    local bullet: Bullet = {}
    bullet.body = love.physics.newBody(pworld, px, py, "kinematic")
    --bullet.body = love.physics.newBody(pworld, px, py, "static")
    bullet.timestamp = love.timer.getTime()
    --local shape = love.physics.newCircleShape(px, py, bulletRadius)
    local shape = love.physics.newCircleShape(0, 0, bulletRadius * PIX2M)
    local fixture = love.physics.newFixture(bullet.body, shape as lp.Shape)
    --fixture:setGroupIndex(bulletCollisionGroup)
    fixture:setMask(bulletMask)
    if dirx and diry then
        print("bullet.body:applyLinearImpulse", dirx, diry)
        bullet.body:applyLinearImpulse(dirx, diry)
    end
    table.insert(bullets, bullet)
    -- }}}
end

function Turret:fire()
    -- {{{
    if DEBUG_TURRET then
        print("Turret:fire()")
    end
    local px, py = self.tank.physbody:getWorldCenter()
    local scale = 3
    print("pbody", px, py)
    spawnBullet(px, py, self.dir.x * scale, self.dir.y * scale)
    -- }}}
end

local function presentDrawlist()
    -- {{{
    for _, v in ipairs(drawlist) do
        if v.self then
            v.f(v.self)
        else
            v.f()
        end
    end
    -- }}}
end

function push2drawlist(f: function, self: any)
    -- {{{
    if not f then
        error("Draw could'not be nil.")
    end
    if type(f) ~= "function" then
        error("Draw function is not a function. It is a .. " .. type(f))
    end
    table.insert(drawlist, { f = f, self = self})
    -- }}}
end

function Tank:fire()
    -- {{{
    if self.turret then
        self.turret:fire()
    end
    -- }}}
end

function Tank:left()
    -- {{{
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:left")
    end
    local imp = -angularImpulseScale * rot
    print("mass", self.physbody:getMass())
    if DEBUG_PHYSICS then
        print("Tank " .. self.id .. " applyTorque", imp)
    end
    self.physbody:applyTorque(imp)
    -- }}}
end

function Tank:right()
    -- {{{
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:right")
    end
    local imp = angularImpulseScale * rot
    print("mass", self.physbody:getMass())
    if DEBUG_PHYSICS then
        print("Tank " .. self.id .. " applyTorque", imp)
    end
    self.physbody:applyTorque(imp)
    -- }}}
end

function Tank:forward()
    -- {{{
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:forward")
    end
    local x, y = self.dir.x * tankForceScale, self.dir.y * tankForceScale
    if DEBUG_PHYSICS then
        print("Tank " .. self.id .. " applyForce x, y", x, y)
    end
    self.physbody:applyForce(x, y)
    --self.pbody:applyLinearImpulse(x, y)
    -- }}}
end

function Tank:backward()
    -- {{{
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:backward")
    end
    --if DEBUG_PHYSICS then
        --print("Tank " .. self.id .. "applyForce x, y", x, y)
    --end
    local x, y = self.dir.x * tankForceScale, self.dir.y * tankForceScale
    print('applied', x, y)
    self.physbody:applyForce(x, y)
    --self.pbody:applyLinearImpulse(-x, -y)
    -- }}}
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

    self.physbody = love.physics.newBody(pworld, 0, 0, "dynamic")
    self.physbody:setUserData(self)

    if not dir then
        dir = vector.new(0, -1)
    end
    --self.pbody:setAngle(math.pi / 3)

    self.id = tankCounter
    self.dir = dir:clone()
    self.pos = pos:clone()
    self.turret = Turret.new(self)
    self.base = Base.new(self)

    if DEBUG_PHYSICS then
        print("angular damping", self.physbody:getAngularDamping())
        print("linear damping", self.physbody:getLinearDamping())
    end

    self.physbody:setAngularDamping(3.99)
    self.physbody:setLinearDamping(2)

    if DEBUG_PHYSICS then
        print("angular damping", self.physbody:getAngularDamping())
        print("linear damping", self.physbody:getLinearDamping())
    end

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

function Tank:drawDirectionVector()
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

function Tank:resetVelocities()
    -- {{{
    if self.physbody then
        self.physbody:setAngularVelocity(0)
        self.physbody:setLinearVelocity(0, 0)
    end
    -- }}}
end

function Tank:updateDir()
    -- {{{
    local unit = 1
    -- возможно зад перепутан с передом
    self.dir = vec2.fromPolar(self.physbody:getAngle() + math.pi / 2, unit)
    -- }}}
end

function Tank:update(): Tank
    -- {{{
    --print("Tank:update()")
    --print("body angle", self.pbody:getAngle())

    self:updateDir()

    if self.turret then
        self.turret:update()
    end

    return self
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
    else
        colprint('Tank ' .. self.id .. ' is damaged. No turret.')
    end
    if cmd_drawBodyStat then
        self:drawDirectionVector()
        drawBodyStat(self.physbody)
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
    self.image = love.graphics.newImage(SCENE_PREFIX .. "/tank_tower.png")
    self.physbody = t.physbody

    if DEBUG_TURRET then
        print("self.tank", self.tank)
        print("self.pbody", self.physbody)
        print("self.img", self.image)
    end

    local w, _ = (self.image as love.graphics.Texture):getDimensions()
    local r = w / 2
    local px, py = self.tank.physbody:getPosition()
    local shape = love.physics.newCircleShape(t.pos.x, t.pos.y, r * PIX2M)
    self.fixture = love.physics.newFixture(self.physbody, shape as love.physics.Shape)
    --self.f:setGroupIndex(tankCollisionGroup)

    if DEBUG_TURRET then
        print("circle shape created x, y, r", px, py)
    end

    return self
    -- }}}
end

local __ONCE__ = false

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
        if not __ONCE__ then
            __ONCE__ = true
            print("vertices", inspect(points))
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

-- Как сделать медленный поворот башни?
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
    -- }}}
end

function Turret:update()
    -- {{{
    -- поворачивать башню только у танка игрока
    if playerTank and self.tank == playerTank then
        self:rotateToMouse()
    end
    -- }}}
end

function Turret:present()
    -- {{{
    if not self.fixture then
        error("Turret:present() - fixture is nil")
    end

    local imgw, imgh = (self.image as love.graphics.Texture):getDimensions()
    local r, sx, sy, ox, oy: number = 0., 1., 1., 0, 0
    --local kx, ky: number = 1., 1.
    local shape = self.fixture:getShape()
    local cshape = self.fixture:getShape() as love.physics.CircleShape

    if shape:getType() ~= "circle" then
        error("Only circle shape allowed.")
    end
    local px, py = cshape:getPoint()
    px, py = self.physbody:getWorldPoints(px, py)
    px, py = px * M2PIX, py * M2PIX
    r = cshape:getRadius() * M2PIX

    if DEBUG_PHYSICS then
        --gr.setColor{1, 0.5, 0, 0.5}
        --gr.circle("fill", px, py, r)
        --drawFixture(self.f)
    end

    gr.setColor{1, 1, 1, 1}
    love.graphics.draw(
        self.image as love.graphics.Drawable,
        px, py,
        self.angle, 
        sx, sy, 
        ox + imgw / 2, oy + imgh / 2
    )

    --local white = {1, 1, 1, 1}
    --gr.setColor(white)
    --love.graphics.rectangle("line", 

    --for _, f in ipairs(self.pbody:getFixtures()) do
        --drawFixture(f)
    --end
    --local x, y = self.pbody:getWorldCenter()
    --local text = string.format("%d", self.tank.id)
    --gr.print(text, x, y)

    -- }}}
end

function Base:present()
    -- {{{
    local shape = self.fixture:getShape()
    if shape:getType() ~= "polygon" then
        error("Tank BaseP shape should be polygon.")
    end

    if DEBUG_PHYSICS then
        drawFixture(self.fixture, {0, 0, 0, 1})
    end

    gr.setColor{1, 1, 1, 1}
    self:updateMeshVerts()
    gr.draw(self.mesh as love.graphics.Drawable, 0, 0)

    --local x, y = self.pbody:getWorldCenter()
    --x, y = x * M2PIX, y * M2PIX
    --local text = string.format("%d", self.tank.id)
    --gr.print(text, x, y)
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
    self.tank = t
    self.image = love.graphics.newImage(SCENE_PREFIX .. "/tank_body_small.png")
    --self.img = love.graphics.newImage(SCENE_PREFIX .. "/tank_body.png")

    -- цифры получены из картинки tank_body_small.png
    local rectXY = {86, 72}
    local rectWH = {84, 111}
    
    self.physbody = t.physbody

    if DEBUG_BASE then
        print("self.tank", self.tank)
        print("self.pbody", self.physbody)
        print("self.img", self.image)
    end

    local px, py = t.pos.x, t.pos.y

    -- XXX Не используется rectXY, будут проблемы при перемещении выделения на текстуре.
    local vertices = {
        px - rectWH[1] / 2 * PIX2M, 
        py - rectWH[2] / 2 * PIX2M,  

        px + rectWH[1] / 2 * PIX2M, 
        py - rectWH[2] / 2 * PIX2M,  

        px + rectWH[1] / 2 * PIX2M, 
        py + rectWH[2] / 2 * PIX2M,  

        px - rectWH[1] / 2 * PIX2M,
        py + rectWH[2] / 2 * PIX2M,
    }

    local shape = love.physics.newPolygonShape(vertices)
    self.fixture = love.physics.newFixture(self.physbody, shape as love.physics.Shape)
    --self.f:setGroupIndex(tankCollisionGroup)
    self.polyshape = shape
    if DEBUG_TURRET then
        print("polygon shape created x, y, r", px, py)
    end

    self:initMeshVerts()
    self.mesh = love.graphics.newMesh(self.meshVerts as {{number}}, 
        "triangles", "dynamic")
    self:updateMeshVerts()
    self.mesh:setTexture(self.image as gr.Texture)
    self:updateMeshTexCoords(rectXY[1], rectXY[2], rectWH[1], rectWH[2])
    
    if not self.mesh then
        error("Could'not create Mesh")
    end

    return self
    -- }}}
end

function Base:updateMeshTexCoords(x: number, y: number, w: number, h: number)
    -- {{{

    --print("updateMeshTexCoords", x, y, w, h)

    -- размеры текстуры в пикселях
    local imgw, imgh = (self.image as gr.Texture):getDimensions()
    -- нормализованная ширина и высота
    local unitw, unith = w / imgw, h / imgh
    -- нормализованные координаты левого верхнего угла выделения
    local x_, y_ = x / imgw, y / imgh

    -- tri1
    self.meshVerts[4][3] = x_
    self.meshVerts[4][4] = y_
    self.meshVerts[5][3] = x_ + unitw
    self.meshVerts[5][4] = y_ + unith
    self.meshVerts[6][3] = x_
    self.meshVerts[6][4] = y_ + unith

    -- tri2
    self.meshVerts[3][3] = x_
    self.meshVerts[3][4] = y_
    self.meshVerts[1][3] = x_ + unitw
    self.meshVerts[1][4] = y_
    self.meshVerts[2][3] = x_ + unitw
    self.meshVerts[2][4] = y_ + unith

    if DEBUG_TEXCOORDS then
        local msg = string.format("(%f, %f), (%f, %f), (%f, %f)",
            self.meshVerts[4][3],
            self.meshVerts[4][4],
            self.meshVerts[5][3],
            self.meshVerts[5][4],
            self.meshVerts[6][3],
            self.meshVerts[6][4]
        )
        print(string.format("BaseP.self.meshVerts texture coordinates: " .. msg))
    end
    -- }}}
end

function Base:initMeshVerts()
    -- {{{
    self.meshVerts = {}
    for _ = 1, 6 do
        table.insert(self.meshVerts, {
            0, 0,           -- 1, 2         - x, y
            0, 0,           -- 3, 4         - u, v
            1, 1, 1, 1,     -- 5, 6, 7, 8   - r, g, b, a
        })
    end
    -- }}}
end

-- TODO сделать меньше копирований
-- TODO Попробовать выставялть матрицы проекции для каждого танка вместо
-- заполнения сетки.
function Base:updateMeshVerts()
    -- {{{
    --if self.tank.pbody:isAwake() then
        self.mesh:setVertices(self.meshVerts)

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

        -- tri1
        self.meshVerts[1][1] = x1
        self.meshVerts[1][2] = y1

        self.meshVerts[2][1] = x2
        self.meshVerts[2][2] = y2

        self.meshVerts[3][1] = x4
        self.meshVerts[3][2] = y4

        -- tri2
        self.meshVerts[5][1] = x2
        self.meshVerts[5][2] = y2

        self.meshVerts[6][1] = x3
        self.meshVerts[6][2] = y3

        self.meshVerts[4][1] = x4
        self.meshVerts[4][2] = y4
        --]]
    --end
    --print("self.meshVerts", inspect(self.meshVerts))
    -- }}}
end

local function onBeginContact(
    _: love.physics.Fixture, 
    _: love.physics.Fixture, 
    _: love.physics.Contact
)
    -- {{{
    --[[
  
  --Добавить здесь преобразование координат из локальных в глобальные. Заполнять списки на отрисовку контактов. Сделать несколько списков отрисовки. Рисуется только
  --то, что попадает в экран камеры. Посмотри+++ на встроенные функции отсечения в движке. Те списки постоянно сбрасывать в nil? Почему-бы и нет, хотя течет динамическая
  --память. Зато структуры динамично работают, видно дейсвие, экшен.

  --local shape = fixture:getShape()
  --local rad = shape:getRadius()
  --local body = fixture:getBody()
  --local x, y = body:getWorldCenter()
  --x, y = x * M2PIX, y * M2PIX

  --lg.setColor(self.color)
  --lg.circle("fill", x, y, shape:getRadius() * M2PIX)

--  print(string.format("onBeginContact() fixture1 = %s fixture2 = %s contact = %s", inspect(fixture1), inspect(fixture2), inspect(contact)))
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
  -- }}}
end

local function onEndContact(
        _: love.physics.Fixture, 
        _: love.physics.Fixture,
        _: love.physics.Contact
    )
    -- {{{
    --[[
  if drawContactPoints then
    local x1, y1, x2, y2 = contact:getPositions()
    local body1 = fixture1:getBody()
    local body2 = fixture2 and fixture2:getBody() or nil  
    if x1 and y1 then
--    x1, y1 = Snake.cam:worldCoords(x1, y1)
      -- отправляю контакты на отрисовку
      push2drawlist(function()
--          linesbuf:pushi("x1 = %f, y1 = %f", x1, y1)
          print("ook")
          lg.setColor(CONTACT_END_DRAW_COLOR)
          lg.circle("fill", x1 * M2PIX, y1 * M2PIX, 10)
        end)
    end
    if x2 and y2 then    
      x2, y2 = Snake.cam:worldCoords(x2, y2)
      -- отправляю контакты на отрисовку
      push2drawlist(function()
          lg.setColor(CONTACT_END_DRAW_COLOR)
          lg.circle("fill", x2 * M2PIX, y2 * M2PIX, 10)
        end)
    end
  end
  --]]
    -- }}}
end

local function onQueryBoundingBox(fixture: love.physics.Fixture): boolean
    -- {{{
    local body = fixture:getBody()
    local selfPtr: Tank = body:getUserData() as Tank
    --проверка на существование связанного объекта, проверка на наличие метода отрисовки через запрос, отрисовка.
    if selfPtr and selfPtr.present then
        selfPtr:present()
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
            push2drawlist(function()
                local oldwidth = gr.getLineWidth()
                local lwidth = 4
                gr.setLineWidth(lwidth)
                gr.setColor{0., 0., 1.}
                gr.rectangle("line", tlx, tly, brx - tlx, bry - tly)
                gr.setLineWidth(oldwidth)
            end)
        end

        pworld:queryBoundingBox(
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

local function drawui()
    -- {{{
    imgui.StyleColorsLight()
    imgui.ShowDemoWindow()
    imgui.ShowUserGuide()
    -- }}}
end

local function moveCameraToPlayer()
    -- {{{
    if playerTank then
        local x, y = playerTank.physbody:getWorldCenter()
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
            camTimer:during(cameraAnimationDuration, function(dt: number, time: number, delay: number)
                local dx, dy = -reldx * (delay - time) * xc, -reldy * (delay - time) * yc
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

local function konsolePresent()
    -- {{{
    gr.setColor{1, 1, 1, 1}

    processAttachedVariables()

    if mode == "command" then
        cmdline = removeFirstColon(cmdline)
        if cmdline then
            --linesbuf:pushiColored("%{red}>: %{black}" .. cmdline)
            local prompt = ">: "
            linesbuf:pushi(prompt .. cmdline)
        end
    end

    linesbuf:draw()
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
    --local sx, sy = 0.1, 0.1
    local sx, sy = 1, 1
    gr.setColor(1, 1, 1, 1)
    for i = 0, len - 1 do
        for j = 0, len - 1 do
            gr.draw(self.img as gr.Drawable, i * imgw * sx, j * imgh * sy, 0, sx, sy)
        end
    end
    --gr.clear{0.5, 0.5, 0.5, 1}
    -- }}}
end

local function mainPresent()
    -- {{{
    push2drawlist(Background.present, background)
    push2drawlist(queryBoundingBox)
    push2drawlist(drawBullets)

    cam:attach()
    presentDrawlist()
    cam:detach()

    drawlist = {}

    changeKeyConfigListbackground()

    coroutine.yield()
    -- }}}
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

local function update(dt: number)
    -- {{{
    camTimer:update(dt)
    pworld:update(1 / 60)
    linesbuf:update()
    updateTanks()
    updateBullets()
    -- }}}
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
    end
    -- }}}
end

function PRINT(...: string)
    print(...)
end

function PINSPECT(t: any)
    print(inspect(t))
end

function INSPECT(t: any): string
    return inspect(t)
end

local function enterCommandMode()
    -- {{{
    if linesbuf.show then
        print("command mode enabled.")
        mode = "command"
        cmdline = ""
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
            linesbuf:pushi(string.format("%s", tabular.show((_G as {any:any})[varname])))
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

-- XXX Global variable
systemPrint = print
--print = konsolePrint

if not __ATTACH_ONCE__ then
    print('before')
    -- attached variables
    attach("playerTank")
    attach("DEFAULT_W")
    attach("DEFAULT_H")
    attach("W")
    attach("H")
    attach("M2PIX")
    attach("PIX2M")
    attach("tankForceScale")
    attach("cam")
    attach("showLogo")
    attach("playerTankKeyconfigIds")
    attach("angularImpulseScale")
    attach("rot")
    attach("camZoomLower")
    attach("camZoomHigher")
    attach("pworld")
    --attach("tanks")
    attach("playerTank")
    attach("background")
    attach("logo")
    --attach("bullets")
    attach("bulletLifetime")
    attach("tankCounter")
    attach("rng")
    print('after')
    __ATTACH_ONCE__ = true
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
    print('setPreviousCommand')
    --prevcmdline = cmdline
    if #cmdhistory ~= 0 then
        if cmdhistoryIndex - 1 < 1 then
            cmdhistoryIndex = #cmdhistory
        else
            cmdhistoryIndex = cmdhistoryIndex - 1
        end
        cmdline = cmdhistory[cmdhistoryIndex]
        print("cmdline", cmdline)
    end
    -- }}}
end

local function setNextCommand()
    -- {{{
    print('setNextCommand')
    if #cmdhistory ~= 0 then
        if cmdhistoryIndex + 1 > #cmdhistory then
            cmdhistoryIndex = 1
        else
            cmdhistoryIndex = cmdhistoryIndex + 1
        end
        cmdline = cmdhistory[cmdhistoryIndex]
        print("cmdline", cmdline)
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
    local res: Tank
    local ok, errmsg: boolean, string = pcall(function()
        if #tanks >= 1 then
            unbindPlayerTankKeys()
        end
        local t = Tank.new(pos, dir)
        table.insert(tanks, t)
        -- игрок управляет последний созданным танком
        playerTank = t
        res = t
        if DEBUG_TANK then
            print("Tank spawn at", pos.x, pos.y)
        end
        bindPlayerTankKeys()
    end)
    if not ok then
        error("Could'not load. Please implement stub-tank. " .. errmsg)
    end
    return res
    -- }}}
end

global cameraKeyConfigIds: {integer} = {}

local function bindCameraZoomKeys()
    -- {{{
    local zoomSpeed = 0.01

    local ids = {
        KeyConfig.bind(
            "isdown",
            { key = "z" },
            function(sc: Shortcut): boolean, Shortcut
                print('zoom in')
                --if mode ~= "normal" then
                    --return false, sc
                --end
                print('zoom in')
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
                print('zoom out')
                --if mode ~= "normal" then
                    --return false, sc
                --end
                print('zoom out')
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
            print("go to logo present()")
            -- режим игрового меню
            while showLogo == true do
                logo:present()
            end
            print("goto mainPresent()")
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

--[[
-- {{{ bindCommandModeHotkey
local function bindCommandModeHotkey()
    KeyConfig.bind(
        "keypressed", 
        { key = ":", mod = {"lshift"} }, 
        function(sc: KeyConfig.Shortcut): boolean, KeyConfig.Shortcut
            print("Switching for command mode")
            mode = "command"
            love.keyboard.setTextInput(true)

            KeyConfig.bind(
                "keypressed",
                { key = "escape", },
                function(sc: KeyConfig.Shortcut): boolean, KeyConfig.Shortcut
                    mode = "normal"
                    return false, sc
                end,
                "escape to logo screen",
                "escape2log")

            return true, sc
        end,
        i18n("commandmode"),
        "commandmode")
end
-- }}}
--]]

-- параметры в метрах
local function makeArmy(x: number, y: number)
    -- {{{
    x = x or 0
    y = y or 0
    local len = 10
    local space = 30
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

local function init()
    -- {{{
    metrics.init()
    setWindowMode()

    loadLocales()

    local canSleep = true
    pworld = love.physics.newWorld(0., 0., canSleep)
    if DEBUG_PHYSICS then
        print("physics world canSleep:", canSleep)
    end
    --self.headBody:setAngularDamping(0.1)
    --self.headBody:setLinearDamping(0.1)
    pworld:setCallbacks(onBeginContact, onEndContact)

    logo = Logo.new()
    cam = require 'camera'.new()
    if DEBUG_CAMERA then
        print("camera created x, y, scale, rot", cam.x, cam.y, cam.scale, cam.rot)
    end

    bindCameraZoomKeys()
    bindCameraControl()
    bindFullscreenSwitcher()
    --bindCommandModeHotkey()
    bindEscape()
    bindKonsole()

    drawCoro = createDrawCoroutine()

    background = Background.new()

    makeArmy()
    makeArmy(0, 500)
    makeArmy(500, 0)
    makeArmy(500, 500)

    enableDEBUG()

    -- }}}
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
end

local function wheelmoved(x: number, y: number)
    metrics.wheelmoved(x, y)
end

local function mousepressed(x: number, y: number, btn: integer)
    -- {{{
    metrics.mousepressed(x, y, btn)
    if btn == 1 then
        if playerTank then
            playerTank:fire()
        end
    elseif btn == 2 then
        x, y = cam:worldCoords(x, y)
        x, y = x * PIX2M, y * PIX2M
        spawnTank(vector.new(x, y))
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
    -- FIXME Нужно менять эти переменные?
    --DEFAULT_W, DEFAULT_H = neww, newh
    -- }}}
end

local function textinput(text: string)
    -- {{{
    metrics.textinput(text)
    if mode == "command" then
        -- Здесь добавить курсор.
        cmdline = cmdline .. text
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
