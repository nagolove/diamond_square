local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local pcall = _tl_compat and _tl_compat.pcall or pcall; local table = _tl_compat and _tl_compat.table or table; SCENE_PREFIX = "scenes/pink1"

local DEBUG_BASE = true
local DEBUG_TANK = true
local DEBUG_TURRET = false

require("love")
love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/empty/?.lua")
local i18n = require("i18n")


require("common")




local gr = love.graphics

local inspect = require("inspect")






require("vector")


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

local pworld
local isActive

local tanks = {}

local playerTank

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

function Tank.new(pos)
   if DEBUG_TANK then
      print('Start of Tank creating..')
   end
   local self = setmetatable({}, Tank_mt)
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

function Turret.new(pos)
   if DEBUG_TURRET then
      print("Start of Turret creating..")
   end
   local self = setmetatable({}, Turret_mt)
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

function Base.new(pos)
   if DEBUG_BASE then
      print("Base.new()")
   end
   local self = setmetatable({}, Base_mt)
   self.pos = shallowCopy(pos)
   self.img = love.graphics.newImage(SCENE_PREFIX .. "/korpus1.png")
   if DEBUG_BASE then
      print("self.pos", self.pos)
      print("self.img", self.img)
   end
   return self
end














local function drawTanks()


   gr.setColor({ 1, 1, 1 })


   for _, v in ipairs(tanks) do
      v.base:present()
      v.turret:present()
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
end

local function draw()

   gr.clear(0.2, 0.2, 0.2)

   drawTanks()


end

local function update(dt)
   playerTankUpdate()
   pworld:update(dt)
end

local function keypressed(key)
   if key == "escape" then
      love.event.quit()
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
















   local canSleep = true
   pworld = love.physics.newWorld(0., 0., canSleep)
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
