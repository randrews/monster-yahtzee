module(..., package.seeall)

local maze = require('maze')

local methods = {}

function new()
   local tbl = {
      maze = maze.new(),
      visible = maze.new(),
      stems = maze.new(),
      encounters = maze.new(),

      state = 'waiting'
   }

   setmetatable(tbl, {__index=methods})
   tbl:init()
   return tbl
end

function methods:change_state(new_state)
   if self.state == 'waiting' and new_state == 'revealing' then
      self.state = 'revealing'
   elseif self.state == 'revealing' and new_state == 'waiting' then
      self.state = 'waiting'
      self:find_stems()
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

   local enc_count, goal = 0, 15 -- How many encs we've placed; how many we want

   -- Selectors for cell types
   local room = function(m, p) return #(m:at(p)) == 1 end
   local branch = function(m, p) return #(m:at(p)) > 2 end
   local hall = function(m, p) return #(m:at(p)) == 2 end

   for _, p in ipairs(self.maze:find(room)) do
      self.encounters:at(p, true)
      enc_count = enc_count + 1
   end

   if enc_count >= goal then return end
   -- Otherwise, let's do some intersections

   local branches = self.maze:find(branch)

   -- Drop a random branch because we need to guarantee a valid starting place.
   if #branches > 0 then table.remove(branches, math.random(#branches)) end

   while #branches > 0 and enc_count < goal do
      local p = table.remove(branches, math.random(#branches))
      self.encounters:at(p, true)
      enc_count = enc_count + 1
   end

   if enc_count >= goal then return end
   -- Geez, not enouch branches either? Let's start doing random cells then

   local halls = self.maze:find(hall)

   while #halls > 0 and enc_count < goal do
      local p = table.remove(halls, math.random(#halls))
      self.encounters:at(p, true)
      enc_count = enc_count + 1
   end

   -- Good for now
end

function methods:find_stems()
   self.stems:clear(false)
   local seen = function(_,p) return self.visible:at(p) end

   for p in self.maze:each() do
      if not self.visible:at(p) then
         -- Find exits to visible tiles
         local exits = self.maze:connected(p, seen)
         if #exits > 0 then -- this is hidden but connected to a visible, so, stem!
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

   while #(self.maze:at(pt)) == 2 do
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