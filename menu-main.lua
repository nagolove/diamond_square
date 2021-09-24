local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string; print('hello from top of main menu module.')






require("love")

local inspect = require("inspect")
local g = love.graphics

 MenuObject = {}














 MenuFunction = {}

 Menu = {Item = {}, ItemRect = {}, }



















































local Menu_mt = {
   __index = Menu,
}

function Menu.new()
   local self = {
      items = {},
      active_item = 1,
      active = false,


   }
   return setmetatable(self, Menu_mt)
end


function Menu:goBack()
   local obj = self.items[self.active_item].obj
   if obj.leave then obj:leave() end
   self.active = false
end

function Menu:compute_rects()

   self.y_pos = (self.h - #self.items * self.font:getHeight()) / 2


   self.items_rects = {}
   local y = self.y_pos
   local rect_width = self.maxWidth
   for _, _ in ipairs(self.items) do
      self.items_rects[#self.items_rects + 1] = {
         x = (self.w - rect_width) / 2,
         y = y,
         w = rect_width,
         h = self.font:getHeight(),
      }
      y = y + self.font:getHeight()
   end
end

function Menu:resize(neww, newh)
   self.w = neww
   self.h = newh
   self:compute_rects()

   self.canvas = g.newCanvas(neww, newh, { msaa = 4 })

end




function Menu:init()
   self:resize(g.getDimensions())
   self.alpha = 1
end



function Menu:searchWidestText()
   local maxWidth = 0.
   for _, v in ipairs(self.items) do
      local w = self.font:getWidth(v.name)
      if w > maxWidth then maxWidth = w end
   end
   self.maxWidth = maxWidth
end

function Menu:clear()
   self.items = {}
   self:searchWidestText()
   self:resize(g.getDimensions())
end




function Menu:addItem(name, object)
   print("menu:addItem()", name, inspect(object))
   assert(type(name) == "string", string.format('Type should be string, not %s', type(name)))
   self.items[#self.items + 1] = { name = name, obj = object }
   self:searchWidestText()
   self:resize(g.getDimensions())
end

function Menu:moveDown()
   if self.active_item + 1 <= #self.items then
      self.active_item = self.active_item + 1
   else
      self.active_item = 1
   end
end

function Menu:moveUp()
   if self.active_item - 1 >= 1 then
      self.active_item = self.active_item - 1
   else
      self.active_item = #self.items
   end
end

function Menu:keyreleased(key)
   if self.active then

      local obj = self.items[self.active_item].obj
      if obj.keyreleased then obj:keyreleased(key) end
   end
end

function Menu:keypressed(key)
   if self.active then

      local obj = self.items[self.active_item].obj
      assert(obj)
      if obj.keypressed then obj:keypressed(key) end
   else


      if key == "up" or key == "k" then self:moveUp()
      elseif key == "down" or key == "j" then self:moveDown()
      elseif key == "escape" then love.event.quit()
      elseif key == "return" or key == "space" then
         local obj = self.items[self.active_item].obj
         if type(obj) == "function" then
            (obj)()
         else
            self.active = true
            if obj.enter then obj:enter() end
         end
      end
   end
end

function Menu:update(dt)
   if self.active then
      local obj = self.items[self.active_item].obj
      if obj.update then obj:update(dt) end
   else

   end
end











function Menu:mousemoved(x, y, dx, dy, istouch)
   if self.active then
      local obj = self.items[self.active_item].obj
      if obj.mousemoved then obj:mousemoved(x, y, dx, dy, istouch) end
   else
      self:process_menu_selection(x, y, dx, dy, istouch)
   end
end

function Menu:mousereleased(x, y, btn, istouch)
   if self.active then
      local obj = self.items[self.active_item].obj
      if obj.mousereleased then obj:mousereleased(x, y, btn, istouch) end
   end
end

function Menu:mousepressed(x, y, button, istouch)
   if self.active then
      local obj = self.items[self.active_item].obj
      assert(obj)
      if obj.mousepressed then obj:mousepressed(x, y, button, istouch) end
   else










   end
end


function Menu:drawList()
   local y = self.y_pos
   g.setFont(self.font)




   for i, k in ipairs(self.items) do

      local q = self.active_item == i and { 1., 1., 1., 1. } or { 0., 0., 0., 1. }
      q[4] = self.alpha
      g.setColor(q)
      g.printf(k.name, 0, y, self.w, "center")
      y = y + self.font:getHeight()
   end

end

function Menu:draw()

   g.clear(0, 0, 0, 0)
   if self.active then
      local obj = self.items[self.active_item].obj
      if obj.draw then





         obj:draw()







      end
   else
      g.push("all")

      self:drawList()

      self:cursorDraw()
      g.pop()
   end
end


function Menu:cursorDraw()



   local v = self.items_rects[self.active_item]
   g.setLineWidth(3)
   g.setColor({ 1, 0, 0 })
   g.rectangle("line", v.x, v.y, v.w, v.h)
end

function Menu:touchpressed(id, x, y, dx, dy, pressure)
   if self.active then
      local obj = self.items[self.active_item].obj
      if obj.touchpressed then obj:touchpressed(id, x, y, dx, dy, pressure) end
   end
end

function Menu:touchreleased(id, x, y, dx, dy, pressure)
   if self.active then
      local obj = self.items[self.active_item].obj
      if obj.touchreleased then obj:touchreleased(id, x, y, dx, dy, pressure) end
   end
end

function Menu:touchmoved(id, x, y, dx, dy, pressure)
   if self.active then
      local obj = self.items[self.active_item].obj
      if obj.touchmoved then obj:touchmoved(id, x, y, dx, dy, pressure) end
   end
end

mainMenu = Menu.new()
print('hello from bottom of main menu module.')
