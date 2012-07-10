module(..., package.seeall)

local methods = {}

function new(game)
   local tbl = {
      game = game,
      name = 'ghost',
      goal = nil,
      round = 1,
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
      self.goal = methods.straight
      self.to_hit = 0.5
   else
      self.name = 'huge ghost'
      self.goal = methods.straight
      self.to_hit = 0.75
   end
end

function methods:description()
   local goal_name = ""
   if self.goal == methods.two_pair then goal_name = "two pair"
   elseif self.goal == methods.three_of_a_kind then goal_name = "three of a kind"
   elseif self.goal == methods.straight then goal_name = "a straight" end

   return string.format("You are fighting a %s. It needs %s to defeat.",
                        self.name, goal_name)
end

-- Let the monster attack, return a table with a health delta and a message.
function methods:attack()
   if self.round == 1 and self.surprise then
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

-- Take an array of dice (numbers), and return
-- whether they match the goal or not:
function methods.two_pair(dice)
   return false
end

function methods.three_of_a_kind(dice)
   return false
end

function methods.straight(dice)
   return false
end