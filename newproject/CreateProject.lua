_DEBUG        = false
local posix   = require("posix")
local unistd  = require("posix.unistd")
local chdir   = unistd.chdir

CreateProject = BaseTask:new()

function CreateProject:execute(myTable)
   local masterTbl = masterTbl()
   local projName  = masterTbl.pargs[1]

   os.execute("mkdir ".. projName)
   chdir(projName)
   userName = os.getenv("USER")
   if (userName == nil) then
      userName = os.getenv("LOGNAME")
   end

   if (userName == nil) then
      userName = ''
   end

   tbl = {
      ProjectName  = projName,
      TestLocation = 'rt',
      UserName     = userName,
      PackageList  = {}
   }

   serializeTbl{name="ProjectData", value=tbl, fn="Hermes.db",indent=true}
end
