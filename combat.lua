module(..., package.seeall)

local message = require('message')

local methods = {}

function new(game, monster, start, font)
   local tbl = {
      game = game,
      monster = monster,
      message = message.new(start, colors),
      font = font,
      finished = false,
      text = {196, 190, 91}
   }

   setmetatable(tbl, {__index=methods})
   tbl:init()
   return tbl
end

function methods:init()
end

function methods:click(x, y)
   if self.message.state == 'waiting' then
      self.message:close()
   end
end

function methods:update(dt)
   if self.finished then return
   else
      self.message:update(dt)
   end
   self.finished = self.message.finished
end

function methods:draw(at, w, h)
   self.message:draw()

   if self.message.state == 'waiting' then
      local g = love.graphics

      local at = point(100, 100)
      local w, h = 600, 400

      g.setColor(self.text)
      if self.font then g.setFont(self.font) end
      local f = g.getFont()
      
      local _, lines = f:getWrap('blah', w-40)
      local ht = lines * f:getHeight()

      g.printf('blah',
               at.x+20, at.y + (h - ht)/2,
               w-40, 'center')
   end
end