local Game = require 'game'

assert(love, "Run this inside Love")

local quads = {}
local mapSprites = nil
local game = nil

function love.load()
   local tiles = love.graphics.newImage('tileset.png')

   local nq = love.graphics.newQuad
   local w, h, sw, sh = 48, 48, 48*5, 48*5

   quads.n = nq(0, 0, w, h, sw, sh)
   quads.e = nq(w, 0, w, h, sw, sh)
   quads.s = nq(w*2, 0, w, h, sw, sh)
   quads.w = nq(w*3, 0, w, h, sw, sh)

   quads.en = nq(0, h, w, h, sw, sh)
   quads.es = nq(w, h, w, h, sw, sh)
   quads.sw = nq(w*2, h, w, h, sw, sh)
   quads.nw = nq(w*3, h, w, h, sw, sh)

   quads.ens = nq(0, h*2, w, h, sw, sh)
   quads.esw = nq(w, h*2, w, h, sw, sh)
   quads.nsw = nq(w*2, h*2, w, h, sw, sh)
   quads.enw = nq(w*3, h*2, w, h, sw, sh)

   quads.ensw = nq(0, h*3, w, h, sw, sh)
   quads.ns = nq(w, h*3, w, h, sw, sh)
   quads.ew = nq(w*2, h*3, w, h, sw, sh)
   quads[''] = nq(w*3, h*3, w, h, sw, sh)

   quads.button = nq(w*4, 0, w, h, sw, sh)

   game = Game.new()
   mapSprites = love.graphics.newSpriteBatch(tiles)
end

function love.draw()
   drawMap(game, mapSprites)
   love.graphics.draw(mapSprites)
end

function drawMap(game, sb)
   sb:clear()
   local map = game.maze
   local vis = game.visible

   for pt in map:each() do
      local q = quads[map:at(pt)]
      if q and vis:at(pt) then
         sb:addq(q, pt.x*48, pt.y*48)
      end
   end

   for pt in game.stems:each() do
      if game.stems:at(pt) then
         sb:addq(quads.button, pt.x*48, pt.y*48)
      end
   end
end