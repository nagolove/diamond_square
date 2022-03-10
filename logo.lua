require('konstants')
local Pipeline = require('pipeline')


 Logo = {}













local pipeline = Pipeline.new(SCENE_PREFIX)

function Logo.new()
   local Logo_mt = {
      __index = Logo,
   }

   local self = setmetatable({}, Logo_mt)










   pipeline:pushCode('logo_present', [[
    ]])

   return self
end

function Logo:present()




end
