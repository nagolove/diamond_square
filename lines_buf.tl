global SCENE_PREFIX: string
global graphic_command_channel: love.thread.Channel
local yield = coroutine.yield

local timeout = 0.5
local t1 = love.timer.getTime()

local font_name = graphic_command_channel:demand(timeout) as string
--if type(font_name) ~= "string" then
    --error("Incorrect font name variable type.")
--end

local font_size = graphic_command_channel:demand(timeout) as integer
--if type(font_size) ~= "number" then
    --error("Declare font size as integer.")
--end
local t2 = love.timer.getTime()

if t2 - t1 >= timeout then
    error("Could not demand data, timeout elapsed.")
end

--local font = love.graphics.newFont(SCENE_PREFIX .. '/' .. "VeraMono.ttf")
print("SCENE_PREFIX", SCENE_PREFIX)
local path = SCENE_PREFIX .. "/" .. font_name
local font = love.graphics.newFont(path, font_size)

local oldfont: love.graphics.Font
local buffer: {string: string} = {}

yield()

while true do
    local cmd: string
    --print('lines_buf: cmd', cmd)
    
    local oldfont = love.graphics.getFont()
    repeat
        cmd = graphic_command_channel:demand() as string

        if cmd == "add" then
            local id = graphic_command_channel:demand() as string
            local message = graphic_command_channel:demand() as string

            if type(id) ~= 'string' then
                error('id in lines_buf should be a string')
            end
            if type(message) ~= 'string' then
                error('message in lines_buf should be a string')
            end

            buffer[id] = message

        elseif cmd == 'remove' then
            local id = graphic_command_channel:demand() as string
            buffer[id] = nil
        elseif cmd == 'clear' then
            buffer = {}
        elseif cmd == 'flush' then
            love.graphics.setFont(font)
            love.graphics.setColor {0, 0, 0, 1}
            local y = 0.

            for k, v in pairs(buffer) do
                love.graphics.print(v, 0, y)
                y = y + font:getHeight()
            end

            break
        else
            error('lines_buf unkonwn command: ' .. cmd)
        end

    until not cmd
    love.graphics.setFont(oldfont)

    yield()
end
