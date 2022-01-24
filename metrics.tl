-- Снятие метрик приложения.
-- Начало сессии.
-- Конец сессии.
-- Запись состояний мыши и клавиатуры в файл.

local file: love.filesystem.File
local fname = "metrics.txt"
local useFlush = false
local dateFormat = "%d %m %y %H %M %S"

local function write(s: string)
    local date = os.date(dateFormat)
    file:write(date .. s .. "\n")
    if useFlush then
        file:flush()
    end
end

local function init(scene: string)
    file = love.filesystem.newFile(fname, "a")
    write(string.format(" init(%s)", scene))
end

local function quit()
    file:close()
end

local function keypressed(key: string)
    write(" keypressed " .. key)
end

local function mousemoved(x: number, y: number, dx: number, dy: number)
    write(
        " mousemoved " .. tostring(x) .. 
        " " .. tostring(y) .. 
        " " .. tostring(dx) ..
        " " .. tostring(dy)
    )
end

local function wheelmoved(x: number, y: number)
    write(" wheelmoved " .. tostring(x) .. " " .. tostring(y))
end

local function mousepressed(x: number, y: number, btn: integer)
    write(
        " mousepressed " .. tostring(x) .. 
        " " .. tostring(y) .. 
        " " .. tostring(btn)
    )
end

local function resize(w: integer, h: integer)
    write(" resize " .. tostring(w) .. " " .. tostring(h))
end

local function textinput(text: string)
    write(" textinput " .. text)
end

local function flush()
    if file then
        file:flush()
    end
end

return {
    init = init,
    keypressed = keypressed,
    mousemoved = mousemoved,
    mousepressed = mousepressed,
    quit = quit,
    resize = resize,
    textinput = textinput,
    wheelmoved = wheelmoved,
    flush = flush,
}
