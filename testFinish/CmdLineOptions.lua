-- $Id: CmdLineOptions.lua 302 2009-02-04 23:56:32Z mclay $ --
CmdLineOptions = BaseTask:new()

function CmdLineOptions:execute(myTable)
   local masterTbl     = masterTbl()
   local usage         = "testfinish [options]"
   local Optiks        = require("Optiks")
   local cmdlineParser = Optiks:new{usage=usage, error = Error}

   cmdlineParser:add_option{ 
      name   = {'-c'},
      dest   = 'cmdResultFn',
      action = 'store',
      type   = 'string',
   }

   cmdlineParser:add_option{ 
      name   = {'-r','--resultFn'},
      dest   = 'resultFn',
      action = 'store',
      type   = 'string',
   }

   cmdlineParser:add_option{ 
      name   = {'-t','--runtimeFn'},
      dest   = 'runtimeFn',
      action = 'store',
      type   = 'string',
   }

   cmdlineParser:add_option{ 
      name   = {'--onFailure'},
      dest   = 'failFn',
      action = 'store',
      type   = 'string',
   }

   cmdlineParser:add_option{ 
      name   = {'-v','--verbose'},
      dest   = 'verbosityLevel',
      action = 'count'
   }

   local optionTbl, pargs = cmdlineParser:parse(arg)

   for v in pairs(optionTbl) do
      masterTbl[v] = optionTbl[v]
   end

   masterTbl.pargs = pargs

end
