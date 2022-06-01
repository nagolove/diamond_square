local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local package = _tl_compat and _tl_compat.package or package; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table



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
debug_print('thread', colorize('%{yellow}>>>>>%{reset} diamond_square started'))

require("love_inc").require_pls_nographic()

debug_print('thread', 'love.filesystem.getRequirePath()', love.filesystem.getRequirePath())

local require_path = "scenes/diamond_square/?.lua;?.lua;?/init.lua;"

love.filesystem.setRequirePath(require_path)
love.filesystem.setCRequirePath("scenes/diamond_square/?.so;?.so")

print('require_path', require_path)
print('getCRequirePath()', love.filesystem.getCRequirePath())
print("package.cpath", package.cpath)
print('getWorkingDirectory', love.filesystem.getWorkingDirectory())

require("love")
require('pipeline')
require("common")




local fromPolar = require('vector-light').fromPolar
local sformat = string.format
local inspect = require("inspect")




local Pipeline = require('pipeline')
local pipeline = Pipeline.new(SCENE_PREFIX)

local yield, resume = coroutine.yield, coroutine.resume

local State = {}




local state = 'map'

local screenW, screenH

local coroutines = {}


local rng = love.math.newRandomGenerator()

local DiamonAndSquare = require('diamondsquare')


local function randomWrapper()
   return rng:random()
end

local diamondSquare = DiamonAndSquare.new(
5,
randomWrapper,
pipeline)








local event_channel = love.thread.getChannel("event_channel")
local main_channel = love.thread.getChannel("main_channel")

local last_render = love.timer.getTime()

local is_stop = false

local function print_fps()
   local msg = sformat("fps %d", love.timer.getFPS())
   pipeline:push('add', 'fps', msg)
end

local function print_io_rate()
   local bytes = pipeline:get_received_in_sec()
   local msg = sformat("передано за секунду Килобайт = %d", math.floor(bytes / 1024))
   pipeline:push('add', 'data_received', msg)
end

local function render_internal()
   pipeline:openAndClose('clear')


   diamondSquare:render()


   pipeline:openAndClose('main_axises')


   pipeline:openPushAndClose('object_lines_buf', 'flush')




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
         diamondSquare = DiamonAndSquare.new(mapn, randomWrapper, pipeline)
         diamondSquare:eval()
         diamondSquare:send2render()
         lines_buf_push_mapn()
      end
   end

   if key == 'x' then
      local mapn = diamondSquare.mapn + 1
      if mapn <= 10 then
         diamondSquare = DiamonAndSquare.new(mapn, randomWrapper, pipeline)
         diamondSquare:eval()
         diamondSquare:send2render()
         lines_buf_push_mapn()
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












end

local function initRenderCode()



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









   pipeline:pushCode('clear', [[
    local color = {0.5, 0.5, 0.5}
    --local color = {0.5, 0.9, 0.5}
    while true do
        love.graphics.clear(color)
        coroutine.yield()
    end
    ]])



end


local function initPipelineObjects()
   local dejavu_mono = "DejaVuSansMono.ttf"
   pipeline:openPushAndClose('lines_buf', dejavu_mono, 24)
   pipeline:openPushAndClose('object_lines_buf', dejavu_mono, 30)
   pipeline:openAndClose("debug_vertices")

   pipeline:sync()
end

local function init()

   print('init started')


   rng:setSeed(300 * 123414)

   screenW, screenH = pipeline:getDimensions()
   print('screenW, screenH', screenW, screenH)


   initRenderCode()

   initPipelineObjects()


   last_render = love.timer.getTime()

   print('init finished')
end

local function quit()
end

local stat_push_counter = 0

local function inc_push_counter()
   local prev_value = stat_push_counter
   stat_push_counter = stat_push_counter + 1
   return prev_value
end

local function mousemoved(x, y, dx, dy)
end

local function wheelmoved(x, y)
end




local function mousepressed(x, y, btn)


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
         end
      end
   end
end

local function processCoroutines()
   local alive = {}
   for _, thread in ipairs(coroutines) do
      local ok = coroutine.resume(thread)
      if ok then
         table.insert(alive, thread)
      end
   end
   coroutines = alive
end

local stateCoro = coroutine.create(function(dt)

   diamondSquare:eval()
   diamondSquare:send2render()


   while true do

      if state == 'map' then
         process_events()
         renderScene()


         processCoroutines();

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
   main_channel:push('quit')
   debug_print('thread', 'Thread resources are freed')
end

debug_print('thread', colorize('%{yellow}<<<<<%{reset} diamond_square finished'))
