-- vim: fdm=marker
-- vim: set colorcolumn=85

local ffi = require('ffi')
ffi.cdef[[
typedef struct {
  float x, y;
  float u, v;
  unsigned char r, g, b, a;
} fm_vertex;
]]
local vertex_size = ffi.sizeof('fm_vertex')
local pixel_size = ffi.sizeof('unsigned char[4]')
local num_verts = meshBufferSize * 6
local imageData = love.image.newImageData(num_verts / pixel_size * vertex_size, 1)
local data = ffi.cast("fm_vertex*", imageData:getPointer())

local function base_present(
    x1, y1, x2, y2, x3, y3, x4, y4,
    rx, ry, rw, rh
)

    assert(x1)
    assert(y1)
    assert(x2)
    assert(y2)
    assert(x3)
    assert(y3)
    assert(x4)
    assert(y4)
    assert(rx)
    assert(ry)
    assert(rw)
    assert(rh)

    -- размеры текстуры в пикселях
    local imgw, imgh = baseImage:getDimensions()
    -- нормализованная ширина и высота
    local unitw, unith = rw / imgw, rh / imgh
    -- нормализованные координаты левого верхнего угла выделения
    local x_, y_ = rx / imgw, ry / imgh

    --if basesMeshVerts == nil then
        --print("ret11")
        --return
    --end

    --print(x1, y1, x2, y2, x3, y3, x4, y4, rx, ry, rw, rh)
    --print('base_present')
    --print("#basesMeshVerts", #basesMeshVerts)
    --print("basesMeshVerts", basesMeshVerts)
    --print("baseMeshIndex", baseMeshIndex)
    
    local vertex

    -- tri1
    basesMeshVerts[baseMeshIndex + 1][1] = x1
    basesMeshVerts[baseMeshIndex + 1][2] = y1
    basesMeshVerts[baseMeshIndex + 1][3] = x_ + unitw
    basesMeshVerts[baseMeshIndex + 1][4] = y_

    vertex = data[baseMeshIndex + 1]
    vertex.x = x1
    vertex.y = y1
    vertex.u = x_ + unitw
    vertex.v = y_
    vertex.r, vertex.g, vertex.b, vertex.a = 1, 1, 1, 1

    basesMeshVerts[baseMeshIndex + 2][1] = x2
    basesMeshVerts[baseMeshIndex + 2][2] = y2
    basesMeshVerts[baseMeshIndex + 2][3] = x_ + unitw
    basesMeshVerts[baseMeshIndex + 2][4] = y_ + unith

    vertex = data[baseMeshIndex + 2]
    vertex.x = x2
    vertex.y = y2
    vertex.u = x_ + unitw
    vertex.v = y_ + unith
    vertex.r, vertex.g, vertex.b, vertex.a = 1, 1, 1, 1

    basesMeshVerts[baseMeshIndex + 3][1] = x4
    basesMeshVerts[baseMeshIndex + 3][2] = y4
    basesMeshVerts[baseMeshIndex + 3][3] = x_
    basesMeshVerts[baseMeshIndex + 3][4] = y_

    vertex = data[baseMeshIndex + 3]
    vertex.x = x4
    vertex.y = y4
    vertex.u = x_
    vertex.v = y_
    vertex.r, vertex.g, vertex.b, vertex.a = 1, 1, 1, 1

    -- tri2
    basesMeshVerts[baseMeshIndex + 5][1] = x2
    basesMeshVerts[baseMeshIndex + 5][2] = y2
    basesMeshVerts[baseMeshIndex + 5][3] = x_ + unitw
    basesMeshVerts[baseMeshIndex + 5][4] = y_ + unith

    vertex = data[baseMeshIndex + 5]
    vertex.x = x2
    vertex.y = y2
    vertex.u = x_ + unitw
    vertex.v = y_ + unith
    vertex.r, vertex.g, vertex.b, vertex.a = 1, 1, 1, 1

    basesMeshVerts[baseMeshIndex + 6][1] = x3
    basesMeshVerts[baseMeshIndex + 6][2] = y3
    basesMeshVerts[baseMeshIndex + 6][3] = x_
    basesMeshVerts[baseMeshIndex + 6][4] = y_ + unith

    vertex = data[baseMeshIndex + 6]
    vertex.x = x3
    vertex.y = y3
    vertex.r, vertex.g, vertex.b, vertex.a = 1, 1, 1, 1

    basesMeshVerts[baseMeshIndex + 4][1] = x4
    basesMeshVerts[baseMeshIndex + 4][2] = y4
    basesMeshVerts[baseMeshIndex + 4][3] = x_
    basesMeshVerts[baseMeshIndex + 4][4] = y_

    vertex = data[baseMeshIndex + 4]
    vertex.x = x4
    vertex.y = y4
    vertex.u = x_
    vertex.v = y_
    vertex.r, vertex.g, vertex.b, vertex.a = 1, 1, 1, 1

     --DEBUG_TEXCOORDS 
    -- {{{
    if DEBUG_TEXCOORDS then
        local msg = string.format("(%f, %f), (%f, %f), (%f, %f)",
            basesMeshVerts[baseMeshIndex + 4][3],
            basesMeshVerts[baseMeshIndex + 4][4],
            basesMeshVerts[baseMeshIndex + 5][3],
            basesMeshVerts[baseMeshIndex + 5][4],
            basesMeshVerts[baseMeshIndex + 6][3],
            basesMeshVerts[baseMeshIndex + 6][4]
        )
        print(string.format("BaseP.self.meshVerts texture coordinates: " .. msg))
    end
    -- }}}
    --]]

    --basesMesh:setVertices(basesMeshVerts, 1 + 6 * baseMeshCount, 6)

    --basesMesh:setVertices(basesMeshVerts)
    --basesMesh:setVertices(imageData)

    --basesMesh:setVertices(basesMeshVerts, 1 + baseMeshIndex, 6)
    
    print('baseMeshIndex', baseMeshIndex)
    print('basesMesh:getDrawRange()', basesMesh:getDrawRange())
    if baseMeshIndex ~= 0 then
        --basesMesh:setDrawRange(1, baseMeshIndex/2)
    end
    --print("self.meshVerts", inspect(self.meshVerts))
    baseMeshIndex = baseMeshIndex + 6
    baseMeshCount = baseMeshCount + 1
end

return {
    base_present = base_present,
}
