-- vim: fdm=marker
-- vim: set colorcolumn=85
love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/pink1/?.lua")
require "love"
require "common"
require "keyconfig"
require "camera"
require "vector"
require "Timer"

global SCENE_PREFIX = "scenes/pink1"

local DEBUG_BASE = true
local DEBUG_TANK = true
local DEBUG_TANK_MOVEMENT = false
local DEBUG_TURRET = true
local DEBUG_CAMERA = true

local W, H = love.graphics.getDimensions()
-- Не работают когда двигается камера?
local tlx, tly, brx, bry: number, number, number, number = 0., 0., W, H 

-- Танк длиной пять метров имеет отображаемый размер 50 пикселей
-- коэффициент на который домножаю при переводе из метров в пиксели
--local M2PIX = 10
-- коэффициент на который домножаю при переводе из пикселей в метры
--local PIX2M = 1 / 10
local PIX2M = 1.

local camTimer: Timer = require "Timer".new()
local cam: Camera
local gr = love.graphics
local drawlist = {}

--local i18n = require "i18n"
--require "external"
--package.path = package.path .. ";scenes/automato/?.lua"

--local inspect = require "inspect"
--local imgui = require "imgui"

local record Turret
    pbody: love.physics.Body
    img: love.graphics.Image
    pos: vector -- центр поворота башни

    new: function(pos: vector, pbody: love.physics.Body): Turret
    present: function()
end

local Turret_mt: metatable<Turret> = {
    __index = Turret,
}

local record Base
    pbody: love.physics.Body
    img: love.graphics.Image
    pos: vector -- центр поворота корпуса

    new: function(pos: vector, pbody: love.physics.Body): Base
    present: function()
end

local Base_mt: metatable<Base> = {
    __index = Base,
}

local record Tank
    pbody: love.physics.Body

    turret: Turret
    base: Base
    -- Центр поворота корпуса. Пока совпадает с центром поворота башни.
    pos: vector 
    -- на сколько пикселей смещается танк при вызове метода движения
    movementDelta: number

    new: function(pos: vector): Tank
    left: function(Tank)
    right: function(Tank)
    up: function(Tank)
    down: function(Tank)
    updateSubObjectsPos: function(Tank)
end

local Tank_mt: metatable<Tank> = {
    __index = Tank,
}

local type CameraSettings = record
    dx: number
    dy: number
end

local cameraSettings: CameraSettings = {
    -- значение в пикселях
    dx = 10, dy = 10,
}

local pworld: love.physics.World
--local isActive: boolean

-- Все танки, в том числе и тот, которым управляет игрок.
local tanks: {Tank} = {}
-- Танк, которым управляет игрок
local playerTank: Tank

local function push2drawlist(f: function)
    if not f then
        error("Draw function could'not be nil.")
    end
    if type(f) ~= "function" then
        error("Draw function is not a function. It is a .. " .. type(f))
    end
    table.insert(drawlist, f)
end

local function presentDrawlist()
    for _, v in ipairs(drawlist) do
        v()
    end
end

function Tank:left()
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:left")
    end
    self.pos.x = self.pos.x - self.movementDelta
    self:updateSubObjectsPos()
end

function Tank:right()
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:right")
    end
    self.pos.x = self.pos.x + self.movementDelta
    self:updateSubObjectsPos()
end

function Tank:up()
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:up")
    end
    self.pos.y = self.pos.y - self.movementDelta
    self:updateSubObjectsPos()
end

function Tank:down()
    if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
        print("Tank:down")
    end
    self.pos.y = self.pos.y + self.movementDelta
    self:updateSubObjectsPos()
end

function Tank.new(pos: vector): Tank
    if DEBUG_TANK then
        print('Start of Tank creating..')
    end
    local self: Tank = setmetatable({} as Tank, Tank_mt)
    local x, y = pos.x, pos.y

    self.pbody = love.physics.newBody(pworld, x, y, "dynamic")
    self.pbody:setUserData(self)

    self.pos = shallowCopy(pos)
    self.turret = Turret.new(pos, self.pbody)
    self.base = Base.new(pos, self.pbody)
    self.movementDelta = 1.

    if DEBUG_TANK then
        print('self.turret', self.turret)
        print('self.base', self.base)
        print('End of Tank creating.')
    end
    return self
end

function Turret.new(pos: vector, pbody: love.physics.Body): Turret
    if DEBUG_TURRET then
        print("Start of Turret creating..")
    end
    local self: Turret = setmetatable({} as Turret, Turret_mt)
    self.pos = shallowCopy(pos)
    self.img = love.graphics.newImage(SCENE_PREFIX .. "/bashnya1.png")
    self.pbody = pbody;

    local w, h = (self.img as love.graphics.Texture):getDimensions()

    --local shape = love.physics.newRectangleShape(w, h)
    local r = w / 2
    local shape = love.physics.newCircleShape(pos.x, pos.y, r)
    --newRectangleShape: function(x: number, y: number, width: number, height: number, angle: number): PolygonShape
    love.physics.newFixture(self.pbody, shape as love.physics.Shape)
    if DEBUG_TURRET then
        --print("rectangle shape created w, h", w, h)
        print("circle shape created x, y, r", pos.x, pos.y, r)
    end

    if DEBUG_TURRET then
        print("self.pos", self.pos)
        print("self.img", self.img)
    end
    return self
end

function Tank:updateSubObjectsPos()
    self.turret.pos.x = self.pos.x
    self.turret.pos.y = self.pos.y

    self.base.pos.x = self.pos.x
    self.base.pos.y = self.pos.y
end

function Turret:present()
    local imgw, imgh = (self.img as love.graphics.Texture):getDimensions()
    local r, sx, sy, ox, oy: number = math.rad(0.), 1., 1., imgw / 2, imgh / 2
    --local kx, ky: number = 1., 1.
    --love.graphics.draw(self.img as love.graphics.Drawable, self.pos.x, self.pos.y, r, sx, sy, ox, oy, kx, ky)
    love.graphics.draw(
        self.img as love.graphics.Drawable,
        self.pos.x, self.pos.y, 
        r, 
        sx, sy, 
        ox, oy
    )
end

function Base:present()
    local imgw, imgh = (self.img as love.graphics.Texture):getDimensions()
    local r, sx, sy, ox, oy: number = math.rad(0.), 1., 1., imgw / 2, imgh / 2
    --love.graphics.draw(self.img as love.graphics.Drawable, self.pos.x, self.pos.y)
    love.graphics.draw(
        self.img as love.graphics.Drawable,
        self.pos.x, self.pos.y, 
        r, 
        sx, sy, 
        ox, oy
    )
end

function Base.new(pos: vector, pbody: love.physics.Body): Base
    if DEBUG_BASE then
        print("Base.new()")
    end
    local self: Base = setmetatable({} as Base, Base_mt)
    self.pos = shallowCopy(pos)
    self.img = love.graphics.newImage(SCENE_PREFIX .. "/korpus1.png")
    self.pbody = pbody
    if DEBUG_BASE then
        print("self.pos", self.pos)
        print("self.img", self.img)
    end
    return self
end

--[[
--{{{
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
--}}}
--]]

local function onBeginContact(
    _: love.physics.Fixture, 
    _: love.physics.Fixture, 
    _: love.physics.Contact
)
  --[[
  Добавить здесь преобразование координат из локальных в глобальные. Заполнять списки на отрисовку контактов. Сделать несколько списков отрисовки. Рисуется только
  то, что попадает в экран камеры. Посмотри+++ на встроенные функции отсечения в движке. Те списки постоянно сбрасывать в nil? Почему-бы и нет, хотя течет динамическая
  память. Зато структуры динамично работают, видно дейсвие, экшен.
  ]]

  --[[
  local shape = fixture:getShape()
  local rad = shape:getRadius()
  local body = fixture:getBody()
  local x, y = body:getWorldCenter()
  x, y = x * M2PIX, y * M2PIX

  lg.setColor(self.color)
  lg.circle("fill", x, y, shape:getRadius() * M2PIX)
  ]]

--  print(string.format("onBeginContact() fixture1 = %s fixture2 = %s contact = %s", inspect(fixture1), inspect(fixture2), inspect(contact)))
  --[[
  if drawContactPoints then
    local x1, y1, x2, y2 = contact:getPositions()
    local body1 = fixture1:getBody()
    local body2 = fixture2 and fixture2:getBody() or nil  
    if x1 and y1 then
--    x1, y1 = Snake.cam:worldCoords(x1, y1)
      -- отправляю контакты на отрисовку
      push2drawlist(function()
          lg.setColor(CONTACT_BEGIN_DRAW_COLOR)
          lg.circle("fill", x1 * M2PIX, y1 * M2PIX, 10)
        end)
    end
    if x2 and y2 then    
      x2, y2 = Snake.cam:worldCoords(x2, y2)
      -- отправляю контакты на отрисовку
      push2drawlist(function()
          lg.setColor(CONTACT_BEGIN_DRAW_COLOR)
          lg.circle("fill", x2 * M2PIX, y2 * M2PIX, 10)
        end)
    end
  end
  --]]
end

--[[
local function onEndContact(fixture1, fixture2, contact)
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
end
--]]

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
            print("Turret object have not present method.")
        end
        if selfPtr.base then
            --print("base.present");
            selfPtr.base:present()
        else
            print("Base object have not present method.")
        end
        --bodiesCount = bodiesCount + 1
        --selfPtr:queryDraw(fixture) 
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

    --for _, v in ipairs(tanks) do
        --v.base:present()
        --v.turret:present()
    --end

    queryBoundingBox()
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

local function drawui()
end

local function bindCameraControl()
    -- не прямой а квадратичный зум?
    local Shortcut = KeyConfig.Shortcut
    local cameraAnimationDuration = 0.2

    local function makeMoveFunction(xc: number, yc: number): function(sc: Shortcut): boolean, Shortcut
        return function(sc: Shortcut): boolean, Shortcut
            local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
            camTimer:during(cameraAnimationDuration, function(dt: number, time: number, delay: number)
                --cam:move(-reldx * (delay - time) * xc, -reldy * (delay - time) * yc)
                local dx, dy = -reldx * (delay - time) * xc, -reldy * (delay - time) * yc
                print("delay - time", delay - time)
                print("dx, dy", dx, dy)
                cam:move(dx * dt, dy * dt)
            end)
            return true, sc
        end
    end

    local bindMode: KeyConfig.BindType = "keypressed"
    --local bindMode = "isdown"
    KeyConfig.bind( bindMode, { key = "a" }, makeMoveFunction(1., 0), "move left", "camleft")
    KeyConfig.bind( bindMode, { key = "d" }, makeMoveFunction(-1.0, 0.), "move right", "camright") 
    KeyConfig.bind( bindMode, { key = "w" }, makeMoveFunction(0., 1.), "move up", "camup") 
    KeyConfig.bind( bindMode, { key = "s" }, makeMoveFunction(0., -1.), "move down", "camdown")
end

local function drawBoundingBox()
    tlx, tly = cam:worldCoords(tlx, tly)
    brx, bry = cam:worldCoords(brx, bry)

    local oldwidth = gr.getLineWidth()
    local lwidth = 4
    gr.setLineWidth(lwidth)
    gr.setColor{0., 0., 1.}
    -- видимые границы камеры
    gr.rectangle("line", tlx, tly, brx - tlx, bry - tly)
    gr.setLineWidth(oldwidth)
end

local function draw()
    --gr.clear(1., 1., 1., 1.)

    gr.clear(0.2, 0.2, 0.2)

    cam:attach()
    drawTanks()
    cam:detach()

    presentDrawlist()

    --cam:attach()
    drawBoundingBox()
    --cam:detach()
    drawlist = {}
end

local function update(dt: number)
    playerTankUpdate()
    camTimer:update(dt)
    pworld:update(dt)
end

local function keypressed(key: string)
    if key == "escape" then
        love.event.quit()
    elseif key == "space" then

        print("space pressed")
        local animLen = 3
        camTimer:during(animLen, function(dt: number, time: number, _: number)
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
        --]]

    end
end

local function spawn(pos: vector): Tank
    local res: Tank
    local ok, errmsg: boolean, string = pcall(function()
        local t = Tank.new(pos)
        table.insert(tanks, t)
        -- игрок управляет последний созданным танком
        playerTank = t
    end)
    if not ok then
        error("Could'not load. Please implement stub-tank. " .. errmsg)
    end
    return res
end

local function init()
    --[[
    i18n.set('en.welcome', 'welcome to this program')
    i18n.load({
        en = {
            good_bye = "good-bye!",
            age_msg = "your age is %{age}.",
            phone_msg = {
                one = "you have one new message.",
                other = "you have %{count} new messages."
            }
        }
    })
    print("translated", i18n.translate('welcome'))
    print("translated", i18n('welcome'))
    --]]

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
        "zoom camera in",
        "zoomin"
    )
    
    local canSleep = true
    pworld = love.physics.newWorld(0., 0., canSleep)
    pworld:setCallbacks(onBeginContact)

    cam = require 'camera'.new()
    if DEBUG_CAMERA then
        print("camera created x, y, scale, rot", cam.x, cam.y, cam.scale, cam.rot)
    end
    bindCameraControl()
end

local function quit()
    tanks = {}
end

--local function mousemoved(x: number, y: number, _: number, _: number)
--end

--local function wheelmoved(x: number, y: number)
--end

local function mousepressed(x: number, y: number, btn: integer)
    if btn == 1 then
        spawn(vector.new(x, y))
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
    --mousemoved = mousemoved,
    --wheelmoved = wheelmoved
}
