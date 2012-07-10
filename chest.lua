module(..., package.seeall)

local methods = {}

function new(game)
   local tbl = {
      game = game,
      message = '',
      health = 0,
      points = 0,
      armor = 0
   }

   setmetatable(tbl, {__index=methods})
   tbl:init()
   return tbl
end

function methods:init()
   self.type = self:random_type()
   self['populate_'..self.type](self)
end

function methods:random_type()
   -- Types are health (20%), armor (20%), trap (10%), gold (50%)
   local type
   
   local r = math.random(10)
   if r == 1 then type = 'trap'
   elseif r <= 3 then type = 'health'
   elseif r <= 5 then type = 'armor'
   else type = 'gold' end

   -- Let's not kill the player to a trap, shall we? It's annoying.
   if self.game.health == 1 and type == 'trap' then type = 'health' end

   return type
end

function methods:populate_health()
   if self.game.health == self.game.max_health then
      self.message = "You find a health potion, but you don't need it.\nYou sell it for 100 points."
      self.points = 100
   else
      self.message = "You find a health potion, and drink it.\nYou gain one health!"
      self.health = 1
   end
end

function methods:populate_trap()
   self.health = -1

   local r = math.random(5)
   if r == 1 then
      self.message = "The chest is full of poisonous spiders!"
   elseif r == 2 then
      self.message = "As you approach the chest, a dart shoots from the wall at you!"
   elseif r == 3 then
      self.message = "The chest is full of delicious berries!\n...Delicious, poisonous berries."
   elseif r == 4 then
      self.message = "You reach inside, and the chest snaps shut on your hand, biting off a finger."
   elseif r == 5 then
      self.message = "The clasp on the chest is electrified."
   end

   self.message = self.message .. "\nYou lose one health."
end

function methods:populate_armor()
   self.armor = 1
   local pieces = {
      "chainmail shirt",
      "steel helmet",
      "pair of sturdy boots",
      "wooden shield"
   }
   self.message = string.format("You find a %s!", pieces[math.random(#pieces)])

   if self.game.armor > 0 then
      self.message = self.message .. string.format("\nYou now have %s pieces of armor.",
                                                   self.game.armor + 1)
   end
end

function methods:populate_gold()
   local adj = {
      "dented",
      "tarnished",
      "tacky",
      "shiny",
      "beautiful",
      "gem-covered"
   }

   local base = math.random(#adj)

   local noun = {
      'crown',
      'scepter',
      'ring',
      'chalice',
      'bracelet',
      'necklace'
   }

   local val = base * 100 + math.random(6) * 10 - 10
   self.message = string.format("You find a %s %s.\nYou sell it for %s points!",
                                adj[base], noun[math.random(#noun)], val)
   self.points = val
end

function methods:apply()
   local g = self.game

   g.score = g.score + self.points
   g.armor = g.armor + self.armor
   g:change_health(self.health)
end