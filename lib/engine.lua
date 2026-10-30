-- -*- lua -*-
_DEBUG       = false
local posix  = require("posix")
local chdir  = require("posix.unistd").chdir
local getcwd = require("posix.unistd").getcwd

require("strict")
local dbg   = require("Dbg"):dbg()
require("fileOps")
Error  = nil
engine = {}
master = {
   projectFn  = "Hermes.db",
}
function ErrorStd(...)
   ErrorDbg(...)
   os.exit(1)
end

function fixFileName(name)
   name = name:gsub("[ &'\"!()[@#]","_")
   name = name:gsub("]","_")
   return name
end


function ErrorDbg(...)
   io.stderr:write("\nError: ")
   for _,v in ipairs{...} do
      io.stderr:write(v)
   end
   io.stderr:write("\n")
end

function engine.buildLuaPath(taskDir, execName)
   local luaPathTbl = {}
   table.insert(luaPathTbl, pathJoin(taskDir, "?" ))
   table.insert(luaPathTbl, pathJoin(taskDir, "?.lua"))
   table.insert(luaPathTbl, "?.lua;?")
   table.insert(luaPathTbl, package.path)
   package.path = table.concat(luaPathTbl,";")
end

function engine.splitCmdName(path)
   return splitFileName(path)
end

function engine.execute(execDir, execName)
   engine.execDir   = execDir
   engine.execName  = execName
   local masterTbl  = masterTbl()

   -- Load the Hermes.db file from the Hermes Project file: Hermes.db
   local projDir = findDirInDirTree(engine.execDir, masterTbl.projectFn)

   local fn = pathJoin(projDir, masterTbl.projectFn)
   assert(loadfile(fn))()

   masterTbl.HermesVersion = ProjectData.HermesVersion

   local taskDir      = pathJoin(projDir, execName) 
   local taskFileName = pathJoin(taskDir, execName .. ".tasks")

   masterTbl.taskDir = taskDir

   assert(loadfile(taskFileName))()

   engine.buildLuaPath(taskDir,execName)
   require("BaseTask")

   -- count number of '-v' or '--verbose' in argument list

   local verboseCnt = 0
   local debugCnt = 0
   for i,v in ipairs(arg) do
      if (v == '-v' or v == '--verbose') then verboseCnt = verboseCnt + 1 end
      if (v == '-D' or v == '--debug')   then debugCnt   = debugCnt   + 1 end
      
   end

  
   engine.verboseCnt = math.max(verboseCnt, debugCnt)

   Error = ErrorStd
   if (engine.verboseCnt > 0) then
      dbg:activateDebug(engine.verboseCnt) 
   end
   
   dbg.start{"engine()"}
   dbg.start{"engine initial state()", level=2}
   dbg.print{'projDir:      ',projDir,      "\n"}
   dbg.print{'execDir:      ',execDir,      "\n"}
   dbg.print{'execName:     ',execName,     "\n"}
   dbg.print{'taskDir:      ',taskDir,      "\n"}
   dbg.print{'taskFileName: ',taskFileName, "\n"}
   dbg.fini("engine initial state")


   local rtn = taskMain()
   dbg.fini("engine")

   return rtn
end

function engine.verbosityLevel()
   return engine.verboseCnt
end

function findDirInDirTree(wd, fn)
   local masterTbl  = masterTbl()
   local cwd        = getcwd()
   local dir        = nil
   local prev       = ""
   local posix_stat = require("posix.sys.stat")

   chdir(wd)
   while (true) do
      local fullFn = pathJoin(wd,  fn)
      local mystat = posix_stat.stat(fullFn)
      if (mystat and posix_stat.S_ISREG(mystat.st_mode) ~= 0) then
         dir = wd
         break
      end
      if (wd == '/' or wd == prev) then
         Error("You must be in a project! Did not find: " .. masterTbl.projectFn)
      end
      prev = wd
      chdir("..")
      wd  = getcwd()
   end

   chdir(cwd)
   return dir
end

function masterTbl()
   return master
end

function task(myTable)
   local name = myTable[1]
   table.remove(myTable,1)

   dbg.start{"task{",name,"}"}
   require(name)
   local myTask = _G[name]:new(name)

   myTask:execute(myTable)
   dbg.fini()
end
