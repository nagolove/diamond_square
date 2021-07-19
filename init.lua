local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local pcall = _tl_compat and _tl_compat.pcall or pcall; local table = _tl_compat and _tl_compat.table or table

love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/pink1/?.lua")
require("love")
require("common")
require("keyconfig")
require("camera")
require("vector")
require("Timer")

SCENE_PREFIX = "scenes/pink1"

local DEBUG_BASE = true
local DEBUG_TANK = true
local DEBUG_TANK_MOVEMENT = false
local DEBUG_TURRET = true
local DEBUG_CAMERA = true

local W, H = love.graphics.getDimensions()

local tlx, tly, brx, bry = 0., 0., W, H






local PIX2M = 1.

local camTimer = require("Timer").new()
local cam
local gr = love.graphics
local drawlist = {}








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

local function push2drawlist(f)
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

function Tank.new(pos)
   if DEBUG_TANK then
      print('Start of Tank creating..')
   end
   local self = setmetatable({}, Tank_mt)
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

function Turret.new(pos, pbody)
   if DEBUG_TURRET then
      print("Start of Turret creating..")
   end
   local self = setmetatable({}, Turret_mt)
   self.pos = shallowCopy(pos)
   self.img = love.graphics.newImage(SCENE_PREFIX .. "/bashnya1.png")
   self.pbody = pbody;

   local w, h = (self.img):getDimensions()


   local r = w / 2
   local shape = love.physics.newCircleShape(pos.x, pos.y, r)

   love.physics.newFixture(self.pbody, shape)
   if DEBUG_TURRET then

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
   local imgw, imgh = (self.img):getDimensions()
   local r, sx, sy, ox, oy = math.rad(0.), 1., 1., imgw / 2, imgh / 2


   love.graphics.draw(
   self.img,
   self.pos.x, self.pos.y,
   r,
   sx, sy,
   ox, oy)

end

function Base:present()
   local imgw, imgh = (self.img):getDimensions()
   local r, sx, sy, ox, oy = math.rad(0.), 1., 1., imgw / 2, imgh / 2

   love.graphics.draw(
   self.img,
   self.pos.x, self.pos.y,
   r,
   sx, sy,
   ox, oy)

end

function Base.new(pos, pbody)
   if DEBUG_BASE then
      print("Base.new()")
   end
   local self = setmetatable({}, Base_mt)
   self.pos = shallowCopy(pos)
   self.img = love.graphics.newImage(SCENE_PREFIX .. "/korpus1.png")
   self.pbody = pbody
   if DEBUG_BASE then
      print("self.pos", self.pos)
      print("self.img", self.img)
   end
   return self
end
















local function onBeginContact(
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
         print("Turret object have not present method.")
      end
      if selfPtr.base then

         selfPtr.base:present()
      else
         print("Base object have not present method.")
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







   queryBoundingBox()
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
end

local function bindCameraControl()

   local Shortcut = KeyConfig.Shortcut
   local cameraAnimationDuration = 0.2

   local function makeMoveFunction(xc, yc)
      return function(sc)
         local reldx, reldy = cameraSettings.dx / cam.scale, cameraSettings.dy / cam.scale
         camTimer:during(cameraAnimationDuration, function(dt, time, delay)

            local dx, dy = -reldx * (delay - time) * xc, -reldy * (delay - time) * yc
            print("delay - time", delay - time)
            print("dx, dy", dx, dy)
            cam:move(dx * dt, dy * dt)
         end)
         return true, sc
      end
   end

   local bindMode = "keypressed"

   KeyConfig.bind(bindMode, { key = "a" }, makeMoveFunction(1., 0), "move left", "camleft")
   KeyConfig.bind(bindMode, { key = "d" }, makeMoveFunction(-1.0, 0.), "move right", "camright")
   KeyConfig.bind(bindMode, { key = "w" }, makeMoveFunction(0., 1.), "move up", "camup")
   KeyConfig.bind(bindMode, { key = "s" }, makeMoveFunction(0., -1.), "move down", "camdown")
end

local function drawBoundingBox()
   tlx, tly = cam:worldCoords(tlx, tly)
   brx, bry = cam:worldCoords(brx, bry)

   local oldwidth = gr.getLineWidth()
   local lwidth = 4
   gr.setLineWidth(lwidth)
   gr.setColor({ 0., 0., 1. })

   gr.rectangle("line", tlx, tly, brx - tlx, bry - tly)
   gr.setLineWidth(oldwidth)
end

local function draw()


   gr.clear(0.2, 0.2, 0.2)

   cam:attach()
   drawTanks()
   cam:detach()

   presentDrawlist()


   drawBoundingBox()

   drawlist = {}
end

local function update(dt)
   playerTankUpdate()
   camTimer:update(dt)
   pworld:update(dt)
end

local function keypressed(key)
   if key == "escape" then
      love.event.quit()
   elseif key == "space" then

      print("space pressed")
      local animLen = 3
      camTimer:during(animLen, function(dt, time, _)
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
end

local function spawn(pos)
   local res
   local ok, errmsg = pcall(function()
      local t = Tank.new(pos)
      table.insert(tanks, t)

      playerTank = t
   end)
   if not ok then
      error("Could'not load. Please implement stub-tank. " .. errmsg)
   end
   return res
end

local function init()
















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
   "zoom camera in",
   "zoomin")


   local canSleep = true
   pworld = love.physics.newWorld(0., 0., canSleep)
   pworld:setCallbacks(onBeginContact)

   cam = require('camera').new()
   if DEBUG_CAMERA then
      print("camera created x, y, scale, rot", cam.x, cam.y, cam.scale, cam.rot)
   end
   bindCameraControl()
end

local function quit()
   tanks = {}
end







local function mousepressed(x, y, btn)
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


}
