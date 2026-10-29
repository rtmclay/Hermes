_DEBUG             = false
local posix        = require("posix")
local unistd       = require("posix.unistd")
local posix_getenv = unistd.getenv
local posix_setenv = unistd.setenv

PairTest = BaseTask:new()
require("fileOps")
local lfs = require("lfs")

local max       = math.max
local concatTbl = table.concat

local ignoreT   = { [".msg"] = 1, [".log"] = 1}

local function findFiles(path, pattern)
   local a = {}
   for file in lfs.dir(path) do
      local ext = extname(file)
      if (not ignoreT[ext]) then
         local i,j  = file:find(pattern)
         if (i) then
            a[#a + 1] = file
         end
      end
   end
   table.sort(a)
   return a
end

function PairTest:execute(myTable)
   local masterTbl = masterTbl()
   local cmd       = masterTbl.cmd
   local OVERWRITE = true
   local passed    = true
   local nStep     = masterTbl.nStep

   if (not cmd) then
      masterTbl.status = 1
      return
   end

   if (nStep < 0) then
      nStep = cmd.maxStep
   end


   for iStep = 0, nStep do
      posix_setenv(cmd.PREFIX .. "EVENTSTEP", iStep, OVERWRITE)
      print ("-----------------------------------------")
      print ("   EventStep: "..tostring(iStep))
      print ("-----------------------------------------\n")

      for _,v in ipairs(cmd.runCmd) do
         io.stdout:write(" Running: ",v,"\n")
         os.execute("("..v .. ") 2>&1 >/dev/null")
      end
      
      local fn1A = findFiles(cmd.testA.dirs[1], cmd.testA.fn)
      local fn2A = findFiles(cmd.testA.dirs[2], cmd.testA.fn)

      local num  = max(#fn1A, #fn2A)
      for i = 1, num do
         if (fn1A[i] ~= fn2A[i]) then
            print("1:", tostring(fn1A[i]), "2:", tostring(fn2A[i]))
            return
         else
            local a = {}
            a[#a + 1] = "cmp"
            a[#a + 1] = pathJoin(cmd.testA.dirs[1], fn1A[i])
            a[#a + 1] = pathJoin(cmd.testA.dirs[2], fn1A[i])
            a[#a + 1] = "2>&1 > /tmp/testCmd.out"
            local cmdStr = concatTbl(a," ")
            local status = os.execute(cmdStr)
            if (status ~= 0) then
               os.execute("cat /tmp/testCmd.out")
               os.execute("rm /tmp/testCmd.out")
               os.execute("cat ".. pathJoin(cmd.testA.dirs[1], cmd.testA.fn) .. ".msg")
               os.execute("cat ".. pathJoin(cmd.testA.dirs[2], cmd.testA.fn) .. ".msg")
               return
            end
            os.execute("rm /tmp/testCmd.out")
         end
      end
      print ("------------------------------------------")
      print ("   EventStep: "..tostring(iStep).." Passed")
      print ("------------------------------------------")
      print ("\n")
   end
end

