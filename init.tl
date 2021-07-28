-- vim: fdm=marker
-- vim: set colorcolumn=85

local enum Mode
    "normal"
    "command"
end

global SCENE_PREFIX = "scenes/t80u"

love.filesystem.setRequirePath("?.lua;?/init.lua;" .. SCENE_PREFIX .. "/?.lua")

local List = require "list"
local metrics = require "metrics"
require "love"
require "common"
require "keyconfig"
require "camera"
require "vector"
require "Timer"
require "imgui"
local i18n = require "i18n"
local inspect = require "inspect"
local vec2 = require "vector"

-- {{{
global DEBUG_BASE = false
global DEBUG_TANK = false
global DEBUG_TANK_MOVEMENT = false
global DEBUG_TURRET = true
global DEBUG_CAMERA = false
global DEBUG_PHYSICS = true
global DEBUG_LOGO = false
global DEBUG_DRAW_THREAD = true
global DEBUG_TEXCOORDS = true
-- }}}

global DEFAULT_W, DEFAULT_H = 1024, 768
global W, H = love.graphics.getDimensions()
global cmd_drawBodyStat: boolean = true
global cmd_drawCameraAxixes: boolean = false

-- Не работают когда двигается камера?
--local tlx, tly, brx, bry: number, number, number, number = 0., 0., W, H 

-- Танк длиной пять метров имеет отображаемый размер 50 пикселей
-- коэффициент на который домножаю при переводе из метров в пиксели
global M2PIX = 10
-- коэффициент на который домножаю при переводе из пикселей в метры
global PIX2M = 1 / 10

local forceScale = 100

global cam: Camera
local camTimer: Timer = require "Timer".new()
local drawlist: {function} = {}
local gr = love.graphics
local lp = love.physics

local linesbuf = require "kons".new(SCENE_PREFIX .. "/VeraMono.ttf", 20)
local mode: Mode = "normal"
local cmdline, prevcmdline: string = "", ""
local cmdhistory: {string} = {}

local drawCoro: thread = nil
local showLogo = true
local playerTankKeyconfigIds: {string} = {}
local Shortcut = KeyConfig.Shortcut

local angularImpulseScale = 5
local rot = math.pi / 4
local zoomLower, zoomHigher = 0.075, 3.5

local record Turret
    -- {{{
    pbody: love.physics.Body
    f: love.physics.Fixture
    img: love.graphics.Image
    angle: number
    tank: Tank
    -- куда смотрит башня, направление выстрела
    dir: vector

    new: function(t: Tank): Turret
    present: function(Turret)
    update: function(Turret)
    fire: function(Turret)
    -- }}}
end

local record Bullet
    body: love.physics.Body
    timestamp: number
end

--[[
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
--]]

local Turret_mt: metatable<Turret> = {
    __index = Turret,
}

local record Base
    -- {{{
    pbody: love.physics.Body
    f: love.physics.Fixture
    img: love.graphics.Image
    --pos: vector -- центр поворота корпуса
    tank: Tank

    new: function(t: Tank): Base
    present: function(Base)
    -- }}}
end

-- ходовая часть с полигоном
local record BaseP
    -- {{{
    pbody: love.physics.Body
    f: love.physics.Fixture
    img: love.graphics.Image
    --pos: vector -- центр поворота корпуса
    tank: Tank
    mesh: love.graphics.Mesh

    --meshVerts: {Vertex}
    meshVerts: {{number}}

    new: function(t: Tank): BaseP
    present: function(BaseP)
    updateMeshVerts: function(BaseP)
    updateMeshTexCoords: function(BaseP, x: number, y: number, w: number, h: number)
    initMeshVerts: function(BaseP)
    -- }}}
end

local BaseP_mt: metatable<BaseP> = {
    __index = BaseP,
}

local Base_mt: metatable<Base> = {
    __index = Base,
}

local record Tank
    -- {{{
    pbody: love.physics.Body
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

local Tank_mt: metatable<Tank> = {
    __index = Tank,
}

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

local Logo_mt: metatable<Logo> = {
    __index = Logo,
}

local type CameraSettings = record
    -- {{{
    dx: number
    dy: number
    -- }}}
end

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
-- Логотип, картинка
global logo: Logo
-- Все снаряды вырущенные из танков, пока не уничтоженные
global bullets: {Bullet} = {}

local bullerRadius = 40
local bulletColor = {0, 0, 0, 1}
-- Продолжительность жизни снаряда в секундах.
local bulletLifetime = 1

local function drawBullets()
    for _, b in ipairs(bullets) do
        local px, py = b.body:getWorldCenter()
        px, py = px * M2PIX, py * M2PIX
        gr.setColor(bulletColor)
        gr.circle("fill", px, py, bullerRadius)
    end
end

local function updateBullets()
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
end

-- размеры в метрах
local function spawnBullet(px: number, py: number)
    local bullet: Bullet = {}
    bullet.body = love.physics.newBody(pworld, 0, 0, "kinematic")
    bullet.timestamp = love.timer.getTime()
    local shape = love.physics.newCircleShape(px, py, bullerRadius)
    love.physics.newFixture(bullet.body, shape as love.physics.Shape)
    table.insert(bullets, bullet)
end

function Turret:fire()
    if DEBUG_TURRET then
        print("Turret:fire()")
    end
    local px, py = self.tank.pbody:getWorldCenter()
    spawnBullet(px, py)
end

local function presentDrawlist()
    for _, v in ipairs(drawlist) do
        v()
    end
end

local function push2drawlist(f: function)
    if not f then
        error("Draw could'not be nil.")
    end
    if type(f) ~= "function" then
        error("Draw function is not a function. It is a .. " .. type(f))
    end
    table.insert(drawlist, f)
end

function Tank:fire()
    if self.turret then
        self.turret:fire()
    end
end

function Tank:left()
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:left")
    end
    --self.pbody:applyForce(x, y)
    --local theta = self.dir - rot
    local imp = -angularImpulseScale * rot
    if DEBUG_PHYSICS then
        --print("Tank " .. self.id .. " applyAngularImpulse", imp)
    end
    self.pbody:applyAngularImpulse(imp)
end

function Tank:right()
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:right")
    end
    local imp = angularImpulseScale * rot
    if DEBUG_PHYSICS then
        --print("Tank " .. self.id .. " applyAngularImpulse", imp)
    end
    self.pbody:applyAngularImpulse(imp)
end

function Tank:forward()
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:forward")
    end
    --if DEBUG_PHYSICS then
        --print("Tank " .. self.id .. "applyForce x, y", x, y)
    --end
    local x, y = self.dir.x * forceScale, self.dir.y * forceScale
    --print('applied', x, y)
    self.pbody:applyForce(x, y)
end

function Tank:backward()
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:backward")
    end
    --if DEBUG_PHYSICS then
        --print("Tank " .. self.id .. "applyForce x, y", x, y)
    --end
    local x, y = self.dir.x * forceScale, self.dir.y * forceScale
    print('applied', x, y)
    self.pbody:applyForce(-x, -y)
end

local tankCounter = 0

-- местоположение передавать в метрах
-- направление шасси - нормализованный вектор
function Tank.new(pos: vector, dir: vector): Tank
    if DEBUG_TANK then
        print('Start of Tank creating..')
    end
    local self: Tank = setmetatable({} as Tank, Tank_mt)

    tankCounter = tankCounter + 1

    self.pbody = love.physics.newBody(pworld, 0, 0, "dynamic")
    self.pbody:setUserData(self)

    if not dir then
        dir = vector.new(0, -1)
    end
    --self.pbody:setAngle(math.pi / 3)

    self.id = tankCounter
    self.dir = dir:clone()
    self.pos = pos:clone()
    self.turret = Turret.new(self)
    --self.base = Base.new(self)
    self.base = BaseP.new(self) as Base

    if DEBUG_PHYSICS then
        print("angular damping", self.pbody:getAngularDamping())
        print("linear damping", self.pbody:getLinearDamping())
    end

    self.pbody:setAngularDamping(3.99)
    self.pbody:setLinearDamping(2)

    if DEBUG_PHYSICS then
        print("angular damping", self.pbody:getAngularDamping())
        print("linear damping", self.pbody:getLinearDamping())
    end

    if DEBUG_TANK then
        print('self.turret', self.turret)
        print('self.base', self.base)
        print('End of Tank creating.')
    end
    return self
end

local function drawBodyStat(body: love.physics.Body)
    local radius = 10
    local x, y = body:getWorldCenter()
    x, y = x * M2PIX, y * M2PIX

    -- зеленый цвет кружка
    gr.setColor{0.1, 1, 0.1}
    gr.circle("fill", x, y, radius)

    -- с черной точкой
    gr.setColor{0, 0, 0, 1}
    gr.circle("fill", x, y, 2)

    local vx, vy = body:getLinearVelocity()
    local scale = 7.
    gr.line(x, y, x + vx * scale, y + vy * scale)

    --local tlx, tly, brx, bry = body:getBoundingBox()
    --tlx, tly, brx, bry = tlx * M2PIX, tly * M2PIX, brx * M2PIX, bry * M2PIX
end

function Tank:drawDirectionVector()
    if self.dir then
        local x, y = self.pbody:getWorldCenter()
        local scale = 50
        local color = {0., 0.05, 0.99, 1}
        x, y = x * M2PIX, y * M2PIX
        gr.setColor(color)
        --print("self.dir", inspect(self.dir))
        --print("drawDirectionVector", x, y, x + self.dir.x * scale, y + self.dir.y * scale)
        gr.line(x, y, x + self.dir.x * scale, y + self.dir.y * scale)
    end
end

function Tank:resetVelocities()
    if self.pbody then
        self.pbody:setAngularVelocity(0)
        self.pbody:setLinearVelocity(0, 0)
    end
end

function Tank:updateDir()
    local unit = 1
    -- возможно зад перепутан с передом
    self.dir = vec2.fromPolar(self.pbody:getAngle() + math.pi / 2, unit)
end

function Tank:update(): Tank
    --print("Tank:update()")
    --print("body angle", self.pbody:getAngle())

    self:updateDir()

    if self.turret then
        self.turret:update()
    end

    return self
end

function Tank:present()
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
        drawBodyStat(self.pbody)
    end
end

function Turret.new(t: Tank): Turret
    -- {{{
    if DEBUG_TURRET then
        print("Start of Turret creating..")
    end
    if not t then
        error("Could'not create Turret without Tank object")
    end

    local self: Turret = setmetatable({} as Turret, Turret_mt)
    self.tank = t
    self.img = love.graphics.newImage(SCENE_PREFIX .. "/tank_tower.png")
    self.pbody = t.pbody

    if DEBUG_TURRET then
        print("self.tank", self.tank)
        print("self.pbody", self.pbody)
        print("self.img", self.img)
    end

    local w, _ = (self.img as love.graphics.Texture):getDimensions()
    local r = w / 2
    local px, py = self.tank.pbody:getPosition()
    local shape = love.physics.newCircleShape(t.pos.x, t.pos.y, r * PIX2M)
    self.f = love.physics.newFixture(self.pbody, shape as love.physics.Shape)

    if DEBUG_TURRET then
        print("circle shape created x, y, r", px, py)
    end

    return self
    -- }}}
end

local __ONCE__ = false

local function drawFixture(f: love.physics.Fixture, color: {number})
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
end

function Turret:update()
    -- поворачивать башню только у танка игрока
    if playerTank and self.tank == playerTank then
        local mx, my = love.mouse.getPosition()
        mx, my = cam:worldCoords(mx, my)
        mx, my = mx * PIX2M, PIX2M

        local x, y = self.pbody:getWorldCenter()
        local d = vec2.new(mx - x, my - y)
        self.dir = d:normalizeInplace()
        local a, _ = d:toPolar()
        if self.angle then
            --linesbuf:push(1, "angle %f, d (%f, %f)", self.angle, d.x, d.y)
        end
        self.angle = a
    end
end

function Turret:present()
    -- {{{
    if not self.f then
        error("Turret:present() - fixture is nil")
    end

    local imgw, imgh = (self.img as love.graphics.Texture):getDimensions()
    local r, sx, sy, ox, oy: number = 0., 1., 1., 0, 0
    --local kx, ky: number = 1., 1.
    local shape = self.f:getShape()
    local cshape = self.f:getShape() as love.physics.CircleShape

    if shape:getType() ~= "circle" then
        error("Only circle shape allowed.")
    end
    local px, py = cshape:getPoint()
    px, py = self.pbody:getWorldPoints(px, py)
    px, py = px * M2PIX, py * M2PIX
    r = cshape:getRadius() * M2PIX

    if DEBUG_PHYSICS then
        --gr.setColor{1, 0.5, 0, 0.5}
        --gr.circle("fill", px, py, r)
        --drawFixture(self.f)
    end

    gr.setColor{1, 1, 1, 1}
    love.graphics.draw(
        self.img as love.graphics.Drawable,
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

function BaseP:present()
    -- {{{
    --local imgw, imgh = (self.img as love.graphics.Texture):getDimensions()
    --local r, sx, sy, ox, oy: number = 0, 1., 1., 0, 0
    --local kx, ky: number = 1., 1.
    local body = self.f:getBody()
    local shape = self.f:getShape()
    if shape:getType() ~= "polygon" then
        error("Tank BaseP shape should be polygon.")
    end
    local pShape: lp.PolygonShape = self.f:getShape() as lp.PolygonShape

    if DEBUG_PHYSICS then
        drawFixture(self.f, {0, 0, 0, 1})
    end

    --local pShape: love.physics.PolygonShape = shape as love.physics.PolygonShape
    local points = {pShape:getPoints()}
    local i = 1
    while i < #points do
        points[i], points[i + 1] = body:getWorldPoints(points[i], points[i + 1])
        points[i] = points[i] * M2PIX
        points[i + 1] = points[i + 1] * M2PIX
        i = i + 2
    end

    --local px, py = 0, 0
    --local angle = self.pbody:getAngle()

    --[[
    love.graphics.draw(
        self.img as love.graphics.Drawable,
        px, py,
        angle + math.pi / 2, 
        sx, sy, 
        ox + imgw / 2, oy + imgh / 2
    )
    --]]

    gr.setColor{1, 1, 1, 1}
    self:updateMeshVerts()
    gr.draw(self.mesh as love.graphics.Drawable, 0, 0)

    --for _, f in ipairs(self.pbody:getFixtures()) do
        ----drawFixture(f)
    --end

    local x, y = self.pbody:getWorldCenter()
    x, y = x * M2PIX, y * M2PIX
    local text = string.format("%d", self.tank.id)
    gr.print(text, x, y)
    -- }}}
end

function Base:present()
    -- {{{
    local imgw, imgh = (self.img as love.graphics.Texture):getDimensions()
    local r, sx, sy, ox, oy: number = 0, 1., 1., 0, 0
    --local kx, ky: number = 1., 1.
    local shape = self.f:getShape()
    local cshape = self.f:getShape() as love.physics.CircleShape

    if shape:getType() ~= "circle" then
        --error("Only circle shape allowed.")
        return
    end

    local px, py = cshape:getPoint()
    px, py = self.pbody:getWorldPoints(px, py)
    px, py = px * M2PIX, py * M2PIX
    r = cshape:getRadius() * M2PIX

    if DEBUG_PHYSICS then
        --gr.setColor{1, 0, 0, 0.5}
        --gr.circle("fill", px, py, r)
        drawFixture(self.f, {0, 0, 0, 1})
    end

    --sx = sx * 2
    --sy = sy * 2
    local angle = self.pbody:getAngle()

    --px, py = px - imgw / 2, py - imgh / 2,

    love.graphics.push()
    --love.graphics.translate(-imgw / 2, -imgh / 2)
    --love.graphics.rotate(angle)
    --love.graphics.translate(imgw / 2, imgh / 2)

    gr.setColor{1, 1, 1, 1}
    love.graphics.draw(
        self.img as love.graphics.Drawable,
        px, py,
        angle + math.pi / 2, 
        sx, sy, 
        ox + imgw / 2, oy + imgh / 2
    )

    --local black = {0, 0, 0, 1}
    --gr.setColor(black)
    --gr.rectangle("line", px, py, imgw, imgh)

    --love.graphics.draw(
        --self.img as love.graphics.Drawable,
        --px, py,
        --0,
        --sx, sy, 
        --ox, oy
    --)

    --love.graphics.translate(-imgw / 2, -imgh / 2)
    love.graphics.pop()

    --gr.setColor{1, 1, 1, 1}
    --love.graphics.draw(
        --self.img as love.graphics.Drawable,
        --px - imgw / 2, py - imgh / 2,
        --angle, 
        --sx, sy, 
        --ox, oy
    --)

    --[[
    gr.setColor{1, 1, 1, 0.5}
    love.graphics.draw(
        self.img as love.graphics.Drawable,
        0, 0,
        0,
        1, 1,
        0, 0
    )

    gr.setColor{1, 1, 1, 0.5}
    love.graphics.draw(
        self.img as love.graphics.Drawable,
        0, 0,
        0,
        1, 1,
        0, 0
    )

    gr.setColor{1, 1, 1, 0.5}
    love.graphics.draw(
        self.img as love.graphics.Drawable,
        0, 0,
        0,
        1, 1,
        100, 300
    )
    --]]

    --for _, f in ipairs(self.pbody:getFixtures()) do
        ----drawFixture(f)
    --end

    local x, y = self.pbody:getWorldCenter()
    x, y = x * M2PIX, y * M2PIX
    local text = string.format("%d", self.tank.id)
    gr.print(text, x, y)
    -- }}}
end

function BaseP.new(t: Tank): BaseP
    -- {{{
    if DEBUG_BASE then
        print("BaseP.new()")
    end
    if not t then
        error("Could'not create BaseP without Tank object")
    end

    local self: BaseP = setmetatable({} as BaseP, BaseP_mt)
    self.tank = t
    self.img = love.graphics.newImage(SCENE_PREFIX .. "/tank_body_small.png")
    --self.img = love.graphics.newImage(SCENE_PREFIX .. "/tank_body.png")

    -- цифры получены из картинки tank_body_small.png
    local rectXY = {86, 72}
    local rectWH = {84, 111}
    
    self.pbody = t.pbody

    if DEBUG_BASE then
        print("self.tank", self.tank)
        print("self.pbody", self.pbody)
        print("self.img", self.img)
    end

    --local w, _ = (self.img as love.graphics.Texture):getDimensions()
    local px, py = t.pos.x, t.pos.y
    --px, py = 0, 0

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
    self.f = love.physics.newFixture(self.pbody, shape as love.physics.Shape)
    if DEBUG_TURRET then
        print("polygon shape created x, y, r", px, py)
    end

    self:initMeshVerts()
    self.mesh = love.graphics.newMesh(self.meshVerts as {{number}}, 
        "triangles", "dynamic")
    self:updateMeshVerts()
    self.mesh:setTexture(self.img as gr.Texture)
    self:updateMeshTexCoords(rectXY[1], rectXY[2], rectWH[1], rectWH[2])
    
    if not self.mesh then
        error("Could'not create Mesh")
    end

    return self
    -- }}}
end

function BaseP:updateMeshTexCoords(x: number, y: number, w: number, h: number)
    -- {{{
    print("updateMeshTexCoords", x, y, w, h)
    -- размеры текстуры в пикселях
    local imgw, imgh = (self.img as gr.Texture):getDimensions()
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

function BaseP:initMeshVerts()
    self.meshVerts = {}
    for _ = 1, 6 do
        table.insert(self.meshVerts, {
            0, 0,           -- 1, 2         - x, y
            0, 0,           -- 3, 4         - u, v
            1, 1, 1, 1,     -- 5, 6, 7, 8   - r, g, b, a
        })
    end
end

function BaseP:updateMeshVerts()
    self.mesh:setVertices(self.meshVerts)

    local body = self.f:getBody()
    local pShape: love.physics.PolygonShape = self.f:getShape() as love.physics.PolygonShape
    local points = {pShape:getPoints()}
    local i = 1
    while i < #points do
        points[i], points[i + 1] = body:getWorldPoints(points[i], points[i + 1])
        points[i] = points[i] * M2PIX
        points[i + 1] = points[i + 1] * M2PIX
        i = i + 2
    end

    -- tri1
    self.meshVerts[1][1] = points[1]
    self.meshVerts[1][2] = points[2]

    self.meshVerts[2][1] = points[3]
    self.meshVerts[2][2] = points[4]

    self.meshVerts[3][1] = points[7]
    self.meshVerts[3][2] = points[8]

    -- tri2
    self.meshVerts[5][1] = points[3]
    self.meshVerts[5][2] = points[4]

    self.meshVerts[6][1] = points[5]
    self.meshVerts[6][2] = points[6]

    self.meshVerts[4][1] = points[7]
    self.meshVerts[4][2] = points[8]

    --print("self.meshVerts", inspect(self.meshVerts))
end

function Base.new(t: Tank): Base
    -- {{{
    if DEBUG_BASE then
        print("Base.new()")
    end
    if not t then
        error("Could'not create Base without Tank object")
    end

    local self: Base = setmetatable({} as Base, Base_mt)
    self.tank = t
    self.img = love.graphics.newImage(SCENE_PREFIX .. "/tank_body_small.png")
    self.pbody = t.pbody

    if DEBUG_BASE then
        print("self.tank", self.tank)
        print("self.pbody", self.pbody)
        print("self.img", self.img)
    end

    local w, _ = (self.img as love.graphics.Texture):getDimensions()
    --local shape = love.physics.newRectangleShape(w, h)
    local r = w / 2
    local px, py = t.pos.x, t.pos.y
    local shape = love.physics.newCircleShape(px, py, r * PIX2M)
    --newRectangleShape: function(x: number, y: number, width: number, height: number, angle: number): PolygonShape
    self.f = love.physics.newFixture(self.pbody, shape as love.physics.Shape)

    if DEBUG_TURRET then
        print("circle shape created x, y, r", px, py)
    end

    return self
    -- }}}
end

--{{{
--[[
local function drawTestCircle()
    local w, h = gr.getDimensions()
    local rad = 100
    local lwidth = 3
    local oldwidth = gr.getLineWidth()
    gr.setLineWidth(lwidth)
    local centerx, centery = w / 2, h / 2
    gr.circle("line", centerx, centery, rad)
    gr.setLineWidth(oldwidth)
end
--]]
--}}}

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

    --[[
    -- {{{
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
end
    -- }}}

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
    if cam then
        local tlx, tly = cam:worldCoords(0, 0)
        local brx, bry = cam:worldCoords(gr.getDimensions())

        --print("gr.getDimensions()", gr.getDimensions())
        --print("W, H", W, H)

        brx, bry = brx + W * PIX2M, bry + H * PIX2M
        --print('tlx, tly', tlx, tly)
        --print('brx, bry', brx, bry)
        --print('---------')

        pworld:queryBoundingBox(
            tlx * PIX2M, tly * PIX2M, 
            brx * PIX2M, bry * PIX2M, 
            onQueryBoundingBox
        )
    end
end

local function unbindPlayerTankKeys()
    for _, id in ipairs(playerTankKeyconfigIds) do
        KeyConfig.unbind(id)
    end
end

local function loadLocales()
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
end

local function bindPlayerTankKeys()
    local function pushId(id: string): string
        table.insert(playerTankKeyconfigIds, id)
        return id
    end

    if playerTank then
        -- {{{
        local kc = KeyConfig
        local bmode: kc.BindType = "isdown"

        -- Непонятное и наверно ненужное перечисление.
        local enum E
            "left"
            "right"
            "forward"
            "backward"
            "resetVelocities"
        end

        -- {{{
        --[[
        local function bindDirection(direction: E)
            kc.bind(
                mode, { key = direction },
                function(sc: Shortcut): boolean, Shortcut
                    playerTank[direction as E](playerTank)
                    playerTank[direction](playerTank)
                    return false, sc
                end,
                "move tank " .. direction, pushId("mt" .. direction)
            )
        end

        bindDirection("left")
        bindDirection("right")
        bindDirection("up")
        bindDirection("down")
        --]]
        -- }}}

        local direction: E 

        direction = "right"
        kc.bind(
            bmode, { key = "d" },
            function(sc: Shortcut): boolean, Shortcut
                playerTank["right"](playerTank)
                return false, sc
            end,
            i18n("mt" .. direction), pushId("mt" .. direction)
        )

        direction = "left"
        kc.bind(
            bmode, { key = "a" },
            function(sc: Shortcut): boolean, Shortcut
                playerTank["left"](playerTank)
                return false, sc
            end,
            i18n("mt" .. direction), pushId("mt" .. direction)
        )

        direction = "forward"
        kc.bind(
            bmode, { key = "w" },
            function(sc: Shortcut): boolean, Shortcut
                playerTank["forward"](playerTank)
                return false, sc
            end,
            i18n("mt" .. direction), pushId("mt" .. direction)
        )

        direction = "backward"
        kc.bind(
            bmode, { key = "s" },
            function(sc: Shortcut): boolean, Shortcut
                playerTank["backward"](playerTank)
                return false, sc
            end,
            i18n("mt" .. direction), pushId("mt" .. direction)
        )

        kc.bind(
            bmode, { key = "v" },
            function(sc: Shortcut): boolean, Shortcut
                playerTank["resetVelocities"](playerTank)
                return false, sc
            end,
            i18n("mt" .. direction), pushId("mt" .. direction)
        )

        kc.bind(
            "isdown", { key = "space" },
            function(sc: Shortcut): boolean, Shortcut
                if playerTank then
                    playerTank:fire()
                end
                return false, sc
            end,
            i18n("fike"), pushId("fire")
        )
        -- }}}
    else
        error("There is no player tank object instance, sorry.")
    end
end

local function changeKeyConfigListbackground()
    KeyConfig.setListSetupCallback(function(list: List)
        list.colors.normal = {bg = {0.19, 0.61, 0.88}, fg = {1, 1., 1., 1.}}
    end)
end

local function drawui()
    imgui.StyleColorsLight()
    imgui.ShowDemoWindow()
    imgui.ShowUserGuide()
end

local function moveCameraToPlayer()
    if playerTank then
        local x, y = playerTank.pbody:getWorldCenter()
        x, y = x * M2PIX, y * M2PIX
        cam:lookAt(x, y)
    end
end

local function bindCameraControl()
    -- не прямой а квадратичный зум?
    local cameraAnimationDuration = 0.2

    local function makeMoveFunction(xc: number, yc: number): function(sc: Shortcut): boolean, Shortcut
        -- {{{
        return function(sc: Shortcut): boolean, Shortcut
            --if mode ~= "normal" then
                --return false, sc
            --end
            local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
            camTimer:during(cameraAnimationDuration, function(dt: number, time: number, delay: number)
                --cam:move(-reldx * (delay - time) * xc, -reldy * (delay - time) * yc)
                local dx, dy = -reldx * (delay - time) * xc, -reldy * (delay - time) * yc
                --print("delay - time", delay - time)
                --print("dx, dy", dx, dy)
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
    --local bindMode = "isdown"
    KeyConfig.bind(bindMode, { key = "left" }, makeMoveFunction(1., 0), 
        i18n("mcleft"), "camleft")
    KeyConfig.bind(bindMode, { key = "right" }, makeMoveFunction(-1.0, 0.), 
        i18n("mcright"), "camright")
    KeyConfig.bind(bindMode, { key = "up" }, makeMoveFunction(0., 1.), 
        i18n("mcup"), "camup") 
    KeyConfig.bind(bindMode, { key = "down" }, makeMoveFunction(0., -1.), 
        i18n("mcdown"), "camdown")

    KeyConfig.bind("keypressed", { key = "c" }, function(sc: Shortcut): boolean, Shortcut
        moveCameraToPlayer()
        return false, sc
    end, i18n("cam2tank"), "cam2tank")
end

local function bindKonsole()
    KeyConfig.bind("keypressed", { key = "`" }, function(sc: Shortcut): boolean, Shortcut
        linesbuf.show = not linesbuf.show
        return false, sc
    end)
end

local function bindEscape()
    KeyConfig.bind("keypressed", { key = "escape" }, function(sc: Shortcut): boolean, Shortcut
        --if mode ~= "normal" then
            --return false, sc
        --end
        if showLogo == true then
            love.event.quit()
        else
            showLogo = true
        end
        return false, sc
    end)
end

local function drawQueryBox()
    local oldwidth = gr.getLineWidth()
    local lwidth = 4
    gr.setLineWidth(lwidth)
    gr.setColor{0., 0., 1.}
    -- видимые границы камеры

    --[[
    local tlx_, tly_ = cam:worldCoords(0, 0)
    local brx_, bry_ = cam:worldCoords(W, H)

    gr.rectangle("line", tlx_, tly_, brx_ - tlx_, bry_ - tly_)
    gr.setLineWidth(oldwidth)
    --]]
end

local function removeFirstColon(s: string): string
    if not s then
        return nil
    end
    if string.sub(s, 1, 1) == ":" then
        return string.sub(s, 2, #s)
    else
        return s
    end
end

--[[
{{{
colprint("test removeFirstColon(':ss'): " .. removeFirstColon(':ss'))
colprint("test removeFirstColon(':'): " .. removeFirstColon(':'))
colprint("test removeFirstColon('::'): " .. removeFirstColon('::'))
}}}
--]]

function printBody(body: love.physics.Body)
    print(">>>>>>>>")
    print("mass:", body:getMass())
    local x, y = body:getWorldCenter()
    x, y = x * M2PIX, y * M2PIX
    print("getWorldCenter() x, y in pixels", x, y)
    print("getAngle()", body:getAngle())
    print(">>>>>>>>")
end

local function konsolePresent()
    --linesbuf.show = true
    gr.setColor{1, 1, 1, 1}
    linesbuf:pushi(string.format("camera x = %d, y = %d, rot = %f, scale = %f", 
        cam.x, cam.y, cam.rot, cam.scale))

    if mode == "command" then
        cmdline = removeFirstColon(cmdline)
        if cmdline then
            linesbuf:pushiColored("%{red}>: %{black}" .. cmdline)
        end
    end

    linesbuf:draw()
end

local function backgroundPresent()
    gr.clear{0.5, 0.5, 0.5, 1}
end

local function mainPresent()
    backgroundPresent()

    push2drawlist(queryBoundingBox)
    push2drawlist(drawBullets)

    cam:attach()
    presentDrawlist()
    cam:detach()

    --cam:attach()
    if DEBUG_PHYSICS then
        drawQueryBox()
    end
    --cam:detach()
    drawlist = {}

    changeKeyConfigListbackground()

    coroutine.yield()
end

local function drawCameraAxixes()
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
end

local function draw()
    local ok, errmsg: boolean, string = coroutine.resume(drawCoro) as (boolean, string)
    if not ok then
        error("drawCoro thread is end: " .. errmsg)
    end
    if cmd_drawCameraAxixes then
        drawCameraAxixes()
    end
    konsolePresent()
end

local function updateTanks()
    local alive: {Tank} = {}
    for _, v in ipairs(tanks) do
        local t =  v:update()
        if t then
            table.insert(alive, t)
        end
    end
    tanks = alive
end

local function update(dt: number)
    camTimer:update(dt)
    pworld:update(1 / 60)
    linesbuf:update()
    updateTanks()
end

--[[
local function processValue(key: string)
    local t = 0.5
    if key == "n" then
        VALUE = VALUE - t
        print("VALUE", VALUE)
    elseif key == "m" then
        VALUE = VALUE + t
        print("VALUE", VALUE)
    elseif key == "b" then
        VALUE = 0
        print("VALUE", VALUE)
    end
end
--]]

local function backspaceCmdLine()
    local u8 = require "utf8"
    -- get the byte offset to the last UTF-8 character in the string.
    local byteoffset = u8.offset(cmdline, -1)
    if byteoffset then
        -- remove the last UTF-8 character.
        -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
        cmdline = string.sub(cmdline, 1, byteoffset - 1)
    end
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

local historyfname = "cmdhistory.txt"

local function enterCommandMode()
    print("command mode enabled.")
    mode = "command"
    cmdline = ""
    love.keyboard.setKeyRepeat(true)
    love.keyboard.setTextInput(true)
    local history = love.filesystem.read(historyfname)
    if history then
        print("commands history loaded.")
        cmdhistory = {}
        for s in history:gmatch("[^\r\n]+") do
            table.insert(cmdhistory, s)
            print("s", s)
        end
        print("all entries.")
    end
end

local function leaveCommandMode()
    print("command mode disabled.")
    mode = "normal"
    love.keyboard.setKeyRepeat(false)
    love.keyboard.setTextInput(false)
    cmdline = ""
end

-- TODO
function konsolePrint(...: any)
    for _, v in ipairs({...}) do
        if type(v) == "string" then
            linesbuf:push(0.5, tostring(v))
        else
            colprint("konsolePrint warning")
        end
    end
end

local function evalCommand()
    local preload = [[
        local inspect = require 'inspect'
        --local systemPrint = print
        --print = konsolePrint
    ]]
    local func, loaderrmsg: function, string = load(preload .. cmdline)
    local time = 2
    if not func then
        linesbuf:push(time, "load() errmsg: " .. loaderrmsg)
    else
        local ok, pcallerrmsg: boolean, string = pcall(function()
            func()
        end)
        if not ok then
            linesbuf:push(time, "pcall() errmsg: " .. pcallerrmsg)
        else
            cmdline = ""
        end
    end
    local trimmed = trim(cmdline) or ""
    if #trimmed ~= 0 then
        table.insert(cmdhistory, cmdline)
        love.filesystem.append(historyfname, cmdline .. "\n")
    end
end

local function processCommandModeKeys(key: string)
    if key == "backspace" then
        backspaceCmdLine()
    elseif key == "escape" then
        leaveCommandMode()
    elseif key == "return" then
        evalCommand()
    elseif key == "up" then
        prevcmdline = cmdline
        cmdline = cmdhistory[#cmdhistory]
    elseif key == "down" then
        if prevcmdline then
            cmdline = prevcmdline
        end
    end
end

local function keypressed(key: string)
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

    --[[
    if key == "space" then
        -- {{{ Testing timer
        print("space pressed")
        local animLen = 3
        camTimer:during(animLen, function(_: number, time: number, _: number)
            push2drawlist(function()
                gr.setColor{1., 0., 0.}
                local radius = 50
                --print("time", time)
                --print("delay", delay)
                --print("a", a)
                gr.circle("fill", W / 2, H / 2, radius * time)
            end)
            --cam:move(-reldx * (delay - time) * xc, -reldy * (delay - time) * yc)
        end,
        function()
            print("after space")
        end)
        -- }}}
    end
    --]]

    --processValue(key)
end

-- положение в метрах
local function spawn(pos: vector, dir: vector): Tank
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
        print("Tank spawn at", pos.x, pos.y)
        bindPlayerTankKeys()
    end)
    if not ok then
        error("Could'not load. Please implement stub-tank. " .. errmsg)
    end
    return res
end

local function bindCameraZoomKeys()
    local zoomSpeed = 0.01

    KeyConfig.bind(
        "isdown",
        { key = "z" },
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end
            if cam.scale < zoomHigher then
                cam:zoom(1. + zoomSpeed)
            end
            return false, sc
        end,
        "zoom camera in",
        "zoomin"
    )
    KeyConfig.bind(
        "isdown",
        { key = "x" },
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end
            if cam.scale > zoomLower then
                cam:zoom(1.0 - zoomSpeed)
            end
            return false, sc
        end,
        "zoom camera out",
        "zoomout"
    )
end

local function setWindowMode()
    love.window.setMode(DEFAULT_W, DEFAULT_H, { resizable = false })
end

local function setFullscreenMode()
    love.window.setFullscreen(true)
end

local function bindFullscreenSwitcher()
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
end

function Logo.new(): Logo
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
end

function Logo:present()
    gr.setColor{1, 1, 1, 1}
    --print('Logo:present() self.sx, self.sy:', self.sx, self.sy)
    love.graphics.draw(self.image as gr.Drawable, 0, 0, 0., self.sx, self.sy)
    coroutine.yield()
end

local function createDrawCoroutine()
    drawCoro = coroutine.create(function()
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
--]]

-- параметры в метрах
local function makeArmy(x: number, y: number)
    x = x or 0
    y = y or 0
    local len = 10
    local space = 30
    for i = 1, len do
        for j = 1, len do
            spawn(vector.new(x + i * space, y + j * space))
        end
    end
end

local function init()
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

    createDrawCoroutine()

    makeArmy()
    makeArmy(0, 500)
    makeArmy(500, 0)
    makeArmy(500, 500)
end

local function quit()
    metrics.quit()
    unbindPlayerTankKeys()
    tanks = {}
end

local function mousemoved(x: number, y: number, dx: number, dy: number)
    metrics.mousemoved(x, y, dx, dy)
end

local function wheelmoved(x: number, y: number)
    metrics.wheelmoved(x, y)
end

local function mousepressed(x: number, y: number, btn: integer)
    metrics.mousepressed(x, y, btn)
    if btn == 1 then
        -- значения координат мыши привести к мировым координатам камеры
        --print("mousepressed")
        --print("x, y", x, y)
        print("before worldCoords", x, y)
        local timeout = 2.5
        linesbuf:push(timeout, "mousepressed(%d, %d)", x, y)
        x, y = cam:worldCoords(x, y)
        linesbuf:push(timeout, "in world coordinates (%d, %d)", x, y)
        print("after worldCoords", x, y)
        --x, y = cam:cameraCoords(x, y)
        x, y = x * PIX2M, y * PIX2M
        spawn(vector.new(x, y))
    elseif btn == 2 then
        --[[
        local count = 100
        for i = 2, count do
            -- значения координат мыши привести к мировым координатам камеры
            --print("mousepressed")
            --print("x, y", x, y)
            print("before worldCoords", x, y)
            local timeout = 2.5
            linesbuf:push(timeout, "mousepressed(%d, %d)", x, y)
            --x, y = cam:worldCoords(x, y)
            --x, y = cam:cameraCoords(x, y)
            linesbuf:push(timeout, "in world coordinates (%d, %d)", x, y)
            print("after worldCoords", x, y)
            --x, y = cam:cameraCoords(x, y)
            x, y = x * PIX2M, y * PIX2M
            spawn(vector.new(x, y))
        end
        --]]
        if playerTank and playerTank.turret then
            playerTank.turret:fire()
        end
    end
end

local function resize(neww: integer, newh: integer)
    metrics.resize(neww, newh)
    if DEBUG_CAMERA then
        print("tanks window resized to w, h", neww, newh)
    end
    W, H = neww, newh
    -- FIXME Нужно менять эти переменные?
    --DEFAULT_W, DEFAULT_H = neww, newh
end

local function textinput(text: string)
    metrics.textinput(text)
    if mode == "command" then
        cmdline = cmdline .. text
    end
end

return {
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
}
