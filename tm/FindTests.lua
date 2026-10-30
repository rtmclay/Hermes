_DEBUG      = false
local posix = require("posix")
require("strict")
FindTests = BaseTask:new()
require("common")
require("Tst")
require("dirlist")
require("fileOps")
local Dbg    = require("Dbg")
local access = require("posix.unistd").access
local chdir  = require("posix.unistd").chdir
local getcwd = require("posix.unistd").getcwd
local stat   = require("posix.sys.stat")

function FindTests:execute(myTable)
   local masterTbl         = masterTbl()
   local pargs             = {}
   local dbg               = Dbg:dbg()
   masterTbl.candidateTsts = {}

   if (masterTbl.spanning ~= myTable.spanning) then return end

   for _,v in ipairs(masterTbl.pargs) do
      pargs[#pargs + 1] = v
   end
   
   if (#pargs < 1) then
      if (#masterTbl.restart > 0 or masterTbl.analyzeFlag) then
         FindTests:findLastTM(pargs)
      else
         local fn = pathJoin(masterTbl.projectDir, masterTbl.testlistFn)
         if (isFile(fn)) then
            pargs[#pargs + 1] = fn
         else
            pargs[#pargs + 1] = "."
         end
      end
   elseif (#masterTbl.restart > 0 or masterTbl.analyzeFlag) then
      for i = 1, #pargs do
         local path = pargs[i]
         local ext  = extname(path)
         if (ext ~= ".tm") then
            Error("Illegal file: ",path,"\n",
                  "The options -r and -a expect *.tm files in the $(projectdir)/testreport directory\n",
                  "or none when using the last generated testing run")
         end
      end
   end

   for i,path in ipairs(pargs) do
      local mystat = stat.stat(path)
      if (mystat == nil) then
         path   = pathJoin(masterTbl.projectDir,path)
         mystat = stat.stat(path)
      end
      dbg.print{"Reading: ",path,"\n"}
      if (stat.S_ISREG(mystat.st_mode) ~= 0) then
	 if (path:find(masterTbl.testRptExt.."$")) then
	    FindTests:readTMfile(path)
	 elseif (path:find(masterTbl.descriptExt.."$")) then
	    FindTests:readTestDescriptFn(path)
	 else
	    FindTests:readTestList(path)
	 end
      else
         dbg.print{"Searching: ",path,"\n"}
	 FindTests:search(path)
      end
   end
end

function FindTests:buildCandidateTsts(testA, ntimes, target, epoch, candidateTsts)
   local idA = {}
   for _,v in ipairs(testA) do
      idA[#idA+1] = v.id
   end
   FindTests:buildCandidateTsts_id(idA, ntimes, target, epoch, candidateTsts)

   local tstKeys = Tst:testfields()

   -- Copy results from previous run to current test.
   -- Active is controlled by user input not last run.

   for _,v in ipairs(testresults.tests) do
      local tst    = candidateTsts[v.id]
      v.active     = tst:get("active")
      for _,key in ipairs(tstKeys) do 
	 tst[key] = v[key]
      end
   end
end

function FindTests:readTestDescriptFn(path)
   local masterTbl = masterTbl()
   local tagA      = masterTbl.tagA
   local targetA   = masterTbl.targetA
   local fn        = pathJoin(getcwd(), path)
   local epoch     = masterTbl.origEpoch
   local dbg       = Dbg:dbg()
   assert(loadfile(fn))()
   dbg.print{"Found: ",fn,"\n"}
   if (masterTbl.spanning) then
      masterTbl.tagTbl = masterTbl.tagTbl or {} 
      for _,tag       in ipairs(tagA)    do
         masterTbl.tagTbl[tag]           = masterTbl.tagTbl[tag] or {} 
         masterTbl.tagTbl[tag].targetTbl = masterTbl.tagTbl[tag].targetTbl or {}
         local targT                     = masterTbl.tagTbl[tag].targetTbl
	 for _,target in ipairs(targetA) do
            targT[target]               = targT[target] or {} 
	    targT[target].candidateTsts = targT[target].candidateTsts or {} 
            targT[target].target        = target
            local candidateTsts         = targT[target].candidateTsts
	    local tstTbl                = buildTstTbl(fn, testdescript, target, epoch, masterTbl.ntimes)
	    for id in pairs(tstTbl) do
	       candidateTsts[id] = tstTbl[id]
	    end
            targT[target].epoch = epoch
	 end
      end
   else
      local target            = masterTbl.target
      local tstTbl            = buildTstTbl(fn, testdescript, target, epoch, masterTbl.ntimes)
      masterTbl.epoch         = epoch
      masterTbl.target        = target
      masterTbl.candidateTsts = masterTbl.candidateTsts or {}
      local candidateTsts     = masterTbl.candidateTsts
      for id in pairs(tstTbl) do
	 candidateTsts[id] = tstTbl[id]
      end
   end
end

function FindTests:readTMfile(path)
   local masterTbl = masterTbl()
   local tagA      = masterTbl.tagA
   local dbg       = Dbg:dbg()
   dbg.print{"readTMfile: ",path,"\n"}
   assert(loadfile(path))()

   -- Use original Epoch from TM file
   local epoch         = testresults.origEpoch

   local ntimes = testresults.ntimes
   masterTbl.ntimes = ntimes
   if (masterTbl.spanning) then
      local tag                       = testresults.tag
      masterTbl.tagTbl                = masterTbl.tagTbl or {} 
      masterTbl.tagTbl[tag]           = masterTbl.tagTbl[tag] or {}
      masterTbl.tagTbl[tag].origEpoch = epoch
      masterTbl.tagTbl[tag].targetTbl = masterTbl.tagTbl[tag].targetTbl or {} 
      local targT                     = masterTbl.tagTbl[tag].targetTbl
      for target in pairs(testresults.tests.targetTbl) do
	 local a                     = testresults.tests.targetTbl[target]
         targT[target]               = targT[target] or {} 
         targT[target].candidateTsts = targT[target].candidateTsts or {}
	 FindTests:buildCandidateTsts(a, ntimes, target, epoch, targT[target].candidateTsts)
	 targT[target].ntimes        = ntimes
	 targT[target].origEpoch     = epoch
	 targT[target].epoch         = epoch
	 targT[target].tag           = testresults.tag
      end
   else
      local target            = testresults.target
      local a                 = testresults.tests
      masterTbl.candidateTsts = masterTbl.candidateTsts or {}
      masterTbl.tag           = testresults.tag
      masterTbl.epoch         = epoch
      masterTbl.origEpoch     = epoch
      masterTbl.target        = target
      FindTests:buildCandidateTsts(a, ntimes, target, epoch, masterTbl.candidateTsts)
   end
end

function FindTests:readTestList(fn)
   local masterTbl = masterTbl()
   local tagA      = masterTbl.tagA
   local targetA   = masterTbl.targetA
   local dbg       = Dbg:dbg()
   dbg.print{"readTestList: ",fn,"\n"}
   assert(loadfile(fn))()

   local epoch = masterTbl.origEpoch

   local ntimes = masterTbl.ntimes
   if (masterTbl.spanning) then
      masterTbl.tagTbl = masterTbl.tagTbl or {} 
      for tag       in ipairs(tagA)    do
         masterTbl.tagTbl[tag]           = masterTbl.tagTbl[tag] or {}
         masterTbl.tagTbl[tag].targetTbl = masterTbl.tagTbl[tag].targetTbl or {}
         local targT                     = masterTbl.tagTbl[tag].targetTbl
	 for target in ipairs(targetA) do
            targT[target]               = targT[target] or {}
            targT[target].epoch         = epoch
	    targT[target].candidateTsts = targT[target].candidateTsts or {}
	    FindTests:buildCandidateTsts_id(testlist, ntimes, target, epoch, targT[target].candidateTsts)
	 end
      end
   else
      masterTbl.epoch         = epoch
      local target            = targetA[1]
      masterTbl.target        = targetA[1]
      masterTbl.candidateTsts = masterTbl.candidateTsts or {}
      FindTests:buildCandidateTsts_id(testlist, ntimes, target, epoch, masterTbl.candidateTsts)
   end
end

function FindTests:buildCandidateTsts_id(idA, ntimes, target, epoch, candidateTsts)
   local masterTbl = masterTbl()

   -- Transform id into test description file
   -- with a list of id's used

   local fnTbl = {}
   for _,id in ipairs(idA) do
      local _, _, fn, idTag = id:find("^(.*)/(.*)")
      fn = pathJoin(masterTbl.projectDir, fn .. ".tdesc")
      fnTbl[fn] = fnTbl[fn] or {}
      table.insert(fnTbl[fn],id)
   end

   local cwd = getcwd()
   -- Read in test description file, store tests with id
   -- in masterTbl.candidateTsts 
   for fn in pairs(fnTbl) do
      local d, f = splitFileName(fn)
      chdir(d)
      assert(loadfile(f))()
      local tstTbl = buildTstTbl(fn, testdescript, target, epoch, ntimes)
      for i,id in ipairs(fnTbl[fn]) do
	 candidateTsts[id] = tstTbl[id]
      end
   end
   chdir(cwd)
end

function FindTests:search(path)
   local dbg       = Dbg:dbg()
   local masterTbl = masterTbl()

   if (not access(path)) then return end
   local cwd	   = getcwd()
   chdir(path)
   if (masterTbl.verbosityLevel > 3) then
      dbg.print{"Searching: ",cwd,"\n"}
   end
   dbg.print{"FindTests:search dirlist(\".\")"}
   local list	   = dirlist(".")
   local found     = false
   for _,v in ipairs(list.files) do
      if (v:find("%.tdesc$")) then
	 FindTests:readTestDescriptFn(v)
	 found = true
      end
   end

   if (not found) then
      for _,v in ipairs(list.dirs) do
	 local dir = pathJoin(getcwd(), v)
	 FindTests:search(dir)
      end
   end
   chdir(cwd)
end

function FindTests:findLastTM(pargs)
   local dbg        = Dbg:dbg()
   local masterTbl  = masterTbl()
   local pattern    = masterTbl.os_mach .. '%' .. masterTbl.testRptExt .. "$"
   pattern          = pattern:gsub("%-", "%%-")
   local tmTbl      = {}
   local testRptDir = masterTbl.testRptDir

   local tagA
   if (masterTbl.spanning) then
      tagA = masterTbl.tagA
   else
      tagA = {''}
   end

   for _, tag in ipairs(tagA) do
      if (masterTbl.spanning) then
	 testRptDir = pathJoin(masterTbl.testRptDirRoot,".span",tag)
      end

      dbg.print{"FindTests:findLastTM:  filelist(\"",testRptDir ,"\")\n"}
      local list	    = filelist(testRptDir)
      for _,v in ipairs(list) do
	 if (v:find(pattern)) then
	    tmTbl[#tmTbl + 1] = v
	 end
      end
      local tmFileName = nil
      if (#tmTbl > 0) then
	 table.sort(tmTbl)
	 for i = #tmTbl, 1, -1 do
	    local fn = pathJoin(testRptDir, tmTbl[i])
	    local attr = lfs.attributes(fn)
	    if (attr and attr.size > 0) then tmFileName = fn; break end
	 end
      end
      if (tmFileName) then
	 pargs[#pargs+1] = tmFileName
      end
   end
end
