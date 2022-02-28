local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local package = _tl_compat and _tl_compat.package or package; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table



local dprint = require('debug_print')
local debug_print = dprint.debug_print

dprint.set_filter({
   [1] = { "joy" },
   [2] = { 'phys' },
   [3] = { "thread", 'someName' },
   [4] = { "graphics" },
   [5] = { "input" },
   [6] = { "verts" },




})


local colorize = require('ansicolors2').ansicolors
debug_print('thread', colorize('%{yellow}>>>>>%{reset} t80 started'))

require("love_inc").require_pls_nographic()

debug_print('thread', 'love.filesystem.getRequirePath()', love.filesystem.getRequirePath())


local require_path = "scenes/t80/?.lua;?.lua;?/init.lua;"
print('require_path', require_path)
love.filesystem.setRequirePath(require_path)





print('getCRequirePath()', love.filesystem.getCRequirePath())

love.filesystem.setCRequirePath("scenes/t80/?.so;?.so")





print("package.cpath", package.cpath)


print('getWorkingDirectory', love.filesystem.getWorkingDirectory())

local wrp = require("wrp")



require('konstants')
require('joystate')
require('pipeline')
require("common")
require('ffi')


require("keyconfig")

local IMGUI = false
if love.system.getOS() == 'Linux' then
   require("imgui")
   IMGUI = true
end

require("love")




local sformat = string.format
local inspect = require("inspect")
local serpent = require('serpent')

local metrics = require("metrics")
local vec2 = require("vector")
local vecl = require("vector-light")








local pipeline = Pipeline.new(SCENE_PREFIX)


local arrow = require('arrow')
arrow.init(pipeline)





local yield, resume = coroutine.yield, coroutine.resume
















local ObjectType = {}

































local Edge = {}










local Arena = {}
































local FilterData = {}













local Hangar = {}
















local Tank = {Options = {}, }








































































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





































local screenW, screenH



M2PIX = 10


PIX2M = 1 / 10














require("Timer")


local camTimer = require("Timer").new()
local camera = love.math.newTransform()


showLogo = true

playerTankKeyconfigIds = {}

angularImpulseScale = 5 * math.pi / 4

camZoomLower, camZoomHigher = 0.075, 3.5











tanks = {}
hangars = {}







require('logo')


local tankCounter = 0

local rng = love.math.newRandomGenerator()



require('diamondsquare')







maxTrackCount = 128
hits = {}


local event_channel = love.thread.getChannel("event_channel")
local main_channel = love.thread.getChannel("main_channel")

local is_stop = false
local last_render = love.timer.getTime()


local Joystick = love.joystick.Joystick
local joystick = love.joystick
local joyState

local joy

local function initJoy()
   for _, j in ipairs(joystick.getJoysticks()) do
      debug_print("joy", colorize('%{green}' .. inspect(j)))
   end
   joy = joystick.getJoysticks()[1]
   if joy then
      debug_print("joy", colorize('%{green}avaible ' .. joy:getButtonCount() .. ' buttons'))
      debug_print("joy", colorize('%{green}hats num: ' .. joy:getHatCount()))
   end
   joyState = JoyState.new(joy)
end

function Bullet.new(px, py, dirx, diry,
   tankId)

   local Bullet_mt = {
      __index = Bullet,
   }
   local self = setmetatable({}, Bullet_mt)

   self.timestamp = love.timer.getTime()
   self.died = false
   self.px = px
   self.py = py

   self.dir = vec2.new(dirx, diry)
   self.id = tankId or 0
   self.objectType = 'Bullet'

   return self

end














local function print_io_rate()
   local bytes = pipeline:get_received_in_sec()
   local msg = sformat("received_in_sec = %d", math.floor(bytes / 1024))
   pipeline:open('formated_text')
   pipeline:push(msg)
   pipeline:push(0)
   pipeline:push(140)
   pipeline:close()
end
















































function Hangar.new(_)
   local Hangar_mt = {
      __index = Hangar,
   }
   local self = setmetatable({}, Hangar_mt)
   self.objectType = "Hangar"
   return self
end

function Hangar:update()

end

function Hangar:present()
end

function Hit.new(x, y)
   local Hit_mt = {
      __index = Hit,
   }
   local self = setmetatable({}, Hit_mt)

   self.ps = nil
   error('self.ps = nil')

   x, y = x * M2PIX, y * M2PIX

   self.x = x
   self.y = y

   return self
end

function Turret:fire()
end

function Arena.new(_)
   local Arena_mt = { __index = Arena }
   local self = setmetatable({}, Arena_mt)

   self.objectType = "Arena"

   return self
end

function Arena:mousemoved(_, _, _, _)
end

function Arena:update()
end

function Arena:mousepressed(x, y, _)

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

function Arena:ser()
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
end



function Tank:fire()
end

function Base:left()
end

function Base:right()
end

function Base:forward()
   if self.tank.fuel > 0. then
   end
end

function Base:backward()
   if self.tank.fuel > 0. then
   end
end


function Tank:left()

end

function Tank:right()

end

function Tank:forward()

end

function Tank:backward()

end

local base_tex_fname = 'tank_body_small.png'
local turret_text_fname = 'tank_tower.png'

local function getTankSize()
   local path = SCENE_PREFIX .. '/' .. base_tex_fname
   local image = love.image.newImageData(path)
   if not image then
      error('Could not load base_tex_fname: ' .. path)
   end
   return image:getDimensions()
end

local tank_width, tank_height = getTankSize()

















local function newBoxBody(width, height, self)

















   local body = wrp.new_box_body(width, height, self)

   return body
end




function Tank.new(pos, _)

   local Tank_mt = {
      __index = Tank,
   }

   local self = setmetatable({}, Tank_mt)

   tankCounter = tankCounter + 1


   self.strength = 1.
   self.fuel = 1.
   self.id = tankCounter
   self.base_first_render = true
   self.turret_first_render = true

   self.color = { 1, 1, 1, 1 }



   self.base = newBoxBody(tank_width, tank_height, self)
   wrp.set_position(self.base, pos.x, pos.y)






   return self
end

function Base:drawDirectionVector()
   if self.dir then
      local x, y = 0, 0
      local scale = 100
      local color = { 0., 0.05, 0.99, 1 }
      x, y = x * M2PIX, y * M2PIX
      arrow.draw(x, y, x + self.dir.x * scale, y + self.dir.y * scale, color)
   end
end

function Base:resetVelocities()
end

function Base:updateDir()
end

function Base:engineCycle()


   if self.tank.fuel > 0 then
   end
end

function Base:update()
   self:updateDir()
   if not self.filterdata then

   end
   self:processTracks()
end

function Base:processTracks()
end

function Tank:update()

   if self.strength <= 0. then
      return self
   end

   return self
end

function Tank:present()
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

   return self
end



function Turret:rotateToMouse()
   local mx, my = love.mouse.getPosition()
   mx, my = mx * PIX2M, my * PIX2M
end

function Turret:update()

   if playerTank and self.tank == playerTank then
      self:rotateToMouse()
   end
end

function Turret:present()
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

   return self
end

function Base:present()
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
end

function Tank:damage(_)
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

























function getTerrainCorners()
end


























































































str = ""

























































local function spawnHangar(pos)
   local hangar = Hangar.new(pos)
   table.insert(hangars, hangar)
   return hangar
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

























































local function on_each_body(x, y, angle, obj)
   local tank = obj
   pipeline:push('new', tank.id, x, y, angle)



end

local function renderScene()

   local nt = love.timer.getTime()
   local fps_limit = 1. / 300.
   local diff = nt - last_render

   if diff >= fps_limit then
      last_render = nt

      pipeline:openAndClose('clear')

      pipeline:open('set_transform')
      pipeline:push(camera)
      pipeline:close()






      pipeline:open('base_shape')
      wrp.query_all_shapes(on_each_body)
      pipeline:push('flush')
      pipeline:close()








      if playerTank then
         pipeline:open('selected_object')
         local body = playerTank.base
         pipeline:push(wrp.get_position(body))
         pipeline:close()
      else
         error('Player should not be nil')
      end


      pipeline:openAndClose('origin_transform')

      print_io_rate()


      pipeline:sync()
   end
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

local lastPosX, lastPosY





local function moveCamera()
   if playerTank then
      if not lastPosX then
      end
      if not lastPosY then
      end
   end
end


















































































































































































local function keypressed(key)

   print('keypressed', key)

















end

cameraKeyConfigIds = {}


































































































local function bindFullscreenSwitcher()

   KeyConfig.bind(
   "keypressed",
   { key = "f11" },
   function(sc)
      local isfs = love.window.getFullscreen()

      if isfs then

      else

      end
      return false, sc
   end,
   "switch fullscreen and windowed modes",
   "switchwindowmode")

end

local function initRenderCode()


   pipeline:pushCode("poly_shape_verts", [[
    local col = {1, 0, 0, 1}
    local inspect = require "inspect"

    while true do
        love.graphics.setColor(col)

        local verts = graphic_command_channel:demand()
        love.graphics.polygon('fill', verts)

        coroutine.yield()
    end
    ]])

   pipeline:pushCode('alpha_draw', [[
    local tex1 = love.graphics.newImage(SCENE_PREFIX .. '/tank_body_small.png')
    local tex2 = love.graphics.newImage(SCENE_PREFIX .. '/tank_tower.png')
    while true do
        love.graphics.setColor {1, 1, 1, 1}
        love.graphics.draw(tex1, 0, 0)
        love.graphics.draw(tex2, 0, 0)
        coroutine.yield()
    end
    ]])

   pipeline:pushCode('selected_object', [[
    -- жесткие значения ширины и высоты, как проверить что они соответствуют
    -- действительным?
    local width, height = 256, 256

    local x, y, angle: number
    local gr = love.graphics
    while true do
        x = graphic_command_channel:demand() as number
        y = graphic_command_channel:demand() as number
        angle = graphic_command_channel:demand() as number

        gr.push()
        gr.translate(x, y)
        gr.rotate(angle)
        gr.translate(-width / 2, -height / 2)

        gr.setColor {0, 0.5, 1, 0.3}

        --gr.setColor {1, 1, 1, 1}

        gr.rectangle('fill', 0, 0, width, height)
        --gr.draw(texture, quad, 0, 0, width, height)
        --gr.draw(texture, quad, 0, 0)

        gr.pop()

        coroutine.yield()
    end
    ]])

   pipeline:pushCode('clear', [[
    while true do
        love.graphics.clear{0.5, 0.5, 0.5}
        coroutine.yield()
    end
    ]])

   pipeline:pushCode('set_transform', [[
    local gr = love.graphics
    local yield = coroutine.yield
    while true do
        gr.applyTransform(graphic_command_channel:demand())
        yield()
    end
    ]])

   pipeline:pushCode('origin_transform', [[
    local gr = love.graphics
    local yield = coroutine.yield
    while true do
        gr.origin()
        yield()
    end
    ]])

   pipeline:pushCode('formated_text', [[
    local font = love.graphics.newFont(24)
    while true do
        local old_font = love.graphics.getFont()

        love.graphics.setColor{0, 0, 0}
        love.graphics.setFont(font)

        local msg = graphic_command_channel:demand()
        local x = math.floor(graphic_command_channel:demand())
        local y = math.floor(graphic_command_channel:demand())
        love.graphics.print(msg, x, y)

        love.graphics.setFont(old_font)

        coroutine.yield()
    end
    ]])

   pipeline:pushCodeFromFile("base_shape", 'poly_shape.lua')
   pipeline:pushCodeFromFile("turret_shape", 'poly_shape.lua')

   pipeline:pushCode('chipmunk_vertex_order', [[
        -- {{{
        local verts_mat = {
            {2135,1982,2135,2238,1879,2238,1879,1982},
            {2589,1642,2589,1898,2333,1898,2333,1642},
            {2887,1937,2887,2193,2631,2193,2631,1937},
        }
        while true do
            for _, verts in ipairs(verts_mat) do
                local count = #verts
                love.graphics.setColor {0, 1, 0}
                love.graphics.polygon('fill', verts)
                --for i = 1, count / 2 - 1 do
                local i, j = 1, 1
                while i <= count do
                    love.graphics.setColor {0, 0, 1}
                    local rad = 100
                    love.graphics.circle('fill', verts[i], verts[i + 1], rad)
                    love.graphics.setColor { 1, 0, 0, 1}
                    --love.graphics.print(tostring(i), verts[i], verts[i + 1])
                    love.graphics.print(tostring(j), verts[i], verts[i + 1])
                    j = j + 1
                    i = i + 2
                end
            end
            coroutine.yield()
        end
        -- }}}
    ]])

end

local function initPipelineObjects()
   pipeline:open('base_shape')
   pipeline:push(base_tex_fname, tank_width, tank_height)




   pipeline:close()

   pipeline:open('turret_shape')
   pipeline:push(turret_text_fname, tank_width, tank_height)




   pipeline:close()


   pipeline:sync()
end































































































































































local space

local function init()

   print('init started')

   metrics.init()



   space = wrp.init_space()
   print('space', space)

   initJoy()
   initRenderCode()
   initPipelineObjects()








   bindFullscreenSwitcher()





   screenW, screenH = pipeline:getDimensions()
   print('screenW, screenH', screenW, screenH)

   arena = Arena.new("arena.lua")

   local corners = getTerrainCorners()
   if corners then
      for _, c in ipairs(corners) do
         spawnHangar(c)
      end
   end


   last_render = love.timer.getTime()
   print('init finished')
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

end

local function updateJoyState()
   joyState:update()
   if joyState.state and joyState.state ~= "" then
      debug_print('joy', joyState.state)
   end
end

local function process_events()
   local events = event_channel:pop()
   if events then
      for _, e in ipairs(events) do
         local evtype = (e)[1]
         if evtype == "mousemoved" then

            local x, y = (e)[2], (e)[3]
            local dx, dy = (e)[4], (e)[5]
            mousemoved(x, y, dx, dy)

         elseif evtype == 'wheelmoved' then

            local x, y = (e)[2], (e)[3]
            wheelmoved(x, y)

         elseif evtype == "keypressed" then
            local key = (e)[2]
            local scancode = (e)[3]

            local msg = '%{green}keypressed '
            debug_print('input', colorize(msg .. key .. ' ' .. scancode))

            dprint.keypressed(scancode)

            if scancode == "escape" then
               is_stop = true
               debug_print('input', colorize('%{blue}escape pressed'))
               break
            end


            keypressed(scancode)




         elseif evtype == "mousepressed" then






            local x, y = (e)[2], (e)[3]
            local btn = (e)[4]
            mousepressed(x, y, btn)

         end
      end
   end
end

local State = {}




local state = 'map'

local function spawnTank(px, py, options)
   local tank = Tank.new(vec2(px, py), options)
   table.insert(tanks, tank)
   return tank
end

local function spawnPlayer()
   playerTank = spawnTank(-20, -20)
end

local Borders = {}







local borders = {}

local function spawnTanks()
   local options = {}













   local tanks_num = 500

   local minx, maxx = 0, 4000
   local miny, maxy = 0, 4000

   borders.x1, borders.y1 = minx, miny
   borders.x2, borders.y2 = maxx, maxy

   for _ = 1, tanks_num do
      local px, py = rng:random(minx, maxx), rng:random(miny, maxy)
      spawnTank(px, py, options)
   end
end

local function applyInput(j)
   local left, right, up, down = 3, 2, 4, 1
   if j and playerTank then
      local body = playerTank.base

      local px, py = 0, 0
      local amount = 100

      if j:isDown(right) then
         wrp.apply_impulse(body, amount, 0, px, py);
      elseif j:isDown(left) then
         wrp.apply_impulse(body, -amount, 0, px, py);
      elseif j:isDown(up) then
         wrp.apply_impulse(body, 0, -amount, px, py);
      elseif j:isDown(down) then
         wrp.apply_impulse(body, 0, amount, px, py);
      end

   end
end


local function cameraScale(j, dt)
   local axes = { j:getAxes() }
   local dy = axes[2]
   local factor = 1 * dt

   if dy == -1 then


      camera:scale(1 + factor, 1 + factor)

   elseif dy == 1 then
      camera:scale(1 - factor, 1 - factor)

   end
end


local function cameraMovement(j, dt)
   local axes = { j:getAxes() }
   local dx, dy = axes[4], axes[5]

   local amount_x, amount_y = 3000 * dt, 3000 * dt
   local tx, ty = 0., 0.
   local changed = false

   if dx > 0 then
      changed = true
      tx = -amount_x
   elseif dx < 0 then
      changed = true
      tx = amount_x
   end

   if dy > 0 then
      changed = true
      ty = -amount_y
   elseif dy < 0 then
      changed = true
      ty = amount_y
   end

   if changed then
      camera:translate(tx, ty)
   end
end

local function spawnBorders()
   local b = borders
   wrp.new_static_segment(b.x1, b.y1, b.x2, b.y1)
   wrp.new_static_segment(b.x2, b.y1, b.x2, b.y2)
   wrp.new_static_segment(b.x2, b.y2, b.x1, b.y2)
   wrp.new_static_segment(b.x1, b.y2, b.x1, b.y1)
end

local stateCoro = coroutine.create(function(dt)

   spawnTanks()
   spawnBorders()
   spawnPlayer()

   while true do
      if state == 'map' then
         process_events()
         renderScene()
         updateTanks()


         camTimer:update(dt)



         cameraScale(joy, dt)
         cameraMovement(joy, dt)

         moveCamera()


         wrp.step(dt);






         applyInput(joy)
         updateJoyState()

         dt = yield()
      elseif state == 'garage' then

      end

   end
end)

local function mainloop()
   local last_time = love.timer.getTime()
   while not is_stop do
      local now_time = love.timer.getTime()
      local dt = now_time - last_time
      last_time = now_time

      local ok, errmsg = resume(stateCoro, dt)
      if not ok then
         error('stateCoro: ' .. errmsg)
      end

      local timeout = 0.0001
      love.timer.sleep(timeout)
   end
end


















init()
mainloop()

if is_stop then
   quit()
   print('space', space)
   wrp.free_space(space)
   main_channel:push('quit')
   debug_print('thread', 'Thread resources are freed')
end

debug_print('thread', colorize('%{yellow}<<<<<%{reset} t80 finished'))
