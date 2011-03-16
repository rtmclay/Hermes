-- $Id: CmdLineOptions.lua 306 2009-02-06 18:30:56Z eijkhout $ --

require("Optiks")
CmdLineOptions = BaseTask:new()

function CmdLineOptions:execute(myTable)
   local masterTbl     = masterTbl()
   local usage         = "updateProjectDataVersion [options]" 
   local cmdlineParser = Optiks:new{usage=usage, error = Error}

   cmdlineParser:add_option{ 
      name   = {'--new_version'},
      dest   = 'new_version',
      action = 'store',
      type   = 'string',
      default = false,
   }

   cmdlineParser:add_option{ 
      name   = {'--version'},
      dest   = 'version',
      action = 'store_true',
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
