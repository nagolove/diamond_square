-- vim: set colorcolumn=85
-- vim: fdm=marker

--local debug_print = print
local dprint = require 'debug_print'
local debug_print = dprint.debug_print

dprint.set_filter { 
    [1] = { "joy" },
    [2] = { 'phys' },
    [3] = { "thread", 'someName' },
    [4] = { "graphics" },
    [5] = { "input" },
    [6] = { "verts" },
    --[7] = { "phys" },
    --[8] = { "phys" },
    --[9] = { "phys" },
    --[0] = { "phys" },
}
--]]

local colorize = require 'ansicolors2'.ansicolors
debug_print('thread', colorize('%{yellow}>>>>>%{reset} diamond_square started'))

require "love_inc".require_pls_nographic()

debug_print('thread', 'love.filesystem.getRequirePath()', love.filesystem.getRequirePath())

local require_path = "scenes/diamond_square/?.lua;?.lua;?/init.lua;"

love.filesystem.setRequirePath(require_path)
love.filesystem.setCRequirePath("scenes/diamond_square/?.so;?.so")

print('require_path', require_path)
print('getCRequirePath()', love.filesystem.getCRequirePath())
print("package.cpath", package.cpath)
print('getWorkingDirectory', love.filesystem.getWorkingDirectory())

require "love"
require 'pipeline'
require "common"

--local tween = require 'tween'
--local camMoveTween = tween.new()

local fromPolar = require 'vector-light'.fromPolar
local sformat = string.format
local inspect = require "inspect"
--local serpent = require 'serpent'
--local i18n = require "i18n"
--local vec2 = require "vector"

local Pipeline = require 'pipeline'
SCENE_PREFIX = "scenes/diamond_square"
local pipeline = Pipeline.new(SCENE_PREFIX)

local yield, resume = coroutine.yield, coroutine.resume

local enum State 
    'map'
end

local state: State = 'map'

local screenW, screenH: number, number

local coroutines: {thread} = {}

local seed = 300 * 123414
local rng1: love.math.RandomGenerator = love.math.newRandomGenerator(os.time())
rng1:setSeed(seed)

local rng2: love.math.RandomGenerator = love.math.newRandomGenerator(os.time())
rng2:setSeed(seed)

local rng3: love.math.RandomGenerator = love.math.newRandomGenerator(os.time())
rng3:setSeed(seed)

local rng4: love.math.RandomGenerator = love.math.newRandomGenerator(os.time())
rng4:setSeed(seed)

local DiamonAndSquare_lua = require 'diamondsquare'
local DiamonAndSquare_c = require 'diamondsquare_c'

local function randomWrapper1(): number
    return rng1:random()
end

local function randomWrapper2(): number
    return rng2:random()
end

local function randomWrapper3(): number
    return rng3:random()
end

local function randomWrapper4(): number
    return rng4:random()
end

local generators: {DiamonAndSquare_lua} = {}
local dim = 6

local function initGenerators()
    local gen: DiamonAndSquare_lua

    gen = DiamonAndSquare_lua.new(dim, randomWrapper1, pipeline)
    table.insert(generators, gen)

    -- Сопрограмма-обертка, в ней должен быть таймер с проверкой.
    --[[
    local function generator_wrapper()
        -- {{{
        local thread: thread
        local ok, errmsg = pcall(function()
        thread = gen:newCoroutine()
        end) as (boolean, string)
        if not ok then
            print('errmsg', errmsg)
        end
        --local stop = false
        print('coro was started')
        --repeat
            --stop = coroutine.resume(thread)
            --print('stop', stop)
            --yield()
        --until stop
        print('coro was finished')
        -- }}}
    end
    --]]

    --[[
    -- Пример с корутиной
    local module = require 'diamondsquare_coro'
    gen = module.new(dim, randomWrapper2, pipeline) as DiamonAndSquare_lua
    table.insert(coroutines, coroutine.create(generator_wrapper))
    --gen:setRez(30)
    gen:setPosition(0., 400.)
    table.insert(generators, gen)
    --]]

    --[[
    -- Пример референсной реализации, должен визуально совпадать с результатом 
    -- первого генератора
    gen = DiamonAndSquare_lua.new(dim, randomWrapper4, pipeline)
    gen:setPosition(400, 400)
    table.insert(generators, gen)
    --]]

    -- Какие есть идеи для наследования записей в Teal?
    gen = DiamonAndSquare_c.new(dim, randomWrapper3, pipeline) as DiamonAndSquare_lua
    gen:setPosition(800., 0.)
    table.insert(generators, gen)
end

local event_channel = love.thread.getChannel("event_channel")
local main_channel = love.thread.getChannel("main_channel")

local last_render: number = love.timer.getTime()

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

    -- Ландшафт
    for _, gen in ipairs(generators) do
        gen:render()
    end

    -- Оси на экране из (0, 0)
    --pipeline:openAndClose('main_axises')

    pipeline:openAndClose('welcome_text')

    -- Инфа об объекте под мышкой
    --pipeline:openPushAndClose('object_lines_buf', 'flush')

    -- Оси через центр экрана
    --camera:draw_axises()
    --]]
end

local function renderScene()
    local nt = love.timer.getTime()
    -- Ограничение кадров в секунду до 300
    local fps_limit = 1. / 300.
    local diff = nt - last_render

    if diff >= fps_limit then
        last_render = nt
        render_internal()

        -- Рисование не должно быть блокирующим.
        -- На стороне рендера должен сохраняться весь контекст кадра.
        -- Если каких-то данных ждать слишком долго, то рисовать то, что есть
        -- в буфере рендера.
        pipeline:sync()
    end
end

-- Нарисовать параметр размера карты в буфер отладочных строк.
local function lines_buf_push_mapn()
    --pipeline:open('lines_buf')
    --pipeline:push("add", 'mapn', "mapn: " .. diamondSquare.mapn)
    ----pipeline:push('enough')
    --pipeline:push('flush')
    --pipeline:close()
end

-- Клавиши для управления генератором ландшафта.
local function processLandscapeKeys(key: string)
    -- Имеет смысл перенести в imgui?

    if key == 'r' then
        --initGenerators()
        for _, gen in ipairs(generators) do
            gen:reset()
            gen:eval()
            gen:send2render()
        end
        --]]
    end

    --[[
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
    --]]

end

local function changeWindowMode()
    --if love.window.getFullscreen() then
    love.window.setFullscreen(not love.window.getFullscreen())
end

local function keypressed(key: string)
    -- {{{
    print('keypressed', key)

    if key == "escape" then
        is_stop = true
        debug_print('input', colorize('%{blue}escape pressed'))
    end

    processLandscapeKeys(key)

    --[[
    if key == 'f1' then
        is_draw_hotkeys_docs = not is_draw_hotkeys_docs
        if is_draw_hotkeys_docs then
            is_draw_gamepad_docs = false
        end
    elseif key == 'f11' then
        changeWindowMode()
    end
    --]]

end

local function initRenderCode()
    -- {{{
    -- рисовать ортогональные оси координат в левом верхнем углу экрана
    -- {{{
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
    -- }}}
   
    -- Буфер для вывода отладочной информации в левом верхнем углу экрана.
    --pipeline:pushCodeFromFile('lines_buf', 'lines_buf.lua')
    -- Буфер для вывода отладочной информации при наведении на физическое тело.
    --pipeline:pushCodeFromFile('object_lines_buf', 'lines_buf.lua')

    -- Очистка экрана
    -- {{{
    pipeline:pushCode('clear', [[
    local color = {0.5, 0.5, 0.5}
    --local color = {0.5, 0.9, 0.5}
    while true do
        love.graphics.clear(color)
        coroutine.yield()
    end
    ]])
    -- }}}

    pipeline:pushCodeFromFileRoot('labels', 'rdr_labels.lua')

    pipeline:pushCode('welcome_text', [[
    local gr = love.graphics
    local fnt = gr.newFont(SCENE_PREFIX .. "/DejaVuSansMono.ttf", 32)
    while true do
        local x0, y0 = 0, 0
        gr.setColor{1, 0, 0, 1}
        gr.setFont(fnt)
        gr.print("Тестовый стенд алгоритма генерации ландшафта.", x0, y0)
        y0 = y0 + fnt:getHeight()
        gr.print("Для пересоздания нажми 'r'", x0, y0)

        gr.setColor{0, 1, 0, 1}
        gr.print("Lua reference(1) 1", 0, 30)
        gr.print("C implemetation 2", 400, 30)
        gr.print("Lua coroutine 3", 0, 400)
        gr.print("Lua reference(2) 4", 400, 400)

        coroutine.yield()
    end
    ]])

    -- }}}
end

-- {{{ Labels
local labels = {
    { 
        labels = "title1", 
        x = 0, 
        y = 0,
    },
    { 
        labels = "other title", 
        x = 500, 
        y = 0,
    },
    { 
        labels = "I am a cow", 
        x = 0, 
        y = 600,
    },
}
-- }}}

-- Инициализация параметрами объектов-корутин на стороне главного потока.
local function initPipelineObjects()
    --local dejavu_mono = "DejaVuSansMono.ttf"

    --pipeline:openPushAndClose('lines_buf', dejavu_mono, 24)
    --pipeline:openPushAndClose('object_lines_buf', dejavu_mono, 30)
    --pipeline:openAndClose("debug_vertices")

    --pipeline:openPushAndClose('labels', serpent.dump(labels) as string)

    pipeline:sync()
end

local function init()
    -- {{{
    print('init started')

    screenW, screenH = pipeline:getDimensions()
    print('screenW, screenH', screenW, screenH)

    -- Загрузка удаленного кода для рисования
    initRenderCode()
    -- Дополнительная инициализация объектов рисовки.
    initPipelineObjects()

    last_render = love.timer.getTime()
    initGenerators()

    print('init finished')
    -- }}}
end

local function quit()
end

local stat_push_counter = 0

local function inc_push_counter(): integer
    local prev_value = stat_push_counter
    stat_push_counter = stat_push_counter + 1
    return prev_value
end

local function mousemoved(_: number, _: number, _: number, _: number)
end

local function wheelmoved(_: number, _: number)
end

--[[
Сделать передвижение камеры по зажатию средней клавиши мыши.
--]]
local function mousepressed(_: number, _: number, _: integer)
    -- {{{
    -- }}}
end

local function process_events()
    local events = event_channel:pop() as {any}
    if events then
        for _, e in ipairs(events) do
            local evtype: string = (e as {string})[1]
            if evtype == "mousemoved" then

                local x, y = (e as {number})[2], (e as {number})[3]
                local dx, dy = (e as {number})[4], (e as {number})[5]
                mousemoved(x, y, dx, dy)

            elseif evtype == 'wheelmoved' then

                local x, y = (e as {number})[2], (e as {number})[3]
                wheelmoved(x, y)

            elseif evtype == "keypressed" then
                local key = (e as {string})[2]
                local scancode = (e as {string})[3]

                local msg = '%{green}keypressed '
                debug_print('input', colorize(msg .. key .. ' ' .. scancode))

                if love.keyboard.isDown('lshift') then
                    dprint.keypressed(scancode)
                end

                -- Использовать scancode или key?
                keypressed(scancode)

                --msg = '%{yellow}keypressed '
                --print(colorize(msg .. key .. ' ' .. scancode))

            elseif evtype == "mousepressed" then
                local x, y = (e as {number})[2], (e as {number})[3]
                local btn = (e as {integer})[4]
                mousepressed(x, y, btn)
            end
        end
    end
end

local function processCoroutines()
    local alive: {thread} = {}
    for _, thread in ipairs(coroutines) do
        local ok = coroutine.resume(thread)
        if ok then
            table.insert(alive, thread)
        end
    end
    coroutines = alive
end

local stateCoro: thread = coroutine.create(function(dt: number)

    for _, gen in ipairs(generators) do
        gen:eval()
        gen:send2render()
    end

    while true do
    -- {{{
        if state == 'map' then
            process_events()
            renderScene()

            --processCamera(dt)
            processCoroutines();

            dt = yield() as number
        end
        --print('state', state)
    -- }}}
    end
end)

local function mainloop()
    local last_time = love.timer.getTime()
    while not is_stop do
        local now_time = love.timer.getTime()
        local dt = now_time - last_time
        last_time = now_time

        local ok, errmsg = resume(stateCoro, dt) as (boolean, string)
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
