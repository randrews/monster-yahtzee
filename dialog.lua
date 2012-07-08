module(..., package.seeall)

local methods = {}

DURATION = 0.15 -- Anim duration in secs

function new(game, message, start, font)
   local tbl = {
      game = game,
      message = message,
      start = start, -- Start point in pixel coordinates
      font = font,
      time = 0,
      state = 'opening',
      finished = false,

      bg = {196, 190, 91},
      fg = {154, 98, 0},
      text = {99,33,0}
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
   elseif self.state == 'waiting' then
      self:drawFinishedDialog(dest, dest_w, dest_h)
   end
end

function methods:drawFinishedDialog(at, w, h)
   local g = love.graphics

   g.setColor(self.bg)
   g.rectangle('fill', at.x, at.y, w, h)

   g.setColor(self.fg)
   g.rectangle('line', at.x, at.y, w, h)

   g.setColor(self.text)
   if self.font then g.setFont(self.font) end
   local f = g.getFont()
      
   local _, lines = f:getWrap(self.message, w-40)
   local ht = lines * f:getHeight()

   g.printf(self.message,
            at.x+20, at.y + (h - ht)/2,
            w-40, 'center')
end