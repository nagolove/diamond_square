require 'love'

global record Moonshine
    draw_shader: function(any, love.graphics.Shader)
    chain: function(number, number, any): Moonshine
end

return Moonshine
