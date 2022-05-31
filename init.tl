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
debug_print('thread', colorize('%{yellow}>>>>>%{reset} t80 started'))

require "love_inc".require_pls_nographic()

debug_print('thread', 'love.filesystem.getRequirePath()', love.filesystem.getRequirePath())

local require_path = "scenes/t80/?.lua;?.lua;?/init.lua;"

love.filesystem.setRequirePath(require_path)
love.filesystem.setCRequirePath("scenes/t80/?.so;?.so")

print('require_path', require_path)
print('getCRequirePath()', love.filesystem.getCRequirePath())
print("package.cpath", package.cpath)
print('getWorkingDirectory', love.filesystem.getWorkingDirectory())

-- TODO Диалог для настройки клавиш геймпада
local joy_conf = require 'joy_conf'
local fire_threshold = 0.5

require "love"
require 'konstants'
require 'pipeline'
require "common"

--local tween = require 'tween'
--local camMoveTween = tween.new()

local fromPolar = require 'vector-light'.fromPolar
local sformat = string.format
local inspect = require "inspect"
--local serpent = require 'serpent'
--local i18n = require "i18n"
local metrics = require "metrics"
--local vec2 = require "vector"
local vecl = require "vector-light"

-- Вывод в строку
--local tabular = require "tabular".show

local Pipeline = require 'pipeline'
local pipeline = Pipeline.new(SCENE_PREFIX)

-- рисование стрелочек векторов
local arrow = require 'arrow'
arrow.init(pipeline)

--local Shortcut = KeyConfig.Shortcut

--local abs, pow, sqrt = math.abs, math.pow, math.sqrt
--local abs = math.abs
local yield, resume = coroutine.yield, coroutine.resume

local enum State 
    'garage'
    'map'
end

local state: State = 'map'

local screenW, screenH: number, number

local coroutines: {thread} = {}
--local stickObj: wrp.Stick

local rng: love.math.RandomGenerator = love.math.newRandomGenerator()

local DiamonAndSquare = require 'diamondsquare'
--local DiamonAndSquare = require 'diamondsquare_c'

local function randomWrapper(): number
    return rng:random()
end

local diamondSquare: DiamonAndSquare = DiamonAndSquare.new(
    5, 
    randomWrapper,
    pipeline
)

--local diamondSquare: DiamonAndSquare = DiamonAndSquare.new(13, rng, pipeline)
--local diamondSquare: DiamonAndSquare = DiamonAndSquare.new(8, rng, pipeline)

--local loadCannonSound = Audio.newSource(SCENE_PREFIX .. "/load.wav", 'static')
--local audMainTheme = Audio.newSource(SCENE_PREFIX .. "/audio/Lime of Adventure.mp3", 'static')

local event_channel = love.thread.getChannel("event_channel")
local main_channel = love.thread.getChannel("main_channel")

local last_render: number = love.timer.getTime()

local PCamera = require "pcamera"
local camera: PCamera

local lj = love.joystick
local Joystick = lj.Joystick
local joyState: JoyState
local joy: Joystick

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

    camera:attach()

    -- Ландшафт
    diamondSquare:render()

    -- Оси на экране из (0, 0)
    pipeline:openAndClose('main_axises')

    -- Инфа об объекте под мышкой
    pipeline:openPushAndClose('object_lines_buf', 'flush')

    camera:detach()

    pipeline:openPushAndClose('joy_stick', stick_x, stick_y)

    -- Строчки с отладочной инфой.
    renderLinesBuf(player_x, player_y)

    -- Оси через центр экрана
    --camera:draw_axises()
    --]]

    camera:draw_bbox()
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
    if not diamondSquare then
        return
    end
    pipeline:open('lines_buf')
    pipeline:push("add", 'mapn', "mapn: " .. diamondSquare.mapn)
    --pipeline:push('enough')
    pipeline:push('flush')
    pipeline:close()
end

-- Клавиши для управления генератором ландшафта.
local function processLandscapeKeys(key: string)
    -- Имеет смысл перенести в imgui?

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
    pipeline:pushCodeFromFile('dbg_phys', 'rdr_dbg_phys.lua')

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
    pipeline:pushCodeFromFile('lines_buf', 'lines_buf.lua')
    -- Буфер для вывода отладочной информации при наведении на физическое тело.
    pipeline:pushCodeFromFile('object_lines_buf', 'lines_buf.lua')
    docsystem.init_render_stage1(pipeline)

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

    -- }}}
end

-- Инициализация параметрами объектов-корутин на стороне главного потока.
local function initPipelineObjects()
    Tank.initPipelineObjects(pipeline, camera)

    local dejavu_mono = "DejaVuSansMono.ttf"
    pipeline:openPushAndClose('lines_buf', dejavu_mono, 24)
    pipeline:openPushAndClose('object_lines_buf', dejavu_mono, 30)

    docsystem.init_render_stage2()

    pipeline:openAndClose("debug_vertices")

    pipeline:sync()

    --[[
    -- {{{
    pipeline:openPushAndClose(
        'lines_buf',                -- coroutine object name
        "add",                      -- object command
        'hi',                       -- message id
        "привет из недр движка",    -- message(payload)
        "flush"                     -- render buffer and break waiting cycle
    )
    -- }}}
    --]]

end

local function init()
    -- {{{
    print('init started')

    -- Начальное значение генератора для определенной карты
    rng:setSeed(300 * 123414)

    metrics.init()

    screenW, screenH = pipeline:getDimensions()
    print('screenW, screenH', screenW, screenH)

    -- Требует инициализации после создания объекта pipeline, но до функций
    -- init*
    camera = PCamera.new(pipeline, screenW, screenH)

    -- Загрузка удаленного кода для рисования
    initRenderCode()
    -- Дополнительная инициализация объектов рисовки.
    initPipelineObjects()

    bindFullscreenSwitcher()

    -- }}}
    last_render = love.timer.getTime()

    print('init finished')
end

local function quit()
    metrics.quit()
end

local stat_push_counter = 0

local function inc_push_counter(): integer
    local prev_value = stat_push_counter
    stat_push_counter = stat_push_counter + 1
    return prev_value
end

local function mousemoved(x: number, y: number, dx: number, dy: number)
    metrics.mousemoved(x, y, dx, dy)
end

local function wheelmoved(x: number, y: number)
    metrics.wheelmoved(x, y)
end

--[[
Сделать передвижение камеры по зажатию средней клавиши мыши.
--]]
local function mousepressed(x: number, y: number, btn: integer)
    -- {{{
    metrics.mousepressed(x, y, btn)
    -- }}}
end

local function joystickpressed(_: Joystick, button: integer)
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

            elseif evtype == "joystickpressed" then
                local joystick = (e as {number})[2] as Joystick
                local button = (e as {number})[3] as integer
                joystickpressed(joystick, button)
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

    diamondSquare:eval()
    diamondSquare:send2render()
    --lines_buf_push_mapn()

    while true do
    -- {{{
        if state == 'map' then
            process_events()
            renderScene()

            ------------ UPDATE HERE PLEASE ------------ 
            --arena:update()

            processCamera(dt)
            processCoroutines();

            applyInput(joy)

            dt = yield() as number
        elseif state == 'garage' then
            --coroutine.yield()
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
    print('space', space)
    wrp.space_free(space)
    main_channel:push('quit')
    debug_print('thread', 'Thread resources are freed')
end

debug_print('thread', colorize('%{yellow}<<<<<%{reset} t80 finished'))
