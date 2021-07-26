local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local load = _tl_compat and _tl_compat.load or load; local math = _tl_compat and _tl_compat.math or math; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table


local Mode = {}




require("global")
love.filesystem.setRequirePath("?.lua;?/init.lua;" .. SCENE_PREFIX .. "/?.lua")

local Tank = require("tank")

local List = require("list")
require("love")
require("common")
require("keyconfig")
require("camera")
require("vector")
require("Timer")
require("imgui")


local tlx, tly, brx, bry = 0., 0., W, H


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
local Shortcut = KeyConfig.Shortcut

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


      kc.bind(
      bmode, { key = "v" },
      function(sc)
         playerTank["resetVelocities"](playerTank)
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

   KeyConfig.bind("keypressed", { key = "c" }, function(sc)
      moveCameraToPlayer()
      return false, sc
   end, i18n("cam2tank"), "cam2tank")
end

local function bindKonsole()
   KeyConfig.bind("keypressed", { key = "`" }, function(sc)
      linesbuf.show = not linesbuf.show
      return false, sc
   end)
end

local function bindEscape()
   KeyConfig.bind("keypressed", { key = "escape" }, function(sc)



      if showLogo == true then
         love.event.quit()
      else
         showLogo = true
      end
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
   local zoomSpeed = 0.01
   local zoomLower, zoomHigher = 0.15, 3.5

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

   bindEscape()
   bindKonsole()

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
   elseif btn == 2 then
      local count = 100
      for i = 2, count do



         print("before worldCoords", x, y)
         local timeout = 2.5
         linesbuf:push(timeout, "mousepressed(%d, %d)", x, y)


         linesbuf:push(timeout, "in world coordinates (%d, %d)", x, y)
         print("after worldCoords", x, y)

         x, y = x * PIX2M, y * PIX2M
         spawn(vector.new(x, y))
      end
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
