require 'konstants'
require 'pipeline'

-- Заставка
global record Logo
    -- {{{
    --image: love.graphics.Image
    sx: number
    sy: number
    imgw: integer
    imgh: integer

    new: function(): Logo

    present: function()
    -- }}}
end

local pipeline = Pipeline.new(SCENE_PREFIX)

function Logo.new(): Logo
    local Logo_mt: metatable<Logo> = {
        __index = Logo,
    }

    local self = setmetatable({} as Logo, Logo_mt)
    --self.image = love.graphics.newImage(fname)
    --local tex = self.image as gr.Texture
    --local windowscale = 0.7
    --self.imgw, self.imgh = ceil(tex:getWidth()), ceil(tex:getHeight())
    --local newdw, newdh = self.imgw * windowscale, self.imgh * windowscale
    --DEFAULT_W, DEFAULT_H = ceil(newdw), ceil(newdh)
    --self.sx, self.sy = DEFAULT_W / self.imgw, DEFAULT_H / self.imgh
    --setWindowMode()

    --local fname = SCENE_PREFIX .. "/t80_background_2.png"
    pipeline:pushCode('logo_present', [[
    ]])

    return self
end

function Logo:present()
    --gr.setColor{1, 1, 1, 1}
    --print('Logo:present() self.sx, self.sy:', self.sx, self.sy)
    --love.graphics.draw(self.image as gr.Drawable, 0, 0, 0., self.sx, self.sy)
    --yield()
end


