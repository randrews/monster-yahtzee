module(..., package.seeall)

local message = require('message')

local methods = {}

function new(game, monster, start, font, map_cell)
   local tbl = {
      game = game,
      monster = monster,
      map_cell = map_cell,
      message = message.new(start, colors),
      font = font,
      finished = false,
      text = {196, 190, 91},
      recent_round = nil,
      dice = {0, 0, 0, 0, 0},
      saved = {}
   }

   setmetatable(tbl, {__index=methods})
   tbl:init()
   return tbl
end

function methods:init()
   self.monster:start_combat()
   self:roll()
   self.monster:try_roll(self:all_dice())

   self.recent_round = self.monster:attack()
   self.game:change_health(self.recent_round.health)
end

function methods:click(x, y)
   if self.message.state == 'waiting' then
      if self.game.health == 0 or self.monster.defeated then
         if self.monster.defeated then self.game:remove_monster(self.map_cell) end
         self.message:close()
      else
         local ms = point(x, y)
         -- First, are we rolling?
         if self:click_in(ms, self:roll_button_rect()) then

            self:roll()
            self.monster:try_roll(self:all_dice())

            self.monster:next_round()
            self.recent_round = self.monster:attack()
            self.game:change_health(self.recent_round.health)

         else
            -- Then, maybe we clicked on a real die?
            local d = self:dice_rect()

            for n = 1, #self.dice do
               local l, s = self:die_rect(n)

               if self:click_in(ms, d+l, s) then
                  local die = table.remove(self.dice, n)
                  table.insert(self.saved, die)
                  break
               end
            end

            -- Or a saved die?
            local sd = self:saved_dice_rect()

            for n = 1, #self.saved do
               local l, s = self:die_rect(n)

               if self:click_in(ms, sd+l, s) then
                  local die = table.remove(self.saved, n)
                  table.insert(self.dice, die)
                  break
               end
            end
         end
      end
   end
end

function methods:all_dice()
   local all = {}
   for _, d in ipairs(self.dice) do table.insert(all, d) end
   for _, d in ipairs(self.saved) do table.insert(all, d) end
   return all
end

function methods:click_in(pt, loc, size)
   assert(pt and loc and size)
   return pt >= loc and pt <= loc+size
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
      
      local _, lines = f:getWrap(self.recent_round.message, w-40)
      local ht = lines * f:getHeight()

      g.printf(self.monster:description(), at.x+20, at.y+20, w-40, 'left')

      local str = string.format('Round %s: %s', self.monster.round,
                                self.recent_round.message)
      g.printf(str,
               at.x+20, at.y + 64,
               w-40, 'center')

      g.push()
      local loc, size = self:dice_rect()
      g.translate(loc.x, loc.y)
      g.setColor(self.text)
      g.rectangle('line', 0, 0, size.x, size.y)
      g.printf('Dice: click to save', 0, -34, w-40, 'left')
      self:draw_dice(self.dice)
      g.pop()

      g.push()
      local loc, size = self:saved_dice_rect()
      g.translate(loc.x, loc.y)
      g.setColor(self.text)
      g.rectangle('line', 0, 0, size.x, size.y)
      g.printf('Saved dice:', 0, -34, w-40, 'left')
      self:draw_dice(self.saved)
      g.pop()

      if self.game.health > 0 and not self.monster.defeated then
         g.push()
         local loc, size = self:roll_button_rect()
         g.translate(loc.x, loc.y)
         g.setColor(self.text)
         g.rectangle('line', 0, 0, size.x, size.y)
         g.printf('Roll', 0, size.y/2-12, size.x, 'center')
         g.pop()
      else
         g.setColor(self.text)
         g.printf('Click to continue',
                  at.x+20, at.y + h-40,
                  w-40, 'center')
      end
   end
end

function methods:draw_dice(dice)
   local g = love.graphics

   for n, d in ipairs(dice) do
      g.setColor(self.text)
      local loc, siz = self:die_rect(n)
      g.rectangle('fill', loc.x, loc.y, siz.x, siz.y)
      g.setColor(self.message.bg)
      g.printf(tostring(d), loc.x, loc.y+2, siz.x, 'center')
   end
end

-- Returns the point (offset from the origin of the dice box) for die n,
-- and a point representing the size
-- n is in 1..5
function methods:die_rect(n)
   return point(10 + 39*(n-1), 7), point(32, 32)
end

-- Returns two points representing the loc and size of the rolled dice rect
function methods:dice_rect()
   local at = point(100, 100)
   local w, h = 600, 400

   local loc = point(at.x+20, at.y+h -- bottom of box
         - 30 -- margin
         - 48 -- height of box
         - (48+34+20)) -- Height of other box

   local size = point(32*5+8*6, 48)

   return loc, size
end

-- Returns two points representing the loc and size of the saved dice rect
function methods:saved_dice_rect()
   local at = point(100, 100)
   local w, h = 600, 400

   local loc = point(at.x+20, at.y+h -- bottom of box
         - 40 -- margin
         - 48) -- height of box

   local size = point(32*5+8*6, 48)
   return loc, size
end

-- Returns two points representing the loc and size of the roll button
function methods:roll_button_rect()
   local at = point(100, 100)
   local w, h = 600, 400

   local dl, ds = self:dice_rect()
   local sl, ss = self:saved_dice_rect()

   local loc = point(dl.x+ds.x+20, dl.y)
   local dim = (sl.y+ss.y) - dl.y

   return loc, point(dim, dim)
end

function methods:roll()
   local count = #self.dice
   self.dice = {}
   for n = 1, count do table.insert(self.dice, math.random(6)) end
end