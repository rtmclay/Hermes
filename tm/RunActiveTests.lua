_DEBUG         = false
local posix    = require("posix")
require("strict")
require("common")
require("JobSubmitBase")
require("serializeTbl")
require("CleanEnv")
require("fileOps")
local chdir    = require("posix.unistd").chdir
local dbg      = require("Dbg"):dbg()
local getcwd   = require("posix.unistd").getcwd
local unlink   = require("posix.unistd").unlink
RunActiveTests = BaseTask:new()
comment    = [[
   Test Results:
      'notfinished': means that the test has started but not completed.
      'failed': means that the test has started but not completed.
      'notrun': test has not started running.
      'diff'  : Test has run but is different from gold copy.
      'passed': Test has run and matches gold copy.]]
resultTbl = {
   started = {
      testresult = 'notfinished',
      comment    = comment
   },
   notrun = {
      testresult = 'notrun',
      comment    = comment
   }, 
}


local function MakeDir(path)
   local paths  = {}
   local myPath = fixFileName(path)
   while (1) do
      local i, j
      if (isDir(myPath)) then break end
      table.insert(paths, 1, myPath)
      i, j, myPath = myPath:find("^(.*)/")
      if (not i) then break end
   end

   for _,v in ipairs(paths) do
      posix.mkdir(v)
   end
end

function RunActiveTests:execute(myTable)
   local masterTbl = masterTbl()

   masterTbl.passed       = 0
   masterTbl.failed       = 0

   local numTests         = 0
   local rptTests         = 0

   for tag       in pairs(masterTbl.tagTbl)    do
      for target in pairs(masterTbl.tagTbl[tag].targetTbl) do
	 numTests     = numTests + countEntries(masterTbl.tagTbl[tag].targetTbl[target].tstTbl)
	 rptTests     = rptTests + countEntries(masterTbl.tagTbl[tag].targetTbl[target].rptTbl)
      end
   end

   masterTbl.rptTests        = rptTests

   if (numTests > 0) then
      print("\nStarting Tests:\n")
   end 

   cleanEnv()

   local i = 0
   for tag       in pairs(masterTbl.tagTbl)    do
      for target in pairs(masterTbl.tagTbl[tag].targetTbl) do
	 local mTbl   = masterTbl.tagTbl[tag].targetTbl[target]
	 _G.masterTbl = function() return mTbl end
	 local cwd    = getcwd() 
	 local tstTbl = mTbl.tstTbl
	 mTbl.passed  = masterTbl.passed
	 mTbl.failed  = masterTbl.failed
         
	 RunActiveTests:makeOutputDirs(tstTbl)
	 
	 for id in pairs(tstTbl) do
	    i = i+1
	    RunActiveTests:runTest(mTbl, tstTbl[id], i, numTests)
	 end
	 chdir(cwd)
	 masterTbl.passed = masterTbl.passed + mTbl.passed
	 masterTbl.failed = masterTbl.failed + mTbl.failed
      end
   end

   _G.masterTbl = function() return masterTbl end

   masterTbl = _G.masterTbl()

   if (numTests > 0) then
      print("\nFinished Tests\n")
   end 
end

function RunActiveTests.makeOutputDirs(self, tstTbl)
   local runtime  = { start_time = -1, end_time = -1 }

   for id in pairs(tstTbl) do
      local tst	      = tstTbl[id]
      local outputDir = tst:get('outputDir')
      MakeDir(fullFn(outputDir))
   end
   
   for id in pairs(tstTbl) do
      local tst	      = tstTbl[id]
      local resultFn  = fullFn(tst:get('resultFn')  )
      local runtimeFn = fullFn(tst:get('runtimeFn') )
      
      serializeTbl{name="myResult", value=resultTbl.notrun, fn=resultFn , indent=true}
      serializeTbl{name="runtime",  value=runtime,          fn=runtimeFn, indent=true}
   end
end

function RunActiveTests:runTest(masterTbl, tst, iTest, numTests)
   local fn_envA        = {'testDir', 'outputDir', 'resultFn',   'testdescriptFn',
                           'cmdResultFn', 'messageFn', 'runtimeFn'}
   local envA           = {'idTag',   'testName',  'packageName', 'packageDir',
                            'TARGET', 'target', 'tag',}
   local envTbl		= {}


   for _,v in ipairs(fn_envA) do
      envTbl[v] = fixFileName(fullFn(tst:get(v)));
   end
   for _,v in ipairs(envA) do
      envTbl[v] = tst:get(v);
   end
   envTbl.projectDir = masterTbl.projectDir

   ------------------------------------------------------------
   -- Find job submit method

   local jobSubmitMethod = tst:get("job_submit_method") or "INTERACTIVE"
   if (masterTbl.BatchFlag) then
      jobSubmitMethod = "BATCH"
   elseif (masterTbl.InteractiveFlag) then
      jobSubmitMethod = "INTERACTIVE"
   end


   local job             = JobSubmitBase:build(jobSubmitMethod, masterTbl)

   local runScript       = tst:expandRunScript(envTbl, job)

   local cwd = getcwd()
   chdir(envTbl.outputDir)
   
   unlink(fullFn(tst:get('cmdResultFn')))

   local resultFn  = fullFn(tst:get('resultFn'))
   serializeTbl{name='myResult', value=resultTbl.started, fn=resultFn, indent=true}
   local t      = epoch()
   local stime  = { start_time = t, end_time = -1 }
   tst:set('start_epoch', t)

   serializeTbl{name="runtime",  value=stime,  fn=fullFn(tst:get('runtimeFn')), indent=true}
   
   local idTag       = envTbl.idTag
   local scriptFn    = idTag .. ".script"
   local f           = assert(io.open(scriptFn,"w"))
   f:write(tst:topOfScript(),"\n")
   f:write(runScript)
   f:close()

   posix.chmod(scriptFn,"rwx------")

   local id         = tst:get('id')
   local background = tst:get('background') or (jobSubmitMethod == "BATCH")
   tst:set('runInBackground',background)

   job:Msg('Started', iTest, numTests, id, envTbl.resultFn, background)
   job:runtest{scriptFn = scriptFn, idTag = idTag, background = background}
   job:Msg('Finished', iTest, numTests, id, envTbl.resultFn, background)

   chdir(cwd)
end
