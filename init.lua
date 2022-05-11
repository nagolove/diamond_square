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
local joy_conf = require('joy_conf')
local fire_threshold = 0.5

require("love")
require('konstants')
require('pipeline')
require("common")


require("keyconfig")




local sformat = string.format
local inspect = require("inspect")


local metrics = require("metrics")






local Pipeline = require('pipeline')
local pipeline = Pipeline.new(SCENE_PREFIX)

local docsystem = require('doc-system')


local arrow = require('arrow')
arrow.init(pipeline)





local yield, resume = coroutine.yield, coroutine.resume

local State = {}




local state = 'map'























































local Arena = {}
















local Hangar = {}















local Tank = require('tank')


















































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

local JoyState = require('joystate')
local DummyJoyState = require('dummyjoystate')

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
   if joy then
      joyState = JoyState.new(joy)
   else
      joyState = DummyJoyState.new(joy)
   end
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

function Arena.new(_)
   local Arena_mt = { __index = Arena }
   local self = setmetatable({}, Arena_mt)



   return self
end










































































function getTerrainCorners()
end


























































































str = ""

























































local function spawnHangar(pos)
   local hangar = Hangar.new(pos)
   table.insert(hangars, hangar)
   return hangar
end










































































































































local function on_each_body_t(
   x, y, angle, obj,
   tur_x, tur_y, tur_angle,
   _)

   local tank = obj

   if type(tank) ~= "table" then
      error("tank should be a table, not a " .. type(tank))
   end

















   if tank then
      pipeline:push('new_t', tank.id, x, y, angle, tur_x, tur_y, tur_angle)
   end
end


















local function renderSegments()
   pipeline:open('border_segments')
   wrp.static_segments_draw(
   function(x1, y1, x2, y2)
      pipeline:push('draw', x1, y1, x2, y2)
   end)

   pipeline:push('flush')
   pipeline:close()
end

local function debug_draw_vertices(
   _, _, _, _,
   _, _, _,
   debug_vertices)

   if debug_vertices then
      pipeline:push("new")

      print(colorize("%{yellow}debug_draw_vertices"))







      pipeline:push(#debug_vertices)
      for i = 1, #debug_vertices do
         pipeline:push(debug_vertices[i])
      end

   else

   end
end

local OBJT_ERROR = 0
local OBJT_TANK = 1
local OBJT_BULLET = 2
local OBJT_SEGMENT = 4

local function move_camera2player()
   if playerTank then
      local px, py = playerTank.base:get_position()
      print('camera was centered to', px, py)
      camera:moveTo(px, py)
   end
end

local function renderTanks()
   pipeline:open('tank')






   wrp.space_query_bb_type(-30000, 30000, 30000, -30000, OBJT_TANK,
   on_each_body_t)

   pipeline:push('flush')
   pipeline:close()

   pipeline:open("debug_vertices")
   wrp.query_all_tanks_t(debug_draw_vertices)
   pipeline:push('enough')
   pipeline:close()
end



























local draw_selected_object = true

local function renderSelectedObject()
   local player_x, player_y, player_angle
   if playerTank then
      local body = playerTank.base
      player_x, player_y, player_angle = body:get_position()
      if draw_selected_object then
         pipeline:open('selected_object')

         pipeline:push(player_x, player_y, player_angle)
         pipeline:close()
      end
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

local function phys_dbg_draw()
   pipeline:open("dbg_phys")
   wrp.space_debug_draw(
   function(px, py, angle, rad)
      pipeline:push('circle', px, py, angle, rad)
   end,
   function(ax, ay, bx, by)
      pipeline:push('segment', ax, ay, bx, by)
   end,
   function(ax, ay, bx, by, rad)
      pipeline:push('fatsegment', ax, ay, bx, by, rad)
   end,
   function(polygon, rad)
      pipeline:push('polygon', polygon, rad)
   end,
   function(size, px, py)

      pipeline:push('dot', size, px, py)
   end)

   pipeline:push("enough")
   pipeline:close()
end

local function render_internal()
   pipeline:openAndClose('clear')

   camera:attach()


   diamondSquare:render()


   renderTanks()




   renderSegments()


   local player_x, player_y = renderSelectedObject()


   pipeline:openAndClose('main_axises')


   pipeline:openPushAndClose('object_lines_buf', 'flush')

   camera:detach()


   renderLinesBuf(player_x, player_y)





   if is_draw_hotkeys_docs then
      docsystem.draw_keyboard()
   end
   if is_draw_gamepad_docs then
      docsystem.draw_gamepad()
   end

   camera:draw_bbox()
end

local function renderScene()
   local nt = love.timer.getTime()

   local fps_limit = 1. / 300.
   local diff = nt - last_render

   if diff >= fps_limit then
      last_render = nt
      render_internal()







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


   local tank = Tank.new(px, py)

   print("tank", inspect(tank))
   table.insert(tanks, tank)
   local tank_x, tank_y, angle = tank.base:get_position()
   local turret_x, turret_y, turret_angle = tank.base:turret_get_pos()





   print(colorize("%{yellow}spawnTank:%{reset}"),
   "\n     tank.id", tank.id,
   "\n     tank_x", tank_x,
   "\n     tank_y", tank_y,
   "\n     angle", angle,
   "\n     turret_x", turret_x,
   "\n     turret_y", turret_y,
   "\n     turret_angle", turret_angle)
















   return tank
end

local function spawnTanks()






   local tanks_num = 2


   local minx, maxx = 0, 4000
   local miny, maxy = 0, 4000

   bordersArea.x1, bordersArea.y1 = minx, miny
   bordersArea.x2, bordersArea.y2 = maxx, maxy


   for _ = 1, tanks_num do



   end


   local w, h = 256, 256
   spawnTank(-w / 70, -h / 70)

   spawnTank(380, 100)
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
   wrp.space_free(space)
   space = wrp.space_new(space_damping)
   wrp.space_set(space)
   print(colorize("%{blue}physics reseted"))
end




local function render_reset_state()
   pipeline:openPushAndClose('tank', 'clear')
end


local function initBorders()
   local lf = love.filesystem
   local borders_data











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
         table.insert(
         segments,
         wrp.static_segment_new(b.x1, b.y1, b.x2, b.y2))

      end
   else
      print(colorize("${red}" .. "no borders data"))
   end
end

local function spawnPlayer()
   local px, py = screenW / 3, screenH / 2
   playerTank = spawnTank(px, py)

   move_camera2player()


   spawnTank(px + 400, py)
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

   if key == '2' then
      draw_selected_object = not draw_selected_object
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

   pipeline:pushCodeFromFile('dbg_phys', 'dbg_phys.lua')



   pipeline:pushCode("main_axises", [[
    local gr = love.graphics
    --local col = {0.3, 0.5, 1, 1}
    --local col = {0, 0, 0, 1}
    local col = {27. / 255, 94. / 255., 194. / 255}
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
    local linew: integer = 5.

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
    --local color = {0.5, 0.5, 0.5}
    local color = {0.5, 0.9, 0.5}
    while true do
        love.graphics.clear(color)
        coroutine.yield()
    end
    ]])


   pipeline:pushCodeFromFile("debug_vertices", "debug_vertices.lua")



   pipeline:pushCodeFromFile('border_segments', 'border_segments.lua')


end


local function initPipelineObjects()
   Tank.initPipelineObjects(pipeline, camera)

   local dejavu_mono = "DejaVuSansMono.ttf"
   pipeline:openPushAndClose('lines_buf', dejavu_mono, 24)
   pipeline:openPushAndClose('object_lines_buf', dejavu_mono, 30)

   docsystem.init_render_stage2()

   pipeline:openAndClose("debug_vertices")

   pipeline:sync()













end

local function add_keyboard_docs()

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
   docsystem.add_keyboard_doc('2', 'Show or hide selected object border.')
   docsystem.finish_keyboard_docs()

end

local function add_gamepad_docs()

   docsystem.add_gamepad_doc("start", "show this help")
   docsystem.add_gamepad_doc("left shift", "reset camera")
   docsystem.add_gamepad_doc('right shift', 'move camera to player')
   docsystem.add_gamepad_doc('X', 'rotate left')
   docsystem.add_gamepad_doc('B', 'rotate right')
   docsystem.add_gamepad_doc('Y', 'move forward')
   docsystem.add_gamepad_doc('A', 'move backward')
   docsystem.finish_gamepad_docs()

end

local function spawnHangars()
   local corners = getTerrainCorners()
   if corners then
      for _, c in ipairs(corners) do
         spawnHangar(c)
      end
   end
end

local function init()

   print('init started')

   rng:setSeed(300 * 123414)

   metrics.init()
   space = wrp.space_new(space_damping)
   wrp.space_set(space)

   screenW, screenH = pipeline:getDimensions()
   print('screenW, screenH', screenW, screenH)



   camera = PCamera.new(pipeline, screenW, screenH)


   initJoy()

   initRenderCode()

   initPipelineObjects()

   add_keyboard_docs()
   add_gamepad_docs()









   bindFullscreenSwitcher()










   last_render = love.timer.getTime()

   print('init finished')
end

local function quit()

   metrics.quit()
   tanks = {}


end

local stat_push_counter = 0

local function inc_push_counter()
   local prev_value = stat_push_counter
   stat_push_counter = stat_push_counter + 1
   return prev_value
end

local function push_tank_body_stat(object)

   local msg = ""
   local mass, inertia, cog_x, cog_y, pos_x, pos_y, v_x, v_y, force_x, force_y, angle, w, torque =
object:get_body_stat()

   msg = sformat('mass, inertia: %.3f, %.3f', mass, inertia)
   pipeline:push('add', inc_push_counter(), msg)

   msg = sformat('cog (%.3f, %.3f)', cog_x, cog_y)
   pipeline:push('add', inc_push_counter(), msg)

   msg = sformat('position (%.3f, %.3f)', pos_x, pos_y)
   pipeline:push('add', inc_push_counter(), msg)

   msg = sformat('velocity (%.3f, %.3f)', v_x, v_y)
   pipeline:push('add', inc_push_counter(), msg)

   msg = sformat('force (%.3f, %.3f)', force_x, force_y)
   pipeline:push('add', inc_push_counter(), msg)

   msg = sformat('angle, ang. vel.: %.3f, %.3f)', angle, w)
   pipeline:push('add', inc_push_counter(), msg)

   msg = sformat('torque: %.3f', torque)
   pipeline:push('add', inc_push_counter(), msg)

end

local function push_tank_turret_stat(object)

   local msg = ""
   local mass, inertia, cog_x, cog_y, pos_x, pos_y, v_x, v_y, force_x, force_y, angle, w, torque =
object:get_turret_stat()

   msg = sformat('mass, inertia: %.3f, %.3f', mass, inertia)
   pipeline:push('add', inc_push_counter(), msg)

   msg = sformat('cog (%.3f, %.3f)', cog_x, cog_y)
   pipeline:push('add', inc_push_counter(), msg)

   msg = sformat('position (%.3f, %.3f)', pos_x, pos_y)
   pipeline:push('add', inc_push_counter(), msg)

   msg = sformat('velocity (%.3f, %.3f)', v_x, v_y)
   pipeline:push('add', inc_push_counter(), msg)

   msg = sformat('force (%.3f, %.3f)', force_x, force_y)
   pipeline:push('add', inc_push_counter(), msg)

   msg = sformat('angle, ang. vel.: %.3f, %.3f)', angle, w)
   pipeline:push('add', inc_push_counter(), msg)

   msg = sformat('torque: %.3f', torque)
   pipeline:push('add', inc_push_counter(), msg)

end

local function mousemoved(x, y, dx, dy)
   metrics.mousemoved(x, y, dx, dy)



   local absx, absy = camera:fromLocal(x, y)


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
      pipeline:push('add', inc_push_counter(), 'object ' .. tostring(object))

      msg = sformat('point (%.3f, %.3f)', shape_x, shape_y)
      pipeline:push('add', inc_push_counter(), msg)

      pipeline:push('add', inc_push_counter(), 'distance ' .. dist)
      pipeline:push('add', inc_push_counter(), sformat('gradient (%.3f, %.3f)', gradx, grady))

      pipeline:push('add', inc_push_counter(), "----------")


      push_tank_body_stat(object)
      pipeline:push('add', inc_push_counter(), "----------")
      push_tank_turret_stat(object)

      pipeline:push('enough')
      pipeline:close()


   end)

   if counter == 0 then
      pipeline:openPushAndClose('object_lines_buf', 'clear')
   end
   stat_push_counter = 0




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
      camera:reset()
   end
   if button == right_shift then
      move_camera2player()
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






local function applyInput(j)

   if not j or not playerTank then
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

   local fire_value = j:getAxis(joy_conf.fire_axis)
   if fire_value > fire_threshold then
      camera:attach()
      playerTank:fire()
      camera:detach()
   end

   local hut_num = 1



   local hut = j:getHat(hut_num)


   if hut == "l" then
      playerTank:rotate_turret("left")
   elseif hut == "r" then
      playerTank:rotate_turret("right")
   end






   if joyState.state then


   end
end

local stateCoro = coroutine.create(function(dt)

   initBorders()
   spawnHangars()
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
         local px, py
         if playerTank then




            px, py = playerTank.base:get_position()
         end
         camera:update(dt, px, py)


         if not physics_pause then
            wrp.space_step(dt);
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
   wrp.space_free(space)
   main_channel:push('quit')
   debug_print('thread', 'Thread resources are freed')
end

debug_print('thread', colorize('%{yellow}<<<<<%{reset} t80 finished'))
