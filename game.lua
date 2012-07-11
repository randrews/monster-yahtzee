module(..., package.seeall)

local maze = require('maze')
local chest = require('chest')
local monster = require('monster')

local methods = {}

function new(w, h)
   w = w or 10
   h = h or 10

   local tbl = {
      maze = maze.new(w,h),
      visible = maze.new(w,h),
      stems = maze.new(w,h),
      encounters = maze.new(w,h),
      monsters = maze.new(w,h),

      health = 3,
      max_health = 4,
      score = 0,
      armor = 0,

      state = 'waiting'
   }

   setmetatable(tbl, {__index=methods})
   tbl:init()
   return tbl
end

function methods:change_state(new_state)
   if self.state == new_state then return end

   if self.state == 'waiting' and new_state == 'revealing' then
      self.state = 'revealing'
   elseif self.state == 'revealing' and new_state == 'waiting' then
      self.state = 'waiting'
      self:find_stems()
   elseif self.state == 'waiting' and new_state == 'encountering' then
      self.state = 'encountering'
   elseif self.state == 'encountering' and new_state == 'waiting' then
      self.state = 'waiting'
      self:find_stems()
   elseif self.state == 'encountering' and new_state == 'dead' then
      self.state = 'dead'
   else
      error(string.format('Cannot switch to state %s from %s', new_state, self.state))
   end
end

function methods:init()
   self.maze:maze()
   self.visible:clear(false)
   self.stems:clear(false)
   self:create_encounters()

   -- Nice to have a couple choices at the start.
   local start = self.maze:random(function(m, p)
                                     return #(m:at(p)) > 2 and not self.encounters:at(p)
                                  end)

   if not start then self:init() -- Vanishingly unlikely, but there can be zero branches.
   else
      self.visible:at(start, true)
      self:find_stems()
   end
end

function methods:create_encounters()
   self.encounters:clear(false)
   local enc = self:place_encounters()

   -- Actually make them into chests / monsters
   for pt in enc:each() do
      if enc:at(pt) then
         if math.random(2) == 1 then
            self.encounters:at(pt, 'monster')
            self.monsters:at(pt, monster.new(self))
         else
            self.encounters:at(pt, 'chest')
         end
      end
   end

   local room = function(m, p) return #(m:at(p)) == 1 end
   local rooms = self.maze:find(room)
   local exit = table.remove(rooms, math.random(#rooms))
   self.encounters:at(exit, 'ladder')
end

function methods:place_encounters()
   local encounters = maze.new(self.encounters.width, self.encounters.height)
   encounters:clear(false)

   local enc_count = 0 -- How many encs we've placed
   -- how many we want:
   local goal = math.floor(self.maze.width * self.maze.height / 5)

   -- Selectors for cell types
   local room = function(m, p) return #(m:at(p)) == 1 end
   local branch = function(m, p) return #(m:at(p)) > 2 end
   local hall = function(m, p) return #(m:at(p)) == 2 end

   for _, p in ipairs(self.maze:find(room)) do
      encounters:at(p, true)
      enc_count = enc_count + 1
   end

   if enc_count >= goal then return encounters end
   -- Otherwise, let's do some intersections

   local branches = self.maze:find(branch)

   -- Drop a random branch because we need to guarantee a valid starting place.
   if #branches > 0 then table.remove(branches, math.random(#branches)) end

   while #branches > 0 and enc_count < goal do
      local p = table.remove(branches, math.random(#branches))
      encounters:at(p, true)
      enc_count = enc_count + 1
   end

   if enc_count >= goal then return encounters end
   -- Geez, not enouch branches either? Let's start doing random cells then

   local halls = self.maze:find(hall)

   while #halls > 0 and enc_count < goal do
      local p = table.remove(halls, math.random(#halls))
      encounters:at(p, true)
      enc_count = enc_count + 1
   end

   return encounters
end

function methods:find_stems()
   self.stems:clear(false)

   -- A tile that is hidden, but contains an exit to a visible tile
   -- (which doesn't coa non-chest encounter) is a stem:
   local seen_and_clear =
      function(_,p)
         return (self.visible:at(p) and
              (not self.encounters:at(p) or self.encounters:at(p) == 'chest'))
      end

   for p in self.maze:each() do
      if not self.visible:at(p) then
         -- Find exits to visible/clear tiles
         local exits = self.maze:connected(p, seen_and_clear)
         if #exits > 0 then -- this is hidden but connected to a visible/clear, so, stem!
            self.stems:at(p, true)
         end
      end
   end
end

function methods:reveal(pt)
   assert(self.stems:at(pt), "This isn't a stem")

   self:change_state('revealing')
   self.stems:at(pt, false)

   local corridor = {pt}
   self.visible:at(pt, true)

   -- Return true iff pt should stop a reveal chain
   local function stopper(pt)
      return #(self.maze:at(pt)) ~= 2 or self.encounters:at(pt)
   end

   while not stopper(pt) do
      local n = self:next(pt)
      self.visible:at(n, true)
      table.insert(corridor, n)
      pt = n
   end

   return corridor
end

function methods:next(pt)
   local hidden = function(_,p) return not self.visible:at(p) end
   local possible = self.maze:connected(pt, hidden)
   assert(#possible == 1, "Multiple paths from this cell")
   return possible[1]
end

function methods:encounter(pt)
   assert(self.encounters:at(pt), "This isn't an encounter")
   self:change_state('encountering')

   if self.encounters:at(pt) == 'chest' then
      self.encounters:at(pt, false)
      local c = chest.new(self)
      c:apply()
      -- Return a message that we can pop up in a dialog
      return 'chest', c.message
   else
      assert(self.monsters:at(pt))
      -- Return a monster that we can bring up a combat with
      return 'monster', self.monsters:at(pt)
   end
end

function methods:remove_monster(pt)
      assert(self.monsters:at(pt))
      self.encounters:at(pt, false)
      self.monsters:at(pt, nil)
end

function methods:change_health(dh)
   self.health = self.health + dh
   self.health = math.min(self.health, self.max_health)
   self.health = math.max(self.health, 0)
end