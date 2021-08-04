local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local load = _tl_compat and _tl_compat.load or load; local math = _tl_compat and _tl_compat.math or math; local pairs = _tl_compat and _tl_compat.pairs or pairs; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table


SCENE_PREFIX = "scenes/t80u"

love.filesystem.setRequirePath("?.lua;?/init.lua;" .. SCENE_PREFIX .. "/?.lua")


require("tabular")
require("love")
require("common")
require("keyconfig")
require("camera")
require("vector")
require("Timer")
require("imgui")

local List = require("list")
i18n = require("i18n")
local metrics = require("metrics")
vec2 = require("vector")
vecl = require("vector-light")
inspect = require("inspect")
tabular = require("tabular")


local gr = love.graphics
local lp = love.physics
local Shortcut = KeyConfig.Shortcut

local Mode = {}




local DrawNode = {}





local Background = {}









local Turret = {}


















local Bullet = {}























local basesMesh
local basesMeshVerts
local baseImage



local baseMeshIndex = 0

local baseMeshCount = 0


local Base = {}





















local Tank = {}































local Logo = {}













local CameraSettings = {}







DEBUG_BASE = false
DEBUG_TANK = false
DEBUG_TANK_MOVEMENT = false
DEBUG_TURRET = true
DEBUG_CAMERA = false
DEBUG_LOGO = false
DEBUG_BULLET = true





DEBUG_DRAW_THREAD = false
DEBUG_TEXCOORDS = false
DEBUG_PHYSICS = false


cmd_drawBodyStat = true
cmd_drawCameraAxixes = false

local debugStack = {}





DEFAULT_W, DEFAULT_H = 1024, 768

W, H = love.graphics.getDimensions()


M2PIX = 10

PIX2M = 1 / 10



local bulletMask = 1

tankForceScale = 1


local historyfname = "cmdhistory.txt"
local linesbuf = require("kons").new(SCENE_PREFIX .. "/VeraMono.ttf", 20)
local mode = "normal"
local cmdline = ""
local cmdhistory = {}
suggestList = List.new()
attachedVarsList = {}


local drawlist = {}

local camTimer = require("Timer").new()
local drawCoro = nil
showLogo = true
playerTankKeyconfigIds = {}
angularImpulseScale = 5
rot = math.pi / 4
camZoomLower, camZoomHigher = 0.075, 3.5
local meshBufferSize = 512
local cameraSettings = {

   dx = 2000, dy = 2000,
}



tanks = {}







bullets = {}

local bulletRadius = 4
local bulletColor = { 1, 1, 1, 1 }

bulletLifetime = 1
tankCounter = 0
rng = love.math.newRandomGenerator()


local cameraZoneR


function disableDEBUG()

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

end

function enableDEBUG()

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

end

function pushDEBUG()

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

end

function popDEBUG()

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

end

local function drawArrow(
   fromx, fromy, tox, toy,
   color)


   local angle = math.pi / 11
   local arrowDiv = 20

   color = color or { 1, 1, 1, 1 }
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


   gr.line(tox, toy, tox - lx, toy - ly)

   gr.line(tox, toy, tox - rx, toy - ry)

   gr.line(fromx, fromy, tox, toy)

   gr.setLineWidth(oldlinew)
end

local function drawBullets()

   for _, b in ipairs(bullets) do
      local px, py = b.body:getWorldCenter()
      px, py = px * M2PIX, py * M2PIX
      gr.setColor(bulletColor)
      if DEBUG_BULLET then

      end
      gr.circle("fill", px, py, bulletRadius)
   end

end

local function updateBullets()

   local alive = {}
   local now = love.timer.getTime()
   for _, v in ipairs(bullets) do
      local diff = now - v.timestamp
      if diff > bulletLifetime then

      end
      table.insert(alive, v)
   end
   bullets = alive

end


local function spawnBullet(px, py, dirx, diry)

   print("spawnBullet")
   local bullet = {}
   bullet.body = love.physics.newBody(pworld, px, py, "kinematic")

   bullet.timestamp = love.timer.getTime()

   local shape = love.physics.newCircleShape(0, 0, bulletRadius * PIX2M)
   local fixture = love.physics.newFixture(bullet.body, shape)

   fixture:setMask(bulletMask)
   if dirx and diry then
      print("bullet.body:applyLinearImpulse", dirx, diry)
      bullet.body:applyLinearImpulse(dirx, diry)
   end
   table.insert(bullets, bullet)

end

function Turret:fire()

   if DEBUG_TURRET then
      print("Turret:fire()")
   end
   local px, py = self.tank.physbody:getWorldCenter()
   local scale = 3
   print("pbody", px, py)
   spawnBullet(px, py, self.dir.x * scale, self.dir.y * scale)

end

local function presentDrawlist()

   for _, v in ipairs(drawlist) do
      if v.self then
         v.f(v.self)
      else
         v.f()
      end
   end

end

function push2drawlist(f, self)

   if not f then
      error("Draw could'not be nil.")
   end
   if type(f) ~= "function" then
      error("Draw function is not a function. It is a .. " .. type(f))
   end
   table.insert(drawlist, { f = f, self = self })

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
   local imp = -angularImpulseScale * rot
   print("mass", self.physbody:getMass())
   if DEBUG_PHYSICS then
      print("Tank " .. self.id .. " applyTorque", imp)
   end
   self.physbody:applyTorque(imp)

end

function Tank:right()

   if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
      print("Tank:right")
   end
   local imp = angularImpulseScale * rot
   print("mass", self.physbody:getMass())
   if DEBUG_PHYSICS then
      print("Tank " .. self.id .. " applyTorque", imp)
   end
   self.physbody:applyTorque(imp)

end

function Tank:forward()

   if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
      print("Tank:forward")
   end
   local x, y = self.dir.x * tankForceScale, self.dir.y * tankForceScale
   if DEBUG_PHYSICS then
      print("Tank " .. self.id .. " applyForce x, y", x, y)
   end
   self.physbody:applyForce(x, y)


end

function Tank:backward()

   if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
      print("Tank:backward")
   end



   local x, y = self.dir.x * tankForceScale, self.dir.y * tankForceScale
   print('applied', x, y)
   self.physbody:applyForce(x, y)


end



function Tank.new(pos, dir)

   local Tank_mt = {
      __index = Tank,
   }

   if DEBUG_TANK then
      print('Start of Tank creating..')
   end
   local self = setmetatable({}, Tank_mt)

   tankCounter = tankCounter + 1

   self.physbody = love.physics.newBody(pworld, 0, 0, "dynamic")
   self.physbody:setUserData(self)

   if not dir then
      dir = vector.new(0, -1)
   end


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

end

local function drawBodyStat(body)

   local color = { 0, 0, 0, 1 }
   local radius = 10
   local x, y = body:getWorldCenter()
   x, y = x * M2PIX, y * M2PIX


   gr.setColor({ 0.1, 1, 0.1 })
   gr.circle("fill", x, y, radius)


   gr.setColor(color)
   gr.circle("fill", x, y, 2)

   local vx, vy = body:getLinearVelocity()
   local scale = 7.

   drawArrow(x, y, x + vx * scale, y + vy * scale, color)

end

function Tank:drawDirectionVector()

   if self.dir then
      local x, y = self.physbody:getWorldCenter()
      local scale = 100
      local color = { 0., 0.05, 0.99, 1 }
      x, y = x * M2PIX, y * M2PIX
      drawArrow(x, y, x + self.dir.x * scale, y + self.dir.y * scale, color)
   end

end

function Tank:resetVelocities()

   if self.physbody then
      self.physbody:setAngularVelocity(0)
      self.physbody:setLinearVelocity(0, 0)
   end

end

function Tank:updateDir()

   local unit = 1

   self.dir = vec2.fromPolar(self.physbody:getAngle() + math.pi / 2, unit)

end

function Tank:update()




   self:updateDir()

   if self.turret then
      self.turret:update()
   end

   return self

end

function Tank:present()

   if self.base and self.base.present then

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

end

function Turret.new(t)

   if DEBUG_TURRET then
      print("Start of Turret creating..")
   end
   if not t then
      error("Could'not create Turret without Tank object")
   end

   local Turret_mt = {
      __index = Turret,
   }

   local self = setmetatable({}, Turret_mt)
   self.tank = t
   self.image = love.graphics.newImage(SCENE_PREFIX .. "/tank_tower.png")
   self.physbody = t.physbody

   if DEBUG_TURRET then
      print("self.tank", self.tank)
      print("self.pbody", self.physbody)
      print("self.img", self.image)
   end

   local w, _ = (self.image):getDimensions()
   local r = w / 2
   local px, py = self.tank.physbody:getPosition()
   local shape = love.physics.newCircleShape(t.pos.x, t.pos.y, r * PIX2M)
   self.fixture = love.physics.newFixture(self.physbody, shape)


   if DEBUG_TURRET then
      print("circle shape created x, y, r", px, py)
   end

   return self

end

local __ONCE__ = false

local function drawFixture(f, color)

   local defaultcolor = { 1, 0.5, 0, 0.5 }
   if not color then
      color = defaultcolor
   end
   local shape = f:getShape()
   local shapeType = shape:getType()
   local body = f:getBody()
   if shapeType == 'circle' then
      local cShape = shape
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
      local pShape = shape
      local points = { pShape:getPoints() }
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


function Turret:rotateToMouse()

   local mx, my = love.mouse.getPosition()
   mx, my = cam:worldCoords(mx, my)
   mx, my = mx * PIX2M, my * PIX2M

   local x, y = self.physbody:getWorldCenter()
   local d = vec2.new(x - mx, y - my)
   self.dir = d:normalizeInplace()
   local a, _ = d:toPolar()















   self.angle = -a

end

function Turret:update()


   if playerTank and self.tank == playerTank then
      self:rotateToMouse()
   end

end

function Turret:present()

   if not self.fixture then
      error("Turret:present() - fixture is nil")
   end

   local imgw, imgh = (self.image):getDimensions()
   local r, sx, sy, ox, oy = 0., 1., 1., 0, 0

   local shape = self.fixture:getShape()
   local cshape = self.fixture:getShape()

   if shape:getType() ~= "circle" then
      error("Only circle shape allowed.")
   end
   local px, py = cshape:getPoint()
   px, py = self.physbody:getWorldPoints(px, py)
   px, py = px * M2PIX, py * M2PIX
   r = cshape:getRadius() * M2PIX

   if DEBUG_PHYSICS then



   end

   gr.setColor({ 1, 1, 1, 1 })
   love.graphics.draw(
   self.image,
   px, py,
   self.angle,
   sx, sy,
   ox + imgw / 2, oy + imgh / 2)














end

























function Base.new(t)

   local Base_mt = {
      __index = Base,
   }

   if DEBUG_BASE then
      print("BaseP.new()")
   end
   if not t then
      error("Could'not create BaseP without Tank object")
   end

   local self = setmetatable({}, Base_mt)
   self.tank = t



   self.rectXY = { 86, 72 }
   self.rectWH = { 84, 111 }

   self.physbody = t.physbody

   if DEBUG_BASE then
      print("self.tank", self.tank)
      print("self.pbody", self.physbody)
   end

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

   local shape = love.physics.newPolygonShape(vertices)
   self.fixture = love.physics.newFixture(self.physbody, shape)

   self.polyshape = shape
   if DEBUG_TURRET then
      print("polygon shape created x, y, r", px, py)
   end

   return self

end




function Base:present()

   local shape = self.fixture:getShape()
   if shape:getType() ~= "polygon" then
      error("Tank BaseP shape should be polygon.")
   end

   if DEBUG_PHYSICS then
      drawFixture(self.fixture, { 0, 0, 0, 1 })
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


   basesMeshVerts[baseMeshIndex + 1][1] = x1
   basesMeshVerts[baseMeshIndex + 1][2] = y1

   basesMeshVerts[baseMeshIndex + 2][1] = x2
   basesMeshVerts[baseMeshIndex + 2][2] = y2

   basesMeshVerts[baseMeshIndex + 3][1] = x4
   basesMeshVerts[baseMeshIndex + 3][2] = y4


   basesMeshVerts[baseMeshIndex + 5][1] = x2
   basesMeshVerts[baseMeshIndex + 5][2] = y2

   basesMeshVerts[baseMeshIndex + 6][1] = x3
   basesMeshVerts[baseMeshIndex + 6][2] = y3

   basesMeshVerts[baseMeshIndex + 4][1] = x4
   basesMeshVerts[baseMeshIndex + 4][2] = y4


   local rx, ry = self.rectXY[1], self.rectXY[2]
   local rw, rh = self.rectWH[1], self.rectWH[2]

   local imgw, imgh = (baseImage):getDimensions()

   local unitw, unith = rw / imgw, rh / imgh

   local x_, y_ = rx / imgw, ry / imgh


   basesMeshVerts[baseMeshIndex + 4][3] = x_
   basesMeshVerts[baseMeshIndex + 4][4] = y_
   basesMeshVerts[baseMeshIndex + 5][3] = x_ + unitw
   basesMeshVerts[baseMeshIndex + 5][4] = y_ + unith
   basesMeshVerts[baseMeshIndex + 6][3] = x_
   basesMeshVerts[baseMeshIndex + 6][4] = y_ + unith


   basesMeshVerts[baseMeshIndex + 3][3] = x_
   basesMeshVerts[baseMeshIndex + 3][4] = y_
   basesMeshVerts[baseMeshIndex + 1][3] = x_ + unitw
   basesMeshVerts[baseMeshIndex + 1][4] = y_
   basesMeshVerts[baseMeshIndex + 2][3] = x_ + unitw
   basesMeshVerts[baseMeshIndex + 2][4] = y_ + unith















   baseMeshIndex = baseMeshIndex + 6
   baseMeshCount = baseMeshCount + 1

   basesMesh:setVertices(basesMeshVerts)
   basesMesh:setDrawRange(1, baseMeshIndex)




end

local function onBeginContact(
   _,
   _,
   _)










































end

local function onEndContact(
   _,
   _,
   _)




























end

local function onQueryBoundingBox(fixture)

   local body = fixture:getBody()
   local selfPtr = body:getUserData()

   if selfPtr and selfPtr.present then
      selfPtr:present()
   end
   return true

end

local function queryBoundingBox()

   if cam then
      local tlx, tly = cam:worldCoords(0, 0)
      local brx, bry = cam:worldCoords(gr.getDimensions())
      brx, bry = brx + W, bry + H

      if DEBUG_PHYSICS then
         push2drawlist(function()
            local oldwidth = gr.getLineWidth()
            local lwidth = 4
            gr.setLineWidth(lwidth)
            gr.setColor({ 0., 0., 1. })
            gr.rectangle("line", tlx, tly, brx - tlx, bry - tly)
            gr.setLineWidth(oldwidth)
         end)
      end

      pworld:queryBoundingBox(
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

local function drawui()

   imgui.StyleColorsLight()
   imgui.ShowDemoWindow()
   imgui.ShowUserGuide()

end

local function moveCameraToPlayer()

   if playerTank then
      local x, y = playerTank.physbody:getWorldCenter()
      x, y = x * M2PIX, y * M2PIX
      cam:lookAt(x, y)
   end

end

local function bindCameraControl()


   local cameraAnimationDuration = 0.2

   local function makeMoveFunction(xc, yc)

      return function(sc)
         if mode ~= "normal" then
            return false, sc
         end
         local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
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
      moveCameraToPlayer()
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

   KeyConfig.bind("keypressed", { key = "escape" }, function(sc)
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
         gr.draw(self.img, i * imgw * sx, j * imgh * sy, 0, sx, sy)
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

local colorWhite = { 1, 1, 1, 1 }

local function presentBasesMesh()
   gr.setColor(colorWhite)
   gr.draw(basesMesh, 0, 0)
   baseMeshIndex = 0
   baseMeshCount = 0
end

local function mainPresent()
   baseMeshIndex = 0
   push2drawlist(Background.present, background)
   push2drawlist(queryBoundingBox)
   push2drawlist(drawBullets)
   push2drawlist(presentBasesMesh)

   cam:attach()
   presentDrawlist()
   cam:detach()

   drawCameraCircle()

   drawlist = {}

   changeKeyConfigListbackground()

   coroutine.yield()
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

   local ok, errmsg = coroutine.resume(drawCoro)
   if not ok then
      error("drawCoro thread is end: " .. errmsg)
   end
   if cmd_drawCameraAxixes then
      drawCameraAxixes()
   end
   konsolePresent()





end

local function updateTanks()

   local alive = {}
   for _, v in ipairs(tanks) do
      local t = v:update()
      if t then
         table.insert(alive, t)
      end
   end
   tanks = alive

end

local function moveCamera()




   if playerTank then
      local w, h = gr.getDimensions()
      local centerx, centery = w / 2, h / 2

      local tankx, tanky = playerTank.physbody:getWorldCenter()

      local diff = vecl.dist(centerx, centery, tankx, tanky)

   end
end

local function update(dt)
   camTimer:update(dt)
   pworld:update(1 / 60)
   linesbuf:update()
   updateTanks()
   updateBullets()
   moveCamera()
end

local function backspaceCmdLine()

   local u8 = require("utf8")

   local byteoffset = u8.offset(cmdline, -1)
   if byteoffset then


      cmdline = string.sub(cmdline, 1, byteoffset - 1)
   end

end

local function enterCommandMode()

   if linesbuf.show then
      print("command mode enabled.")
      mode = "command"
      cmdline = ""
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
         linesbuf:pushi(string.format("%s", tabular.show((_G)[varname])))
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

   print('setPreviousCommand')

   if #cmdhistory ~= 0 then
      if cmdhistoryIndex - 1 < 1 then
         cmdhistoryIndex = #cmdhistory
      else
         cmdhistoryIndex = cmdhistoryIndex - 1
      end
      cmdline = cmdhistory[cmdhistoryIndex]
      print("cmdline", cmdline)
   end

end

local function setNextCommand()

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


local function spawnTank(pos, dir)

   local res
   local ok, errmsg = pcall(function()
      if #tanks >= 1 then


      end
      local t = Tank.new(pos, dir)
      table.insert(tanks, t)

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

end

cameraKeyConfigIds = {}

local function bindCameraZoomKeys()

   local zoomSpeed = 0.01

   local ids = {
      KeyConfig.bind(
      "isdown",
      { key = "z" },
      function(sc)
         print('zoom in')



         print('zoom in')
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
         print('zoom out')



         print('zoom out')
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

   if DEBUG_LOGO then
      print("Logo.new()")
   end
   local self = setmetatable({}, Logo_mt)
   local fname = SCENE_PREFIX .. "/t80_background_2.png"
   self.image = love.graphics.newImage(fname)
   local tex = self.image
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

   gr.setColor({ 1, 1, 1, 1 })

   love.graphics.draw(self.image, 0, 0, 0., self.sx, self.sy)
   coroutine.yield()

end

local function createDrawCoroutine()
   return coroutine.create(function()
      if DEBUG_DRAW_THREAD then
         print("drawCoro started")
      end
      while true do

         while showLogo == true do
            logo:present()
         end

         while showLogo == false do
            mainPresent()
         end
      end
      if DEBUG_DRAW_THREAD then
         print("drawCoro finished")
      end
   end)
end































local function makeArmy(x, y)

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

end

local function initBaseMeshVerts()
   basesMeshVerts = {}
   for _ = 1, 6 * meshBufferSize do
      table.insert(basesMeshVerts, {
         0, 0,
         0, 0,
         1, 1, 1, 1,
      })
   end
end



local function initBasesMesh()
   basesMesh = gr.newMesh(meshBufferSize * 6, "triangles", "dynamic")
   initBaseMeshVerts()
   basesMesh:setVertices(basesMeshVerts)
   baseImage = love.graphics.newImage(SCENE_PREFIX .. "/tank_body_small.png")
   basesMesh:setTexture(baseImage)
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


   pworld:setCallbacks(onBeginContact, onEndContact)

   logo = Logo.new()
   cam = require('camera').new()
   if DEBUG_CAMERA then
      print("camera created x, y, scale, rot", cam.x, cam.y, cam.scale, cam.rot)
   end

   bindCameraZoomKeys()
   bindCameraControl()
   bindFullscreenSwitcher()

   bindEscape()
   bindKonsole()

   initBasesMesh()
   drawCoro = createDrawCoroutine()

   background = Background.new()

   makeArmy()
   makeArmy()
   makeArmy()
   makeArmy()
   makeArmy()
   makeArmy()
   makeArmy()
   makeArmy(0, 500)
   makeArmy(500, 0)
   makeArmy(500, 500)

   enableDEBUG()

   cameraZoneR = H / 2

end

local function quit()

   metrics.quit()
   unbindPlayerTankKeys()
   tanks = {}

end

local function mousemoved(x, y, dx, dy)
   metrics.mousemoved(x, y, dx, dy)
end

local function wheelmoved(x, y)
   metrics.wheelmoved(x, y)
end

local function mousepressed(x, y, btn)

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

end

local function resize(neww, newh)

   metrics.resize(neww, newh)
   if DEBUG_CAMERA then
      print("tanks window resized to w, h", neww, newh)
   end
   W, H = neww, newh
   cameraZoneR = newh / 2

   DEFAULT_W, DEFAULT_H = neww, newh

end

local function textinput(text)

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
   wheelmoved = wheelmoved,

}
