_DEBUG      = false
local posix = require("posix")
require("strict")
require("common")
require("string_utils")
require("fileOps")
require("version")
local getcwd = require("posix.unistd").getcwd

CmdLineOptions = BaseTask:new()

local function vname()
   return "tm "..Version
end


function CmdLineOptions:execute(myTable)
   local masterTbl     = masterTbl()

   local usage         = "Usage: tm [options] [file] [directory]"

   local Optiks        = require("Optiks")
   local cmdlineParser = Optiks:new{usage=usage,version=vname(), error = Error}

   cmdlineParser:add_option{
      name   = {'-a','--analyze'},
      dest   = 'analyzeFlag',
      action = 'store_true',
      help   = 'Analyze for the current target',
   }
   cmdlineParser:add_option{
      name   = {'-A','--Analyze'},
      dest   = 'AnalyzeFlag',
      action = 'store_true',
      help   = 'Analyze for the all targets',
   }

   cmdlineParser:add_option{
      name   = {'-b','--batch'},
      dest   = 'BatchFlag',
      action = 'store_true',
      help   = 'Submit tests to a batch queue',
   }

   cmdlineParser:add_option{
      name   = {'--batchlog'},
      dest   = 'batchLog',
      action = 'store',
      help   = 'filename to capture submit script info',
   }

   cmdlineParser:add_option{
      name    = {'--epoch'},
      dest    = 'epoch',
      action  = 'store',
      type    = 'number',
      default = -1,
      help    = 'Use the epoch given',
   }

   cmdlineParser:add_option{
      name   = {'-f','--full'},
      dest   = 'full',
      action = 'store_true',
      help   = 'Report individual test results when spanning targets',
   }

   cmdlineParser:add_option{
      name   = {'-g','--generate'},
      dest   = 'generate',
      action = 'store_true',
      help   = 'Generate a test list and store in "my.tests" in project directory',
   }

   cmdlineParser:add_option{
      name   = {'-k','--keyword'},
      dest   = 'keywords',
      action = 'append',
      help   = 'A keyword to select tests',
   }

   cmdlineParser:add_option{
      name   = {'--interactive'},
      dest   = 'InteractiveFlag',
      action = 'store_true',
      help   = 'Force batch run to be interactive.',
   }

   cmdlineParser:add_option{
      name   = {'-m','--min', '--minNP'},
      dest   = 'minNP',
      action = 'store',
      type   = 'number',
      help   = 'the minimum number of processor that will be run',
   }

   cmdlineParser:add_option{
      name    = {'-n', '--times'},
      dest    = 'ntimes',
      action  = 'store',
      type    = 'number',
      default = 1,
      help    = 'Run each test the number of times given',
   }

   cmdlineParser:add_option{
      name   = {'-r','--restart'},
      dest   = 'restart',
      action = 'append',
      type   = 'string',
      help   = 'A restart criteria to select tests to rerun, "-r wrong" will restart all test that did not pass',
   }

   cmdlineParser:add_option{
      name   = {'-R','--Restart'},
      dest   = 'Restart',
      action = 'append',
      type   = 'string',
      help   = 'A restart criteria to select tests to rerun, "-r wrong" will restart all test that did not pass.  This will span targets, "-r" only does the current target',
   }

   cmdlineParser:add_option{
      name   = {'-s','--status'},
      dest   = 'statusList',
      action = 'append',
      type   = 'string',
      help   = 'Only print individual test that match a particular status, "-s wrong" reports all tests that do not pass',
   }

   cmdlineParser:add_option{
      name   = {'-t','--target'},
      dest   = 'targetList',
      action = 'append',
      type   = 'string',
      help   = 'A target string.  It sets $(TARGET) in runScript',
   }

   cmdlineParser:add_option{
      name   = {'--tag'},
      dest   = 'tagA',
      action = 'append',
      type   = 'string',
      help   = 'Tag test with string given',
   }

   cmdlineParser:add_option{
      name   = {'-v','--verbose'},
      dest   = 'verbosityLevel',
      action = 'count',
      help   = 'Increasing the level of verbosity help output',
   }

   cmdlineParser:add_option{
      name   = {'-D','--debug'},
      dest   = 'debugLevel',
      action = 'count',
      help   = 'Increasing the level of debug support',
   }

   cmdlineParser:add_option{
      name   = {'-x','--max', '--maxNP'},
      dest   = 'maxNP',
      action = 'store',
      type   = 'number',
      help   = 'the maximum number of processor that will be run',
   }

   local optionTbl, pargs = cmdlineParser:parse(arg)

   if (#optionTbl.Restart > 0) then
      optionTbl.restart = optionTbl.Restart
   end

   if (optionTbl.AnalyzeFlag) then
      optionTbl.analyzeFlag = optionTbl.AnalyzeFlag
   end

   for v in pairs(optionTbl) do
      masterTbl[v] = optionTbl[v]
   end
   masterTbl.pargs = pargs

   masterTbl.cwd = getcwd()
   if (masterTbl.batchLog) then
      if (masterTbl.batchLog:sub(1,1) ~= '/') then
         masterTbl.batchLog = pathJoin(masterTbl.cwd,masterTbl.batchLog)
      end
      unlink(masterTbl.batchLog)
   end

   masterTbl.tagA       = expandOptions(masterTbl.tagA)
   masterTbl.targetList = expandOptions(masterTbl.targetList)
   masterTbl.spanning   = masterTbl.AnalyzeFlag or (#masterTbl.Restart > 0) or
                          (#masterTbl.tagA > 0) or (#masterTbl.targetList > 1)
end

function expandOptions(aa)
   local a = {}
   for _,v in ipairs(aa) do
      for word in v:split("[ :,]") do
	 local s = word:trim()
	 if (s ~= "") then
	    a[#a+1] = s
	 end
      end
   end
   return a
end
