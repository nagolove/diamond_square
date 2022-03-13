local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local os = _tl_compat and _tl_compat.os or os; local package = _tl_compat and _tl_compat.package or package; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table



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
local Wrapper = wrp


require("love")
require('konstants')
require('joystate')
require('pipeline')
require("common")


require("keyconfig")




local sformat = string.format
local inspect = require("inspect")
local serpent = require('serpent')

local metrics = require("metrics")
local vec2 = require("vector")



local Pipeline = require('pipeline')
local pipeline = Pipeline.new(SCENE_PREFIX)


local arrow = require('arrow')
arrow.init(pipeline)





local yield, resume = coroutine.yield, coroutine.resume










































local Edge = {}










local Arena = {}





























local FilterData = {}
















local Hangar = {}















local Tank = require('tank')


local Turret = {}































local Base = {}





























































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














require("Timer")

local physics_pause = false


local tanks = {}


local hangars = {}


local playerTank


require('logo')

local rng = love.math.newRandomGenerator()

rng:setSeed(os.time())

local DiamonAndSquare = require('diamondsquare')
local diamondSquare = DiamonAndSquare.new(8, rng, pipeline)





local event_channel = love.thread.getChannel("event_channel")
local main_channel = love.thread.getChannel("main_channel")

local is_stop = false
local last_render = love.timer.getTime()


local Joystick = love.joystick.Joystick
local joystick = love.joystick
local joyState

local joy


local Camera = {}




























local Camera_mt = {
   __index = Camera,
}

function Camera:setTransform()
   pipeline:open('set_transform')
   pipeline:push(self.transform)
   pipeline:close()
end

function Camera:setOrigin()
   pipeline:openAndClose('origin_transform')
end

function Camera.new()
   local self = setmetatable({}, Camera_mt)
   self.x, self.y = 0, 0
   self.scale = 1.
   self.dt = 0
   self.transform = love.math.newTransform()
   pipeline:pushCode("camera_axises", [[
    local yield = coroutine.yield
    local linew = 1.
    local color = {0, 0, 0, 1}
    while true do
        local oldlw = love.graphics.getLineWidth()
        local w, h = love.graphics.getDimensions()
        love.graphics.setLineWidth(linew)
        love.graphics.setColor(color)
        love.graphics.line(w / 2, 0, w / 2, h)
        love.graphics.line(0, h / 2, w, h / 2)
        love.graphics.setLineWidth(oldlw)
        yield()
    end
    ]])
   return self
end

function Camera:checkInput(j)
   self:checkMovement(j)
   self:checkScale(j)
end

function Camera:draw_axises()
   pipeline:openAndClose("camera_axises")
end

function Camera:push2lines_buf()
   local msg = sformat("camera: (%.3f, %.3f, %.4f)", self.x, self.y, self.scale)
   pipeline:push("add", "camera", msg)
   local mat = { self.transform:getMatrix() }
   local fmt1 = "%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f,"
   local fmt2 = "%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f"
   local msg = sformat(
   "camera mat: (" .. fmt1 .. fmt2 .. ")",
   mat[1],
   mat[2],
   mat[3],
   mat[4],
   mat[5],
   mat[6],
   mat[7],
   mat[8],
   mat[9],
   mat[10],
   mat[11],
   mat[12],
   mat[13],
   mat[14],
   mat[15],
   mat[16])

   pipeline:push("add", "camera_mat", msg)
end

function Camera:update(dt)
   self.dt = dt
end

function Camera:checkMovement(j)
   local axes = { j:getAxes() }
   local dx, dy = axes[4], axes[5]

   local amount_x, amount_y = 3000 * self.dt, 3000 * self.dt
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
      self.x = self.x + tx
      self.y = self.y + ty
      self.transform:translate(tx, ty)
   end
end


function Camera:checkScale(j)
   local axes = { j:getAxes() }
   local dy = axes[2]
   local factor = 1 * self.dt

   if dy == -1 then


      self.scale = 1 + factor
      self.transform:scale(1 + factor, 1 + factor)

   elseif dy == 1 then
      self.scale = 1 - factor
      self.transform:scale(1 - factor, 1 - factor)

   end
end





function Camera:checkPlayerInCircle()
   local rad = 300
end


function Camera:moveToPlayer()
   if not playerTank and playerTank.base then
      return
   end

   local px, py, _ = wrp.get_position(playerTank.base)
   print("camera x, y, scale", self.x, self.y, self.scale)
   print("tank x, y", px, py)

   self.scale = 1.
   local dx, dy = self.x + -px + screenW / 2, self.y + -py + screenH / 2
   self.x, self.y = self.x + dx, self.y + dy
   if self.x ~= dx or self.y ~= dy then

      self.transform:reset()
      self.transform:scale(self.scale)

      self.transform:translate(dx, dy)
   end
end

function Camera:moveToOrigin()
   self.x, self.y = 0, 0
   self.scale = 1,
   self.transform:translate(self.x, self.y)
   self.transform:reset()
   self.transform:scale(self.scale, self.scale)
end

local camera

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

local function print_io_rate()
   local bytes = pipeline:get_received_in_sec()
   local msg = sformat("передано за секунду Килобайт = %d", math.floor(bytes / 1024))
   pipeline:push('add', 'data_received', msg)
end

function Hangar.new(_)
   local Hangar_mt = {
      __index = Hangar,
   }
   local self = setmetatable({}, Hangar_mt)

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



local base_tex_fname = 'tank_body.cut.png'
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

function Turret.new(t)
   if not t then
      error("Could'not create Turret without Tank object")
   end

   local Turret_mt = {
      __index = Turret,
   }

   local self = setmetatable({}, Turret_mt)
   self.tank = t

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






























end

function Base:drawTrack()
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
   if tank then
      pipeline:push('new', tank.id, x, y, angle)
   end



end

local function renderInternal()
   pipeline:openAndClose('clear')


   camera:setTransform()















   pipeline:open('base_shape')

   wrp.query_all_tanks(on_each_body)
   pipeline:push('flush')
   pipeline:close()


   pipeline:open('border_segments')




   wrp.draw_static_segments(
   function(x1, y1, x2, y2)
      pipeline:push('draw', x1, y1, x2, y2)
   end)

   pipeline:push('flush')
   pipeline:close()

   local player_x, player_y

   if playerTank then
      pipeline:open('selected_object')
      local body = playerTank.base
      player_x, player_y = wrp.get_position(body)

      pipeline:push(wrp.get_position(body))
      pipeline:close()
   else
      error('Player should not be nil')
   end


   pipeline:openAndClose('main_axises')


   camera:setOrigin()

   pipeline:open('lines_buf')
   print_io_rate()
   camera:push2lines_buf()
   local msg = sformat("player pos (%.3f, %.3f)", player_x, player_y)
   pipeline:push("add", "player_pos", msg)
   pipeline:push('flush')
   pipeline:close()

   pipeline:openPushAndClose('object_lines_buf', 'flush')

   camera:draw_axises()
end

local function renderScene()

   local nt = love.timer.getTime()
   local fps_limit = 1. / 300.
   local diff = nt - last_render

   if diff >= fps_limit then
      last_render = nt
      renderInternal()
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


















































































































































































local function keypressed(key)

   print('keypressed', key)

   if key == "p" then
      physics_pause = not physics_pause
   end

















end


































































































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



   pipeline:pushCode("main_axises", [[
    local col = {0.3, 0.5, 1, 1}
    while true do
        local size = 1000
        --love.graphics.setColor(col)
        love.graphics.setColor {0, 0, 0, 1}
        local rad = 100
        love.graphics.circle("line", 0, 0, rad)
        love.graphics.line(0, size, 0, -size)
        love.graphics.line(-size, 0, size, 0)
        coroutine.yield()
    end
    ]])


   pipeline:pushCodeFromFile('lines_buf', 'lines_buf.lua')

   pipeline:pushCodeFromFile('object_lines_buf', 'lines_buf.lua')


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


   pipeline:pushCodeFromFile("base_shape", 'poly_shape.lua')

   pipeline:pushCodeFromFile("turret_shape", 'poly_shape.lua')



   pipeline:pushCode('border_segments', [[
    local yield = coroutine.yield
    local linew = 6
    while true do
        local cmd: string
        
        local oldlw = love.graphics.getLineWidth()
        love.graphics.setLineWidth(linew)
        repeat
            cmd = graphic_command_channel:demand() as string

            if cmd == "draw" then
                local x1, y1, x2, y2: number, number, number, number
                x1 = graphic_command_channel:demand() as number
                y1 = graphic_command_channel:demand() as number
                x2 = graphic_command_channel:demand() as number
                y2 = graphic_command_channel:demand() as number

                love.graphics.setColor {0, 0, 0, 1}
                love.graphics.line(x1, y1, x2, y2)
                --print(x1, y1, x2, y2)

            elseif cmd == 'flush' then
                break
            else
                error('unkonwn command: ' .. cmd)
            end

        until not cmd
        love.graphics.setLineWidth(oldlw)

        yield()
    end
    ]])


end


local function initPipelineObjects()
   pipeline:open('base_shape')
   pipeline:push(base_tex_fname, tank_width, tank_height)





   pipeline:close()

   pipeline:open('turret_shape')
   pipeline:push(turret_text_fname, tank_width, tank_height)





   pipeline:close()


   pipeline:openPushAndClose('lines_buf', "DejaVuSansMono.ttf", 24)
   pipeline:openPushAndClose('object_lines_buf', "DejaVuSansMono.ttf", 24)

   pipeline:sync()

   pipeline:openPushAndClose(
   'lines_buf',
   "add",
   'hi',
   "привет из недр движка",
   "flush")

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


   camera = Camera.new()








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
   tanks = {}


end

local function mousemoved(x, y, dx, dy)
   metrics.mousemoved(x, y, dx, dy)

   local absx, absy = camera.x, camera.y
   print('absx, absy', absx, absy)
   local counter = 0
   wrp.get_shape_under_point(x + absx, y + absy,
   function(
      shape,
      x,
      y,
      distance,
      gradx,
      grady)


      counter = counter + 1
      pipeline:open('object_lines_buf')
      pipeline:push('pos', x, y)


      pipeline:push('add', 2, 'shape ' .. tostring(shape))
      pipeline:push('add', 3, sformat('point (%.3f, %.3f)', x, y))
      pipeline:push('add', 4, 'distance ' .. distance)
      pipeline:push('add', 5, sformat('gradient (%.3f, %.3f)', gradx, grady))

      pipeline:push('add', 6, "----------")

      local body = wrp.get_shape_body(shape)
      local mass, inertia, cog_x, cog_y, pos_x, pos_y, v_x, v_y,
      force_x, force_y, angle, w, torque = wrp.get_body_stat(body)

      local msg = ""
      msg = sformat('mass, inertia: %.3f, %.3f', mass, inertia)
      pipeline:push('add', 7, msg)

      msg = sformat('cog (%.3f, %.3f)', cog_x, cog_y)
      pipeline:push('add', 8, msg)

      msg = sformat('position (%.3f, %.3f)', pos_x, pos_y)
      pipeline:push('add', 9, msg)

      msg = sformat('velocity (%.3f, %.3f)', v_x, v_y)
      pipeline:push('add', 10, msg)

      msg = sformat('force (%.3f, %.3f)', force_x, force_y)
      pipeline:push('add', 11, msg)

      msg = sformat('angle, ang. vel.: %.3f, %.3f)', angle, w)
      pipeline:push('add', 12, msg)

      msg = sformat('torque: %.3f', torque)
      pipeline:push('add', 13, msg)

      pipeline:push('enough')
      pipeline:close()


   end)

   if counter == 0 then
      pipeline:openPushAndClose('object_lines_buf', 'clear', 'enough')
   end




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

         elseif evtype == "joystickpressed" then
            local joystick = (e)[2]
            local button = (e)[3]

            print('joystick', inspect(joystick))
            print('button', inspect(button))

            local left_shift = 5
            local right_shift = 6


            if button == left_shift then
               print("moveToOrigin()")
               camera:moveToOrigin()
            end
            if button == right_shift then
               print("moveToPlayer()")
               camera:moveToPlayer()
            end
         end
      end
   end
end

local State = {}




local state = 'map'


local function spawnTank(px, py)
   local tank = Tank.new(vec2(px, py), tank_width, tank_height)
   table.insert(tanks, tank)
   local px, py, angle = wrp.get_position(tank.base)
   tank._prev_x, tank._prev_y = px, py
   pipeline:openPushAndClose(
   'base_shape',
   'new',
   tank.id,
   px, py, angle,
   "flush")

   return tank
end

local function spawnPlayer()
   playerTank = spawnTank(-20, -20)
end

local Borders = {}







local borders = {}









local function spawnTanks()






   local tanks_num = 5


   local minx, maxx = 0, 4000
   local miny, maxy = 0, 4000

   borders.x1, borders.y1 = minx, miny
   borders.x2, borders.y2 = maxx, maxy




   for _ = 1, tanks_num do
      local px, py = rng:random(minx, maxx), rng:random(miny, maxy)
      local tank = spawnTank(px, py)
   end

   spawnTank(100, 100)
   spawnTank(screenW / 2, screenH / 2)


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

local function spawnBorders()
   local b = borders
   local space = 5000
   wrp.new_static_segment(b.x1 - space, b.y1 - space, b.x2 + space, b.y1 - space)
   wrp.new_static_segment(b.x2 + space, b.y1 - space, b.x2 + space, b.y2 + space)
   wrp.new_static_segment(b.x2 + space, b.y2 + space, b.x1 - space, b.y2 + space)
   wrp.new_static_segment(b.x1 - space, b.y2 + space, b.x1 - space, b.y1 - space)
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




         camera:checkInput(joy)
         camera:update(dt)


         if not physics_pause then
            wrp.step(dt);
         end






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
