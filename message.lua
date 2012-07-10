module(..., package.seeall)

local methods = {}
DURATION = 0.15 -- Anim duration in secs

function new(start, colors)
   colors = colors or {}

   local tbl = {
      start = start, -- Start point in pixel coordinates
      state = 'opening',
      time = 0,
      finished = false,

      fg = colors.fg or {154, 98, 0},
      bg = colors.bg or {99,33,0}
   }

   setmetatable(tbl, {__index=methods})
   return tbl
end

function methods:update(dt)
   if self.finished then return
   else
      if self.state == 'opening' then
         self.time = self.time + dt
         if self.time >= DURATION then
            self.time = DURATION
            self.state = 'waiting'
         end
      elseif self.state == 'closing' then
         self.time = self.time - dt
         if self.time <= 0 then
            self.time = 0
            self.finished = true
         end
      end
   end
end

function methods:close()
   self.state = 'closing'
end

function methods:draw()
   local g = love.graphics

   local dest = point(100, 100)
   local dest_w, dest_h = 600, 400

   if self.state == 'opening' or self.state == 'closing' then
      local pct = self.time / DURATION
      local curr_x = (dest.x - self.start.x) * pct + self.start.x
      local curr_y = (dest.y - self.start.y) * pct + self.start.y

      local curr_w = dest_w * pct
      local curr_h = dest_h * pct

      g.setColor(self.bg)
      g.rectangle('fill', curr_x, curr_y, curr_w, curr_h)

      g.setColor(self.fg)
      g.rectangle('line', curr_x, curr_y, curr_w, curr_h)
   else
      g.setColor(self.bg)
      g.rectangle('fill', dest.x, dest.y, dest_w, dest_h)

      g.setColor(self.fg)
      g.rectangle('line', dest.x, dest.y, dest_w, dest_h)
   end
end
