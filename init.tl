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

local wrp = require "wrp"
-- TODO Диалог для настройки клавиш геймпада
local joy_conf = require 'joy_conf'
local fire_threshold = 0.5

require "love"
require 'konstants'
require 'pipeline'
require "common"
require "Timer"
-- Логотип, картинка или главное меню?
require 'logo'
-- Доработка keyconfig для джойстика
require "keyconfig"

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

local docsystem = require 'doc-system'

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

local Tank = require 'tank'

local screenW, screenH: number, number

local space: wrp.Space
local space_damping = 0.02

-- Все танки, в том числе и тот, которым управляет игрок.
local tanks: {Tank} = {}

local Hangar = require 'hangar'

-- Ангары(точки для ремонта, также точки появления техники
local hangars: {Hangar} = {}

-- Танк, которым управляет игрок
local playerTank: Tank

--local stickObj: wrp.Stick

local record Borders
    x1: number
    y1: number
    x2: number
    y2: number
end

local stick_x, stick_y = 0., 0.

local rng: love.math.RandomGenerator = love.math.newRandomGenerator()

--local DiamonAndSquare = require 'diamondsquare'
local DiamonAndSquare = require 'diamondsquare_c'
--local diamondSquare: DiamonAndSquare = DiamonAndSquare.new(5, rng, pipeline)
local diamondSquare: DiamonAndSquare = DiamonAndSquare.new(13, rng, pipeline)
--local diamondSquare: DiamonAndSquare = DiamonAndSquare.new(8, rng, pipeline)

--local loadCannonSound = Audio.newSource(SCENE_PREFIX .. "/load.wav", 'static')
--local audMainTheme = Audio.newSource(SCENE_PREFIX .. "/audio/Lime of Adventure.mp3", 'static')

local event_channel = love.thread.getChannel("event_channel")
local main_channel = love.thread.getChannel("main_channel")

local last_render: number = love.timer.getTime()

local PCamera = require "pcamera"
local camera: PCamera

-- Границы в которых создаются танки
-- Сделать сохраняемыми и загружаемыми из файла.
local bordersArea: Borders = {}
--local borders: {Borders} = {}

local segments: {wrp.Shape} = {}

local JoyState = require 'joystate'
local DummyJoyState = require 'dummyjoystate'

local lj = love.joystick
local Joystick = lj.Joystick
local joyState: JoyState
local joy: Joystick

local OBJT_ERROR            = 0
local OBJT_TANK             = 1
local OBJT_TANK_STICK       = 2
local OBJT_BULLET           = 4
local OBJT_SEGMENT          = 8
local OBJT_HANAGR           = 16

local draw_selected_object = true

local spawn_only_player = true
--local spawn_only_player = false

local is_stop = false
local is_physics_paused = false
local is_draw_hotkeys_docs = false
local is_draw_gamepad_docs = false
local is_draw_debug_phys = true

--local min_angle = 1000.
--local max_angle = -19999.
local last_angle = 0.
--local last_tur_angle = 0.

local function initJoy()
    for _, j in ipairs(lj.getJoysticks()) do
        debug_print("joy", colorize('%{green}' .. inspect(j)))
    end
    joy = lj.getJoysticks()[1]
    if joy then
        debug_print("joy", colorize('%{green}avaible ' .. joy:getButtonCount() .. ' buttons'))
        debug_print("joy", colorize('%{green}hats num: ' .. joy:getHatCount()))
        joyState = JoyState.new(joy)
    else 
        joyState = DummyJoyState.new(joy) as JoyState
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

-- возвращает массив со значениями координат углов ландшафта в метрах по часовой
-- стрелке от левого верхнего угла.
function getTerrainCorners(): {vector}
end

local function spawnHangar(x: number, y: number): Hangar
    local hangar = Hangar.new(x, y, 0.)
    table.insert(hangars, hangar)
    return hangar
end

local function on_each_body_t(
    x: number, y: number, angle: number, obj: any,
    tur_x: number, tur_y: number, tur_angle: number,
    _: {{number}}
)
    local tank = obj as Tank

    if type(tank) ~= "table" then
        error("tank should be a table, not a " .. type(tank))
    end

    --[[
    -- {{{
    print(
        colorize("%{red}on_each_body_t: %{reset}"),
        "\n     tank.id", tank.id,
        "\n     x", x,
        "\n     y", y,
        "\n     angle", angle, 
        "\n     obj", obj, 
        "\n     tur_x", tur_x, 
        "\n     tur_y", tur_y, 
        "\n     tur_angle", tur_angle
    )
    -- }}}
    --]]

    if tank then
        pipeline:push('new_t', tank.id, x, y, angle, tur_x, tur_y, tur_angle)
    end
end

--[[
local function on_each_body(x: number, y: number, angle: number, obj: any)
    local tank = obj as Tank

    if type(tank) ~= "table" then
        error("tank should be a table, not a " .. type(tank))
    end

    if tank then
        pipeline:push('new', tank.id, x, y, angle)
    end
    --print('lua: on_each_body')
    --print('id, x, y, angle', tank.id, x, y, angle)
    --print('tank.id', tank.id)
end
--]]

local function renderSegments()
    pipeline:open('border_segments')
    wrp.static_segments_draw(
        function(x1: number, y1: number, x2: number, y2:number)
            pipeline:push('draw', x1, y1, x2, y2)
        end
    )
    pipeline:push('flush')
    pipeline:close()
end

local function debug_draw_vertices(
    _: number, _: number, _: number, _: any,
    _: number, _: number, _: number,
    debug_vertices: {{number}}
)
    if debug_vertices then
        pipeline:push("new")

        print(colorize("%{yellow}debug_draw_vertices"))

        --pipeline:push("new", 2, 'enough')

        --pipeline:push(2)
        --pipeline:push({ 1, 2, 4, 5, 100, 100})
        --pipeline:push({ 10, 20, 40, 50, 10, 10})

        pipeline:push(#debug_vertices)
        for i = 1, #debug_vertices do
            pipeline:push(debug_vertices[i])
        end
        --]]
    else
        --print("no debug vertices.")
    end
end

local function move_camera2player()
    if playerTank then
        local px, py = playerTank.base:get_position()
        print('camera was centered to', px, py)
        camera:moveTo(px, py)
    end
end

local function renderTanks()

    pipeline:open('tank')
    -- Сделать разумное описание ограничивающего прямоугольника
    wrp.space_query_bb_type(-30000, 30000, 30000, -30000, OBJT_TANK,
        on_each_body_t)
    pipeline:push('flush')
    pipeline:close()

    --pipeline:open("debug_vertices")
    --wrp.query_all_tanks_t(debug_draw_vertices)
    --pipeline:push('enough')
    --pipeline:close()
end

local function renderSelectedObject(): number, number
    local player_x, player_y, player_angle: number, number, number
    if playerTank then
        local body = playerTank.base
        player_x, player_y, player_angle = body:get_position()
        if draw_selected_object then
            pipeline:open('selected_object')
            --pipeline:push(body:get_position())
            pipeline:push(player_x, player_y, player_angle)
            pipeline:close()
        end
    else
        error('Player should not be nil')
    end
    return player_x, player_y
end

local function renderLinesBuf(player_x: number, player_y: number)
    pipeline:open('lines_buf')
    print_io_rate()
    print_fps()
    camera:push2lines_buf()
    local msg = sformat("player pos (%.3f, %.3f)", player_x, player_y)
    pipeline:push("add", "player_pos", msg)

    if joy then
        local axes = {joy:getAxes()}
        msg = table.concat(axes, ",")
        pipeline:push("add", 'joy_axes', msg)
    end
    
    -- Верно-ли, что здесь единственный вызов flush() для данного объекта в
    -- кадре?
    pipeline:push('flush')

    pipeline:close()
end

local function phys_dbg_draw()
    pipeline:open("dbg_phys")
    wrp.space_debug_draw(
        function(px: number, py: number, angle: number, rad: number)
            --print('px, py, angle, rad:', px, py, angle, rad)
            --pipeline:push('circle', px, py, angle, rad)
            pipeline:push('circle', px, py, rad, angle)
        end,
        function(ax: number, ay: number, bx: number, by: number)
            pipeline:push('segment', ax, ay, bx, by)
        end,
        function(ax: number, ay: number, bx: number, by: number, rad: number)
            pipeline:push('fatsegment', ax, ay, bx, by, rad)
        end,
        function(polygon: {number}, rad: number)
            pipeline:push('polygon', polygon, rad)
        end,
        function(size: number, px: number, py: number)
            pipeline:push('dot', size, px, py)
        end
    )
    pipeline:push("enough")
    pipeline:close()
end

local function render_internal()
    pipeline:openAndClose('clear')

    camera:attach()

    -- Ландшафт
    diamondSquare:render()

    -- Танки
    renderTanks()

    if is_draw_debug_phys then
        phys_dbg_draw()
    end

    -- Ограничители уровня, преграды в виде отрезков.
    renderSegments()

    -- Выделенный объект - управляемый игроком
    local player_x, player_y = renderSelectedObject()

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
    -- Ограничение кадров в секунду до 300
    local fps_limit = 1. / 300.
    local diff = nt - last_render

    if diff >= fps_limit then
        last_render = nt
        render_internal()

        --local ok, errmsg: boolean, string = pcall(render_internal)
        --if not ok then
            --print('renderScene:' .. errmsg)
            --os.exit(10)
        --end

        -- Рисование не должно быть блокирующим.
        -- На стороне рендера должен сохраняться весь контекст кадра.
        -- Если каких-то данных ждать слишком долго, то рисовать то, что есть
        -- в буфере рендера.
        pipeline:sync()
    end
end

local function updateTanks()
    -- {{{
    local alive: {Tank} = {}
    for _, tank in ipairs(tanks) do
        local t =  tank:update()
        if t then
            table.insert(alive, t)
        else
            print('---------------')
        end
    end
    tanks = alive
    -- }}}
end

-- Не добавляет в таблицу рисовки на стороне потока рендера.
-- Необходимо проверять - есть ли другой танк под текущей точкой. Принимать во
-- внимание ширину, высоту объекта и некоторый запас, 5-10 пикселей.
local function spawnTank(px: number, py: number): Tank
    --local tank = Tank.new(vec2(px, py), tank_width, tank_height)
    --init_table.x, init_table.y = math.floor(px), math.floor(py);
    local tank = Tank.new(px, py)
    --local tank = Tank.new(init)
    print("tank", inspect(tank))
    table.insert(tanks, tank)
    local tank_x, tank_y, angle = tank.base:get_position()
    local turret_x, turret_y, turret_angle = tank.base:turret_get_pos()

    --print(colorize(
        --"%{magenta}" .. 'body type: ' .. wrp.get_body_type(tank.base)
    --))

    print(colorize("%{yellow}spawnTank:%{reset}"),
        "\n     tank.id", tank.id, 
        "\n     tank_x", tank_x, 
        "\n     tank_y", tank_y, 
        "\n     angle", angle, 
        "\n     turret_x", turret_x, 
        "\n     turret_y", turret_y, 
        "\n     turret_angle", turret_angle
    )

    -- Эти значения используются в C модуле для определения на сколько
    -- сдвинулся объект с момента предыдущей обработки.
    --[[
    -- {{{
    tank._prev_x, tank._prev_y = tank_x, tank_y
    pipeline:openPushAndClose(
        'base_shape',
        'new_t', 
        tank.id, 
        tank_x, tank_y, angle, 
        turret_x, turret_y, turret_angle,
        "flush"
    )
    -- }}}
    --]]

    return tank
end

local function spawnTanks()

    --[[
    Если больше 150 объектов, то начинается периодическое мелькание.
    Расчитать количество передаваемых данных за кадр и в среднем за секунду
    которое приводит к мельканию.
    --]]
    local tanks_num = 2
    --local tanks_num = 100

    local minx, maxx = 0, 4000
    local miny, maxy = 0, 4000

    bordersArea.x1, bordersArea.y1 = minx, miny
    bordersArea.x2, bordersArea.y2 = maxx, maxy

    -- Генерация танков проводится после генерации карты.
    -- Сперва создавать танки NPC случайным образом в подходящих местах карты.
    -- Затем добавить ангары.

    --local rad = 1000
    for _ = 1, tanks_num do
        --local px, py = rng:random(minx, maxx), rng:random(miny, maxy)
        --local p = vec2.fromPolar(rng:random() * 2 * math.pi, rad)
        --spawnTank(p.x, p.y)
    end

    --spawnTank(-100, 100)
    local w, h = 256, 256

    if not spawn_only_player then
        spawnTank(-w / 70, - h / 70)
        spawnTank(380, 100)
        spawnTank(screenW / 2, screenH / 2)
    end

    --pipeline:push('enough')
    --pipeline:close()
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

-- Сброс физики - удаление пространства, всех тел и фигур
local function physics_reset()
    -- Здесь должны удаляться все тела. Значит необходимо пересоздать все
    -- структуры данных на lua стороне во избежании использования ссылок на
    -- старые данные
    wrp.space_free(space)
    space = wrp.space_new(space_damping)
    wrp.space_set(space)
    print(colorize("%{blue}physics reseted"))
end

-- Сброс состояния рендера. 
--[[ 
Посылаются сообщения всем используемым объектам об очистке текущего состояния 
в начальное. 
Какие состояния могут быть? 
Что сбрасывать? 
Как запомнить все состояния которые нужно сбрасывать?
--]]
local function render_reset_state()
    pipeline:openPushAndClose('tank', 'clear')
end

-- Создать сегменты ограничивающие карту
local function initBorders()
    local lf = love.filesystem
    local borders_data: {Borders}

    -- Удалить существующие сегменты если они созданы.
    --[[
    -- XXX Здесь происходит падение
    if #segments ~= 0 then
        for _, v in ipairs(segments) do
            --wrp.free_static_segment(v)
        end
    end
    --]]

    local ok, msg = pcall(function()
        local path = SCENE_PREFIX .. "/borders_data.lua" 
        borders_data = lf.load(path)() as {Borders}
    end) as (boolean, string)
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
                wrp.static_segment_new(b.x1, b.y1, b.x2, b.y2)
            )
        end
    else
        print(colorize("${red}" .. "no borders data"))
    end
end

--[[
local function writeTurretAngles()
    love.filesystem.append('turret.txt', tostring(last_angle) .. '\n')
    love.filesystem.append('turret.txt', tostring(last_tur_angle) .. '\n')
    love.filesystem.append('turret.txt', '\n')
end
--]]

local function spawnPlayer()
    local px, py = screenW / 3, screenH / 2
    playerTank = spawnTank(px, py)

    playerTank:register_hit_handler(
        function(
                tank: wrp.Tank, 
                x: number, y: number, 
                nx: number, ny: number, 
                alpha: number
        )
        --print('tank', tank)
        local tank: Tank = tank:get_table() as Tank
        if tank then
            for k, v in ipairs(tanks) do
                if tank == v then
                    table.remove(tanks, k)
                end
            end
        end
        tank = nil
        wrp.space_remove(tank)
        --print('intersection with: ', wrp.get_object_type(tank as any))
        --writeTurretAngles()
    end)
    --]]

    if not spawn_only_player then
        -- near friend for debugger
        spawnTank(px + 400, py)
    end

    move_camera2player()
    --camera:attach()
    --camera:detach()
    --pipeline:sync()
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

local function changePlayerTank(key: string)
    if love.keyboard.isDown('lshift') then
        if key == 'left' then
            prevTankAsPlayer()
        elseif key == 'right' then
            nextTankAsPlayer()
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

    -- Пауза для физики
    if key == "p" then
        is_physics_paused = not is_physics_paused
    end

    --[[
    if key == 's' then
        writeTurretAngles()
    end
    --]]

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

    --[[
    local num = 500
    if key == '9' then
        for _ = 1, 15 do
            playerTank:rotate_turret("left")
        end
        print('left')
    elseif key == '0' then
        for _ = 1, 15 do
            playerTank:rotate_turret("right")
        end
        print('right')
    end
    --]]

    if key == 'a' then
        is_draw_debug_phys = not is_draw_debug_phys
    end

    if is_physics_paused then
        -- Полностью перезагрузить уровень.
        if key == 'q' then

            physics_reset()
            render_reset_state()
            initBorders()
            spawnTanks()
            spawnPlayer()

        -- Перезагрузить сегменты из файла.
        elseif key == '1' then
            -- FIXME падает если вызвать несколько раз
            initBorders()
        end
    end

    processLandscapeKeys(key)
    changePlayerTank(key)

    --[[
    if showLogo then
        showLogo = false
        print("showLogo", showLogo)
    end

    if mode == "command" then
        processCommandModeKeys(key)
    else
        if key == ";" and love.keyboard.isDown("lctrl") then
            enterCommandMode()
        end
    end
    --]]

    -- }}}
end

local function bindFullscreenSwitcher()
    -- {{{
    KeyConfig.bind(
        "keypressed", 
        { key = "f11" }, 
        function(sc: KeyConfig.Shortcut): boolean, KeyConfig.Shortcut
            local isfs = love.window.getFullscreen()
                --diamondSquare:draw2canvas()
            if isfs then
                --setWindowMode()
            else
                --setFullscreenMode()
            end
            return false, sc
        end,
        "switch fullscreen and windowed modes", 
        "switchwindowmode")
    -- }}}
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
   
    pipeline:pushCode("joy_stick", [[
    local gr = love.graphics
    local w, h = gr.getDimensions()
    local color = {1, 1, 1, 1}
    local rad = 10

    while true do
        local x = graphic_command_channel:demand() as number
        local y = graphic_command_channel:demand() as number

        gr.setColor(color)
        gr.circle("fill", x, y, rad)

        coroutine.yield()
    end
    ]])

    -- Буфер для вывода отладочной информации в левом верхнем углу экрана.
    pipeline:pushCodeFromFile('lines_buf', 'lines_buf.lua')
    -- Буфер для вывода отладочной информации при наведении на физическое тело.
    pipeline:pushCodeFromFile('object_lines_buf', 'lines_buf.lua')
    docsystem.init_render_stage1(pipeline)

    -- Рисование прозрачного прямоугольника над определенным телом.
    -- {{{
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
    -- }}}

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

    pipeline:pushCodeFromFile("debug_vertices", "debug_vertices.lua")

    -- Рисование линий физических сегментов используемых для ограничения 
    -- игрового поля.
    pipeline:pushCodeFromFile('border_segments', 'border_segments.lua')

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

local function add_keyboard_docs()
    -- {{{
    docsystem.add_keyboard_doc("escape", "exit")
    docsystem.add_keyboard_doc("r", "Rebuild map")
    docsystem.add_keyboard_doc('z', 'Decrease map size')
    docsystem.add_keyboard_doc('x', 'Increase map size')
    docsystem.add_keyboard_doc('shift+left', 'Previous tank as player')
    docsystem.add_keyboard_doc('shift+right', 'Next tank as player')
    docsystem.add_keyboard_doc('a', 'Enable or disable debug phys drawing')
    docsystem.add_keyboard_doc('p', 'Pause for physics engine. "P" - mode')
    docsystem.add_keyboard_doc('f1', 'Show or hide this text')
    docsystem.add_keyboard_doc('q', "Fully reload map with objects.")
    docsystem.add_keyboard_doc('1', 'Reload static physics segments.')
    docsystem.add_keyboard_doc('2', 'Show or hide selected object border.')
    docsystem.finish_keyboard_docs()
    -- }}}
end

local function add_gamepad_docs()
    -- {{{
    docsystem.add_gamepad_doc("start", "show this help")
    docsystem.add_gamepad_doc("left shift", "reset camera")
    docsystem.add_gamepad_doc('right shift', 'move camera to player')
    docsystem.add_gamepad_doc('X', 'rotate left')
    docsystem.add_gamepad_doc('B', 'rotate right')
    docsystem.add_gamepad_doc('Y', 'move forward')
    docsystem.add_gamepad_doc('A', 'move backward')
    docsystem.finish_gamepad_docs()
    -- }}}
end

local function spawnHangars()
    --[[
    Как расставлять ангары? В каких точках карты? Алгоритм расстановки.
    Значит сперва нужно подготовить карту для расстановки препятствий.
    --]]
    --[[
    local corners = getTerrainCorners()
    if corners then
        for _, c in ipairs(corners) do
            spawnHangar(c)
        end
    end
    --]]

    --[[ getAngarPoints() - исходя из площади "зеленой" т.е. доступной части 
    карты рассчитывается количество точек ангаров. Затем случайным образом
    производится подбор точек отвечающих условиям, а именно - доступность места
    для выезда танчика. Возможно - доступность пути.
    Идея - анимация всего процесса создания карты:
    * DiamonAndSquare
    * Подсчет площади
    * Расстановка ангаров
    * Проверка путей и доступности

    То есть для турнира создается случайная карта, на нее приглашаются боты или
    игроки.

    Статья К. Касперски об усложнении взлома, в дистрибутиве находится
    прекомпилированный lua код. PhysFS используется с ключом шифрования.
    Неясна защита сетевого режима.

    Все изменения в код не должны разрушать текущую систему(программу).
    Пускай небольшие изменения разрушают работоспособность программы. Значит
    необходимо организовать дополнительные проверки или огранизовать 
    параллельные структуры данных. Но избегать краха и неработоспособности
    программы. В последствии возможно производить переписывание, разрущающее
    временно программу с целью удаления "параллельных" структур данных.
    --]]

    --[[ -- PSEUDOCODE
    local possiblePoints = getAngarPoints()
    for _, v in ipairs(possiblePoints) do
        spawnHangar(v[1], v[2])
    end
    --]]
end

local function init()
    -- {{{
    print('init started')

    -- Начальное значение генератора для определенной карты
    rng:setSeed(300 * 123414)

    metrics.init()
    space = wrp.space_new(space_damping)
    wrp.space_set(space)

    screenW, screenH = pipeline:getDimensions()
    print('screenW, screenH', screenW, screenH)

    -- Требует инициализации после создания объекта pipeline, но до функций
    -- init*
    camera = PCamera.new(pipeline, screenW, screenH)

    -- Начало геймпада
    initJoy()
    -- Загрузка удаленного кода для рисования
    initRenderCode()
    -- Дополнительная инициализация объектов рисовки.
    initPipelineObjects()

    add_keyboard_docs()
    add_gamepad_docs()

    --loadLocales()

    --logo = Logo.new()

    --bindCameraZoomKeys()
    --bindKonsoleCameraZoomKeys()
    --bindCameraControl()

    bindFullscreenSwitcher()

    --bindEscape()
    --bindKonsole()
    --bindTerrainControlKeys()
    --bindDeveloperKeys()

    --arena = Arena.new("arena.lua")
    --terrain()

    -- }}}
    last_render = love.timer.getTime()

    print('init finished')
end

local function quit()
    -- {{{
    metrics.quit()
    tanks = {}
    --writeParticles(particlesfname)
    -- }}}
end

local stat_push_counter = 0

local function inc_push_counter(): integer
    local prev_value = stat_push_counter
    stat_push_counter = stat_push_counter + 1
    return prev_value
end

local function push_tank_body_stat(object: wrp.Tank)
    -- {{{
    local msg = ""
    local mass, inertia, cog_x, cog_y, pos_x, pos_y, v_x, v_y, 
        force_x, force_y, angle, w, torque = object:get_body_stat()

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
    -- }}}
end

local function push_tank_turret_stat(object: wrp.Tank)
    -- {{{
    local msg = ""
    local mass, inertia, cog_x, cog_y, pos_x, pos_y, v_x, v_y, 
        force_x, force_y, angle, w, torque = object:get_turret_stat()

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
    -- }}}
end

local function mousemoved(x: number, y: number, dx: number, dy: number)
    metrics.mousemoved(x, y, dx, dy)

    --local absx, absy = -camera.x, -camera.y
    --local absx, absy = camera:fromLocal2(x, y)
    local absx, absy = camera:fromLocal(x, y)

    --print('absx, absy', absx, absy)
    local counter = 0
    wrp.get_body_under_point(x + absx, y + absy, 
        function(
            object: wrp.Tank,
            shape_x: number,
            shape_y: number,
            dist: number,
            gradx: number,
            grady: number
        )

        -- {{{

        if not object then
            error("get_body_under_point: object in nil")
        end

        print("under cursor")

        local msg = ""
        counter = counter + 1
        pipeline:open('object_lines_buf')
        --pipeline:push('pos', absx, absy)
        pipeline:push('pos', x + absx, y + absy)
        pipeline:push('add', inc_push_counter(), 'object ' .. tostring(object))

        msg = sformat('point (%.3f, %.3f)', shape_x, shape_y)
        pipeline:push('add', inc_push_counter(), msg)

        pipeline:push('add', inc_push_counter(), 'distance ' .. dist)
        pipeline:push('add', inc_push_counter(), sformat('gradient (%.3f, %.3f)', gradx, grady))

        pipeline:push('add', inc_push_counter(), "----------")

        --wrp.shape_print_filter(shape)
        push_tank_body_stat(object)
        pipeline:push('add', inc_push_counter(), "----------")
        push_tank_turret_stat(object)

        pipeline:push('enough')
        pipeline:close()

        -- }}}
    end)

    if counter == 0 then
        pipeline:openPushAndClose('object_lines_buf', 'clear')
    end
    stat_push_counter = 0

    --if mode == 'editor' then
        --arena:mousemoved(x, y, dx, dy)
    --end
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

local function updateJoyState()
    joyState:update()
    if joyState.state and joyState.state ~= "" then
        --debug_print('joy', joyState.state)
        --print('joy', joyState.state)
    end
end

local function joystickpressed(_: Joystick, button: integer)
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
        -- Вывести справку по управлению
        is_draw_gamepad_docs = not is_draw_gamepad_docs
        is_draw_hotkeys_docs = false
    end
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

--[[
Задача: написать модуль, встроенный в бинарный файл love, для замены
pipeline.tl
--]]

--local last_scalar_mul = 0.

local function player_rotate_turret(j: Joystick)
    -- {{{
    local axes = { j:getAxes() }
    local x_axis_index = joy_conf.dx_turret_axis_index
    local y_axis_index = joy_conf.dy_turret_axis_index

    local angle, _ = vecl.toPolar(axes[x_axis_index], axes[y_axis_index])
    angle = angle + math.pi

    --[[
    if min_angle > angle then
        min_angle = angle
    end
    if max_angle < angle then
        max_angle = angle
    end
    --]]

    --print('screeW', screenW)
    --print('screeH', screenH)

    --local stick_range = 2.
    --local stick_scale_x = stick_range / screenW
    --local stick_scale_y = stick_range / screenH

    --print('stick_scale_x', stick_scale_x)
    --print('stick_scale_y', stick_scale_y)
    --print('axes[x_axis_index]', axes[x_axis_index])
    --print('axes[y_axis_index]', axes[y_axis_index])

    --print(
        --'stick_scale_x * axes[x_axis_index]',
        --stick_scale_x * axes[x_axis_index]
    --)
    --print(
        --'stick_scale_y * axes[y_axis_index]',
        --stick_scale_y * axes[y_axis_index]
    --)

    --stick_x = screenW / 2. + axes[x_axis_index] / stick_scale_x
    --stick_y = screenH / 2. + axes[y_axis_index] / stick_scale_y
    --stick_x = 0. + axes[x_axis_index] / stick_scale_x
    --stick_y = 0. + axes[y_axis_index] / stick_scale_y

    --wrp.stickobj_position_set(stickObj, stick_x, stick_y)

    --stick_x = screenW / 2. + stick_scale_x * axes[x_axis_index]
    --stick_y = screenH / 2. + stick_scale_y * axes[y_axis_index]
    --print('stick_x', stick_x)
    --print('stick_y', stick_y)

    --pipeline:openPushAndClose('joy_stick', stick_x, stick_y)

    --print(min_angle, max_angle)
    --local diff = math.abs(last_angle - angle) / 5.
    --print('diff', diff)
    --local num = 5
    local num = 20

    --local tmpx, tmpy, turret_angle = playerTank.base:turret_get_pos()
    local _, _, turret_angle = playerTank.base:turret_get_pos()
    local tur_x, tur_y = fromPolar(turret_angle, 1.)
    --last_tur_angle = turret_angle

    local scalar_mul = tur_x * axes[x_axis_index] + 
                       tur_y * axes[y_axis_index]

    --if last_scalar_mul ~= scalar_mul then
        --last_scalar_mul = scalar_mul
        ----print('scalar_mul', scalar_mul)
    --end

    turret_angle = turret_angle - math.floor(turret_angle / (math.pi * 2)) *
        (math.pi * 2)

    if last_angle ~= angle then
        local angle_diff = math.abs(last_angle - angle)
        if angle_diff < 0.04 then
            --print('num divided', num)
            num = math.floor(num / 10)
        end
        --print('angle diff', angle_diff)
        if scalar_mul < 0 then
            for _ = 1, num do
                playerTank:rotate_turret("left")
            end
        elseif scalar_mul > 0 then
            for _ = 1, num do
                playerTank:rotate_turret("right")
            end
        end
    end

    last_angle = angle
    -- }}}
end

local function applyInput(j: Joystick)
    -- {{{
    -- Нужно and или or?
    if not j or not playerTank then
        return
    end

    local left, right, up, down = 3, 2, 4, 1

    --[[
    Как узнать направление движения и направление приложения силы?
    --]]

    -- FIXME Если прикладывать слишком большой импульс, то объект пролетает
    -- за заграждение в виде EdgeShape
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

    player_rotate_turret(j)

    --[[
    local hut_num = 1
    --local msg = j:getHat(hut_num)
    --love.filesystem.append("hat", msg, #(msg as string))

    local hut = j:getHat(hut_num)
    --print('hut', hut)
    if hut == "l" then
        playerTank:rotate_turret("left")
    elseif hut == "r" then
        playerTank:rotate_turret("right")
    end
    --]]

    --if joy:isDown(5) then
        --print('os.exit(1)')
        --os.exit(1)
    --end

    --[[
    if joyState.state then
        --love.filesystem.append("joystate", joyState.state, #joyState.state)
        --print(joyState.state)
    end
    --]]

    -- }}}
end

local function processCamera(dt: number)
    if not joy then
        return
    end
    local axes = {joy:getAxes()}
    --local dscale = axes[joy_conf.scale_axis_index]
    local dx = axes[joy_conf.dx_axis_index]
    local dy = axes[joy_conf.dy_axis_index]
    local px, py: number, number
    if playerTank then
        -- Имеет-ли смысл кэшировать значения вызова
        -- playerTank.base:get_position() на один раз за кадр?
        px, py = playerTank.base:get_position()
    end
    --camera:update(dt, dx, dy, dscale, px, py)
    camera:update(dt, dx, dy, 0., px, py)
end

local stateCoro: thread = coroutine.create(function(dt: number)

    -- Ограничители поля
    initBorders()
    -- Точки возникновения, ремонта и улучшения техники
    spawnHangars()
    -- Танки
    spawnTanks()
    -- Машина игрока
    spawnPlayer()

    --stickObj = wrp.stickobj_new()

    diamondSquare:eval()
    diamondSquare:send2render()
    --lines_buf_push_mapn()

    while true do
    -- {{{
        if state == 'map' then
            process_events()
            renderScene()
            updateTanks()

            ------------ UPDATE HERE PLEASE ------------ 
            --arena:update()

            processCamera(dt)

            -- шаг физики
            if not is_physics_paused then
                wrp.space_step(dt);
            end

            --[[
            Почему тела не расталкиваются?
            Мигания рендера
            --]]
    
            applyInput(joy)
            updateJoyState()

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
