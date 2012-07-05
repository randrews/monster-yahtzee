module(..., package.seeall)

local maze = require('maze')

local methods = {}

function new()
   local tbl = {
      maze = maze.new(),
      visible = maze.new(),
      stems = maze.new()
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