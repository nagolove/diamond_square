local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local math = _tl_compat and _tl_compat.math or math; require('konstants')
require('common')
require('vector')

local serpent = require("serpent")
local Pipeline = require('pipeline')
local inspect = require('inspect')
local wrp = require("wrp")



local Tank = {Rect = {}, FullInfo = {}, }





























































































































local rect_body = {
   x = 87,
   y = 73,
   w = 82,
   h = 110,
}


local rect_turret = {
   x = 101,
   y = 0,
   w = 54,
   h = 160,
}

local init_table = {
   x = 0,
   y = 0,

   type = "tank",
   w = rect_body.w,
   h = rect_body.h,


   anchorA = { 0., 0. },
   anchorB = {
      0.,

      -25.,
   },


   turret_dx = 0,
   turret_dy = 0,
   turret_rot_point = { rect_turret.w / 2., rect_turret.h / 2. },

   turret_w = rect_turret.w,
   turret_h = rect_turret.h,
}


local px, py = 0, 0
local impulse_amount = 100
local vel_limit = 160
local ang_vel_limit = 2

function Tank:fire()
end

function Tank:left()


   if ang_vel_limit > self.base:get_ang_vel() then
      self.base:apply_impulse(-0.2, 0, 128, 128)
   end

end

function Tank:right()
   if ang_vel_limit > self.base:get_ang_vel() then
      self.base:apply_impulse(0.2, 0, 128, 128)

   end
end

function Tank:forward()
   local vx, vy = self.base:get_vel()
   local len = vec_len(vx, vy)
   if len < vel_limit then

      self.base:apply_impulse(0, -impulse_amount, px, py);
   end

end

function Tank:backward()

   local vx, vy = self.base:get_vel()
   local len = vec_len(vx, vy)
   if len < vel_limit then
      self.base:apply_impulse(0, impulse_amount, px, py);
   end

end


local tankCounter = 0

local Tank_mt = {
   __index = Tank,
}

function Tank.new(x, y)

   if x ~= x or y ~= y then
      error("NaN in tank positon.")
   end

   local self = setmetatable({}, Tank_mt)

   tankCounter = tankCounter + 1

   self.strength = 1.
   self.fuel = 1.
   self.id = tankCounter
   self.color = { 1, 1, 1, 1 }
   self.type = "tank"

   local debug_verts = nil

   init_table.x, init_table.y = math.floor(x), math.floor(y)
   self.base, debug_verts = wrp.tank_new(init_table, self)

   if debug_verts then
      print("debug_verts:", inspect(debug_verts))
   end

   print('self.base', self.base)



   return self
end

function Tank:update()

   if self.strength <= 0. then
      return nil
   end

   return self
end

function Tank:engineCycle()


   if self.fuel > 0 then
   end
end

function Tank:pushTrack()






























end

function Tank:drawDirectionVector()










end

function Tank:rotate_turret(dir)
   if dir == "left" then
      self.base:turret_rotate(-1)
   elseif dir == "right" then
      self.base:turret_rotate(1)
   end

end

function Tank.initPipelineObjects(pipeline)
   pipeline:pushCodeFromFile("base_shape", 'poly_shape.lua')

   pipeline:open('base_shape')












   local full_info = {
      rect_body = rect_body,
      rect_turret = rect_turret,
      init_table = init_table,
      base_tex_fname = "gfx/body.png",
      turret_tex_fname = "gfx/turret.png",
   }
   local ser_full_info = serpent.dump(full_info)
   pipeline:push(ser_full_info)

   pipeline:close()
end

return Tank
