-- vim: set colorcolumn=85
-- vim: fdm=marker

--[[
-- информация о наборе частиц
local record ParticleSystemDefinition
    -- {{{
    -- режим смешивания
    blendmode: love.graphics.BlendMode
    -- режим смешивания канала прозрачности
    alphamode: love.graphics.BlendAlphaMode
    lifetime1: number
    lifetime2: number
    -- интенсивность эммисия
    emissionRate: number
    -- вариация размеров
    sizeVariation: number
    -- линейное ускорение
    lineAcceleration: {number}
    colors: {{number}}
    emiterlifetimeexp: string
    rotation1: number
    rotation2: number
    -- }}}
end
--]]

--local type ParticlesMap = {string: ParticleSystemDefinition}

--[[
local particles: ParticlesMap= {
    -- {{{
    -- значение для по-умолчанию для новых эффектов
    ["default"] = {
        blendmode = 'alpha',
        alphamode = 'alphamultiply',
        lifetime1 = 1,
        lifetime2 = 2,
        emissionRate = 10,
        sizeVariation = 1,
        lineAcceleration = { -20, -20, 20, 20 },
        colors = {
            { 1, 1, 1, 1, },
            { 1, 1, 1, 0, },
        },
        emiterlifetimeexp = "return 0.1 + (rng:random() + 0.01) / 2",
        rotation1 = 0,
        rotation2 = math.pi * 2,
    }
    -- }}}
}
--]]

-- То, что создается когда происходит попадание снаряда в танк.
-- Должен содержать анимацию попадания?
local record Hit 
    -- {{{
    -- в пикселях
    x: number
    -- в пикселях
    y: number
    ps: love.graphics.ParticleSystem

    -- координаты в метрах
    new: function(x: number, y: number): Hit
    -- }}}
end

--[[
local enum Mode
    "normal"
    "command"
    "editor"
end
--]]

--[[
local enum Brush
    "None" -- ничего не рисовать
    "Hangar"
end
--]]

--local record DrawNode
    --f: function
    --self: any
--end

-- }}}

--[[
local record Edge
    x1: number
    y1: number
    x2: number
    y2: number
end
--]]

-- Чем занят класс Arena?
-- Класс Arena применяется для хранения геометрии ограничивающей игровое поле.
-- Также объект класса позволяет записать полное описание сцены в строку или файл и
-- восстановить сцену из файла. Сцена содержит списки танков, списки ребер, списки ангаров.
local record Arena
    -- {{{
    new: function(fname: string): Arena
    -- }}}
end

--[[
local enum Particles
    "default"
    "rocket"
    "gauss"
end
--]]

-- Konsole editing
--local historyfname = "cmdhistory.txt"

--[[

global mode: Mode = "normal"
global cmdline: string = ""
local cmdhistory: {string} = {}
global cursorpos: integer = 1
--global suggestList: List = List.new()
-- список имен переменных для отображения в консоли
global attachedVarsList: {string: function} = {}
--]]

--[[
local function getTankSize(): integer, integer
    local path = SCENE_PREFIX .. '/' .. base_tex_fname
    local image = love.image.newImageData(path)
    if not image then
        error('Could not load base_tex_fname: ' .. path)
    end
    return image:getDimensions() as (integer, integer)
end
--]]

--[[
local tank_width, tank_height = getTankSize()
--]]

--[[
Где находится обрабатывающая функция?
В методах танка?
-----------------------------------------------------------------------
|                           Свободная функция?                        |
-----------------------------------------------------------------------
В методах пули?
В методах ангара?

танк и танк
танк и пуля
танк и грань
танк и ангар
--]]

--[[
local function processTankVsBullet(_: Tank, _: Bullet)
end

local function processTankVsTank(_: Tank, _: Bullet)
end
--]]

--[[
local contactMap = {
    ['Tank'] = {
        ['Bullet'] = function(_: Tank, _: Bullet)
        end,
        ['Tank'] = function(_: Tank, _: Tank)
        end,
    }
}
-]]

--[[
local function loadLocales()
    -- {{{
    local localePath = SCENE_PREFIX .. "/locales"
    local files = love.filesystem.getDirectoryItems(localePath)
    print("locale files", inspect(files))
    for _, v in ipairs(files) do 
        i18n.loadFile(localePath .. "/" .. v, function(path: string): any
            local chunk, errmsg = love.filesystem.load(path)
            if not chunk then
                error(errmsg)
            end
            return chunk
        end) 
    end
    --i18n.setLocale('en')
    i18n.setLocale('ru')
    --print("i18n", inspect(i18n))
    -- }}}
end
--]]

--[[
local function bindDeveloperKeys()
    -- {{{
    local kc = KeyConfig
    kc.bind(
        --'keypressed', { key = "p" },
        'isdown', { key = "p" },
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end

            print('works')
            if playerTank then
                --local x, y = playerTank.base.physbody:getWorldCenter()
                --newHit(x, y)
                --print('new Hit created at', x, y)
            end

            return false, sc
        end,
        --i18n("mt" .. "right"))
        'spawn Hit')
    kc.bind(
        --'keypressed', { key = "p" },
        'keypressed', { key = "r" },
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end

            --terrain()

            return false, sc
        end,
        --i18n("mt" .. "right"))
        'spawn Hit')
    -- }}}
end
--]]

--[[
local function bindTerrainControlKeys()
    -- {{{
    local kc = KeyConfig
    kc.bind(
        'keypressed', { key = "t" },
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end
            print('drawTerrain', drawTerrain)
            drawTerrain = not drawTerrain
            return false, sc
        end,
        --i18n("mt" .. "right"))
        'draw terrain or not')
    -- }}}
end
--]]

--[[
local function buildParticlesNames(): {string}
    local res: {string} = {}
    for k, _ in pairs(particles) do
        table.insert(res, k)
    end
    return res
end
--]]

--local currentParticesType: integer = 0

--[[
local function selectParticleType(): string
    -- {{{
    local v: number
    local st: boolean
    local names = buildParticlesNames()
    local zeroseparated, _ = separateByZeros(names)
    v, st = imgui.Combo("тип частиц", currentParticesType, zeroseparated)
    if st then
        currentParticesType = ceil(v)
        for k, s in ipairs(names) do
            if k == v then
                print(k, s)
                return s
            end
        end
    end
    return 'default'
    -- }}}
end
--]]

local str: string = ""

--[[
-- {{{
local function drawParticlesEditor()
    imgui.Begin(i18n('effecteditor'), false, "AlwaysAutoResize")
    local v: number
    local st: boolean
    --local str: string

    local particleType = selectParticleType()

    str, st = imgui.InputText('название типа', str, "")
    imgui.SameLine()
    if imgui.Button('добавить новый тип') then

    end

    --str, st = imgui.InputText('название типа', str, "None")

    --print('particleType', particleType)
    local psdef = particles[particleType]
    --v, st = imgui.SliderInt('скорость частиц', 0, -1, 1)

    local zeroseparated = separateByZeros({ "1", "2" })
    -- как рисовать картинку здесь выбираемого изображения?
    v, st = imgui.Combo('выбор картинки', activeImage - 1, zeroseparated)
    if st then
        print('v', v)
        activeImage = ceil(tonumber(v)) + 1
    end

    psdef.lifetime1, st = imgui.SliderInt('время жизни от', psdef.lifetime1, 0, 1000)
    psdef.lifetime2, st = imgui.SliderInt('время жизни до', psdef.lifetime2, 0, 1000)
    psdef.emissionRate, st = imgui.SliderInt('эмиссия', psdef.emissionRate, 0, 1000)
    psdef.sizeVariation, st = imgui.SliderFloat('вариации размера', psdef.sizeVariation, 0, 1)

    psdef.lineAcceleration[1], st = imgui.SliderInt('парам1', psdef.lineAcceleration[1], -100, 100)
    psdef.lineAcceleration[2], st = imgui.SliderInt('парам2', psdef.lineAcceleration[2], -100, 100)
    psdef.lineAcceleration[3], st = imgui.SliderInt('парам3', psdef.lineAcceleration[3], -100, 100)
    psdef.lineAcceleration[4], st = imgui.SliderInt('парам4', psdef.lineAcceleration[4], -100, 100)

    psdef.colors[1][1], st = imgui.SliderFloat('цвет красный 1', psdef.colors[1][1], 0, 1)
    psdef.colors[1][2], st = imgui.SliderFloat('цвет зеленый 1', psdef.colors[1][2], 0, 1)
    psdef.colors[1][3], st = imgui.SliderFloat('цвет голубой 1', psdef.colors[1][3], 0, 1)
    psdef.colors[1][4], st = imgui.SliderFloat('цвет прозрачности 1', psdef.colors[1][4], 0, 1)

    psdef.colors[2][1], st = imgui.SliderFloat('цвет красный 2', psdef.colors[2][1], 0, 1)
    psdef.colors[2][2], st = imgui.SliderFloat('цвет зеленый 2', psdef.colors[2][2], 0, 1)
    psdef.colors[2][3], st = imgui.SliderFloat('цвет голубой 2', psdef.colors[2][3], 0, 1)
    psdef.colors[2][4], st = imgui.SliderFloat('цвет прозрачности 2', psdef.colors[2][4], 0, 1)

    --
    psdef.emiterlifetimeexp = imgui.InputTextMultiline("emiterlifetimeexp", psdef.emiterlifetimeexp, 600, 400);

    imgui.End()
end
-- }}}
--]]

--[[
local tmpColumns = {
    true,
    false,
    false,
}
--]]

--[[
-- {{{
local function drawArenaPallete()
    imgui.Begin('арена', false, "AlwaysAutoResize")
    if imgui.Button('выгрузить на накопитель нжмд') then

    end
    if imgui.Button('подгрузить с на накопителя нжмд') then
    end
    if imgui.Button('включить режим кисти граней') then

    end
    if imgui.Button(i18n('inserhangarmode')) then
        mode = 'editor'
        setupBrush('Hangar')
    end
    if imgui.Button('отключить редектирование') then
        mode = 'normal'
    end

    if imgui.BeginTable('какая-то таблица', 5) then
        imgui.TableNextColumn(); 
        tmpColumns[1] = imgui.Checkbox("Огурец", tmpColumns[1])
        imgui.TableNextColumn()
        tmpColumns[2] = imgui.Checkbox("Томат", tmpColumns[2])
        imgui.TableNextColumn()
        tmpColumns[3] = imgui.Checkbox("Паштет", tmpColumns[3])
        imgui.EndTable()
    end

    imgui.End()
end
-- }}}
--]]

--[[
local function bindCameraControl()
    -- {{{
    -- не прямой а квадратичный зум?
    local cameraAnimationDuration = 0.2

    local type Return = function(sc: Shortcut): boolean, Shortcut
    --local function makeMoveFunction(xc: number, yc: number): Return
    local function makeMoveFunction(_: number, _: number): Return
        -- {{{
        return function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end

            --local reldx = cameraSettings.dx / cam.scale 
            --local reldy = cameraSettings.dy / cam.scale
            camTimer:during(cameraAnimationDuration, 
                --function(dt: number, time: number, delay: number)
                function(_: number, _: number, _: number)
                    --local dx = -reldx * (delay - time) * xc
                    --local dy = -reldy * (delay - time) * yc
                    --if delay - time > 0 then
                        --cam:move(dx * dt, dy * dt)
                    --end
                end,
                function()
                    --print("after camera moving")
                end)
            return true, sc
            --return false, sc
        end
        -- }}}
    end

    local bindMode: KeyConfig.BindType = "isdown"
    KeyConfig.bind(bindMode, { key = "left" }, makeMoveFunction(1., 0), 
        i18n("mcleft"), "camleft")
    KeyConfig.bind(bindMode, { key = "right" }, makeMoveFunction(-1.0, 0.), 
        i18n("mcright"), "camright")
    KeyConfig.bind(bindMode, { key = "up" }, makeMoveFunction(0., 1.), 
        i18n("mcup"), "camup") 
    KeyConfig.bind(bindMode, { key = "down" }, makeMoveFunction(0., -1.), 
        i18n("mcdown"), "camdown")

    KeyConfig.bind("keypressed", { key = "c" }, 
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end
            --moveCameraToTank(playerTank)
            return false, sc
        end, 
        i18n("cam2tank"), "cam2tank")
    -- }}}
end
--]]

--[[
local function bindKonsole()
    -- {{{
    KeyConfig.bind("keypressed", { key = "`" }, 
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end
            --linesbuf.show = not linesbuf.show
            return false, sc
        end
    )
    -- }}}
end
--]]

--[[
-- Сомнительная функция, не работает наверное.
local function bindEscape()
    -- {{{
    KeyConfig.bind("keypressed", { key = "escape" }, 
        function(sc: Shortcut): boolean, Shortcut
            if mode ~= "normal" then
                return false, sc
            end
            if showLogo == true then
                print('your pressed Escape. exit to system')
                love.event.quit()
            else
                showLogo = true
            end
            return false, sc
        end
    )
    -- }}}
end
--]]

--[[
local function print_body_stat(body: wrp.Body)
    -- {{{
    print('body', body)
    local mass, inertia, cog_x, cog_y, pos_x, pos_y, v_x, v_y, 
        force_x, force_y, angle, w, torque = wrp.get_body_stat(body)

    print('body stat:')
    print("mass", mass)
    print("inertia", inertia)
    print("cog_x", cog_x)
    print("cog_y", cog_y)
    print("pos_x", pos_x)
    print("pos_y", pos_y)
    print("v_x", v_x)
    print("v_y", v_y)
    print("force_x", force_x)
    print("force_y", force_y)
    print("angle", angle)
    print("w", w)
    print("torque", torque)

    -- }}}
end
--]]

