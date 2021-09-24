print('hello from top of main menu module.')

--[[
require "background"
require "cmn"
require "common"
--]]
require "love"

local inspect = require "inspect"
local g = love.graphics

global record MenuObject
    draw: function(MenuObject)
    enter: function(MenuObject)
    keypressed: function(MenuObject, string)
    keyreleased: function(MenuObject, string)
    leave: function(MenuObject)
    mousemoved: function(MenuObject, number, number, number, number, boolean)
    mousepressed: function(MenuObject, number, number, number, boolean)
    mousereleased: function(MenuObject, number, number, number, boolean)
    touchmoved: function(MenuObject, id: number, x: number, y: number, dx: number, dy: number, pressure: number)
    touchpressed: function(MenuObject, id: number, x: number, y: number, dx: number, dy: number, pressure: number)
    touchreleased: function(MenuObject, id: number, x: number, y: number, dx: number, dy: number, pressure: number)
    update: function(MenuObject, number)
end

global type MenuFunction = function()

global type Menu = record

    record Item
        name: string
        obj: MenuObject
    end

    record ItemRect
        x: number
        y: number
        w: number
        h: number
    end

    items: {Item}
    --back: Background
    active_item: integer
    w: number
    h : number
    active: boolean
    font: love.graphics.Font
    maxWidth: number
    alpha: number
    canvas: love.graphics.Canvas
    y_pos: number
    items_rects: {ItemRect}

    --drawCursor: function(Menu)
    addItem: function(Menu, name: string, object: MenuObject|MenuFunction)
    clear: function(Menu)
    compute_rects: function(Menu)
    cursorDraw: function(Menu)
    draw: function(Menu)
    drawList: function(Menu)
    goBack: function(Menu)
    init: function(Menu)
    keypressed: function(Menu, string)
    keyreleased: function(Menu, string)
    mousemoved: function(Menu, number, number, number, number, boolean)
    mousepressed: function(Menu, number, number, number, boolean)
    mousereleased: function(Menu, number, number, number, boolean)
    moveDown: function(Menu)
    moveUp: function(Menu)
    process_menu_selection: function(Menu, number, number, number, number, boolean)
    resize: function(Menu, number, number)
    searchWidestText: function(Menu)
    touchmoved: function(Menu, id: number, x: number, y: number, dx: number, dy: number, pressure: number)
    touchpressed: function(Menu, id: number, x: number, y: number, dx: number, dy: number, pressure: number)
    touchreleased: function(Menu, id: number, x: number, y: number, dx: number, dy: number, pressure: number)
    update: function(Menu, number)
end

local Menu_mt: metatable<Menu> = {
    __index = Menu
}

function Menu.new(): Menu
    local self: Menu = {
        items = {},
        active_item = 1, -- указывает индекс выбранного пункта
        active = false,  -- указывает, что запущено какое-то состояние из меню
        --font = require "fonts".menu,
        --back = require "background".new()
    }
    return setmetatable(self, Menu_mt)
end

-- вызывается из игрового состояния для возвращения в меню
function Menu:goBack()
    local obj = self.items[self.active_item].obj
    if obj.leave then obj:leave() end
    self.active = false
end

function Menu:compute_rects()
    -- позиционирование игрек посредине высоты экрана
    self.y_pos = (self.h - #self.items * self.font:getHeight()) / 2

    -- заполнение прямоугольников меню
    self.items_rects = {}
    local y = self.y_pos
    local rect_width = self.maxWidth
    for _, _ in ipairs(self.items) do
        self.items_rects[#self.items_rects + 1] = { 
            x = (self.w - rect_width) / 2, 
            y = y, 
            w = rect_width, 
            h = self.font:getHeight()
        }
        y = y + self.font:getHeight()
    end
end

function Menu:resize(neww: number, newh: number)
    self.w = neww
    self.h = newh
    self:compute_rects()
    --self.back:resize(neww, newh)
    self.canvas = g.newCanvas(neww, newh, {msaa = 4})
    --print(string.format("menu:resize() %d*%d -> %d*%d!", w, h, neww, newh))
end

-- как лучше хранить актиный элемент из списка меню? По индексу?
-- Важен порядок элементов. Значит добавлять в массив таблички по индексу.
-- TODO перенести в конструктор
function Menu:init()
    self:resize(g.getDimensions())
    self.alpha = 1
end

-- ищет наиболее длинный текст в списке пунктов меню и устанавливает
-- внутреннюю переменную menu.maxWidth по найденному значению(в знаках).
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

-- добавить следующий пункт с заголовком name и обработчиком object.
-- object - таблица с методами update, draw, keypressed и другими.
-- Или object может быть функцией(пока не реализовано).
function Menu:addItem(name: string, object: MenuObject)
    print("menu:addItem()", name, inspect(object))
    assert(type(name) == "string", string.format('Type should be string, not %s', type(name)))
    self.items[#self.items + 1] = { name = name, obj = object as MenuObject}
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

function Menu:keyreleased(key: string)
    if self.active then
        --пересылка обработки в активное состояние
        local obj = self.items[self.active_item].obj
        if obj.keyreleased then obj:keyreleased(key) end
    end
end

function Menu:keypressed(key: string)
    if self.active then
        --пересылка обработки в активное состояние
        local obj = self.items[self.active_item].obj
        assert(obj)
        if obj.keypressed then obj:keypressed(key) end
    else
        --движение по меню

        if key == "up" or key == "k" then self:moveUp()
        elseif key == "down" or key == "j" then self:moveDown()
        elseif key == "escape" then love.event.quit()
        elseif key == "return" or key == "space" then 
            local obj = self.items[self.active_item].obj
            if type(obj) == "function" then
                (obj as function)()
            else
                self.active = true
                if obj.enter then obj:enter() end
            end
        end
    end
end

function Menu:update(dt: number) 
    if self.active then
        local obj = self.items[self.active_item].obj
        if obj.update then obj:update(dt) end
    else
        --self.back:update(dt)
    end
end

--[[
function Menu:process_menu_selection(x: number, y: number, _: number, _: number, _: boolean)
    for k, v in ipairs(self.items_rects) do
        --if pointInRect(x, y, v.x, v.y, v.w, v.h) then 
            --self.active_item = k 
        --end
    end
end
--]]

function Menu:mousemoved(x: number, y: number, dx: number, dy: number, istouch: boolean)
    if self.active then
        local obj = self.items[self.active_item].obj
        if obj.mousemoved then obj:mousemoved(x, y, dx, dy, istouch) end
    else
        self:process_menu_selection(x, y, dx, dy, istouch)
    end
end

function Menu:mousereleased(x: number, y: number, btn: number, istouch: boolean)
    if self.active then
        local obj = self.items[self.active_item].obj
        if obj.mousereleased then obj:mousereleased(x, y, btn, istouch) end
    end
end

function Menu:mousepressed(x: number, y: number, button: number, istouch: boolean)
    if self.active then
        local obj = self.items[self.active_item].obj
        assert(obj)
        if obj.mousepressed then obj:mousepressed(x, y, button, istouch) end
    else
        --[[
        local active_rect = self.items_rects[self.active_item]
        if button == 1 and active_rect and pointInRect(x, y, active_rect.x, 
            active_rect.y, active_rect.w, active_rect.h) then
            self.active = true
            local obj = self.items[self.active_item].obj
            if type(obj) == "table" and obj.enter then obj:enter()
            elseif type(obj) == "function" then (obj as function)() end
        end
        --]]
    end
end

-- печать вертикального списка меню
function Menu:drawList()
    local y = self.y_pos
    g.setFont(self.font)

    --print('Menu:drawList()', inspect(self.items))
    --os.exit()

    for i, k in ipairs(self.items) do
        --local q = self.active_item == i and pallete.active or pallete.inactive 
        local q = self.active_item == i and {1., 1., 1., 1.} or {0., 0., 0., 1.}
        q[4] = self.alpha
        g.setColor(q)
        g.printf(k.name, 0, y, self.w, "center")
        y = y + self.font:getHeight()
    end
    --print("Menu:drawList() self", inspect(self))
end

function Menu:draw()
    --print("Menu:draw() self", inspect(self))
    g.clear(0, 0, 0, 0)
    if self.active then
        local obj = self.items[self.active_item].obj
        if obj.draw then 

            --g.setCanvas{self.canvas, stencil = true}
            --g.setColor{1, 1, 1, 1}
            --g.clear{1, 1, 1, 1}

            obj:draw() 

            --g.setCanvas()
            --g.setColor{1, 1, 1, 0.2}
            --g.clear(pallete.background)
            --g.setColor{1, 1, 1, 1}
            --g.draw(self.canvas)

        end
    else
        g.push("all")
        --self.back:draw()
        self:drawList()
        --self:drawCursor()
        self:cursorDraw()
        g.pop()
    end
end

--function Menu:drawCursor()
function Menu:cursorDraw()
    --print("Menu:drawCursor() self", self.items_rects[self.active_item])
    --print(debug.traceback())

    local v = self.items_rects[self.active_item]
    g.setLineWidth(3)
    g.setColor{1, 0, 0}
    g.rectangle("line", v.x, v.y, v.w, v.h)
end

function Menu:touchpressed(id: number, x: number, y: number, dx: number, dy: number, pressure: number)
    if self.active then
        local obj = self.items[self.active_item].obj
        if obj.touchpressed then obj:touchpressed(id, x, y, dx, dy, pressure) end
    end
end

function Menu:touchreleased(id: number, x: number, y: number, dx: number, dy: number, pressure: number)
    if self.active then
        local obj = self.items[self.active_item].obj
        if obj.touchreleased then obj:touchreleased(id, x, y, dx, dy, pressure) end
    end
end

function Menu:touchmoved(id: number, x: number, y: number, dx: number, dy: number, pressure: number)
    if self.active then
        local obj = self.items[self.active_item].obj
        if obj.touchmoved then obj:touchmoved(id, x, y, dx, dy, pressure) end
    end
end

global mainMenu: Menu = Menu.new()
print('hello from bottom of main menu module.')

--]]
