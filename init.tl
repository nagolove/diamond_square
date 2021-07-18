global SCENE_PREFIX = "scenes/pink1"

local DEBUG_BASE = true
local DEBUG_TANK = true
local DEBUG_TURRET = false

require "love"
love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/empty/?.lua")
local i18n = require "i18n"

--require "external"
require "common"

--package.path = package.path .. ";scenes/automato/?.lua"

--local cam = require "camera".new()
local gr = love.graphics
--local imgui = require "imgui"
local inspect = require "inspect"
--local keyconfig = require "keyconfig"
--local mtschemes = require "mtschemes"
--local next = next
--local sim = require "simulator"
--local timer = require "Timer"

require "vector"
--local vec2 = require "vector"

local record Turret
    img: love.graphics.Image
    pos: vector -- центр поворота башни

    new: function(pos: vector): Turret
    present: function()
end

local Turret_mt: metatable<Turret> = {
    __index = Turret,
}

local record Base
    img: love.graphics.Image
    pos: vector -- центр поворота корпуса

    new: function(pos: vector): Base
    present: function()
end

local Base_mt: metatable<Base> = {
    __index = Base,
}

local record Tank
    turret: Turret
    base: Base
    -- Центр поворота корпуса. Пока совпадает с центром поворота башни.
    pos: vector 
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

local tanks: {Tank} = {}
-- Танк, которым управляет игрок
local playerTank: Tank

function Tank:left()
    if DEBUG_TANK then
        print("self.pos before", inspect(self.pos))
    end
    self.pos.x = self.pos.x - self.movementDelta
    self:updateSubObjectsPos()
    if DEBUG_TANK then
        print("self.pos after", inspect(self.pos))
    end
end

function Tank:right()
    print("Tank:right")
    self.pos.x = self.pos.x + self.movementDelta
    self:updateSubObjectsPos()
end

function Tank:up()
    print("Tank:up")
    self.pos.y = self.pos.y - self.movementDelta
    self:updateSubObjectsPos()
end

function Tank:down()
    print("Tank:down")
    self.pos.y = self.pos.y + self.movementDelta
    self:updateSubObjectsPos()
end

function Tank.new(pos: vector): Tank
    if DEBUG_TANK then
        print('Start of Tank creating..')
    end
    local self: Tank = setmetatable({} as Tank, Tank_mt)
    self.turret = Turret.new(pos)
    self.base = Base.new(pos)
    self.pos = shallowCopy(pos)
    self.movementDelta = 1.
    if DEBUG_TANK then
        print('self.turret', self.turret)
        print('self.base', self.base)
        print('End of Tank creaating.')
    end
    return self
end

function Turret.new(pos: vector): Turret
    if DEBUG_TURRET then
        print("Start of Turret creating..")
    end
    local self: Turret = setmetatable({} as Turret, Turret_mt)
    self.pos = shallowCopy(pos)
    self.img = love.graphics.newImage(SCENE_PREFIX .. "/bashnya1.png")
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
    self.base.pos.x = self.pos.y
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

function Base.new(pos: vector): Base
    if DEBUG_BASE then
        print("Base.new()")
    end
    local self: Base = setmetatable({} as Base, Base_mt)
    self.pos = shallowCopy(pos)
    self.img = love.graphics.newImage(SCENE_PREFIX .. "/korpus1.png")
    if DEBUG_BASE then
        print("self.pos", self.pos)
        print("self.img", self.img)
    end
    return self
end

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

local function drawTanks()
    --gr.setColor{0, 0, 0}

    gr.setColor{1, 1, 1}
    --local w, h = gr.getDimensions()

    for _, v in ipairs(tanks) do
        v.base:present()
        v.turret:present()
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

local function drawui()
end

local function draw()
    --gr.clear(1., 1., 1., 1.)
    gr.clear(0.2, 0.2, 0.2)

    drawTanks()

    --gr.print("TestTest")
end

local function update()
    playerTankUpdate()
end

local function keypressed(key: string)
    if key == "escape" then
        love.event.quit()
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


