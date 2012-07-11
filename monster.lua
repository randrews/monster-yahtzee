module(..., package.seeall)

local methods = {}

function new(game, boss)
   local tbl = {
      game = game,
      name = 'ghost',
      boss = boss,
      goal = nil,
      round = 1,
      defeated = false,
      surprise = (math.random(2) == 1)
   }

   setmetatable(tbl, {__index=methods})
   tbl:init()
   return tbl
end

function methods:init()
   local r = math.random(10)

   if r <= 3 then
      self.name = 'tiny ghost'
      self.goal = methods.two_pair
      self.to_hit = 0.25
   elseif r <=6 then
      self.name = 'ghost'
      self.goal = methods.three_of_a_kind
      self.to_hit = 0.5
   elseif r <= 8 then
      self.name = 'large ghost'
      self.goal = methods.full_house
      self.to_hit = 0.5
   else
      self.name = 'huge ghost'
      self.goal = methods.four_of_a_kind
      self.to_hit = 0.6
   end
end

function methods:start_combat()
   if self.boss then
      self.name = 'boss ghost'
      self.goal = methods.straight
      self.to_hit = 0.5 + 0.05 * self.game.level
   end
end

function methods:description()
   local goal_name = ""
   if self.goal == methods.two_pair then goal_name = "two pair"
   elseif self.goal == methods.three_of_a_kind then goal_name = "three of a kind"
   elseif self.goal == methods.four_of_a_kind then goal_name = "four of a kind"
   elseif self.goal == methods.full_house then goal_name = "a full house"
   elseif self.goal == methods.straight then goal_name = "a straight" end

   if self.defeated then
      return string.format("You have defeated the %s with %s!",
                        self.name, goal_name)
   else
      if self.boss then
         return string.format("Surprise! You are fighting the level boss. It needs %s to defeat.", goal_name)
      else
         return string.format("You are fighting a %s. It needs %s to defeat.",
                              self.name, goal_name)
      end
   end
end

-- Let the monster attack, return a table with a health delta and a message.
function methods:attack()
   if self.defeated then
      return {health=0, message="You defeat the monster!"}
   elseif self.round == 1 and self.surprise then
      return {health=0, message="You surprise it!"}
   else
      local to_hit = math.max(0.1, self.to_hit - self.game.armor * 0.1)
      local swing = math.random()

      if swing <= to_hit then -- A solid hit
         return {health=-1, message="The monster hits you!"}
      elseif swing <= self.to_hit then -- Hit the armor...
         return {health=0, message="The monster is blocked by your armor!"}
      else -- A straight-up miss
         return {health=0, message="The monster misses you."}
      end
   end
end

function methods:next_round()
   self.round = self.round + 1
end

-- Takes an array of dice and sets defeated if it's what kills this dude.
function methods:try_roll(dice)
   if self.goal(dice) then self.defeated = true end
   return self.defeated
end

-- Returns a frequency chart of an array of dice
function methods.frequency(dice)
   local f = {}
   for _, d in ipairs(dice) do
      if not f[d] then f[d] = 1
      else f[d] = f[d] + 1 end
   end

   return f
end

-- Take an array of dice (numbers), and return
-- whether they match the goal or not:
function methods.two_pair(dice)
   local f = methods.frequency(dice)
   local c = 0

   for _, n in pairs(f) do
      if n >= 2 then c = c + 1 end
   end

   return c >= 2
end

function methods.three_of_a_kind(dice)
   local f = methods.frequency(dice)

   for _, n in pairs(f) do
      if n >= 3 then return true end
   end
   return false
end

function methods.straight(dice)
   local f = methods.frequency(dice)

   for n=2, 5 do
      if not f[n] or f[n] == 0 then return false end
   end
   return f[1] or f[6]
end

function methods.four_of_a_kind(dice)
   local f = methods.frequency(dice)

   for _, n in pairs(f) do
      if n >= 4 then return true end
   end
   return false
end

function methods.full_house(dice)
   local f = methods.frequency(dice)
   local three, two = false, false

   for _, n in pairs(f) do
      if n >= 3 then three=true
      elseif n >= 2 then two=true end
   end
   return three and two
end