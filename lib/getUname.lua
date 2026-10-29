_DEBUG      = false
local posix   = require("posix")
local utsname = require("posix.sys.utsname")


require("strict")
function getUname()
   local t                = {}
   local info             = utsname.uname()
   local osName		  = info.sysname
   local machName	  = info.machine
   osName		  = string.gsub(osName,"[ /]","_")
   if (string.lower(osName) == "aix") then
      machName = "rs6k"
   elseif (osName:lower():sub(1,4) == "irix") then
      osName   = "Irix"
      machName = "mips"
   end
   t.osName    = osName
   t.machName  = machName
   t.hostName  = info.nodename
   t.os_mach   = osName .. '-' .. machName
   t.target    = os.getenv("TARGET") or ""

   return t
end
