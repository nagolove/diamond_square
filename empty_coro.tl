--[[
Модуль корутины рисования отладочного вывода chipmunk.
--]]

--local serpent = require 'serpent'

local inspect = require 'inspect'
local colorize = require('ansicolors2').ansicolors
local format = string.format
local yield = coroutine.yield
local gr = love.graphics

require 'love'

global graphic_command_channel: love.thread.Channel
global SCENE_PREFIX: string

---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

-- Прололжение работы после вызова pipeline:sync() --
--yield()

---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

-- счетчик команд
local cmd_num = 0

local commands = {}

local enum Command
    "enough"
end

-- Выйти из цикла приема сообщений, ничего не рисовать
function commands.enough(): boolean
    return false
end

local cmd_circle_buf: {Command} = {}
local cmd_circle_buf_maxnum = 16 * 2

local function push_cbuf(cmd: Command)
    if #cmd_circle_buf >= cmd_circle_buf_maxnum then
        table.remove(cmd_circle_buf, 1)
    end
    table.insert(cmd_circle_buf, cmd)
end

local function print_stack()
    print(colorize(
        "%{blue}cmd stack: " .. 
        inspect(cmd_circle_buf) .. 
        "%{reset}"
    ))
end

while true do
    local cmd: Command
    cmd_num = 0

    --local ok, errmsg: boolean, string = pcall(function()

    repeat
        cmd = graphic_command_channel:demand() as Command
        push_cbuf(cmd)

        local fun = commands[cmd]
        if not fun then
            print_stack()
            error('empty_coro unknown command: ' .. cmd)
       end
        if not fun() then
            break
        end

        cmd_num = cmd_num + 1
    until not cmd

    --end)
    --if not ok then 
        --print('dbg_phys:', errmsg)
    --end

    yield()
end

 
