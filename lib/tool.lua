#!/usr/bin/env lua
_DEBUG      = false
local posix = require("posix")

require("strict")
function tool()
   require ("engine")

   for i = 1,#arg do
      arg[i-1] = arg[i]
   end
   arg[#arg] = nil

   local execDir, execName = engine.splitCmdName(arg[0])
   
   return engine.execute(execDir, execName)
end

os.exit(tool())

