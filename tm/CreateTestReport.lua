-- $Id: CreateTestReport.lua 287 2008-11-06 18:45:20Z mclay $ --

CreateTestReport = BaseTask:new()

require("serialize")
require("fileOps")

function CreateTestReport:execute(myTable)
   local masterTbl	 = masterTbl()
   local target          = myTable.target

   local prefix = ""
   if (target ~= "") then
      prefix = target .. "-"
   end

   local uuid            = prefix .. UUIDString(masterTbl.epoch) .. "-" .. masterTbl.os_mach
   local tstReportFn	 = pathJoin(masterTbl.testRptDir, uuid .. masterTbl.testRptExt)
   masterTbl.tstReportFn = tstReportFn

   --------------------------------------------------------
   -- Do not create a report when there are no tests to run

   if (#masterTbl.tstTbl == 0) then return end

   local HumanData	 = ''
   local testresults	 = buildTestReportTable(HumanData,masterTbl)

   serialize{name="testresults", value=testresults, fn=tstReportFn, indent=true}
end