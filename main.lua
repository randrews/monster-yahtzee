TILE = 64 -- Size of a tile in px

local Game = require 'game'
local point = require 'point'
local reveal = require 'reveal'
local dialog = require 'dialog'
local status = require 'status'
local combat = require 'combat'

assert(love, "Run this inside Love")

local quads = {}
local mapSprites = nil
local background = nil
local dialogFont = nil
local map_loc = nil
local game = nil
local status_bar = nil
local tiles = nil

local current_animation = nil

function love.load()
   math.randomseed(os.time())
   tiles = love.graphics.newImage('tileset.png')
   background = love.graphics.newImage('background.png')

   local nq = love.graphics.newQuad
   local w, h, sw, sh = TILE, TILE, TILE*5, TILE*5

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
   quads.chest = nq(0, h*4, w, h, sw, sh)
   quads.monster = nq(w, h*4, w, h, sw, sh)
   quads.heart = nq(w*4, h, 40, 40, sw, sh)

   -- Board dims in tiles
   local board_w = math.floor(love.graphics.getWidth()/TILE)
   -- Leave 64px at the bottom for the status bar, yo.
   local board_h = math.floor((love.graphics.getHeight()-64)/TILE)

   -- Offset of map in tiles
   local map_x = (love.graphics.getWidth() - board_w*TILE) / 2
   local map_y = (love.graphics.getHeight() - 64 - board_h*TILE) / 2
   map_loc = point(map_x, map_y)

   game = create_game()

   mapSprites = love.graphics.newSpriteBatch(tiles)
   dialogFont = love.graphics.newFont('Painted.ttf',24)
   love.graphics.setFont(love.graphics.newFont('Painted.ttf', 12))

   status_bar = status.new(game, quads, tiles)
end

function create_game()
   -- Board dims in tiles
   local board_w = math.floor(love.graphics.getWidth()/TILE)
   -- Leave 64px at the bottom for the status bar, yo.
   local board_h = math.floor((love.graphics.getHeight()-64)/TILE)

   return Game.new(board_w,board_h)
end

function love.draw()
   love.graphics.setColor(255,255,255)
   love.graphics.draw(background, 0, 0)

   drawMap(game, mapSprites)
   love.graphics.draw(mapSprites)
   status_bar:draw()

   if current_animation then current_animation:draw() end
end

function drawMap(game, sb)
   love.graphics.setColor(255, 255, 255, 255)
   sb:clear()
   local map = game.maze
   local vis = game.visible

   for pt in map:each() do
      local q = quads[map:at(pt)]
      if q and vis:at(pt) then
         sb:addq(q, pt.x*TILE + map_loc.x, pt.y*TILE + map_loc.y)
      end
   end

   for pt in game.stems:each() do
      if game.stems:at(pt) then
         sb:addq(quads.button, pt.x*TILE + map_loc.x, pt.y*TILE + map_loc.y)
      end
   end

   for pt in game.encounters:each() do
      if game.encounters:at(pt) and game.visible:at(pt) then
         local q = quads[game.encounters:at(pt)] or quads.chest
         sb:addq(q, pt.x*TILE + map_loc.x, pt.y*TILE + map_loc.y)
      end
   end
end

function love.mousepressed(mouse_x, mouse_y)
   x = math.floor((mouse_x-map_loc.x)/TILE)
   y = math.floor((mouse_y-map_loc.y)/TILE)
   local pt = point(x, y)
   if game.state == 'waiting' and game.stems:at(pt) then
      -- They clicked on a stem, give 'em some corridor:
      local path = game:reveal(pt)
      current_animation = reveal.new(game, path, map_loc, background)
   elseif game.state == 'waiting' and game.encounters:at(pt) then
      -- They clicked on an encounter, give 'em the business:
      local center = point(pt.x*TILE+TILE/2, pt.y*TILE+TILE/2) + map_loc
      local type, event = game:encounter(pt)
      if type == 'chest' then
         current_animation = dialog.new(game, event, center, dialogFont)
      else
         current_animation = combat.new(game, event, center, dialogFont, pt)
      end
   elseif game.state == 'encountering' then
      current_animation:click(mouse_x, mouse_y)
   elseif game.state == 'dead' then
      current_animation:click(mouse_x, mouse_y)
      game = create_game()
      status_bar:set_game(game)
   end
end

function point_to_tile(pt)
   pt = pt - map_loc
   local t_pt = point(math.floor(pt.x/TILE), math.floor(pt.y/TILE))
   return game.maze:inside(t_pt) and t_pt
end

function love.update(dt)
   local pt = point_to_tile(point(love.mouse.getPosition()))
   status_bar.message = nil
   if pt and game.state == 'waiting' then
      local enc = game.encounters:at(pt)
      if game.stems:at(pt) then
         status_bar.message = "Click to explore"
      elseif game.visible:at(pt) and enc == 'chest' then
         status_bar.message = "Click to loot chest"
      elseif game.visible:at(pt) and enc == 'monster' then
         local mon = game.monsters:at(pt)
         local name = (mon and mon.name) or "monster"
         status_bar.message = "Click to fight " .. name
      end
   end

   if current_animation then
      current_animation:update(dt)
      if current_animation.finished then
         current_animation = nil
         if game.health == 0 then
            local msg = string.format('You have died, with a score of %s.\nSorry! Click to play again.', game.score)
            current_animation = dialog.new(game,
                                           msg,
                                           point(400, 300),
                                           dialogFont)
            game:change_state('dead')
         else
            game:change_state('waiting')
         end
      end
   end
end