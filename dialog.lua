module(..., package.seeall)

local Message = require('message')

local methods = {}

function new(game, string, start, font)
   local tbl = {
      game = game,
      string = string,
      font = font,
      finished = false,
      message = Message.new(start,{
                               bg = {196, 190, 91},
                               fg = {154, 98, 0}}),
      text = {99,33,0}
   }

   setmetatable(tbl, {__index=methods})
   return tbl
end

function methods:update(dt)
   if self.finished then return
   else
      self.message:update(dt)
   end
   self.finished = self.message.finished
end

function methods:click()
   if self.message.state == 'waiting' then self.message:close() end
end

function methods:draw()
   local g = love.graphics
   local at = point(100, 100)
   local w, h = 600, 400

   self.message:draw()

   if self.message.state == 'waiting' then
      g.setColor(self.text)
      if self.font then g.setFont(self.font) end
      local f = g.getFont()
      
      local _, lines = f:getWrap(self.string, w-40)
      local ht = lines * f:getHeight()

      g.printf(self.string,
               at.x+20, at.y + (h - ht)/2,
               w-40, 'center')
   end
end
