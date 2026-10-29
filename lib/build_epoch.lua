_DEBUG      = false
local posix = require("posix")

local gettimeofday = require("posix.sys.time").gettimeofday

require("strict")

epoch = false
function build_epoch()
   if (posix.gettimeofday) then
      local x1, x2 = gettimeofday()
      if (x2 == nil) then
         epoch = function()
            local t = gettimeofday()
            return t.tv_sec + t.tv_usec*1.0e-6
         end
      else
         epoch = function()
            local t1, t2 = gettimeofday()
            return t1 + t2*1.0e-6
         end
      end
   else
      require("sys")
      epoch = sys.gettimeofday
   end
end
