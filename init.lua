local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table


local Mode = {}




love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/pink1/?.lua")

require("love")
require("common")
require("keyconfig")
require("camera")
require("vector")
require("Timer")
require("imgui")

SCENE_PREFIX = "scenes/pink1"

local DEBUG_BASE = true
local DEBUG_TANK = true
local DEBUG_TANK_MOVEMENT = false
local DEBUG_TURRET = true
local DEBUG_CAMERA = true
local DEBUG_PHYSICS = true

local W, H = love.graphics.getDimensions()

local tlx, tly, brx, bry = 0., 0., W, H



local M2PIX = 10

local PIX2M = 1 / 10


local cam
local camTimer = require("Timer").new()
local drawlist = {}
local gr = love.graphics
local linesbuf = require("kons").new()
local mode = "normal"
local cmdline = ""

local i18n = require("i18n")
local inspect = require("inspect")

local Turret = {}












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

local CameraSettings = {}




local cameraSettings = {

   dx = 10, dy = 10,
}


local pworld

local tanks = {}

local playerTank

local function presentDrawlist()
   for _, v in ipairs(drawlist) do
      v()
   end
end

local function push2drawlist(f)



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

function Tank.new(pos)
   if DEBUG_TANK then
      print('Start of Tank creating..')
   end
   local self = setmetatable({}, Tank_mt)
   local x, y = pos.x, pos.y

   tankCounter = tankCounter + 1

   self.pbody = love.physics.newBody(pworld, x * PIX2M, y * PIX2M, "dynamic")

   self.pbody:setUserData(self)

   self.id = tankCounter
   self.turret = Turret.new(self)
   self.base = Base.new(self)
   self.movementDelta = 1.

   if DEBUG_PHYSICS then
      print("pbody:getAngularDamping()", self.pbody:getAngularDamping())
      print("pbody:getLinearDamping()", self.pbody:getLinearDamping())
   end




   if DEBUG_TANK then
      print('self.turret', self.turret)
      print('self.base', self.base)
      print('End of Tank creating.')
   end
   return self
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
   self.img = love.graphics.newImage(SCENE_PREFIX .. "/bashnya1.png")
   self.pbody = t.pbody;

   if DEBUG_TURRET then
      print("self.tank", self.tank)
      print("self.pbody", self.pbody)
      print("self.img", self.img)
   end

   local w, _ = (self.img):getDimensions()

   local r = w / 2
   local px, py = self.tank.pbody:getPosition()
   local shape = love.physics.newCircleShape(px, py, r * M2PIX)

   self.f = love.physics.newFixture(self.pbody, shape)

   if DEBUG_TURRET then
      print("circle shape created x, y, r", px, py)
   end

   return self
end

local function drawFixture(f)
   local shape = f:getShape()
   local shapeType = shape:getType()
   if shapeType == 'circle' then
      local cShape = shape
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
   local imgw, imgh = (self.img):getDimensions()
   local r, sx, sy, ox, oy = math.rad(0.), 1., 1., imgw / 2, imgh / 2

   local shape = self.f:getShape()
   local cshape = self.f:getShape()

   if shape:getType() ~= "circle" then
      error("Only circle shape allowed.")
   end
   local px, py = cshape:getPoint()
   px, py = self.pbody:getWorldPoints(px, py)
   px, py = px * M2PIX, py * M2PIX
   r = cshape:getRadius() * M2PIX



   love.graphics.draw(
   self.img,
   px, py,
   r,
   sx, sy,
   ox, oy)


   for _, f in ipairs(self.pbody:getFixtures()) do
      drawFixture(f)
   end



end

function Base:present()
   local imgw, imgh = (self.img):getDimensions()
   local r, sx, sy, ox, oy = math.rad(0.), 1., 1., imgw / 2, imgh / 2

   local shape = self.f:getShape()
   local cshape = self.f:getShape()
   if shape:getType() ~= "circle" then
      error("Only circle shape allowed.")
   end
   local px, py = cshape:getPoint()
   px, py = self.pbody:getWorldPoints(px, py)
   px, py = px * M2PIX, py * M2PIX
   r = cshape:getRadius() * M2PIX
   gr.setColor({ 1, 0, 0, 0.5 })
   gr.circle("fill", px, py, r)

   gr.setColor({ 1, 1, 1, 0.5 })
   love.graphics.draw(
   self.img,
   px, py,
   r,
   sx, sy,
   ox, oy)


   for _, f in ipairs(self.pbody:getFixtures()) do
      drawFixture(f)
   end

   local x, y = self.pbody:getWorldCenter()
   x, y = x * M2PIX, y * M2PIX
   local text = string.format("%d", self.tank.id)
   gr.print(text, x, y)
end

function Base.new(t)
   if DEBUG_BASE then
      print("Base.new()")
   end
   if not t then
      error("Could'not create Base without Tank object")
   end

   local self = setmetatable({}, Base_mt)
   self.tank = t
   self.img = love.graphics.newImage(SCENE_PREFIX .. "/korpus1.png")
   self.pbody = t.pbody

   if DEBUG_BASE then
      print("self.tank", self.tank)
      print("self.pbody", self.pbody)
      print("self.img", self.img)
   end

   local w, _ = (self.img):getDimensions()

   local r = w / 2
   local px, py = self.tank.pbody:getPosition()
   local shape = love.physics.newCircleShape(px, py, r * PIX2M)

   self.f = love.physics.newFixture(self.pbody, shape)

   if DEBUG_TURRET then
      print("circle shape created x, y, r", px, py)
   end

   return self
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

   if selfPtr then

      if selfPtr.turret then

         selfPtr.turret:present()
      else
         if DEBUG_TURRET then
            print("Turret object have not present method.")
         end
      end
      if selfPtr.base then

         selfPtr.base:present()
      else
         if DEBUG_BASE then
            print("Base object have not present method.")
         end
      end
   end
   return true

end

local function queryBoundingBox()
   pworld:queryBoundingBox(
   tlx * PIX2M, tly * PIX2M,
   brx * PIX2M, bry * PIX2M,
   onQueryBoundingBox)

end

local function drawTanks()


   gr.setColor({ 1, 1, 1 })


   for _, v in ipairs(tanks) do
      v.base:present()
      v.turret:present()
   end


end

local playerTankKeyconfigIds = {}

local function unbindPlayerTankKeys()
   for _, id in ipairs(playerTankKeyconfigIds) do
      KeyConfig.unbind(id)
   end
end

local function bindPlayerTankKeys()
   local function pushId(id)
      table.insert(playerTankKeyconfigIds, id)
      return id
   end

   if playerTank then

      local kc = KeyConfig
      local Shortcut = kc.Shortcut
      local bmode = "isdown"


      local E = {}



























      local direction

      direction = "right"
      kc.bind(
      bmode, { key = direction },
      function(sc)
         playerTank["right"](playerTank)
         return false, sc
      end,
      "move tank " .. direction, pushId("mt" .. direction))


      direction = "left"
      kc.bind(
      bmode, { key = direction },
      function(sc)
         playerTank["left"](playerTank)
         return false, sc
      end,
      "move tank " .. direction, pushId("mt" .. direction))


      direction = "up"
      kc.bind(
      bmode, { key = direction },
      function(sc)
         playerTank["up"](playerTank)
         return false, sc
      end,
      "move tank " .. direction, pushId("mt" .. direction))


      direction = "down"
      kc.bind(
      bmode, { key = direction },
      function(sc)
         playerTank["down"](playerTank)
         return false, sc
      end,
      "move tank " .. direction, pushId("mt" .. direction))



   else
      error("There is no player tank object instance, sorry.")
   end
end

local function playerTankUpdate()
   if playerTank then

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
   imgui.StyleColorsLight()
   imgui.ShowDemoWindow()
   imgui.ShowUserGuide()
end

local function bindCameraControl()

   local Shortcut = KeyConfig.Shortcut
   local cameraAnimationDuration = 0.2

   local function makeMoveFunction(xc, yc)

      return function(sc)
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

   local bindMode = "keypressed"

   KeyConfig.bind(bindMode, { key = "a" }, makeMoveFunction(1., 0), "move left", "camleft")
   KeyConfig.bind(bindMode, { key = "d" }, makeMoveFunction(-1.0, 0.), "move right", "camright")
   KeyConfig.bind(bindMode, { key = "w" }, makeMoveFunction(0., 1.), "move up", "camup")
   KeyConfig.bind(bindMode, { key = "s" }, makeMoveFunction(0., -1.), "move down", "camdown")
   KeyConfig.bind(bindMode, { key = "escape" }, function(sc)
      love.event.quit()
      return false, sc
   end)
   KeyConfig.bind(bindMode, { key = "`" }, function(sc)
      linesbuf.show = not linesbuf.show
      return false, sc
   end)

end

local function drawBoundingBox()
   local oldwidth = gr.getLineWidth()
   local lwidth = 4
   gr.setLineWidth(lwidth)
   gr.setColor({ 0., 0., 1. })


   local tlx_, tly_ = cam:worldCoords(tlx, tly)
   local brx_, bry_ = cam:worldCoords(brx, bry)

   gr.rectangle("line", tlx_, tly_, brx_ - tlx_, bry_ - tly_)
   gr.setLineWidth(oldwidth)
end

local function draw()
   gr.clear(0.2, 0.2, 0.2)

   cam:attach()
   drawTanks()
   presentDrawlist()
   cam:detach()


   drawBoundingBox()

   drawlist = {}


   linesbuf:pushi(string.format("camera x, y: %d, %d", cam.x, cam.y))

   if mode == "command" then
      linesbuf:pushi(">:" .. cmdline)
   end

   linesbuf:draw()
end

local function update(dt)

   camTimer:update(dt)
   pworld:update(1 / 60)
   linesbuf:update()
end

local function processValue(key)
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

local function keypressed(key)
   if key == "space" then

      print("space pressed")
      local animLen = 3
      camTimer:during(animLen, function(_, time, _)
         push2drawlist(function()
            gr.setColor({ 1., 0., 0. })
            local radius = 50



            gr.circle("fill", W / 2, H / 2, radius * time)
         end)

      end,
      function()
         print("after space")
      end)

   end

   processValue(key)
end


local function spawn(pos)
   local res
   local ok, errmsg = pcall(function()
      if #tanks >= 1 then
         unbindPlayerTankKeys()
      end
      local t = Tank.new(pos)
      table.insert(tanks, t)

      playerTank = t
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
   function(sc)
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
      if cam.scale > zoomLower then
         cam:zoom(1.0 - zoomSpeed)
      end
      return false, sc
   end,
   "zoom camera out",
   "zoomout")

end

local DEFAULT_W, DEFAULT_H = 1024, 768

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

local function init()
   setWindowMode()



   i18n.set('en.welcome', 'welcome to this program')
   i18n.load({
      en = {
         good_bye = "good-bye!",
         age_msg = "your age is %{age}.",
         phone_msg = {
            one = "you have one new message.",
            other = "you have %{count} new messages.",
         },
      },
   })
   print("translated", i18n.translate('welcome'))
   print("translated", i18n('welcome'))


   local canSleep = true
   pworld = love.physics.newWorld(0., 0., canSleep)
   if DEBUG_PHYSICS then
      print("physics world canSleep:", canSleep)
   end


   pworld:setCallbacks(onBeginContact, onEndContact)

   cam = require('camera').new()
   if DEBUG_CAMERA then
      print("camera created x, y, scale, rot", cam.x, cam.y, cam.scale, cam.rot)
   end

   bindCameraZoomKeys()
   bindCameraControl()
   bindFullscreenSwitcher()


   KeyConfig.bind(
   "keypressed",
   { key = ":", mod = { "shift" } },
   function(sc)
      mode = "command"
      love.keyboard.setTextInput(true)
      return false, sc
   end,
   "go to command mode",
   "commandmode")
end

local function quit()
   unbindPlayerTankKeys()
   tanks = {}
end

local function mousemoved(_, _, _, _)
end

local function wheelmoved(_, _)

end

local function mousepressed(x, y, btn)
   if btn == 1 then



      print("before worldCoords", x, y)
      x, y = cam:worldCoords(x, y)
      print("after worldCoords", x, y)



      spawn(vector.new(x, y))
   end
end

local function resize(w, h)
   if DEBUG_CAMERA then
      print("tanks window resized to w, h", w, h)
   end
end

local function textinput(text)
   print("textinput", text)
   cmdline = cmdline .. text
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
