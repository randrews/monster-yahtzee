module(..., package.seeall)

local methods = {}

function new(game, quads, image)
   local tbl = {
      game = game,
      quads = quads,
      image = image,
      message = nil
   }

   setmetatable(tbl, {__index=methods})
   tbl:init()
   return tbl
end

function methods:init()
   self.font = love.graphics.newFont('Painted.ttf',24)
end

function methods:set_game(game) self.game = game end

function methods:draw()
   local g = love.graphics

   g.setColor(255,255,255)
   local f = self.font
   g.setFont(f)

   for n = 1, self.game.max_health do
      if n > self.game.health then
         g.setColor(0,0,0,128)
      else
         g.setColor(255,255,255)
      end
      g.drawq(self.image, self.quads.heart,
              (n-1)*40+10,
              g.getHeight()-40)
   end

   local m = self.message or string.format("Level %s, score: %s",
                                           self.game.level,
                                           self.game.score)

   g.setColor(99,33,0)
   local maxw = TILE*self.game.max_health+20
   g.printf(m, maxw-10, g.getHeight()-44, g.getWidth() - maxw, 'right')
end