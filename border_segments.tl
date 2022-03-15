--[[
-- Рисование сегмента
draw: function(x1, y1, x2, y2)
-- Включить или выключить рисование координаты на концах отрезка
print_coordinates: function(state: boolean)
-- Прервать цикл рисования
flush: function()
]]

local yield = coroutine.yield
local linew = 12
local gr = love.graphics
local font = gr.newFont(42)

-- Рисовать-ли координаты в начале и конце отрезка.
local print_coordinates = false

local msg_bool = 
    "border_segments: print_coordinates " .. 
    "command should have boolean argument."

while true do
    local cmd: string
    
    local oldlw = gr.getLineWidth()
    local oldf = gr.getFont()
    gr.setFont(font)
    gr.setLineWidth(linew)
    repeat
        cmd = graphic_command_channel:demand() as string

        if cmd == "draw" then
            local x1, y1, x2, y2: number, number, number, number
            x1 = graphic_command_channel:demand() as number
            y1 = graphic_command_channel:demand() as number
            x2 = graphic_command_channel:demand() as number
            y2 = graphic_command_channel:demand() as number

            gr.setColor {0, 0, 0, 1}
            gr.line(x1, y1, x2, y2)

            if print_coordinates then
                local msg: string
                gr.setColor {1, 0, 0, 1}
                msg = string.format("(%d, %d)", x1, y1)
                gr.print(msg, x1, y1)
                msg = string.format("(%d, %d)", x2, y2)
                gr.print(msg, x2, y2)
            end

        elseif cmd == 'print_coordinates' then
            local state = graphic_command_channel:demand() as boolean
            if type(state) ~= 'boolean' then
                error(msg_bool)
            end
        elseif cmd == 'flush' then
            break
        else
            error('unkonwn command: ' .. cmd)
        end

    until not cmd
    gr.setLineWidth(oldlw)
    gr.setFont(oldf)

    yield()
end
