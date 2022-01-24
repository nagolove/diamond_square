local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local os = _tl_compat and _tl_compat.os or os; local string = _tl_compat and _tl_compat.string or string




local file
local fname = "metrics.txt"
local useFlush = false
local dateFormat = "%d %m %y %H %M %S"

local function write(s)
   local date = os.date(dateFormat)
   file:write(date .. s .. "\n")
   if useFlush then
      file:flush()
   end
end

local function init(scene)
   file = love.filesystem.newFile(fname, "a")
   write(string.format(" init(%s)", scene))
end

local function quit()
   file:close()
end

local function keypressed(key)
   write(" keypressed " .. key)
end

local function mousemoved(x, y, dx, dy)
   write(
   " mousemoved " .. tostring(x) ..
   " " .. tostring(y) ..
   " " .. tostring(dx) ..
   " " .. tostring(dy))

end

local function wheelmoved(x, y)
   write(" wheelmoved " .. tostring(x) .. " " .. tostring(y))
end

local function mousepressed(x, y, btn)
   write(
   " mousepressed " .. tostring(x) ..
   " " .. tostring(y) ..
   " " .. tostring(btn))

end

local function resize(w, h)
   write(" resize " .. tostring(w) .. " " .. tostring(h))
end

local function textinput(text)
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
