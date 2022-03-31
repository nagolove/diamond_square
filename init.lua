local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local package = _tl_compat and _tl_compat.package or package; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table



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


local metrics = require("metrics")
local vec2 = require("vector")





local Pipeline = require('pipeline')
local pipeline = Pipeline.new(SCENE_PREFIX)

local docsystem = require('doc-system')


local arrow = require('arrow')
arrow.init(pipeline)





local yield, resume = coroutine.yield, coroutine.resume























































local Arena = {}





local FilterData = {}
















local Hangar = {}















local Tank = require('tank')


local Turret = {}































local Base = {}













































































































local Hit = {}














local screenW, screenH

local space
local space_damping = 0.02














require("Timer")

local physics_pause = false


local tanks = {}


local hangars = {}


local playerTank


require('logo')

local Borders = {}






local rng = love.math.newRandomGenerator()

rng:setSeed(300 * 123414)


local DiamonAndSquare = require('diamondsquare')

local diamondSquare = DiamonAndSquare.new(5, rng, pipeline)





local event_channel = love.thread.getChannel("event_channel")
local main_channel = love.thread.getChannel("main_channel")

local is_stop = false
local last_render = love.timer.getTime()

local PCamera = require("pcamera")
local camera



local bordersArea = {}


local segments = {}

local lj = love.joystick
local Joystick = lj.Joystick
local joyState
local joy

local function initJoy()
   for _, j in ipairs(lj.getJoysticks()) do
      debug_print("joy", colorize('%{green}' .. inspect(j)))
   end
   joy = lj.getJoysticks()[1]
   if joy then
      debug_print("joy", colorize('%{green}avaible ' .. joy:getButtonCount() .. ' buttons'))
      debug_print("joy", colorize('%{green}hats num: ' .. joy:getHatCount()))
   end
   joyState = JoyState.new(joy)
end

local function print_fps()
   local msg = sformat("fps %d", love.timer.getFPS())
   pipeline:push('add', 'fps', msg)
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










































































































































local function on_each_body(x, y, angle, obj)
   local tank = obj

   if type(tank) ~= "table" then
      error("tank should be a table, not a " .. type(tank))
   end

   if tank then
      pipeline:push('new', tank.id, x, y, angle)
   end



end

local function renderSegments()
   pipeline:open('border_segments')
   wrp.draw_static_segments(
   function(x1, y1, x2, y2)
      pipeline:push('draw', x1, y1, x2, y2)
   end)

   pipeline:push('flush')
   pipeline:close()
end

local function renderTanks()
   pipeline:open('base_shape')
   wrp.query_all_tanks(on_each_body)
   pipeline:push('flush')
   pipeline:close()
end

























local function renderSelectedObject()
   local player_x, player_y
   if playerTank then
      pipeline:open('selected_object')
      local body = playerTank.base
      player_x, player_y = body:get_position()






      pipeline:push(body:get_position())
      pipeline:close()
   else
      error('Player should not be nil')
   end
   return player_x, player_y
end

local function renderLinesBuf(player_x, player_y)
   pipeline:open('lines_buf')
   print_io_rate()
   print_fps()
   camera:push2lines_buf()
   local msg = sformat("player pos (%.3f, %.3f)", player_x, player_y)
   pipeline:push("add", "player_pos", msg)



   pipeline:push('flush')

   pipeline:close()
end

local is_draw_hotkeys_docs = false
local is_draw_gamepad_docs = false

local function renderInternal()
   pipeline:openAndClose('clear')


   camera:setTransform()


   diamondSquare:render()


   renderTanks()

   renderSegments()


   local player_x, player_y = renderSelectedObject()


   pipeline:openAndClose('main_axises')


   pipeline:openPushAndClose('object_lines_buf', 'flush')


   camera:setOrigin()


   renderLinesBuf(player_x, player_y)


   camera:draw_axises()


   if is_draw_hotkeys_docs then
      docsystem.draw_keyboard()
   end
   if is_draw_gamepad_docs then
      docsystem.draw_gamepad()
   end
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



















































































































































































local function spawnTank(px, py)
   local tank = Tank.new(vec2(px, py), tank_width, tank_height)
   table.insert(tanks, tank)
   local tank_x, tank_y, angle = tank.base:get_position()







   tank._prev_x, tank._prev_y = tank_x, tank_y
   pipeline:openPushAndClose(
   'base_shape',
   'new',
   tank.id,
   tank_x, tank_y, angle,
   "flush")

   return tank
end

local function spawnTanks()






   local tanks_num = 2


   local minx, maxx = 0, 4000
   local miny, maxy = 0, 4000

   bordersArea.x1, bordersArea.y1 = minx, miny
   bordersArea.x2, bordersArea.y2 = maxx, maxy





   local rad = 1000
   for _ = 1, tanks_num do

      local p = vec2.fromPolar(
      rng:random() * 2 * math.pi,
      rad)

      spawnTank(p.x, p.y)
   end

   spawnTank(-100, 100)
   spawnTank(100, 100)
   spawnTank(screenW / 2, screenH / 2)


end


local function lines_buf_push_mapn()
   if not diamondSquare then
      return
   end
   pipeline:open('lines_buf')
   pipeline:push("add", 'mapn', "mapn: " .. diamondSquare.mapn)

   pipeline:push('flush')
   pipeline:close()
end


local function processLandscapeKeys(key)
   if not diamondSquare then
      return
   end

   if key == 'r' then
      diamondSquare:reset()
      diamondSquare:eval()
      diamondSquare:send2render()
   end

   if key == 'z' then
      local mapn = diamondSquare.mapn - 1
      if mapn >= 1 then
         diamondSquare = DiamonAndSquare.new(mapn, rng, pipeline)
         diamondSquare:eval()
         diamondSquare:send2render()
         lines_buf_push_mapn()
      end
   end

   if key == 'x' then
      local mapn = diamondSquare.mapn + 1
      if mapn <= 10 then
         diamondSquare = DiamonAndSquare.new(mapn, rng, pipeline)
         diamondSquare:eval()
         diamondSquare:send2render()
         lines_buf_push_mapn()
      end
   end
end


local function physics_reset()
   wrp.free_space(space)
   space = wrp.new_space(space_damping)
   print(colorize("%{blue}physics reseted"))
end




local function render_reset_state()
   pipeline:openPushAndClose('base_shape', 'clear')
end


local function initBorders()
   local lf = love.filesystem
   local borders_data


   if #segments ~= 0 then
      for _, v in ipairs(segments) do
         wrp.free_static_segment(v)
      end
   end

   local ok, msg = pcall(function()
      local path = SCENE_PREFIX .. "/borders_data.lua"
      borders_data = lf.load(path)()
   end)
   if not ok then
      error('Could not load borders data: ' .. msg)
   else
      print(colorize("%{blue}borders loaded"))
   end

   if borders_data then
      for _, b in ipairs(borders_data) do
         print('border', inspect(b))
         local segment = wrp.new_static_segment(b.x1, b.y1, b.x2, b.y2)
         table.insert(segments, segment)
      end
   else
      print(colorize("${red}" .. "no borders data"))
   end
end

local function spawnPlayer()
   local px, py = screenW / 3, screenH / 2
   playerTank = spawnTank(px, py)
   camera:setPlayer(playerTank)


   spawnTank(px + 200, py)
end

local function nextTankAsPlayer()
   print('nextTankAsPlayer')
   local index = -1
   for k, v in ipairs(tanks) do
      if v == playerTank then
         index = k + 1
         break
      end
   end
   if tanks[index] then
      playerTank = tanks[index]
   else
      playerTank = tanks[1]
   end
   camera:setPlayer(playerTank)
end

local function prevTankAsPlayer()
   print('prevTankAsPlayer')
   local index = -1
   for k, v in ipairs(tanks) do
      if v == playerTank then
         index = k - 1
         break
      end
   end
   if tanks[index] then
      playerTank = tanks[index]
   else
      playerTank = tanks[#tanks]
   end
   camera:setPlayer(playerTank)
end

local function changePlayerTank(key)
   if love.keyboard.isDown('lshift') then
      if key == 'left' then
         prevTankAsPlayer()
      elseif key == 'right' then
         nextTankAsPlayer()
      end
   end
end

local function changeWindowMode()

   love.window.setFullscreen(not love.window.getFullscreen())
end

local function keypressed(key)

   print('keypressed', key)

   if key == "escape" then
      is_stop = true
      debug_print('input', colorize('%{blue}escape pressed'))
   end


   if key == "p" then
      physics_pause = not physics_pause
   end

   if key == 'f1' then
      is_draw_hotkeys_docs = not is_draw_hotkeys_docs
      if is_draw_hotkeys_docs then
         is_draw_gamepad_docs = false
      end
   elseif key == 'f11' then
      changeWindowMode()
   end

   if physics_pause then

      if key == 'q' then

         physics_reset()
         render_reset_state()
         initBorders()
         spawnTanks()
         spawnPlayer()


      elseif key == '1' then

         initBorders()
      end
   end

   processLandscapeKeys(key)
   changePlayerTank(key)

















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
    local gr = love.graphics
    --local col = {0.3, 0.5, 1, 1}
    local col = {0, 0, 0, 1}
    local rad = 100
    local size = 1000

    while true do
        gr.setColor(col)
        --gr.setColor {0, 0, 0, 1}
        gr.setLineWidth(1)
        gr.circle("line", 0, 0, rad)
        gr.line(0, size, 0, -size)
        gr.line(-size, 0, size, 0)

        coroutine.yield()
    end
    ]])


   pipeline:pushCodeFromFile('lines_buf', 'lines_buf.lua')

   pipeline:pushCodeFromFile('object_lines_buf', 'lines_buf.lua')
   docsystem.init_render_stage1(pipeline)


   pipeline:pushCode('selected_object', [[
    -- жесткие значения ширины и высоты, как проверить что они соответствуют
    -- действительным?
    local width, height = 256, 256
    local selection_color = {0, 0.5, 1, 0.3}
    local border_color = {0, 0, 0, 1}
    local linew = 5

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

        gr.setColor(selection_color)
        gr.rectangle('fill', 0, 0, width, height)

        gr.setColor(border_color)
        gr.setLineWidth(linew)
        gr.rectangle('line', 0, 0, width, height)

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



   pipeline:pushCodeFromFile('border_segments', 'border_segments.lua')


end


local function initPipelineObjects()
   pipeline:open('base_shape')
   pipeline:push(base_tex_fname, tank_width, tank_height)





   pipeline:close()

   pipeline:open('turret_shape')
   pipeline:push(turret_text_fname, tank_width, tank_height)





   pipeline:close()


   local dejavu_mono = "DejaVuSansMono.ttf"
   pipeline:openPushAndClose('lines_buf', dejavu_mono, 24)
   pipeline:openPushAndClose('object_lines_buf', dejavu_mono, 30)
   docsystem.init_render_stage2()

   pipeline:sync()










end





































































































local function add_gamepad_docs()
   docsystem.add_keyboard_doc("escape", "exit")
   docsystem.add_keyboard_doc("r", "Rebuild map")
   docsystem.add_keyboard_doc('z', 'Decrease map size')
   docsystem.add_keyboard_doc('x', 'Increase map size')
   docsystem.add_keyboard_doc('shift+left', 'Previous tank as player')
   docsystem.add_keyboard_doc('shift+right', 'Next tank as player')
   docsystem.add_keyboard_doc('p', 'Pause for physics engine. "P" - mode')
   docsystem.add_keyboard_doc('f1', 'Show or hide this text')
   docsystem.add_keyboard_doc('q', "Fully reload map with objects.")
   docsystem.add_keyboard_doc('1', 'Reload static physics segments.')
   docsystem.finish_keyboard_docs()
end

local function add_keyboard_docs()
   docsystem.add_gamepad_doc("start", "show this help")
   docsystem.add_gamepad_doc("left shift", "reset camera")
   docsystem.add_gamepad_doc('right shift', 'move camera to player')
   docsystem.add_gamepad_doc('X', 'rotate left')
   docsystem.add_gamepad_doc('B', 'rotate right')
   docsystem.add_gamepad_doc('Y', 'move forward')
   docsystem.add_gamepad_doc('A', 'move backward')
   docsystem.finish_gamepad_docs()
end

local function init()

   print('init started')
   metrics.init()
   space = wrp.new_space(space_damping)


   screenW, screenH = pipeline:getDimensions()

   print('screenW, screenH', screenW, screenH)


   camera = PCamera.new(pipeline, screenW, screenH)


   initJoy()

   initRenderCode()

   initPipelineObjects()

   add_keyboard_docs()
   add_gamepad_docs()









   bindFullscreenSwitcher()








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

   local absx, absy = -camera.x, -camera.y


   local counter = 0

   wrp.get_body_under_point(x + absx, y + absy,










   function(
      object,
      shape_x,
      shape_y,
      dist,
      gradx,
      grady)


      if not object then
         error("get_body_under_point: object in nil")
      end

      print("under cursor")

      local msg = ""
      counter = counter + 1
      pipeline:open('object_lines_buf')

      pipeline:push('pos', x + absx, y + absy)


      pipeline:push('add', 2, 'object ' .. tostring(object))

      msg = sformat('point (%.3f, %.3f)', shape_x, shape_y)
      pipeline:push('add', 3, msg)

      pipeline:push('add', 4, 'distance ' .. dist)
      pipeline:push('add', 5, sformat('gradient (%.3f, %.3f)', gradx, grady))

      pipeline:push('add', 6, "----------")



      local body = object

      local mass, inertia, cog_x, cog_y, pos_x, pos_y, v_x, v_y,
      force_x, force_y, angle, w, torque = body:get_stat()

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
      pipeline:openPushAndClose('object_lines_buf', 'clear')
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

local function joystickpressed(_, button)
   local left_shift = 5
   local right_shift = 6
   local start = 8

   if button == left_shift then
      print("setToOrigin()")
      camera:setToOrigin()
   end
   if button == right_shift then
      print("moveToPlayer()")
      camera:moveToPlayer()
   end
   if button == start then

      is_draw_gamepad_docs = not is_draw_gamepad_docs
      is_draw_hotkeys_docs = false
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

            if love.keyboard.isDown('lshift') then
               dprint.keypressed(scancode)
            end


            keypressed(scancode)




         elseif evtype == "mousepressed" then
            local x, y = (e)[2], (e)[3]
            local btn = (e)[4]
            mousepressed(x, y, btn)

         elseif evtype == "joystickpressed" then
            local joystick = (e)[2]
            local button = (e)[3]
            joystickpressed(joystick, button)
         end
      end
   end
end

local State = {}




local state = 'map'









local function applyInput(j)

   if not j and not playerTank then
      return
   end

   local left, right, up, down = 3, 2, 4, 1







   if j:isDown(right) then
      playerTank:right()
   elseif j:isDown(left) then
      playerTank:left()
   elseif j:isDown(up) then
      playerTank:forward()
   elseif j:isDown(down) then
      playerTank:backward()
   end

end

local stateCoro = coroutine.create(function(dt)

   initBorders()
   spawnTanks()
   spawnPlayer()

   diamondSquare:eval()
   diamondSquare:send2render()


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
