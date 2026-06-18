CmdLineOptions = BaseTask:new()

local function vname()
   return "1.0"
end

function CmdLineOptions:execute(myTable)
   local masterTbl     = masterTbl()
   local Optiks        = require("Optiks")

   local usage         = "Usage: findcmd [options] cmd"

   local cmdlineParser = Optiks:new{usage=usage,version=vname(), error = Error}

   cmdlineParser:add_option{
      name   = {'--pathOnly'},
      dest   = 'pathOnly',
      action = 'store_true',
      help   = 'return just the path without the command',
   }

   cmdlineParser:add_option{
      name   = {'--debug','-D'},
      dest   = 'debug',
      action = 'store_true',
      help   = 'Turn on debugging',
   }


   local optionTbl, pargs = cmdlineParser:parse(arg)

   for v in pairs(optionTbl) do
      masterTbl[v] = optionTbl[v]
   end
   masterTbl.pargs = pargs
end
