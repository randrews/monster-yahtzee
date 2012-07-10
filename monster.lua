module(..., package.seeall)

local methods = {}

function new(game)
   local tbl = {
      game = game,
      name = 'ghost',
      goal = nil
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
