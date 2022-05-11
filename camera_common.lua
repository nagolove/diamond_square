 BBox_relative = {}




 BBox_pix = {}






local inspect = require("inspect")

local function check_bbox(bbox)

   if not bbox.w or not bbox.h then
      return false
   end
   if bbox.w < 0.1 or bbox.w > 1. then
      return false
   end
   if bbox.h < 0.1 or bbox.h > 1. then
      return false
   end
   return true

end

local function calc_bbox_pix(
   bbox,
   screenW,
   screenH,
   cam_x,
   cam_y)


   if not check_bbox(bbox) then
      error("bad camera bbox: " .. inspect(bbox))
   end
   local real_w, real_h = bbox.w * screenW, bbox.h * screenH

   return {
      x = cam_x + (screenW - real_w) / 2,
      y = cam_y + (screenH - real_h) / 2,
      w = real_w,
      h = real_h,
   }
end

return {
   check_bbox = check_bbox,
   calc_bbox_pix = calc_bbox_pix,
}
