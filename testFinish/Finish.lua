_DEBUG      = false
local posix = require("posix")

require("strict")
require("build_epoch")
require("serializeTbl")
require("getUname")
require("fileOps")
require("string_utils")

local dbg   = require("Dbg"):dbg()
local lfs   = require("lfs")
local load  = (_VERSION == "Lua 5.1") and loadstring or load

Finish = BaseTask:new()

function Finish.parseInput(self, fnA)

   local result = "passed"

   for i = 1, #fnA do
      local fn = fnA[i]

      local attr = lfs.attributes(fn)
      if ( not attr or type(attr) ~= "table" or attr.mode ~= "file") then
         return "failed"
      end

      local ext     = extname(fn)
      local singleR
      if (ext == ".lua") then
         singleR = self:parseLuaResult(fn)
      else
         singleR = self:parseCSVResult(fn)
      end
      if (singleR ~= "passed") then
         return singleR
      end
   end
   return result
end

acceptT = { failed = true, passed = true, diff = true } 

function Finish.parseCSVResult(self, fn)
   local result = "passed"
   local f      = io.open(fn,"r")
   local whole  = f:read("*all")
   local found  = false
   f:close()

   for myLine in whole:split("\n") do
      local line  = myLine:trim()
      local first = line:sub(1,1)
      if (first ~= "#" and line:len() > 0) then
         local word = line
         local idx  = line:find(',')
         if (idx) then
             word = line:sub(1, idx-1)
         end
         word       = word:lower()
         found      = true
         if (word ~= "passed") then
            result = word
            break
         end
      end
   end
   if (not found) then
      result = "failed"
   end
   return acceptT[result] and result or "failed"
end

function Finish.parseLuaResult(self, fn)
   local f      = io.open(fn,"r")
   local result = "passed"
   local found  = false
   if (f) then
      local s = f:read("*all")
      assert(load(s))()
      for i,v in ipairs(myTbl) do
         local word  = v.result:lower()

         found       = true
	 if (word ~= "passed") then
            result = word
	 end
      end
   end
   if (not found) then
      result = "failed"
   end
   return acceptT[result] and result or "failed"
end



function Finish.execute(self,myTable)
   local masterTbl = masterTbl()

   ---------------------------------------------------------------
   -- Diff tools write out "result.lua"
   local resultFn     = masterTbl.resultFn
   local runtimeFn    = masterTbl.runtimeFn
   local pargs        = masterTbl.pargs
   local failFn       = masterTbl.failFn
   if (masterTbl.cmdResultFn) then
      pargs[#pargs+1] = masterTbl.cmdResultFn
   end

   if (failFn and isFile(failFn)) then
      os.remove(failFn)
   end

   local result       = self:parseInput(pargs)

   if (result ~= "passed" and failFn) then
      local f = io.open(failFn,"w")
      if (f) then
         f:close()
      end
   end

   local myResult = { testresult = result }

   serializeTbl{name="myResult", value=myResult, fn=resultFn, indent=true}

   local t = getUname()
   build_epoch()

   assert(loadfile(runtimeFn))()
   runtime.end_time = epoch()

   for k in pairs(t) do
      runtime[k] = t[k]
   end

   serializeTbl{name="runtime",  value=runtime,  fn=runtimeFn, indent=true}
end
