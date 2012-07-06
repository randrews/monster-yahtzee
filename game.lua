module(..., package.seeall)

local maze = require('maze')

local methods = {}

function new()
   local tbl = {
      maze = maze.new(),
      visible = maze.new(),
      stems = maze.new(),

      state = 'waiting'
   }

   setmetatable(tbl, {__index=methods})
   tbl:init()
   return tbl
end

function methods:init()
   self.maze:maze()
   self.visible:clear(false)
   self.stems:clear(false)

   local start = self.maze:random(function(m, p)
                                     return #(m:at(p)) > 2
                                  end)

   if not start then self:init()
   else
      self.visible:at(start, true)

      for _, p in ipairs(self.maze:connected(start)) do
         self.stems:at(p, true)
      end
   end
end

function methods:reveal(pt)
   assert(self.stems:at(pt), "This isn't a stem")
   assert(self.state == 'waiting', "Not in a valid state to reveal")

   self.state = 'revealing'
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