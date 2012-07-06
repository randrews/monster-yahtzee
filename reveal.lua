module(..., package.seeall)

local point = require('point')
local Game = require('game')

local methods = {}

ANIM = 0.25 -- 1/4 sec per animation
INTERVAL = 0.1 -- 1/10 sec between starting each tile

function new(game, tiles)
   local tbl = {
      game = game,
      tiles = tiles,
      time = 0,
      finished = false,
      covers = {}
   }

   setmetatable(tbl, {__index=methods})
   tbl:makeCovers()
   tbl:startCover()
   return tbl
end

function methods:update(dt)
   self.time = self.time + dt
   if self.time >= INTERVAL then
      self.time = 0
      self:startCover()
   end

   for _, cover in ipairs(self.covers) do
      if cover.started then cover.time = cover.time + dt end
      if cover.time >= ANIM then cover.time = ANIM ; cover.finished = true end
   end

   for _, cover in ipairs(self.covers) do
      if not cover.finished then return end
   end
   self.finished = true
end

function methods:draw()
   local g = love.graphics
   g.push()
   for _, cover in ipairs(self.covers) do
      local a = (ANIM - cover.time) * 255 / ANIM

      if not cover.finished and a > 0 then
         g.setColor(0,0,0, a)
         g.rectangle('fill', cover.x, cover.y, cover.w, cover.h)
      end
   end
   g.pop()
end

function methods:makeCovers()
   for _, t in ipairs(self.tiles) do
      table.insert(self.covers, {
                      x = t.x*48,
                      y = t.y*48,
                      w = 48, h = 48,
                      started = false,
                      finished = false,
                      time = 0
                   })
   end
end

function methods:startCover()
   for _, cover in ipairs(self.covers) do
      if not cover.started then
         cover.started = true
         return true
      end
   end

   return false
end