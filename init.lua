local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local load = _tl_compat and _tl_compat.load or load; local math = _tl_compat and _tl_compat.math or math; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table


local Mode = {}




SCENE_PREFIX = "scenes/t80u"

love.filesystem.setRequirePath("?.lua;?/init.lua;" .. SCENE_PREFIX .. "/?.lua")

local List = require("list")
local metrics = require("metrics")
require("love")
require("common")
require("keyconfig")
require("camera")
require("vector")
require("Timer")
require("imgui")
local i18n = require("i18n")
local inspect = require("inspect")
local vec2 = require("vector")


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


DEFAULT_W, DEFAULT_H = 1024, 768
W, H = love.graphics.getDimensions()
cmd_drawBodyStat = true
cmd_drawCameraAxixes = false



M2PIX = 10

PIX2M = 1 / 10



local bulletMask = 1

local forceScale = 100


local camTimer = require("Timer").new()

local DrawNode = {}




local drawlist = {}
local gr = love.graphics
local lp = love.physics

local linesbuf = require("kons").new(SCENE_PREFIX .. "/VeraMono.ttf", 20)
local mode = "normal"
local cmdline, prevcmdline = "", ""
local cmdhistory = {}

local drawCoro = nil
local showLogo = true
local playerTankKeyconfigIds = {}
local Shortcut = KeyConfig.Shortcut

local angularImpulseScale = 5
local rot = math.pi / 4
local zoomLower, zoomHigher = 0.075, 3.5

local Turret = {}

















local Bullet = {}



















local Turret_mt = {
   __index = Turret,
}


local Base = {}




















local Base_mt = {
   __index = Base,
}

local Tank = {}






























local Tank_mt = {
   __index = Tank,
}

local Logo = {}













local Logo_mt = {
   __index = Logo,
}

local CameraSettings = {}






local cameraSettings = {

   dx = 100, dy = 100,
}




tanks = {}







bullets = {}


local bulletRadius = 4
local bulletColor = { 1, 1, 1, 1 }

local bulletLifetime = 1

local vecl = require("vector-light")

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

   gr.setColor(color)


   gr.line(tox, toy, tox - lx, toy - ly)

   gr.line(tox, toy, tox - rx, toy - ry)

   gr.line(fromx, fromy, tox, toy)
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
   local px, py = self.tank.pbody:getWorldCenter()
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

local function push2drawlist(f, self)
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
   if DEBUG_PHYSICS then

   end
   self.pbody:applyAngularImpulse(imp)
end

function Tank:right()
   if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
      print("Tank:right")
   end
   local imp = angularImpulseScale * rot
   if DEBUG_PHYSICS then

   end
   self.pbody:applyAngularImpulse(imp)
end

function Tank:forward()
   if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
      print("Tank:forward")
   end



   local x, y = self.dir.x * forceScale, self.dir.y * forceScale
   self.pbody:applyForce(x, y)
end

function Tank:backward()
   if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
      print("Tank:backward")
   end



   local x, y = self.dir.x * forceScale, self.dir.y * forceScale
   print('applied', x, y)
   self.pbody:applyForce(-x, -y)
end

local tankCounter = 0



function Tank.new(pos, dir)
   if DEBUG_TANK then
      print('Start of Tank creating..')
   end
   local self = setmetatable({}, Tank_mt)

   tankCounter = tankCounter + 1

   self.pbody = love.physics.newBody(pworld, 0, 0, "dynamic")
   self.pbody:setUserData(self)

   if not dir then
      dir = vector.new(0, -1)
   end


   self.id = tankCounter
   self.dir = dir:clone()
   self.pos = pos:clone()
   self.turret = Turret.new(self)
   self.base = Base.new(self)

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
      local x, y = self.pbody:getWorldCenter()
      local scale = 100
      local color = { 0., 0.05, 0.99, 1 }
      x, y = x * M2PIX, y * M2PIX
      drawArrow(x, y, x + self.dir.x * scale, y + self.dir.y * scale, color)
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

   self.dir = vec2.fromPolar(self.pbody:getAngle() + math.pi / 2, unit)
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

function Turret.new(t)

   if DEBUG_TURRET then
      print("Start of Turret creating..")
   end
   if not t then
      error("Could'not create Turret without Tank object")
   end

   local self = setmetatable({}, Turret_mt)
   self.tank = t
   self.img = love.graphics.newImage(SCENE_PREFIX .. "/tank_tower.png")
   self.pbody = t.pbody

   if DEBUG_TURRET then
      print("self.tank", self.tank)
      print("self.pbody", self.pbody)
      print("self.img", self.img)
   end

   local w, _ = (self.img):getDimensions()
   local r = w / 2
   local px, py = self.tank.pbody:getPosition()
   local shape = love.physics.newCircleShape(t.pos.x, t.pos.y, r * PIX2M)
   self.f = love.physics.newFixture(self.pbody, shape)


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

   local x, y = self.pbody:getWorldCenter()
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

   if not self.f then
      error("Turret:present() - fixture is nil")
   end

   local imgw, imgh = (self.img):getDimensions()
   local r, sx, sy, ox, oy = 0., 1., 1., 0, 0

   local shape = self.f:getShape()
   local cshape = self.f:getShape()

   if shape:getType() ~= "circle" then
      error("Only circle shape allowed.")
   end
   local px, py = cshape:getPoint()
   px, py = self.pbody:getWorldPoints(px, py)
   px, py = px * M2PIX, py * M2PIX
   r = cshape:getRadius() * M2PIX

   if DEBUG_PHYSICS then



   end

   gr.setColor({ 1, 1, 1, 1 })
   love.graphics.draw(
   self.img,
   px, py,
   self.angle,
   sx, sy,
   ox + imgw / 2, oy + imgh / 2)














end

function Base:present()

   local shape = self.f:getShape()
   if shape:getType() ~= "polygon" then
      error("Tank BaseP shape should be polygon.")
   end

   if DEBUG_PHYSICS then
      drawFixture(self.f, { 0, 0, 0, 1 })
   end

   gr.setColor({ 1, 1, 1, 1 })
   self:updateMeshVerts()
   gr.draw(self.mesh, 0, 0)






end

function Base.new(t)

   if DEBUG_BASE then
      print("BaseP.new()")
   end
   if not t then
      error("Could'not create BaseP without Tank object")
   end

   local self = setmetatable({}, Base_mt)
   self.tank = t
   self.img = love.graphics.newImage(SCENE_PREFIX .. "/tank_body_small.png")



   local rectXY = { 86, 72 }
   local rectWH = { 84, 111 }

   self.pbody = t.pbody

   if DEBUG_BASE then
      print("self.tank", self.tank)
      print("self.pbody", self.pbody)
      print("self.img", self.img)
   end

   local px, py = t.pos.x, t.pos.y


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
   self.f = love.physics.newFixture(self.pbody, shape)

   self.pshape = shape
   if DEBUG_TURRET then
      print("polygon shape created x, y, r", px, py)
   end

   self:initMeshVerts()
   self.mesh = love.graphics.newMesh(self.meshVerts,
   "triangles", "dynamic")
   self:updateMeshVerts()
   self.mesh:setTexture(self.img)
   self:updateMeshTexCoords(rectXY[1], rectXY[2], rectWH[1], rectWH[2])

   if not self.mesh then
      error("Could'not create Mesh")
   end

   return self

end

function Base:updateMeshTexCoords(x, y, w, h)

   print("updateMeshTexCoords", x, y, w, h)

   local imgw, imgh = (self.img):getDimensions()

   local unitw, unith = w / imgw, h / imgh

   local x_, y_ = x / imgw, y / imgh


   self.meshVerts[4][3] = x_
   self.meshVerts[4][4] = y_
   self.meshVerts[5][3] = x_ + unitw
   self.meshVerts[5][4] = y_ + unith
   self.meshVerts[6][3] = x_
   self.meshVerts[6][4] = y_ + unith


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
      self.meshVerts[6][4])

      print(string.format("BaseP.self.meshVerts texture coordinates: " .. msg))
   end

end

function Base:initMeshVerts()
   self.meshVerts = {}
   for _ = 1, 6 do
      table.insert(self.meshVerts, {
         0, 0,
         0, 0,
         1, 1, 1, 1,
      })
   end
end




function Base:updateMeshVerts()

   self.mesh:setVertices(self.meshVerts)

   local body = self.f:getBody()


   local x1, y1, x2, y2, x3, y3, x4, y4 = self.pshape:getPoints()
   x1, y1 = body:getWorldPoints(x1, y1)
   x2, y2 = body:getWorldPoints(x2, y2)
   x3, y3 = body:getWorldPoints(x3, y3)
   x4, y4 = body:getWorldPoints(x4, y4)

   x1, y1 = M2PIX * x1, M2PIX * y1
   x2, y2 = M2PIX * x2, M2PIX * y2
   x3, y3 = M2PIX * x3, M2PIX * y3
   x4, y4 = M2PIX * x4, M2PIX * y4


   self.meshVerts[1][1] = x1
   self.meshVerts[1][2] = y1

   self.meshVerts[2][1] = x2
   self.meshVerts[2][2] = y2

   self.meshVerts[3][1] = x4
   self.meshVerts[3][2] = y4


   self.meshVerts[5][1] = x2
   self.meshVerts[5][2] = y2

   self.meshVerts[6][1] = x3
   self.meshVerts[6][2] = y3

   self.meshVerts[4][1] = x4
   self.meshVerts[4][2] = y4



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

local function drawQueryBox(x, y, w, h)
   local oldwidth = gr.getLineWidth()
   local lwidth = 4
   gr.setLineWidth(lwidth)
   gr.setColor({ 0., 0., 1. })
   gr.rectangle("line", x, y, w, h)
   gr.setLineWidth(oldwidth)
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
   for _, id in ipairs(playerTankKeyconfigIds) do
      KeyConfig.unbind(id)
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
   local function pushId(id)
      table.insert(playerTankKeyconfigIds, id)
      return id
   end

   if playerTank then

      local kc = KeyConfig
      local bmode = "isdown"

      kc.bind(
      bmode, { key = "d" },
      function(sc)
         if mode ~= "normal" then
            return false, sc
         end
         playerTank["right"](playerTank)
         return false, sc
      end,
      i18n("mt" .. "right"), pushId("mt" .. "right"))


      kc.bind(
      bmode, { key = "a" },
      function(sc)
         if mode ~= "normal" then
            return false, sc
         end
         playerTank["left"](playerTank)
         return false, sc
      end,
      i18n("mt" .. "left"), pushId("mt" .. "left"))


      kc.bind(
      bmode, { key = "w" },
      function(sc)
         if mode ~= "normal" then
            return false, sc
         end
         playerTank["forward"](playerTank)
         return false, sc
      end,
      i18n("mt" .. "forward"), pushId("mt" .. "forward"))


      kc.bind(
      bmode, { key = "s" },
      function(sc)
         if mode ~= "normal" then
            return false, sc
         end
         playerTank["backward"](playerTank)
         return false, sc
      end,
      i18n("mt" .. "backward"), pushId("mt" .. "backward"))


      kc.bind(
      bmode, { key = "v" },
      function(sc)
         if mode ~= "normal" then
            return false, sc
         end
         playerTank["resetVelocities"](playerTank)
         return false, sc
      end,
      i18n("resetVelocities"), pushId("resetVelocities"))


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
      i18n("fire"), pushId("fire"))


   else
      error("There is no player tank object instance, sorry.")
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
      local x, y = playerTank.pbody:getWorldCenter()
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
         camTimer:during(cameraAnimationDuration, function(dt, time, delay)
            local dx, dy = -reldx * (delay - time) * xc, -reldy * (delay - time) * yc
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

local function konsolePresent()
   gr.setColor({ 1, 1, 1, 1 })
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

local Background = {}






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

local function mainPresent()
   push2drawlist(Background.present, background)
   push2drawlist(queryBoundingBox)
   push2drawlist(drawBullets)

   cam:attach()
   presentDrawlist()
   cam:detach()

   if DEBUG_PHYSICS then
      drawQueryBox()
   end
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

local function update(dt)
   camTimer:update(dt)
   pworld:update(1 / 60)
   linesbuf:update()
   updateTanks()
   updateBullets()
end

local function backspaceCmdLine()
   local u8 = require("utf8")

   local byteoffset = u8.offset(cmdline, -1)
   if byteoffset then


      cmdline = string.sub(cmdline, 1, byteoffset - 1)
   end
end

function PRINT(...)
   print(...)
end

function PINSPECT(t)
   print(inspect(t))
end

function INSPECT(t)
   return inspect(t)
end

local historyfname = "cmdhistory.txt"

local function enterCommandMode()
   if linesbuf.show then
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

local function evalCommand()





   local preload = [[]]
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

local function processCommandModeKeys(key)
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


local function spawn(pos, dir)
   local res
   local ok, errmsg = pcall(function()
      if #tanks >= 1 then
         unbindPlayerTankKeys()
      end
      local t = Tank.new(pos, dir)
      table.insert(tanks, t)

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
   function(sc)
      if mode ~= "normal" then
         return false, sc
      end
      if cam.scale < zoomHigher then
         cam:zoom(1. + zoomSpeed)
      end
      return false, sc
   end,
   "zoom camera in",
   "zoomin")

   KeyConfig.bind(
   "isdown",
   { key = "x" },
   function(sc)
      if mode ~= "normal" then
         return false, sc
      end
      if cam.scale > zoomLower then
         cam:zoom(1.0 - zoomSpeed)
      end
      return false, sc
   end,
   "zoom camera out",
   "zoomout")

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
   drawCoro = coroutine.create(function()
      if DEBUG_DRAW_THREAD then
         print("drawCoro started")
      end
      while true do
         print("go to logo present()")

         while showLogo == true do
            logo:present()
         end
         print("goto mainPresent()")

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

   createDrawCoroutine()

   background = Background.new()

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



      print("before worldCoords", x, y)
      local timeout = 2.5
      linesbuf:push(timeout, "mousepressed(%d, %d)", x, y)
      x, y = cam:worldCoords(x, y)
      linesbuf:push(timeout, "in world coordinates (%d, %d)", x, y)
      print("after worldCoords", x, y)

      x, y = x * PIX2M, y * PIX2M
      spawn(vector.new(x, y))
   end
end

local function resize(neww, newh)
   metrics.resize(neww, newh)
   if DEBUG_CAMERA then
      print("tanks window resized to w, h", neww, newh)
   end
   W, H = neww, newh


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
