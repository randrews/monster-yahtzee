module(..., package.seeall)

local point = require('point')
local Game = require('game')

local methods = {}

local ANIM = 0.25 -- 1/4 sec per animation
local INTERVAL = 0.1 -- 1/10 sec between starting each tile
local TILE = TILE or 48 -- Pull the tile size from global, or default to 48

function new(game, tiles, map_offset, background)
   local tbl = {
      game = game,
      tiles = tiles,
      map_offset = map_offset or point(0,0),
      background = background,
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
         if self.background then
            g.setColor(255,255,255,a)
            g.drawq(self.background, cover.quad, cover.x, cover.y)
         else
            g.setColor(0,0,0, a)
            g.rectangle('fill', cover.x, cover.y, TILE, TILE)
         end
      end
   end
   g.pop()
end

function methods:makeCovers()
   for _, t in ipairs(self.tiles) do
      local cover = {
         x = t.x*TILE + self.map_offset.x,
         y = t.y*TILE + self.map_offset.y,
         started = false,
         finished = false,
         time = 0
      }

      if self.background then
         cover.quad = love.graphics.newQuad(cover.x, cover.y,
                                            TILE, TILE,
                                            self.background:getWidth(),
                                            self.background:getHeight())
      end

      table.insert(self.covers, cover)
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