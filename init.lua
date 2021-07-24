local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local load = _tl_compat and _tl_compat.load or load; local math = _tl_compat and _tl_compat.math or math; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table


local Mode = {}




SCENE_PREFIX = "scenes/t80u"

love.filesystem.setRequirePath("?.lua;?/init.lua;" .. SCENE_PREFIX .. "/?.lua")

local List = require("list")
require("love")
require("common")
require("keyconfig")
require("camera")
require("vector")
require("Timer")
require("imgui")

DEBUG_BASE = false
DEBUG_TANK = false
DEBUG_TANK_MOVEMENT = false
DEBUG_TURRET = false
DEBUG_CAMERA = false
DEBUG_PHYSICS = false
DEBUG_LOGO = true








DEBUG_DRAW_THREAD = true

DEFAULT_W, DEFAULT_H = 1024, 768
W, H = love.graphics.getDimensions()

cmd_drawBodyStat = true


local tlx, tly, brx, bry = 0., 0., W, H



M2PIX = 10

PIX2M = 1 / 10



local camTimer = require("Timer").new()
local drawlist = {}
local gr = love.graphics

local linesbuf = require("kons").new(SCENE_PREFIX .. "/VeraMono.ttf", 20)
local mode = "normal"
local cmdline, prevcmdline = "", ""
local cmdhistory = {}

local i18n = require("i18n")
local inspect = require("inspect")

local drawCoro = nil
local showLogo = true
local playerTankKeyconfigIds = {}

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

local Logo = {}













local Logo_mt = {
   __index = Logo,
}

local CameraSettings = {}






local cameraSettings = {

   dx = 100, dy = 100,
}




tanks = {}





local function presentDrawlist()
   for _, v in ipairs(drawlist) do
      v()
   end
end

local function push2drawlist(f)
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








end

function Tank:right()








end

local forceScale = 2

function Tank:forward()
   if DEBUG_TANK and DEBUG_TANK_MOVEMENT then
      print("Tank:forward")
   end




   local x, y = self.dir.x * forceScale, self.dir.y * forceScale
   print('applied', x, y)
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
   local x, y = pos.x, pos.y

   tankCounter = tankCounter + 1

   self.pbody = love.physics.newBody(pworld, x, y, "dynamic")


   self.pbody:setUserData(self)

   if not dir then
      dir = vector.new(0, -1)
   end

   self.id = tankCounter
   self.dir = dir:clone()
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

local function drawBodyStat(body)
   local radius = 10
   local x, y = body:getWorldCenter()
   x, y = x * M2PIX, y * M2PIX

   gr.setColor({ 0.1, 1, 0.1 })
   gr.circle("fill", x, y, radius)

   local vx, vy = body:getLinearVelocity()
   local scale = 7.
   gr.line(x, y, x + vx * scale, y + vy * scale)



end

function Tank:drawDirectionVector()
   if self.dir then
      local x, y = self.pbody:getWorldCenter()
      local scale = 50
      local color = { 0.8, 0.95, 0.99, 1 }
      x, y = x * M2PIX, y * M2PIX
      gr.setColor(color)


      gr.line(x, y, x + self.dir.x * scale, y + self.dir.y * scale)
   end
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
   local shape = love.physics.newCircleShape(px, py, r * PIX2M)

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


   r = r * 0.8

   gr.setColor({ 1, 0.5, 0, 0.5 })
   gr.circle("fill", px, py, r)




   gr.setColor({ 1, 1, 1, 1 })
   love.graphics.draw(
   self.img,
   px - imgw / 2, py - imgh / 2,
   0,
   sx, sy,
   ox, oy)






   for _, f in ipairs(self.pbody:getFixtures()) do

   end




end

function Base:present()

   local imgw, imgh = (self.img):getDimensions()
   local r, sx, sy, ox, oy = 0, 1., 1., 0, 0

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



   local angle = self.pbody:getAngle()

   gr.setColor({ 1, 1, 1, 1 })
   love.graphics.draw(
   self.img,
   px - imgw / 2, py - imgh / 2,
   angle,
   sx, sy,
   ox, oy)































   for _, f in ipairs(self.pbody:getFixtures()) do

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


   self.img = love.graphics.newImage(SCENE_PREFIX .. "/tank_body_small.png")
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

   if selfPtr and selfPtr.present then
      selfPtr:present()



















   end
   return true

end

local function queryBoundingBox()










   local x1, y1 = -20000, -20000
   local x2, y2 = 20000, 20000
   pworld:queryBoundingBox(
   x1 * PIX2M, y1 * PIX2M,
   x2 * PIX2M, y2 * PIX2M,
   onQueryBoundingBox)


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
      i18n("mt" .. direction), pushId("mt" .. direction))


      direction = "left"
      kc.bind(
      bmode, { key = direction },
      function(sc)
         playerTank["left"](playerTank)
         return false, sc
      end,
      i18n("mt" .. direction), pushId("mt" .. direction))


      direction = "forward"
      kc.bind(
      bmode, { key = "up" },
      function(sc)
         playerTank["forward"](playerTank)
         return false, sc
      end,
      i18n("mt" .. direction), pushId("mt" .. direction))


      direction = "backward"
      kc.bind(
      bmode, { key = "down" },
      function(sc)
         playerTank["backward"](playerTank)
         return false, sc
      end,
      i18n("mt" .. direction), pushId("mt" .. direction))



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

   local bindMode = "isdown"

   KeyConfig.bind(bindMode, { key = "a" }, makeMoveFunction(1., 0),
   i18n("mcleft"), "camleft")
   KeyConfig.bind(bindMode, { key = "d" }, makeMoveFunction(-1.0, 0.),
   i18n("mcright"), "camright")
   KeyConfig.bind(bindMode, { key = "w" }, makeMoveFunction(0., 1.),
   i18n("mcup"), "camup")
   KeyConfig.bind(bindMode, { key = "s" }, makeMoveFunction(0., -1.),
   i18n("mcdown"), "camdown")
   KeyConfig.bind(bindMode, { key = "escape" }, function(sc)
      if showLogo == true then
         love.event.quit()
      else
         showLogo = true
      end
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

local function backgroundPresent()
   gr.clear({ 0.5, 0.5, 0.5, 1 })
end

local function mainPresent()
   backgroundPresent()



   cam:attach()
   queryBoundingBox()
   presentDrawlist()
   cam:detach()




   drawlist = {}



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
   local ok = coroutine.resume(drawCoro)
   if not ok then

   end

   drawCameraAxixes()
   konsolePresent()
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
   local preload = [[
        local inspect = require 'inspect'
        --local systemPrint = print
        --print = konsolePrint
    ]]
   local f, loaderrmsg = load(preload .. cmdline)
   local time = 2
   if not f then
      linesbuf:push(time, "load() errmsg: " .. loaderrmsg)
   else
      local ok, pcallerrmsg = pcall(function()
         f()
      end)
      if not ok then
         linesbuf:push(time, "pcall() errmsg: " .. pcallerrmsg)
      else
         cmdline = ""
      end
   end
   table.insert(cmdhistory, cmdline)
   love.filesystem.append(historyfname, cmdline .. "\n")
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
























   processValue(key)
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
   local Shortcut = KeyConfig.Shortcut
   local zoomSpeed = 0.01
   local zoomLower, zoomHigher = 0.15, 3.5

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

local function bindCommandModeHotkey()
   KeyConfig.bind(
   "keypressed",
   { key = ":", mod = { "lshift" } },
   function(sc)
      print("Switching for command mode")
      mode = "command"
      love.keyboard.setTextInput(true)

      KeyConfig.bind(
      "keypressed",
      { key = "escape" },
      function(sc)
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


   pworld:setCallbacks(onBeginContact, onEndContact)

   logo = Logo.new()
   cam = require('camera').new()
   if DEBUG_CAMERA then
      print("camera created x, y, scale, rot", cam.x, cam.y, cam.scale, cam.rot)
   end

   bindCameraZoomKeys()
   bindCameraControl()
   bindFullscreenSwitcher()


   createDrawCoroutine()

   local len = 10
   for i = 1, len do
      for j = 1, len do

      end
   end
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
      local timeout = 2.5
      linesbuf:push(timeout, "mousepressed(%d, %d)", x, y)
      x, y = cam:worldCoords(x, y)
      linesbuf:push(timeout, "in world coordinates (%d, %d)", x, y)
      print("after worldCoords", x, y)

      x, y = x * PIX2M, y * PIX2M
      spawn(vector.new(x, y))
   end
end

local function resize(w, h)
   if DEBUG_CAMERA then
      print("tanks window resized to w, h", w, h)
   end
end

local function textinput(text)
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
