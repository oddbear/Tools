using System.Configuration;
using System.IO;
using EFGuidIdentityPatcher.Common;

namespace GetDefaultValues
{
    class Program
    {
		/*
		An old example I made of a pathing tool for EF edmx files.
		
		It finds and fixed the problem of NEWSEQUENTIALID not identified as "Identity" in edmx files generated from EF.
		
		KB2561001 did make you able to fix this manually, you did however have to do this for every column manually every time you regenerated the edmx file.
		This tool did the same, but found those columns and automated the process.
		*/
        static void Main(string[] args)
        {
            var connectionString = "data source=.;initial catalog=testdb;integrated security=True;multipleactiveresultsets=True;App=patcherApp";
            var xmlFile = Path.Combine(@".\file.edmx");

            var patchingInfo = new PatchingInfo(connectionString, xmlFile);

            var dbContext = new DbContext(patchingInfo);
            var list = dbContext.GetDefualtValues();
            var patcher = new Patcher(patchingInfo, list);
            patcher.Patch();
        }
    }
}