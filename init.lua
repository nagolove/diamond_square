local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local load = _tl_compat and _tl_compat.load or load; local math = _tl_compat and _tl_compat.math or math; local pairs = _tl_compat and _tl_compat.pairs or pairs; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table


SCENE_PREFIX = "scenes/t80"

love.filesystem.setRequirePath("?.lua;?/init.lua;" .. SCENE_PREFIX .. "/?.lua")


require("tabular")
require("love")
require("common")
require("keyconfig")
require("camera")
require("vector")
require("Timer")
require("imgui")
require('render')
require('diamondsquare')
require('profi')




local serpent = require('serpent')
local List = require("list")

i18n = require("i18n")
local metrics = require("metrics")
vec2 = require("vector")
vecl = require("vector-light")
inspect = require("inspect")
tabular = require("tabular")


local Filesystem = love.filesystem

local Graphics = love.graphics
local Physics = love.physics
local gr = love.graphics
local lp = love.physics
local Shortcut = KeyConfig.Shortcut
local profi = require('profi')

local Drawable = love.graphics.Drawable
local abs, ceil, pow, resume, sqrt = math.abs, math.ceil, math.pow,
coroutine.resume, math.sqrt
local yield = coroutine.yield

local Mode = {}





local Brush = {}




local ObjectType = {}







local DrawNode = {}





local Background = {}








local TurretCommon = {}







local turretCommon = {
   barrelRectXY = { 124, 0 },
   barrelRectWH = { 8, 109 },
   towerRectXY = { 101, 103 },
   towerRectWH = { 54, 58 },
}


local Edge = {}






local Arena = {}





























local FilterData = {}













local Hangar = {}
















local Tank = {}





































local Turret = {}















































local Base = {}



















































local Bullet = {}






















local ParticleSystemDefinition = {}













local ParticlesMap = {}

particles = {


   ["default"] = {
      blendmode = 'alpha',
      alphamode = 'alphamultiply',
      lifetime1 = 1,
      lifetime2 = 2,
      emissionRate = 10,
      sizeVariation = 1,
      lineAcceleration = { -20, -20, 20, 20 },
      colors = {
         { 1, 1, 1, 1 },
         { 1, 1, 1, 0 },
      },
      emiterlifetimeexp = "return 0.1 + (rng:random() + 0.01) / 2",
      rotation1 = 0,
      rotation2 = math.pi * 2,
   },

}


local Hit = {}













local Logo = {}













local CameraSettings = {}








local currentNavigator

local particlesfname = "particles-def.lua"
maxParticlesNumber = 512
notificationDelay = 2.5

DEFAULT_W, DEFAULT_H = 1024, 768

W, H = love.graphics.getDimensions()


M2PIX = 10

PIX2M = 1 / 10







tankForceScale = 8


local historyfname = "cmdhistory.txt"
local linesbuf = require("kons").new(SCENE_PREFIX .. "/VeraMono.ttf", 26)
mode = "normal"
cmdline = ""
local cmdhistory = {}
cursorpos = 1
suggestList = List.new()

attachedVarsList = {}
local hitImages = {
   love.graphics.newImage(SCENE_PREFIX .. '/flame2.png'),
   love.graphics.newImage(SCENE_PREFIX .. '/tentacles.png'),
}




local drawlistTop = {}

local drawlistBottom = {}




local camTimer = require("Timer").new()
local drawCoro = nil
showLogo = true

playerTankKeyconfigIds = {}

angularImpulseScale = 5 * math.pi / 4

camZoomLower, camZoomHigher = 0.075, 3.5

local zoomSpeed = 0.01
local cameraSettings = {

   dx = 2000, dy = 2000,
}



tanks = {}
hangars = {}







bullets = {}

local bulletRadius = 4
local bulletColor = { 0.1, 0.1, 0.1, 1 }

bulletLifetime = 35

tankCounter = 0
rng = love.math.newRandomGenerator()




local cameraZoneR

local edgeColor = { 0, 0, 0, 1 }
local edgeLineWidth = 10


local drawTerrain = true

local baseBatch = Batch.new("tank_body_small.png")
local turretBatch = Batch.new("tank_tower.png")
local hangarBatch = Batch.new("hangar.png")

maxTrackCount = 128
hits = {}
local coroutines = {}


local function initParticles(fname)
   print('initParticles')
   print('loading from', fname)
   local fdata = love.filesystem.read(fname)
   if fdata then
      local ok, data = serpent.load(fdata), ParticlesMap
      if ok then
         for k, v in pairs(data) do
            if particles[k] then
               print(string.format('override existing value [%s]. Be careful.', k))
            end
            particles[k] = v
         end
      else
         print('parsing error', fname)
      end
   else
      print('reading error', fname)
   end
end

local function writeParticles(fname)
   Filesystem.write(fname, serpent.dump(particles))
end

local function updateCoroutines()

   local alive = {}
   for _, coro in ipairs(coroutines) do
      if coroutine.status(coro) ~= 'dead' then
         local ok, errmsg = coroutine.resume(coro), string
         if ok then
            table.insert(alive, coro)
         else
            print('coro error:', errmsg)
         end
      end
   end
   coroutines = alive

end

function Bullet.new(px, py, dirx, diry,
   tankId)

   local Bullet_mt = {
      __index = Bullet,
   }
   local self = setmetatable({}, Bullet_mt)

   self.physbody = love.physics.newBody(physworld, px, py, "dynamic")
   self.physbody:setUserData(self)
   self.physbody:setBullet(true)
   self.timestamp = love.timer.getTime()
   self.died = false
   self.px = px
   self.py = py
   local shape = love.physics.newCircleShape(0, 0, bulletRadius * PIX2M)
   love.physics.newFixture(self.physbody, shape)


   self.physbody:setMass(1)
   local impulse = 100
   if dirx and diry then
      self.physbody:applyLinearImpulse(dirx * impulse, diry * impulse)
   end

   self.dir = vec2.new(dirx, diry)
   self.id = tankId or 0
   self.objectType = 'Bullet'

   return self

end

local function contactFilter(fix1, fix2)


   local collide = true
   local objectType1
   local objectType2
   local userdata1, userdata2

   if fix1 then
      userdata1 = fix1:getBody():getUserData()
      if userdata1 then
         objectType1 = userdata1['objectType']

      end
   end
   if fix2 then
      userdata2 = fix2:getBody():getUserData()
      if userdata2 then

         objectType2 = userdata2['objectType']

      end
   end



   if objectType1 and objectType2 then
      if objectType1 == 'Base' and objectType2 == 'Turret' then
         local id1 = userdata1['id']
         local id2 = userdata2['id']
         if id1 == id2 then

            collide = true
         end
      end
   end












   return collide

end











































local function getBodyFilterData(body)

   local result = {}
   for _, fixture in ipairs(body:getFixtures()) do
      local categoies, mask, group = fixture:getFilterData()
      table.insert(result, {
         categoies = categoies,
         mask = mask,
         group = group,
      })
   end
   return result

end

function Hangar.new(pos)
   local Hangar_mt = {
      __index = Hangar,
   }
   local self = setmetatable({}, Hangar_mt)
   self.objectType = "Hangar"
   self.physbody = Physics.newBody(physworld, 0, 0, "static")
   self.physbody:setUserData(self)
   self.rectXY = { 0, 0 }
   self.rectWH = { 511, 511 }
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
   local shape = Physics.newPolygonShape(vertices)
   self.vertices = vertices
   self.fixture = Physics.newFixture(self.physbody, shape)

   self.polyshape = shape
   self.color = { 1, 1, 1, 1 }
   return self
end

function Hangar:update()

end

function Hangar:present()
   local shape = self.fixture:getShape()
   if shape:getType() ~= "polygon" then
      error("Tank BaseP shape should be polygon.")
   end

   local body = self.fixture:getBody()

   local x1, y1, x2, y2, x3, y3, x4, y4 = self.polyshape:getPoints()

   x1, y1 = body:getWorldPoints(x1, y1)
   x2, y2 = body:getWorldPoints(x2, y2)
   x3, y3 = body:getWorldPoints(x3, y3)
   x4, y4 = body:getWorldPoints(x4, y4)

   x1, y1 = M2PIX * x1, M2PIX * y1
   x2, y2 = M2PIX * x2, M2PIX * y2
   x3, y3 = M2PIX * x3, M2PIX * y3
   x4, y4 = M2PIX * x4, M2PIX * y4

   hangarBatch:present(
   x1, y1, x2, y2, x3, y3, x4, y4,
   self.rectXY[1], self.rectXY[2], self.rectWH[1], self.rectWH[2],
   self.color)







end

local function updateHangars()
   for _, v in ipairs(hangars) do
      if v.update then
         v:update()
      end
   end
end
local function drawArrow(
   fromx, fromy, tox, toy,
   color)


   local angle = math.pi / 11
   local arrowDiv = 20

   color = color or { 1, 1, 1, 1 }
   local x, y = fromx - tox, fromy - toy
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


   gr.line(tox, toy, tox - lx, toy - ly)

   gr.line(tox, toy, tox - rx, toy - ry)

   gr.line(fromx, fromy, tox, toy)

   gr.setLineWidth(oldlinew)
end

local function drawBullets()

   for _, b in ipairs(bullets) do
      local px, py = b.physbody:getWorldCenter()
      px, py = px * M2PIX, py * M2PIX
      gr.setColor(bulletColor)
      gr.circle("fill", px, py, bulletRadius)
   end

end

local function updateBullets()

   local alive = {}
   local now = love.timer.getTime()
   for _, bullet in ipairs(bullets) do

      bullet.velx, bullet.vely = bullet.physbody:getLinearVelocity()
      bullet.mass = bullet.physbody:getMass()
      bullet.px, bullet.py = bullet.physbody:getWorldCenter()
      bullet.px, bullet.py = bullet.px * M2PIX, bullet.py * M2PIX

      local diff = now - bullet.timestamp

      if diff < bulletLifetime and not bullet.died then
         table.insert(alive, bullet)
      end
   end
   bullets = alive

end

local activeImage = 1

local function newParticleSystemWithDef(psdef)
   local ps
   ps = love.graphics.newParticleSystem(hitImages[activeImage], maxParticlesNumber)


   ps:setParticleLifetime(psdef.lifetime1, psdef.lifetime2)

   ps:setEmissionRate(psdef.emissionRate)
   ps:setSizeVariation(psdef.sizeVariation)


   ps:setLinearAcceleration(
   psdef.lineAcceleration[1],
   psdef.lineAcceleration[2],
   psdef.lineAcceleration[3],
   psdef.lineAcceleration[4])


   ps:setColors(
   psdef.colors[1][1],
   psdef.colors[1][2],
   psdef.colors[1][3],
   psdef.colors[1][4],
   psdef.colors[2][1],
   psdef.colors[2][2],
   psdef.colors[2][3],
   psdef.colors[2][4])


   local lifetime = 1.
   local ok, errmsg = pcall(function()

      lifetime = rng:random() * 2
   end)
   if not ok then
      print('pddef.emiterlifetimeexp compilation error', errmsg)
   end
   ps:setEmitterLifetime(lifetime)









   ps:setRotation(psdef.rotation1, psdef.rotation2)
   return ps
end

function Hit.new(x, y)
   local Hit_mt = {
      __index = Hit,
   }
   local self = setmetatable({}, Hit_mt)




   self.ps = newParticleSystemWithDef(particles['default'])

   x, y = x * M2PIX, y * M2PIX

   self.x = x
   self.y = y

   return self
end

function Turret:createFireCoro()
   return coroutine.create(function()
      if not self.loaded then


      end





























      local px, py = self.tank.base.physbody:getWorldCenter()


      local magic = 14

      print(self.id)


      table.insert(bullets, Bullet.new(
      px - self.dir.x * magic,
      py - self.dir.y * magic,
      -self.dir.x, -self.dir.y,
      self.id))

   end)
end

function Turret:fire()
   table.insert(coroutines, self:createFireCoro())
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

function push2drawlistTop(f, self)
   if not f then
      error("Draw could'not be nil.")
   end
   if type(f) ~= "function" then
      error("Draw function is not a function. It is a .. " .. type(f))
   end
   table.insert(drawlistTop, { f = f, self = self })
end

function push2drawlistBottom(f, self)
   if not f then
      error("Draw could'not be nil.")
   end
   if type(f) ~= "function" then
      error("Draw function is not a function. It is a .. " .. type(f))
   end
   table.insert(drawlistBottom, { f = f, self = self })
end

function Arena.new(fname)
   local Arena_mt = { __index = Arena }
   local self = setmetatable({}, Arena_mt)

   if fname and type(fname) == "string" then
      local edges = {}
      local filedata = love.filesystem.read(fname)
      if filedata then
         local ok = false
         local root
         ok, root = serpent.load(filedata)
         self.edges = edges

         if (root).rngSeed then
            local seed = (root).rngSeed
            print('seed value loaded', seed)
            rng = love.math.newRandomGenerator(seed)
         end

         if not ok then
            print("Could'not do serpent.load()")
            self:createFixtures()
         end
      else
         self.edges = edges
         self:createFixtures()
      end
   end

   self.objectType = "Arena"

   return self
end

function Arena:mousemoved(_, _, _, _)
   push2drawlistTop(function()
      local linew = 3
      if self.mode then
         if self.mode == 'second' then
            gr.setColor({ 0, 0, 0.9, 1 })
            local ow = gr.getLineWidth()
            gr.setLineWidth(linew)
            gr.line(
            self.edges[#self.edges].x1,
            self.edges[#self.edges].y1,
            self.edges[#self.edges].x2,
            self.edges[#self.edges].y2)

            gr.setLineWidth(ow)
         end
      end
   end)
end

function Arena:update()
end

function Arena:mousepressed(x, y, _)
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

function Arena:present(fixture)
   local shape = fixture:getShape()
   local x1, y1, x2, y2 = shape:getPoints()
   x1, y1 = fixture:getBody():getWorldPoints(x1, y1)
   x2, y2 = fixture:getBody():getWorldPoints(x2, y2)
   x1, y1, x2, y2 = x1 * M2PIX, y1 * M2PIX, x2 * M2PIX, y2 * M2PIX
   local olw = gr.getLineWidth()
   local ocolor = { gr.getColor() }
   gr.setColor(edgeColor)
   gr.setLineWidth(edgeLineWidth)
   gr.line(x1, y1, x2, y2)
   gr.setColor(ocolor)
   gr.setLineWidth(olw)
end

function Arena:save2file(fname)

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
   assert(self.edges)
   if self.physbody then
      self.physbody:destroy()
      self.physbody = nil
   end
   if not self.physbody then
      self.physbody = love.physics.newBody(physworld, 0, 0, 'static')
   end
   for _, edge in ipairs(self.edges) do
      local shape = lp.newEdgeShape(edge.x1, edge.y1, edge.x2, edge.y2)
      lp.newFixture(self.physbody, shape)
   end
end



function Tank:fire()

   if self.turret then
      self.turret:fire()
   end

end

function Tank:circleMove()
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

      end
   end))
end

function Base:left()
   self.physbody:applyTorque(-angularImpulseScale)
end

function Base:right()
   self.physbody:applyTorque(angularImpulseScale)
end

function Base:forward()

   if self.tank.fuel > 0. then
      local x, y = self.dir.x * tankForceScale, self.dir.y * tankForceScale
      self.physbody:applyForce(x, y)
   end

end

function Base:backward()

   if self.tank.fuel > 0. then
      local x, y = self.dir.x * tankForceScale, self.dir.y * tankForceScale
      self.physbody:applyForce(-x, -y)
   end

end


function Tank:left()
   self.base:left()
end

function Tank:right()
   self.base:right()
end

function Tank:forward()
   self.base:forward()
end

function Tank:backward()
   self.base:backward()
end



function Tank.new(pos, dir)

   local Tank_mt = {
      __index = Tank,
   }




   local self = setmetatable({}, Tank_mt)

   tankCounter = tankCounter + 1








   self.strength = 1.
   self.fuel = 1.
   self.id = tankCounter
   if not dir then
      dir = vector.new(0, 0)
   end
   self.dir = dir:clone()

   self.pos = pos
   self.color = { 1, 1, 1, 1 }
   local angle, _ = dir:toPolar()
   self.base = Base.new(self)
   self.base.physbody:setAngle(angle)
   self.turret = Turret.new(self)



   self.base.id = self.id
   self.turret.id = self.id

   return self

end

























function Base:drawDirectionVector()

   if self.dir then
      local x, y = self.physbody:getWorldCenter()
      local scale = 100
      local color = { 0., 0.05, 0.99, 1 }
      x, y = x * M2PIX, y * M2PIX
      drawArrow(x, y, x + self.dir.x * scale, y + self.dir.y * scale, color)
   end

end

function Base:resetVelocities()

   if self.physbody then
      self.physbody:setAngularVelocity(0)
      self.physbody:setLinearVelocity(0, 0)
   end

end

function Base:updateDir()

   local unit = 1

   self.dir = vec2.fromPolar(self.physbody:getAngle() + math.pi / 2, unit)

end

function Base:engineCycle()


   if self.tank.fuel > 0 then
   end
end

function Base:update()
   self:updateDir()
   if not self.filterdata then
      self.filterdata = getBodyFilterData(self.physbody)
   end
   self:processTracks()
end

function Base:processTracks()
   local vx, vy = self.physbody:getLinearVelocity()
   local len = vecl.len(vx, vy)
   local threshold = 1
   local w = self.physbody:getAngularVelocity()
   if len > threshold or w > 0.1 then
      self:pushTrack()
   end

end

local function removeTank(tank)
   for k, v in ipairs(tanks) do
      if v == tank then
         table.remove(tanks, k)
         print('tank removed. allright')
         break
      end
   end
end

function Tank:update()




   if self.strength <= 0. then
      table.insert(coroutines, coroutine.create(function()
         print('tank died')
         yield()


         self.base.physbody:destroy()
         self.turret.physbody:destroy()

         removeTank(self)
      end))
      return self
   end

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
































end

function Turret.new(t)

   if not t then
      error("Could'not create Turret without Tank object")
   end

   local Turret_mt = {
      __index = Turret,
   }

   local self = setmetatable({}, Turret_mt)
   self.tank = t
   self.objectType = "Turret"
   self.tankphysbody = t.base.physbody


   local px, py = t.base.physbody:getWorldCenter()

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

   self.fixtureBarrel = lp.newFixture(self.physbody, self.barrelShape)
   self.barrelCategories, self.barrelMask, self.barrelGroup = self.fixtureBarrel:getFilterData()




   self.fixtureTower = lp.newFixture(self.physbody, self.towerShape)
   self.towerCategories, self.towerMask, self.towerGroup = self.fixtureTower:getFilterData()







   self.fixtureTower:setDensity(0.0001)
   self.fixtureBarrel:setDensity(0.0001)
   self.physbody:resetMassData()


   local p1x, p1y = self.tank.base.physbody:getWorldCenter()
   local p2x, p2y = self.tank.base.physbody:getWorldCenter()



   self.joint = lp.newWeldJoint(self.tank.base.physbody, self.physbody, p1x, p1y, p2x, p2y, false)












   return self

end



function Turret:rotateToMouse()

   local mx, my = love.mouse.getPosition()
   mx, my = cam:worldCoords(mx, my)
   mx, my = mx * PIX2M, my * PIX2M

   local x, y = self.physbody:getWorldCenter()
   local d = vec2.new(x - mx, y - my)
   self.dir = d:normalizeInplace()
   local a, _ = d:toPolar()















   self.angle = -a

   self.physbody:setAngle(self.angle + math.pi)

end

function Turret:update()


   if playerTank and self.tank == playerTank then
      self:rotateToMouse()
   end












end

function Turret:present()

   if not self.fixtureTower or not self.fixtureBarrel then
      return
   end

   local towerShape = self.fixtureTower:getShape()
   local barrelShape = self.fixtureBarrel:getShape()

   if towerShape:getType() ~= "polygon" or
      barrelShape:getType() ~= "polygon" then
      error("Only polygon shapes are allowed.")
   end

   local body = self.fixtureTower:getBody()


   local tx1, ty1, tx2, ty2, tx3, ty3, tx4, ty4 = self.towerShape:getPoints()

   tx1, ty1 = body:getWorldPoints(tx1, ty1)
   tx2, ty2 = body:getWorldPoints(tx2, ty2)
   tx3, ty3 = body:getWorldPoints(tx3, ty3)
   tx4, ty4 = body:getWorldPoints(tx4, ty4)

   tx1, ty1 = M2PIX * tx1, M2PIX * ty1
   tx2, ty2 = M2PIX * tx2, M2PIX * ty2
   tx3, ty3 = M2PIX * tx3, M2PIX * ty3
   tx4, ty4 = M2PIX * tx4, M2PIX * ty4


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


   turretCommon.towerRectWH[1],
   turretCommon.towerRectWH[2],
   self.tank.color)

   turretBatch:present(
   bx1, by1, bx2, by2, bx3, by3, bx4, by4,
   turretCommon.barrelRectXY[1],
   turretCommon.barrelRectXY[2],
   turretCommon.barrelRectWH[1],
   turretCommon.barrelRectWH[2],
   self.tank.color)



end

function Base.new(t)

   local Base_mt = {
      __index = Base,
   }

   if not t then
      error("Could'not create BaseP without Tank object")
   end

   local self = setmetatable({}, Base_mt)
   self.objectType = "Base"
   self.tank = t
   self.track = {}


   self.rectXY = { 86, 72 }
   self.rectWH = { 84, 111 }

   self.physbody = love.physics.newBody(physworld, 0, 0, "dynamic")
   self.physbody:setAngularDamping(3.99)
   self.physbody:setLinearDamping(2)
   self.physbody:setUserData(self)

   local px, py = t.pos.x, t.pos.y



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

   local shape = Physics.newPolygonShape(vertices)
   self.fixture = Physics.newFixture(self.physbody, shape)

   self.polyshape = shape

   return self

end




function Base:present()

   local shape = self.fixture:getShape()
   if shape:getType() ~= "polygon" then
      error("Tank BaseP shape should be polygon.")
   end

   local body = self.fixture:getBody()

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
   self.rectXY[1], self.rectXY[2], self.rectWH[1], self.rectWH[2],
   self.tank.color)


   self.x4 = x4
   self.y4 = y4
   self.x1 = x1
   self.y1 = y1
   self:drawTrack()

end

function Base:pushTrack()
   if self.x4 and self.y4 and self.x1 and self.y1 then
      local trackNode = {}
      local len = 15
      local deltalen = 3
      local dx1, dx2 = vecl.normalize(self.x4 - self.x1, self.y4 - self.y1)
      local deltax, deltay = dx1 * deltalen, dx2 * deltalen
      local x1, y1, x4, y4
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
   gr.setColor({ 0, 0, 0, 1 })
   for _, v in ipairs(self.track) do
      gr.line(v[1], v[2], v[3], v[4])
      gr.line(v[5], v[6], v[7], v[8])
   end
   gr.setLineWidth(olw)
end


local function newHit(x, y)
   table.insert(hits, Hit.new(x, y))
end

function Tank:damage(bullet)
   local bulx, buly = bullet.physbody:getWorldCenter()
   local px, py = bullet.px, bullet.py
   local len = sqrt(pow(abs(bulx - px), 2) + pow(abs(buly - py), 2))
   print('len', len)
   local damage = 0.25
   self.strength = self.strength - damage
   print('strength', self.strength)
end
















local function processTankVsBullet(_, _)
end

local function processTankVsTank(_, _)
end

local contactMap = {
   ['Tank'] = {
      ['Bullet'] = processTankVsBullet,
      ['Tank'] = processTankVsTank,
   },
}

local function onBeginContact(
   fixture1,
   fixture2,
   contact)




   local p1x, p1y, _, _ = contact:getPositions()

   local body1 = fixture1:getBody()
   local userdata1 = body1:getUserData()
   local body2 = fixture2:getBody()
   local userdata2 = body2:getUserData()
   local objectType1
   local objectType2

   if fixture1 then
      userdata1 = fixture1:getBody():getUserData()
      if userdata1 then
         objectType1 = userdata1['objectType']

      end
   end
   if fixture2 then
      userdata2 = fixture2:getBody():getUserData()
      if userdata2 then

         objectType2 = userdata2['objectType']

      end
   end



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
               local b = fixture1:getUserData()
               if b and b.died then
                  b.died = true
               end

               (userdata2['tank']):damage(userdata1)
            end
            if objectType2 == 'Bullet' then
               local b = fixture2:getUserData()
               if b and b.died then
                  b.died = true
               end

               (userdata1['tank']):damage(userdata2)
            end

         end
      end
   end

















end

local function onEndContact(
   _,
   _,
   _)



end

local function onQueryBoundingBox(fixture)

   local selfPtr = fixture:getBody():getUserData()
   if selfPtr and selfPtr['present'] then
      (selfPtr['present'])(selfPtr, fixture)
   end
   return true

end

local function queryBoundingBox()

   if cam then
      local tlx, tly = cam:worldCoords(0, 0)
      local brx, bry = cam:worldCoords(gr.getDimensions())
      brx, bry = brx + W, bry + H















      physworld:queryBoundingBox(
      tlx * PIX2M, tly * PIX2M,
      brx * PIX2M, bry * PIX2M,
      onQueryBoundingBox)

   end

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

   local localePath = SCENE_PREFIX .. "/locales"
   local files = love.filesystem.getDirectoryItems(localePath)
   print("locale files", inspect(files))
   for _, v in ipairs(files) do
      i18n.loadFile(localePath .. "/" .. v, function(path)
         local chunk, errmsg = love.filesystem.load(path)
         if not chunk then
            error(errmsg)
         end
         return chunk
      end)
   end

   i18n.setLocale('ru')


end

local function drawHits()
   local blendmode, alphamode = love.graphics.getBlendMode()












   for _, v in ipairs(hits) do
      gr.setColor({ 1, 1, 1, 1 })
      love.graphics.draw(v.ps, v.x, v.y)
   end
end

local function updateHits(dt)
   for _, v in ipairs(hits) do
      v.ps:update(dt)
   end
end

function terrain(mapn, rez)
   if not mapn then
      mapn = 8
   end
   if not rez then
      rez = 128
   end
   print('terrain', mapn, rez)
   linesbuf:push(notificationDelay, 'terrain mapn = %d, rez = %d', mapn, rez)
   diamondSquare = DiamonAndSquare.new(mapn, rez, rng)
   diamondSquare:eval()
   diamondSquare:draw2canvas()
   diamondSquare.canvas:newImageData():encode('png', 'terrain.png')
end



function getTerrainCorners()

end

local function bindDeveloperKeys()
   local kc = KeyConfig
   kc.bind(

   'isdown', { key = "p" },
   function(sc)
      if mode ~= "normal" then
         return false, sc
      end

      print('works')
      if playerTank then
         local x, y = playerTank.base.physbody:getWorldCenter()
         newHit(x, y)
         print('new Hit created at', x, y)
      end

      return false, sc
   end,

   'spawn Hit')
   kc.bind(

   'keypressed', { key = "r" },
   function(sc)
      if mode ~= "normal" then
         return false, sc
      end

      terrain()

      return false, sc
   end,

   'spawn Hit')
end

local function bindTerrainControlKeys()
   local kc = KeyConfig
   kc.bind(
   'keypressed', { key = "t" },
   function(sc)
      if mode ~= "normal" then
         return false, sc
      end
      print('drawTerrain', drawTerrain)
      drawTerrain = not drawTerrain
      return false, sc
   end,

   'draw terrain or not')













end

local function bindPlayerTankKeys()

   if playerTank then

      local kc = KeyConfig
      local bmode = "isdown"

      local ids = {
         kc.bind(
         bmode, { key = "d" },
         function(sc)
            if mode ~= "normal" then
               return false, sc
            end
            playerTank["right"](playerTank)
            return false, sc
         end,
         i18n("mt" .. "right")),

         kc.bind(
         bmode, { key = "a" },
         function(sc)
            if mode ~= "normal" then
               return false, sc
            end
            playerTank["left"](playerTank)
            return false, sc
         end,
         i18n("mt" .. "left")),

         kc.bind(
         bmode, { key = "w" },
         function(sc)
            if mode ~= "normal" then
               return false, sc
            end
            playerTank["forward"](playerTank)
            return false, sc
         end,
         i18n("mt" .. "forward")),

         kc.bind(
         bmode, { key = "s" },
         function(sc)
            if mode ~= "normal" then
               return false, sc
            end
            playerTank["backward"](playerTank)
            return false, sc
         end,
         i18n("mt" .. "backward")),

         kc.bind(
         bmode, { key = "v" },
         function(sc)
            if mode ~= "normal" then
               return false, sc
            end
            playerTank["resetVelocities"](playerTank)
            return false, sc
         end,
         i18n("resetVelocities")),

         kc.bind(
         "isdown", { key = "space" },
         function(sc)
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

   else
      error("There is no player tank object instance, sorry. Keys are not binded.")
   end

end

local function changeKeyConfigListbackground()

   KeyConfig.setListSetupCallback(function(list)
      list.colors.normal = { bg = { 0.19, 0.61, 0.88 }, fg = { 1, 1., 1., 1. } }
   end)

end

local function buildParticlesNames()
   local res = {}
   for k, _ in pairs(particles) do
      table.insert(res, k)
   end
   return res
end

local currentParticesType = 0

local function selectParticleType()
   local v
   local st
   local zeroseparated, _ = separateByZeros(buildParticlesNames())
   v, st = imgui.Combo("тип частиц", currentParticesType, zeroseparated)
   if st then
      currentParticesType = ceil(v)
   end
end

local function drawParticlesEditor()
   imgui.Begin(i18n('effecteditor'), false, "AlwaysAutoResize")
   local v
   local st

   selectParticleType()

   local psdef = particles["default"]


   local zeroseparated = separateByZeros({ "1", "2" })
   v, st = imgui.Combo('выбери картинки', activeImage - 1, zeroseparated)
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


   psdef.emiterlifetimeexp = imgui.InputTextMultiline("emiterlifetimeexp", psdef.emiterlifetimeexp, 600, 400);

   if imgui.Button('>> write system') then


   end
   imgui.End()
end

local function findTank(object)
   for i, v in ipairs(tanks) do
      if v == object then
         return i
      end
   end
   return nil
end

local function moveCameraToTank(tank)

   if tank then
      local x, y = tank.base.physbody:getWorldCenter()
      x, y = x * M2PIX, y * M2PIX
      cam:lookAt(x, y)
   end

end

local function enableMovement()
   for _, tank in ipairs(tanks) do
      if tank ~= playerTank then
         tank:circleMove()
      end
   end
end

local function spawnHangar(pos)
   local hangar = Hangar.new(pos)
   table.insert(hangars, hangar)
   return hangar
end


local function spawnTank(pos, dir)

   local ok, errmsg = pcall(function()
      if #tanks >= 1 then


      end
      table.insert(tanks, Tank.new(pos, dir))
      print("Tank spawn at", pos.x, pos.y)
   end)
   if not ok then
      error("Could'not load. Please implement stub-tank. " .. errmsg)
   end
   return tanks[#tanks]

end


local function physInit()
   local canSleep = true
   physworld = love.physics.newWorld(0., 0., canSleep)
   physworld:setCallbacks(onBeginContact, onEndContact)
   physworld:setContactFilter(contactFilter)
end


function reset()
   print('reset')

   KeyConfig.clear()
   if physworld then
      physworld:destroy()
      print('physworld destroyed.')
      local object = physworld
      object:release()
      print('physworld object released.')
      physworld = nil
   end
   tanks = {}
   playerTank = nil
   bullets = {}
   baseBatch = Batch.new("tank_body_small.png")
   turretBatch = Batch.new("tank_tower.png")
   hangarBatch = Batch.new("hangar.png")
   physInit()



end

local function makeArmy()



















   local angle = rng:random() * 2 * math.pi
   spawnTank(vector.new(0, 0), fromPolar(angle))
   spawnTank(vector.new(
   diamondSquare.width * PIX2M,
   diamondSquare.height * PIX2M),
   fromPolar(angle))
   spawnTank(vector.new(0, -diamondSquare.height * PIX2M), fromPolar(angle))
   spawnTank(vector.new(-diamondSquare.width * PIX2M, 0), fromPolar(angle))
   spawnTank(vector.new(
   diamondSquare.width * PIX2M / 2, diamondSquare.height * PIX2M / 2),
   fromPolar(angle))

end

local navigatorIndex




local function drawNavigator()
   if not currentNavigator then
      currentNavigator = tanks[1]
   end
   imgui.Begin('навигатор', false, "AlwaysAutoResize")
   if imgui.Button('предыдущий') then
      navigatorIndex = findTank(currentNavigator)
      if navigatorIndex - 1 >= 1 then
         navigatorIndex = navigatorIndex - 1
      end
   end
   if imgui.Button('следующий') then
      navigatorIndex = findTank(currentNavigator)
      if navigatorIndex + 1 <= #tanks then
         navigatorIndex = navigatorIndex + 1
      end
   end
   if imgui.Button('включить движение') then
      enableMovement()
   end
   if imgui.Button('остановить движение') then

   end
   if imgui.Button('сделать армию') then
      makeArmy()
   end
   if imgui.Button('удалить все танки') then
      tanks = {}
      bullets = {}
      print("removed")
   end
   if imgui.Button('reset') then
      reset()
   end

   currentNavigator = tanks[navigatorIndex]

   moveCameraToTank(currentNavigator)
   imgui.End()
end

local brushFunction

local function setupBrush(brush)
   if brush == "Hangar" then
      brushFunction = function()
         local mx, my = cam:worldCoords(love.mouse.getPosition())
         local pos = vector.new(mx * PIX2M, my * PIX2M)
         spawnHangar(pos)
      end
   else
      brushFunction = nil
   end
end

local tmpColumns = {
   true,
   false,
   false,
}

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

local function drawui()

   imgui.StyleColorsLight()
   imgui.ShowDemoWindow()
   imgui.ShowUserGuide()

   drawParticlesEditor()
   drawNavigator()
   drawArenaPallete()


end

local function bindCameraControl()


   local cameraAnimationDuration = 0.2

   local Return = {}
   local function makeMoveFunction(xc, yc)

      return function(sc)
         if mode ~= "normal" then
            return false, sc
         end
         local reldx = cameraSettings.dx / cam.scale
         local reldy = cameraSettings.dy / cam.scale
         camTimer:during(cameraAnimationDuration,
         function(dt, time, delay)
            local dx = -reldx * (delay - time) * xc
            local dy = -reldy * (delay - time) * yc
            if delay - time > 0 then
               cam:move(dx * dt, dy * dt)
            end
         end,
         function()

         end)
         return true, sc

      end

   end

   local bindMode = "isdown"
   KeyConfig.bind(bindMode, { key = "left" }, makeMoveFunction(1., 0),
   i18n("mcleft"), "camleft")
   KeyConfig.bind(bindMode, { key = "right" }, makeMoveFunction(-1.0, 0.),
   i18n("mcright"), "camright")
   KeyConfig.bind(bindMode, { key = "up" }, makeMoveFunction(0., 1.),
   i18n("mcup"), "camup")
   KeyConfig.bind(bindMode, { key = "down" }, makeMoveFunction(0., -1.),
   i18n("mcdown"), "camdown")

   KeyConfig.bind("keypressed", { key = "c" },
   function(sc)
      if mode ~= "normal" then
         return false, sc
      end
      moveCameraToTank(playerTank)
      return false, sc
   end,
   i18n("cam2tank"), "cam2tank")

end

local function bindKonsole()

   KeyConfig.bind("keypressed", { key = "`" },
   function(sc)
      if mode ~= "normal" then
         return false, sc
      end
      linesbuf.show = not linesbuf.show
      return false, sc
   end)


end


local function bindEscape()

   KeyConfig.bind("keypressed", { key = "escape" },
   function(sc)
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
   end)


end

local function removeFirstColon(s)

   if not s then
      return nil
   end
   if string.sub(s, 1, 1) == ":" then
      return string.sub(s, 2, #s)
   else
      return s
   end

end









function printBody(body)

   print(">>>>>>>>")
   print("mass:", body:getMass())
   local x, y = body:getWorldCenter()
   x, y = x * M2PIX, y * M2PIX
   print("getWorldCenter() x, y in pixels", x, y)
   print("getAngle()", body:getAngle())
   print(">>>>>>>>")

end

local function processAttachedVariables()
   for _, v in pairs(attachedVarsList) do
      v()
   end
end

local function stats()
   linesbuf:pushi('Lua used %d Mb', (collectgarbage('count')) / 1024)
   local stat = love.graphics.getStats()
   linesbuf:pushi('drawcalls %d', stat.drawcalls)
   linesbuf:pushi('canvasswitches %d', stat.canvasswitches)

end

local function konsolePresent()

   gr.setColor({ 1, 1, 1, 1 })

   processAttachedVariables()

   if mode == "command" then
      cmdline = removeFirstColon(cmdline)
      if cmdline then



         local prompt = ">: "

         linesbuf:pushi(prompt .. cmdline)
      end
   end

   stats()


   linesbuf.color = { 0, 1, 1 }
   linesbuf:draw()


   if suggestList then


   end

end

function Background.new()

   local Background_mt = {
      __index = Background,
   }
   local self = setmetatable({}, Background_mt)


   self.img = gr.newImage(SCENE_PREFIX .. "/grass3.jpg")

   return self

end

function Background:present()

   local len = 50
   local imgw, imgh = (self.img):getDimensions()
   local sx, sy = 1, 1
   gr.setColor(1, 1, 1, 1)
   for i = 0, len - 1 do
      for j = 0, len - 1 do
         gr.draw(self.img,
         i * imgw * sx, j * imgh * sy, 0, sx, sy)
      end
   end

end

local isCameraCircleOut = false

local function drawCameraCircle()
   local circleColor1 = { 1, 0, 0, 1 }
   local circleColor2 = { 1, 1, 1, 1 }
   local linew = 8
   local w, h = gr.getDimensions()
   local oldcolor = { gr.getColor() }
   local olw = gr.getLineWidth()

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
   hangarBatch:prepare()

   push2drawlistTop(drawBullets)

   cam:attach()

   if drawTerrain and diamondSquare then
      love.graphics.setColor({ 1, 1, 1, 1 })
      love.graphics.circle('fill', 0, 0, 100)
      diamondSquare:present()
   end
   queryBoundingBox()

   presentDrawlistBottom()

   baseBatch:flush()
   turretBatch:flush()
   hangarBatch:flush()

   drawHits()

   presentDrawlistTop()

   cam:detach()

   drawCameraCircle()

   drawlistTop = {}
   drawlistBottom = {}

   changeKeyConfigListbackground()

   yield()
end

local function drawCameraAxixes()

   local color = { 0., 0.1, 0.97 }
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

   local ok, errmsg = resume(drawCoro)
   if not ok then
      error("drawCoro thread is end: " .. errmsg)
   end
   drawCameraAxixes()
   konsolePresent()





end

local function updateTanks()

   local alive = {}
   for _, tank in ipairs(tanks) do
      local t = tank:update()
      if t then
         table.insert(alive, t)
      else
         print('---------------')
      end
   end
   tanks = alive

end

posbuffer = {}
local maxBufLen = 5

local lastPosX, lastPosY




local function moveCamera()
   if playerTank then



      local tankx, tanky = playerTank.base.physbody:getWorldCenter()
      tankx, tanky = tankx * M2PIX, tanky * M2PIX





      table.insert(posbuffer, { tankx, tanky })
      if #posbuffer > maxBufLen then
         table.remove(posbuffer, 1)
      end

      if not lastPosX then
         lastPosX = tankx
      end

      if not lastPosY then
         lastPosY = tanky
      end


      local dx, dy = lastPosX - tankx, lastPosY - tanky
      lastPosX = tankx
      lastPosY = tanky
      cam:move(-dx, -dy)
   end
end

local function mainUpdate(dt)
   profi:start()
   camTimer:update(dt)
   if physworld then
      physworld:update(1 / 60)
   end
   linesbuf:update()
   updateTanks()
   updateBullets()
   updateHangars()
   updateHits(dt)
   updateCoroutines()
   arena:update()
   moveCamera()
   profi:stop()
end

local function backspaceCmdLine()

   local u8 = require("utf8")

   local byteoffset = u8.offset(cmdline, -1)
   if byteoffset then



      cmdline = string.sub(cmdline, 1, byteoffset - 1)
      if cursorpos - 1 >= 1 then
         cursorpos = cursorpos - 1
      end
   end

end

local function enterCommandMode()

   if linesbuf.show then
      print("command mode enabled.")
      mode = "command"
      cmdline = ""
      cursorpos = 1
      love.keyboard.setKeyRepeat(true)
      love.keyboard.setTextInput(true)

      local historydata = love.filesystem.read(historyfname)
      if historydata then

         cmdhistory = {}
         for s in historydata:gmatch("[^\r\n]+") do
            table.insert(cmdhistory, s)

         end

      end

   end

end

local function leaveCommandMode()

   print("command mode disabled.")
   mode = "normal"
   love.keyboard.setKeyRepeat(false)
   love.keyboard.setTextInput(false)
   cmdline = ""

end


function konsolePrint(...)

   for _, v in ipairs({ ... }) do
      if type(v) == "string" then
         linesbuf:push(0.5, tostring(v))
      else
         colprint("konsolePrint warning")
      end
   end

end

function attach(varname)
   if type(varname) == "string" then
      attachedVarsList[varname] = function()
         local ok, errmsg = pcall(function()
            local l = (_G)[varname]
            local output = tabular.show2(l)
            if output then


               linesbuf:pushi(output)
               linesbuf:pushi(string.format("%s", varname))




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

function detach(varname)
   if type(varname) == "string" then
      attachedVarsList[varname] = nil
   end
end

local function evalCommand()



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




   cmdline = trim(cmdline)
   local func, loaderrmsg = load(preload .. cmdline)
   local time = 2


   if not func then
      linesbuf:push(time, "load() errmsg: " .. loaderrmsg)
      print("load() errmsg:|" .. loaderrmsg .. "|")
   else
      local ok, pcallerrmsg = pcall(function()
         func()
      end)
      if not ok then
         linesbuf:push(time, "pcall() errmsg: " .. pcallerrmsg)
         print("pcall() errmsg:|" .. pcallerrmsg .. "|")
      end
   end

   if #cmdline ~= 0 then
      table.insert(cmdhistory, cmdline)
      love.filesystem.append(historyfname, cmdline .. "\n")
   end
   suggestList = nil

end

local cmdhistoryIndex = 0

local function setPreviousCommand()

   if #cmdhistory ~= 0 then
      if cmdhistoryIndex - 1 < 1 then
         cmdhistoryIndex = #cmdhistory
      else
         cmdhistoryIndex = cmdhistoryIndex - 1
      end
      cmdline = cmdhistory[cmdhistoryIndex]
      cursorpos = #cmdline + 1
   end

end

local function setNextCommand()

   if #cmdhistory ~= 0 then
      if cmdhistoryIndex + 1 > #cmdhistory then
         cmdhistoryIndex = 1
      else
         cmdhistoryIndex = cmdhistoryIndex + 1
      end
      cmdline = cmdhistory[cmdhistoryIndex]
      cursorpos = #cmdline + 1
   end

end

local function suggestCompletion()

   if not suggestList then
      suggestList = List.new()
   end

   for k, v in pairs(_G) do
      suggestList:add(string.format("%s: %s", tostring(k), tostring(v)))
   end

end

local function processCommandModeKeys(key)

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

end

local function keypressed(key)

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

end

cameraKeyConfigIds = {}

local function bindCameraZoomKeys()

   local ids = {
      KeyConfig.bind(
      "isdown",
      { key = "z" },
      function(sc)
         if mode ~= "normal" then
            return false, sc
         end
         if cam.scale < camZoomHigher then
            cam:zoom(1. + zoomSpeed)
         end
         return false, sc
      end,
      "zoom camera in",
      "zoomin"),

      KeyConfig.bind(
      "isdown",
      { key = "x" },
      function(sc)
         if mode ~= "normal" then
            return false, sc
         end
         if cam.scale > camZoomLower then
            cam:zoom(1.0 - zoomSpeed)
         end
         return false, sc
      end,
      "zoom camera out",
      "zoomout"),

   }
   cameraKeyConfigIds = {}
   for _, v in ipairs(ids) do
      table.insert(cameraKeyConfigIds, v)
   end
   print('bindCameraZoomKeys')

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
   function(sc)
      local isfs = love.window.getFullscreen()
      diamondSquare:draw2canvas()
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

function Logo.new()

   local Logo_mt = {
      __index = Logo,
   }

   local self = setmetatable({}, Logo_mt)
   local fname = SCENE_PREFIX .. "/t80_background_2.png"
   self.image = love.graphics.newImage(fname)
   local tex = self.image
   local windowscale = 0.7
   self.imgw, self.imgh = ceil(tex:getWidth()), ceil(tex:getHeight())
   local newdw, newdh = self.imgw * windowscale, self.imgh * windowscale
   DEFAULT_W, DEFAULT_H = ceil(newdw), ceil(newdh)
   self.sx, self.sy = DEFAULT_W / self.imgw, DEFAULT_H / self.imgh
   setWindowMode()
   return self

end

function Logo:present()

   gr.setColor({ 1, 1, 1, 1 })

   love.graphics.draw(self.image, 0, 0, 0., self.sx, self.sy)
   yield()

end

local function createDrawCoroutine()
   return coroutine.create(function()
      while true do

         while showLogo == true do
            logo:present()
         end

         while showLogo == false do
            mainPresent()
         end
      end
   end)
end




function drawMiniMap()

end

local function mainInit()

   metrics.init()
   setWindowMode()




   loadLocales()
   physInit()

   logo = Logo.new()
   cam = require('camera').new()
   print("camera created x, y, scale, rot",
   cam.x, cam.y, cam.scale, cam.rot)

   bindCameraZoomKeys()
   bindCameraControl()
   bindFullscreenSwitcher()
   bindEscape()
   bindKonsole()
   bindTerrainControlKeys()
   bindDeveloperKeys()

   drawCoro = createDrawCoroutine()

   background = Background.new()


   initParticles(particlesfname)


   arena = Arena.new("arena.lua")
   terrain()
   makeArmy()
   local corners = getTerrainCorners()
   if corners then
      for _, c in ipairs(corners) do
         spawnHangar(c)
      end
   end

   local herostartpos = vector.new(0, 0)
   local alpha = rng:random() * math.pi
   playerTank = spawnTank(herostartpos, fromPolar(alpha))

   bindPlayerTankKeys()






   cameraZoneR = H / 2

end

local function quit()

   profi:writeReport("t80-profiling.txt")
   print('profi report was writtent')
   metrics.quit()
   unbindPlayerTankKeys()
   tanks = {}
   writeParticles(particlesfname)

end

local function mousemoved(x, y, dx, dy)
   metrics.mousemoved(x, y, dx, dy)
   if mode == 'editor' then
      arena:mousemoved(x, y, dx, dy)
   end
end

local function wheelmoved(x, y)
   metrics.wheelmoved(x, y)
end




local function mousepressed(x, y, btn)

   metrics.mousepressed(x, y, btn)
   if mode == 'normal' then
      if btn == 1 then
         if playerTank then
            playerTank:fire()
         end
      end





   elseif mode == 'editor' then
      arena:mousepressed(x, y, btn)
      if btn == 1 and brushFunction then
         brushFunction(x, y)
      end
   end

end

local function resize(neww, newh)

   metrics.resize(neww, newh)
   print("tanks window resized to w, h", neww, newh)
   W, H = neww, newh
   cameraZoneR = newh / 2

   DEFAULT_W, DEFAULT_H = neww, newh

end

local function textinput(text)

   metrics.textinput(text)
   if mode == "command" then


      local sub = string.sub
      cmdline = sub(cmdline, 1, cursorpos - 1) ..
      text .. sub(cmdline, cursorpos, #cmdline)
      cursorpos = cursorpos + 1
   end

end

return {

   init = mainInit,
   quit = quit,
   draw = draw,
   drawui = drawui,
   update = mainUpdate,
   keypressed = keypressed,
   mousepressed = mousepressed,
   resize = resize,
   textinput = textinput,
   mousemoved = mousemoved,
   wheelmoved = wheelmoved,

}
