-- vim: fdm=marker
-- vim: set colorcolumn=85

local enum Mode
    "normal"
    "command"
end

global SCENE_PREFIX = "scenes/t80u"

love.filesystem.setRequirePath("?.lua;?/init.lua;" .. SCENE_PREFIX .. "/?.lua")

local List = require "list"
require "love"
require "common"
require "keyconfig"
require "camera"
require "vector"
require "Timer"
require "imgui"

global DEBUG_BASE = false
global DEBUG_TANK = false
global DEBUG_TANK_MOVEMENT = false
global DEBUG_TURRET = false
global DEBUG_CAMERA = false
global DEBUG_PHYSICS = false
global DEBUG_LOGO = true

--local DEBUG_BASE = true
--local DEBUG_TANK = true
--local DEBUG_TANK_MOVEMENT = false
--local DEBUG_TURRET = true
--local DEBUG_CAMERA = true
--local DEBUG_PHYSICS = true
--local DEBUG_LOGO = true
global DEBUG_DRAW_THREAD = true

global DEFAULT_W, DEFAULT_H = 1024, 768
global W, H = love.graphics.getDimensions()

-- Не работают когда двигается камера?
local tlx, tly, brx, bry: number, number, number, number = 0., 0., W, H 

-- Танк длиной пять метров имеет отображаемый размер 50 пикселей
-- коэффициент на который домножаю при переводе из метров в пиксели
global M2PIX = 10
-- коэффициент на который домножаю при переводе из пикселей в метры
global PIX2M = 1 / 10
--local PIX2M = 1.

global cam: Camera
local camTimer: Timer = require "Timer".new()
local drawlist: {function} = {}
local gr = love.graphics
local linesbuf = require "kons".new(SCENE_PREFIX .. "/VeraMono.ttf", 20)
local mode: Mode = "normal"
local cmdline: string = ""
local cmdhistory: {string} = {}

local i18n = require "i18n"
local inspect = require "inspect"

local drawCoro: thread = nil
local showLogo = true

local record Turret
    -- {{{
    pbody: love.physics.Body
    f: love.physics.Fixture
    img: love.graphics.Image
    --pos: vector -- центр поворота башни
    tank: Tank

    new: function(t: Tank): Turret
    present: function()
    -- }}}
end

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
    present: function()
    -- }}}
end

local Base_mt: metatable<Base> = {
    __index = Base,
}

local record Tank
    -- {{{
    pbody: love.physics.Body
    id: integer
    turret: Turret
    base: Base
    -- Центр поворота корпуса. Пока совпадает с центром поворота башни.
    --pos: vector 
    -- на сколько пикселей смещается танк при вызове метода движения
    movementDelta: number

    -- абсолютные координаты в пикселях
    new: function(pos: vector): Tank

    left: function(Tank)
    right: function(Tank)
    up: function(Tank)
    down: function(Tank)
    -- }}}
end

local Tank_mt: metatable<Tank> = {
    __index = Tank,
}

local record Logo
    image: love.graphics.Image
    sx: number
    sy: number
    imgw: integer
    imgh: integer

    new: function(): Logo

    present: function()
end

local Logo_mt: metatable<Logo> = {
    __index = Logo,
}

local type CameraSettings = record
    dx: number
    dy: number
end

local cameraSettings: CameraSettings = {
    -- значение в пикселях
    dx = 10, dy = 10,
}

-- Экземпляр box2d
global pworld: love.physics.World
-- Все танки, в том числе и тот, которым управляет игрок.
global tanks: {Tank} = {}
-- Танк, которым управляет игрок
global playerTank: Tank
-- Логотип, картинка
global logo: Logo

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

local VALUE = 0.

function Tank:left()
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:left")
    end
    local x, y = -VALUE, 0
    if DEBUG_PHYSICS then
        print("Tank " .. self.id .. "applyForce x, y", x, y)
    end
    self.pbody:applyForce(x, y)
end

function Tank:right()
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:right")
    end
    local x, y = VALUE, 0
    if DEBUG_PHYSICS then
        print("Tank " .. self.id .. "applyForce x, y", x, y)
    end
    self.pbody:applyForce(x, y)
end

function Tank:up()
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:up")
    end
    local x, y = 0, -VALUE
    if DEBUG_PHYSICS then
        print("Tank " .. self.id .. "applyForce x, y", x, y)
    end
    self.pbody:applyForce(x, y)
end

function Tank:down()
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:down")
    end
    local x, y = 0, VALUE
    if DEBUG_PHYSICS then
        print("Tank " .. self.id .. "applyForce x, y", x, y)
    end
    self.pbody:applyForce(x, y)
end

local tankCounter = 0

function Tank.new(pos: vector): Tank
    if DEBUG_TANK then
        print('Start of Tank creating..')
    end
    local self: Tank = setmetatable({} as Tank, Tank_mt)
    local x, y = pos.x, pos.y

    tankCounter = tankCounter + 1

    self.pbody = love.physics.newBody(pworld, x * PIX2M, y * PIX2M, "dynamic")
    --self.pbody:setMass(1.)
    self.pbody:setUserData(self)

    self.id = tankCounter
    self.turret = Turret.new(self)
    self.base = Base.new(self)
    self.movementDelta = 1.

    if DEBUG_PHYSICS then
        print("pbody:getAngularDamping()", self.pbody:getAngularDamping())
        print("pbody:getLinearDamping()", self.pbody:getLinearDamping())
    end

    --self.pbody:setAngularDamping(0.1)
    --self.pbody:setLinearDamping(0.1)

    if DEBUG_TANK then
        print('self.turret', self.turret)
        print('self.base', self.base)
        print('End of Tank creating.')
    end
    return self
end

function Turret.new(t: Tank): Turret
    if DEBUG_TURRET then
        print("Start of Turret creating..")
    end
    if not t then
        error("Could'not create Turret without Tank object")
    end

    local self: Turret = setmetatable({} as Turret, Turret_mt)
    self.tank = t
    --self.img = love.graphics.newImage(SCENE_PREFIX .. "/bashnya1.png")
    self.img = love.graphics.newImage(SCENE_PREFIX .. "/tank_tower.png")
    self.pbody = t.pbody;

    if DEBUG_TURRET then
        print("self.tank", self.tank)
        print("self.pbody", self.pbody)
        print("self.img", self.img)
    end

    local w, _ = (self.img as love.graphics.Texture):getDimensions()
    --local shape = love.physics.newRectangleShape(w, h)
    local r = w / 2
    local px, py = self.tank.pbody:getPosition()
    local shape = love.physics.newCircleShape(px, py, r * M2PIX)
    --newRectangleShape: function(x: number, y: number, width: number, height: number, angle: number): PolygonShape
    self.f = love.physics.newFixture(self.pbody, shape as love.physics.Shape)

    if DEBUG_TURRET then
        print("circle shape created x, y, r", px, py)
    end

    return self
end

local function drawFixture(f: love.physics.Fixture)
    local shape = f:getShape()
    local shapeType = shape:getType()
    if shapeType == 'circle' then
        local cShape: love.physics.CircleShape = shape as love.physics.CircleShape
        local px, py = cShape:getPoint()
        local radius = cShape:getRadius()
        px, py = f:getBody():getWorldPoints(px, py)
        local lw = 3
        local olw = gr.getLineWidth()
        gr.setLineWidth(lw)
        gr.circle("line", px * M2PIX, py * M2PIX, radius)
        gr.setLineWidth(olw)
    else
        error("Shape type " .. shapeType .. " unsupported.")
    end
end

function Turret:present()
    local imgw, imgh = (self.img as love.graphics.Texture):getDimensions()
    local r, sx, sy, ox, oy: number = math.rad(0.), 1., 1., imgw / 2, imgh / 2
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
    --gr.setColor{1, 0, 0, 0.5}
    --gr.circle("fill", px, py, r)

    love.graphics.draw(
        self.img as love.graphics.Drawable,
        px, py,
        r, 
        sx, sy, 
        ox, oy
    )

    for _, f in ipairs(self.pbody:getFixtures()) do
        drawFixture(f)
    end
    --local x, y = self.pbody:getWorldCenter()
    --local text = string.format("%d", self.tank.id)
    --gr.print(text, x, y)
end

function Base:present()
    local imgw, imgh = (self.img as love.graphics.Texture):getDimensions()
    local r, sx, sy, ox, oy: number = math.rad(0.), 1., 1., imgw / 2, imgh / 2
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
    gr.setColor{1, 0, 0, 0.5}
    gr.circle("fill", px, py, r)

    gr.setColor{1, 1, 1, 0.5}
    love.graphics.draw(
        self.img as love.graphics.Drawable,
        px, py,
        r, 
        sx, sy, 
        ox, oy
    )

    for _, f in ipairs(self.pbody:getFixtures()) do
        drawFixture(f)
    end

    local x, y = self.pbody:getWorldCenter()
    x, y = x * M2PIX, y * M2PIX
    local text = string.format("%d", self.tank.id)
    gr.print(text, x, y)
end

function Base.new(t: Tank): Base
    if DEBUG_BASE then
        print("Base.new()")
    end
    if not t then
        error("Could'not create Base without Tank object")
    end

    local self: Base = setmetatable({} as Base, Base_mt)
    self.tank = t
    --self.img = love.graphics.newImage(SCENE_PREFIX .. "/korpus1.png")
    --self.img = love.graphics.newImage(SCENE_PREFIX .. "/tank_body.png")
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
    local px, py = self.tank.pbody:getPosition()
    local shape = love.physics.newCircleShape(px, py, r * PIX2M)
    --newRectangleShape: function(x: number, y: number, width: number, height: number, angle: number): PolygonShape
    self.f = love.physics.newFixture(self.pbody, shape as love.physics.Shape)

    if DEBUG_TURRET then
        print("circle shape created x, y, r", px, py)
    end

    return self
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
    --print("onQueryBoundingBox")
    local body = fixture:getBody()
    local selfPtr: Tank = body:getUserData() as Tank
    --проверка на существование связанного объекта, проверка на наличие метода отрисовки через запрос, отрисовка.
    if selfPtr then
        --print("selfPtr")
        if selfPtr.turret then 
            --print("turret.present");
            selfPtr.turret:present()
        else
            if DEBUG_TURRET then
                print("Turret object have not present method.")
            end
        end
        if selfPtr.base then
            --print("base.present");
            selfPtr.base:present()
        else
            if DEBUG_BASE then
                print("Base object have not present method.")
            end
        end
    end
    return true
    -- }}}
end

local function queryBoundingBox()
    pworld:queryBoundingBox(
        tlx * PIX2M, tly * PIX2M, 
        brx * PIX2M, bry * PIX2M, 
        onQueryBoundingBox
    )
end

local function drawTanks()
    --gr.setColor{0, 0, 0}

    gr.setColor{1, 1, 1}
    --local w, h = gr.getDimensions()

    for _, v in ipairs(tanks) do
        v.base:present()
        v.turret:present()
    end

    --queryBoundingBox()
end

local playerTankKeyconfigIds: {string} = {}

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
        local Shortcut = kc.Shortcut
        local bmode: kc.BindType = "isdown"

        -- Непонятное и наверно ненужное перечисление.
        local enum E
            "left"
            "right"
            "down"
            "up"
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
            bmode, { key = direction },
            function(sc: Shortcut): boolean, Shortcut
                playerTank["right"](playerTank)
                return false, sc
            end,
            i18n("mt" .. direction), pushId("mt" .. direction)
        )

        direction = "left"
        kc.bind(
            bmode, { key = direction },
            function(sc: Shortcut): boolean, Shortcut
                playerTank["left"](playerTank)
                return false, sc
            end,
            i18n("mt" .. direction), pushId("mt" .. direction)
        )

        direction = "up"
        kc.bind(
            bmode, { key = direction },
            function(sc: Shortcut): boolean, Shortcut
                playerTank["up"](playerTank)
                return false, sc
            end,
            i18n("mt" .. direction), pushId("mt" .. direction)
        )

        direction = "down"
        kc.bind(
            bmode, { key = direction },
            function(sc: Shortcut): boolean, Shortcut
                playerTank["down"](playerTank)
                return false, sc
            end,
            i18n("mt" .. direction), pushId("mt" .. direction)
        )

        -- }}}
    else
        error("There is no player tank object instance, sorry.")
    end
end

local function playerTankUpdate()
    if playerTank then
        --print("playerTankUpdate internal")
        local lk = love.keyboard
        if lk.isDown("left") then
            playerTank:left()
        elseif lk.isDown("right") then
            playerTank:right()
        elseif lk.isDown("up") then
            playerTank:up()
        elseif lk.isDown("down") then
            playerTank:down()
        end
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

local function bindCameraControl()
    -- не прямой а квадратичный зум?
    local Shortcut = KeyConfig.Shortcut
    local cameraAnimationDuration = 0.2

    local function makeMoveFunction(xc: number, yc: number): function(sc: Shortcut): boolean, Shortcut
        -- {{{
        return function(sc: Shortcut): boolean, Shortcut
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

    local bindMode: KeyConfig.BindType = "keypressed"
    --local bindMode = "isdown"
    KeyConfig.bind(bindMode, { key = "a" }, makeMoveFunction(1., 0), 
        i18n("mcleft"), "camleft")
    KeyConfig.bind(bindMode, { key = "d" }, makeMoveFunction(-1.0, 0.), 
        i18n("mcright"), "camright")
    KeyConfig.bind(bindMode, { key = "w" }, makeMoveFunction(0., 1.), 
        i18n("mcup"), "camup") 
    KeyConfig.bind(bindMode, { key = "s" }, makeMoveFunction(0., -1.), 
        i18n("mcdown"), "camdown")
    KeyConfig.bind(bindMode, { key = "escape" }, function(sc: Shortcut): boolean, Shortcut
        if showLogo == true then
            love.event.quit()
        else
            showLogo = true
        end
        return false, sc
    end)
    KeyConfig.bind(bindMode, { key = "`" }, function(sc: Shortcut): boolean, Shortcut
        linesbuf.show = not linesbuf.show
        return false, sc
    end)

end

local function drawBoundingBox()
    local oldwidth = gr.getLineWidth()
    local lwidth = 4
    gr.setLineWidth(lwidth)
    gr.setColor{0., 0., 1.}
    -- видимые границы камеры

    local tlx_, tly_ = cam:worldCoords(tlx, tly)
    local brx_, bry_ = cam:worldCoords(brx, bry)

    gr.rectangle("line", tlx_, tly_, brx_ - tlx_, bry_ - tly_)
    gr.setLineWidth(oldwidth)
end

local function removeFirstColon(s: string): string
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

local function konsolePresent()
    --linesbuf.show = true
    gr.setColor{1, 1, 1, 1}
    linesbuf:pushi(string.format("camera x, y: %d, %d", cam.x, cam.y))

    if mode == "command" then
        cmdline = removeFirstColon(cmdline)
        linesbuf:pushiColored("%{red}>: %{black}" .. cmdline)
    end

    linesbuf:draw()
end

local function mainPresent()
    gr.clear(0.2, 0.2, 0.2)

    cam:attach()
    drawTanks()
    presentDrawlist()
    cam:detach()

    --cam:attach()
    drawBoundingBox()
    --cam:detach()
    drawlist = {}

    changeKeyConfigListbackground()

    coroutine.yield()
end

local function draw()
    local ok: boolean = coroutine.resume(drawCoro)
    if not ok then
        --error("drawCoro thread is end")
    end
    konsolePresent()
end

local function update(dt: number)
    --playerTankUpdate()
    camTimer:update(dt)
    pworld:update(1 / 60)
    linesbuf:update()
end

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

local function enterCommandMode()
    print("command mode enabled.")
    mode = "command"
    cmdline = ""
    love.keyboard.setKeyRepeat(true)
    love.keyboard.setTextInput(true)
end

local function leaveCommandMode()
    print("command mode disabled.")
    mode = "normal"
    love.keyboard.setKeyRepeat(false)
    love.keyboard.setTextInput(false)
    cmdline = ""
end

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
        local systemPrint = print
        print = konsolePrint
    ]]
    local f, loaderrmsg: function, string = load(preload .. cmdline)
    local time = 2
    if not f then
        linesbuf:push(time, "load() errmsg: " .. loaderrmsg)
    else
        local ok, pcallerrmsg: boolean, string = pcall(function()
            f()
        end)
        if not ok then
            linesbuf:push(time, "pcall() errmsg: " .. pcallerrmsg)
        else
            cmdline = ""
        end
    end
    table.insert(cmdhistory, cmdline)
end

local prevcmdline: string

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

    processValue(key)
end

-- положение в пикселях
local function spawn(pos: vector): Tank
    local res: Tank
    local ok, errmsg: boolean, string = pcall(function()
        if #tanks >= 1 then
            unbindPlayerTankKeys()
        end
        local t = Tank.new(pos)
        table.insert(tanks, t)
        -- игрок управляет последний созданным танком
        playerTank = t
        res = t
        bindPlayerTankKeys()
    end)
    if not ok then
        error("Could'not load. Please implement stub-tank. " .. errmsg)
    end
    return res
end

local function bindCameraZoomKeys()
    local Shortcut = KeyConfig.Shortcut
    local zoomSpeed = 0.01
    local zoomLower, zoomHigher = 0.3, 2

    KeyConfig.bind(
        "isdown",
        { key = "z" },
        function(sc: Shortcut): boolean, Shortcut
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
        logo = Logo.new()
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

local function init()
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

    cam = require 'camera'.new()
    if DEBUG_CAMERA then
        print("camera created x, y, scale, rot", cam.x, cam.y, cam.scale, cam.rot)
    end

    bindCameraZoomKeys()
    bindCameraControl()
    bindFullscreenSwitcher()
    --bindCommandModeHotkey()

    createDrawCoroutine()
end

local function quit()
    unbindPlayerTankKeys()
    tanks = {}
end

local function mousemoved(_: number, _: number, _: number, _: number)
end

local function wheelmoved(_: number, _: number)
    --KeyConfig.send(
end

local function mousepressed(x: number, y: number, btn: integer)
    if btn == 1 then
        -- значения координат мыши привести к мировым координатам камеры
        --print("mousepressed")
        --print("x, y", x, y)
        print("before worldCoords", x, y)
        x, y = cam:worldCoords(x, y)
        print("after worldCoords", x, y)
        --x, y = cam:cameraCoords(x, y)
        --x, y = x * PIX2M, y * PIX2M
        --print("x, y", x, y)
        spawn(vector.new(x, y))
    end
end

local function resize(w: integer, h: integer)
    if DEBUG_CAMERA then
        print("tanks window resized to w, h", w, h)
    end
end

local function textinput(text: string)
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
