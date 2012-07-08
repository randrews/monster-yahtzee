module(..., package.seeall)

local methods = {}

function new(game, quads)
   local tbl = {
      game = game,
      quads = quads,
      message = nil
   }

   return setmetatable(tbl, {__index=methods})
end

function methods:draw()
   local g = love.graphics

   g.setColor(30, 30, 20)
   g.rectangle('fill', 0, g.getHeight()-64, g.getWidth(), 64)
end