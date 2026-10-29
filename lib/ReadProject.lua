_DEBUG      = false
local posix = require("posix")

ReadProject = BaseTask:new()
require("strict")
require("fileOps")
local dbg    = require("Dbg"):dbg()
local getcwd = require("posix.unistd").getcwd

local function findPackageName(fileName)
   local masterTbl   = masterTbl()
   local projectDir  = masterTbl.projectDir
   local projectData = masterTbl.projectData

   local i,j, p, icnt
   local pkgTbl = {}
   local icnt   = 0
   for _,v in ipairs(projectData.PackageList or {}) do
      pkgTbl[v.pkgName] = v
      icnt = icnt + 1
   end

   if (icnt == 0) then
      return ""
   end

   local paths = {}

   i,j, p = fileName:find( projectDir .. "/(.*)")

   if (p == nil) then
      return ""
   end 

   while (1) do
      paths[#paths + 1] = p
      i,j, p = p:find("^(.*)/")
      if (not i) then break end
   end

   local pkgName = ""
   for _,p in ipairs(paths) do
      if (pkgTbl[p]) then
	 pkgName = p
	 break
      end
   end
   if (pkgName == "") then
      pkgName = paths[#paths]
   else
      local t = pkgTbl[pkgName]
      for k in pairs(t) do
         masterTbl[k] = t[k]
      end
   end

   return pkgName
end

function ReadProject:execute(myTable)
   local masterTbl  = masterTbl()

   masterTbl.projectDir = findDirInDirTree(getcwd(),masterTbl.projectFn)
   local projectFn = pathJoin(masterTbl.projectDir, masterTbl.projectFn)
   assert(loadfile(projectFn))()
   
   masterTbl.projectData = ProjectData
   masterTbl.packageName = findPackageName(getcwd())
   masterTbl.packageDir  = pathJoin(masterTbl.projectDir, masterTbl.packageName)

   dbg.print{"packageDir:  ","\"",masterTbl.packageDir,"\"\n"}
   dbg.print{"packageName: ","\"",masterTbl.packageName,"\"\n"}
   dbg.print{"projectDir:  ","\"",masterTbl.projectDir,"\"\n"}

end

