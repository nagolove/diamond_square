--[[
record LinesBuffer
    -- добавить идентификатор и запись. 
    -- Цикл обработки команд не прерывается.
    add: function(id: string|number, message: string)

    -- Удалить запись из словаря.
    remove: function(id: string, message: string)

    -- Очистить словарь и прервать цикл обработки команд.
    clear: function()

    -- Рисовать и прервать цикл обработки команд.
    flush: function()

    -- Прервать цикл обработки команд.
    -- Используется при множественном добавлении или удалении.
    enough: function()

    -- Рисовать рамку вокруг таблицы или нет.
    -- Перерасчитывает ширину рамки.
    border: function(boolean)

    -- Установить рисование таблицы по центру экрана.
    align_center: function()

    -- Установить точку рисования таблицы. 
    -- Сбрасывается вызовом align_center()
    pos: function(x: number, y: number)
end
--]]
    
global SCENE_PREFIX: string
global graphic_command_channel: love.thread.Channel
local gr = love.graphics
local yield = coroutine.yield
local colorize = require 'ansicolors2'.ansicolors

local timeout = 0.5
local t1 = love.timer.getTime()

local font_name = graphic_command_channel:demand(timeout) as string
if type(font_name) ~= "string" then
    error("Incorrect font name variable type.")
end

local font_size = graphic_command_channel:demand(timeout) as integer
if type(font_size) ~= "number" then
    error("Declare font size as integer.")
end
local t2 = love.timer.getTime()

if t2 - t1 >= timeout then
    error("Could not demand data, timeout elapsed.")
end

--local font = gr.newFont(SCENE_PREFIX .. '/' .. "VeraMono.ttf")
print("SCENE_PREFIX", SCENE_PREFIX)
local path = SCENE_PREFIX .. "/" .. font_name
local font = gr.newFont(path, font_size)

local buffer: {string: string} = {}
-- Количество записей
local buffer_num: integer = 0
-- Рисовать-ли рамку вокруг текста?
local use_border = false
-- Ширина рамки вокруг текста. Равняется максимальной ширине текста.
local border_w = 0
-- Толщина рамки вокруг текста, в пикселях.
local border_line_width = 10

---------------------------------------------------------------
--[[---------------------]] yield() --[[---------------------]]
---------------------------------------------------------------

local posx, posy = 0., 0.

local function calculate_border_witdh()
    local max_len = 0
    gr.setLineWidth(border_line_width)
    for _, v in pairs(buffer) do
        local pix_len = font:getWidth(v) as integer
        if pix_len > max_len then
            max_len = pix_len
        end
    end
    border_w = max_len
    print('calculate_border_witdh')
end

local text_color = {0, 0, 0, 1}
local border_color = {0, 0, 0, 1}

-- Перерасчет posx, posy для рисования текущей таблицы по центру экрана.
local function align_center(): boolean
    local w, h = gr.getDimensions()
    posx = (w - border_w) / 2
    posy = (h - buffer_num * font:getHeight()) / 2
    print('posx, posy', posx, posy)
    return true
end

local function draw(): boolean
    gr.setFont(font)
    gr.setColor(text_color)
    local y = posy
    for _, v in pairs(buffer) do
        gr.print(v, posx, y)
        y = y + font:getHeight()
    end
    return false
end

local commands: {string: function(): boolean} = {
    ['add'] = function(): boolean
        local id = graphic_command_channel:demand() as string
        local message = graphic_command_channel:demand() as string

        if type(id) ~= 'string' and type(id) ~= 'number' then
            print('id, type(id)', id, type(id))
            error('id in lines_buf should be a string or number')
        end
        if type(message) ~= 'string' then
            error('message in lines_buf should be a string')
        end

        buffer[id] = message
        buffer_num = buffer_num + 1

        return true
    end,
    ['border'] = function(): boolean
        print(colorize('%{yellow}cmd == border'))
        local state = graphic_command_channel:demand() as boolean
        if type(state) ~= 'boolean' then
            error('lines_buf: border should be a boolean value')
        end
        use_border = state
        if use_border then
            calculate_border_witdh()
        end
        return true
    end,
    ['align_center'] = align_center,
    ['pos'] = function(): boolean
        local x = graphic_command_channel:demand() as number
        local y = graphic_command_channel:demand() as number

        if type(x) ~= 'number' then
            error('x should be a number in lines_buf->add')
        end
        if type(y) ~= 'number' then
            error('y should be a number in lines_buf->add')
        end

        posx, posy = x, y
        return true
    end,
    ['remove'] = function(): boolean
        local id = graphic_command_channel:demand() as string
        if buffer[id] then
            buffer[id] = nil
            buffer_num = buffer_num - 1
        end
        return true
    end,
    ['clear'] = function(): boolean
        buffer = {}
        buffer_num = 0
        return false
    end,
    ['enough'] = function(): boolean
        return false
    end,
    ['flush'] = draw,
}

while true do
    local cmd: string
    --print('lines_buf: cmd', cmd)

    local oldfont = gr.getFont()
    repeat
        cmd = graphic_command_channel:demand() as string

        --[[
        Добавить цветной текст? В каком виде?
        add_colored
        add_color
        add_text
        finish_add_colored
        --]]

        local fun = commands[cmd]
        if not fun then
            error('lines_buf unkonwn command: ' .. cmd)
        end
        if not fun() then
            break
        end

    until not cmd
    gr.setFont(oldfont)

    yield()
end
